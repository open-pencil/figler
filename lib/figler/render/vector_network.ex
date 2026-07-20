defmodule Figler.Render.VectorNetwork.Vertex do
  @moduledoc "A typed editable-vector vertex."

  @enforce_keys [:position]
  defstruct [:position]

  @type t :: %__MODULE__{position: Figler.Render.Vector.t()}
end

defmodule Figler.Render.VectorNetwork.Segment do
  @moduledoc "A typed editable-vector cubic segment with relative tangent handles."

  @enforce_keys [:start, :end, :tangent_start, :tangent_end]
  defstruct [:start, :end, :tangent_start, :tangent_end]

  @type t :: %__MODULE__{
          start: non_neg_integer(),
          end: non_neg_integer(),
          tangent_start: Figler.Render.Vector.t(),
          tangent_end: Figler.Render.Vector.t()
        }
end

defmodule Figler.Render.VectorNetwork.Region do
  @moduledoc "A filled editable-vector region composed from ordered segment loops."

  @enforce_keys [:winding_rule, :loops]
  defstruct [:winding_rule, :loops]

  @type t :: %__MODULE__{
          winding_rule: :even_odd | :winding,
          loops: [[non_neg_integer()]]
        }
end

defmodule Figler.Render.VectorNetwork.Ref do
  @moduledoc "A normalized reference to an editable-vector blob and its source coordinate size."

  alias Figler.Render.Vector

  defstruct [:blob_index, :normalized_size]

  @type t :: %__MODULE__{
          blob_index: non_neg_integer() | nil,
          normalized_size: Vector.t() | nil
        }

  @doc false
  @spec from_sparse(map() | {term(), map() | nil} | nil) :: t() | nil
  def from_sparse(nil), do: nil

  def from_sparse({blob_index, normalized_size}) do
    %__MODULE__{
      blob_index: blob_index,
      normalized_size: Vector.from_sparse(normalized_size)
    }
  end

  def from_sparse(value) when is_map(value) do
    %__MODULE__{
      blob_index: Map.get(value, :vector_network_blob),
      normalized_size: Vector.from_sparse(Map.get(value, :normalized_size))
    }
  end
end

defmodule Figler.Render.VectorNetwork do
  @moduledoc "A rendering-neutral decoded Figma editable-vector network."

  alias Figler.Render.Vector
  alias Figler.Render.VectorNetwork.Region
  alias Figler.Render.VectorNetwork.Segment
  alias Figler.Render.VectorNetwork.Vertex

  @enforce_keys [:vertices, :segments, :regions]
  defstruct [:vertices, :segments, :regions]

  @type t :: %__MODULE__{
          vertices: [Vertex.t()],
          segments: [Segment.t()],
          regions: [Region.t()]
        }

  @doc "Decodes and validates one Figma editable-vector blob."
  @spec decode(binary(), Vector.t() | nil, Vector.t() | nil) :: {:ok, t()} | {:error, term()}
  def decode(blob, normalized_size \\ nil, node_size \\ nil) when is_binary(blob) do
    with {:ok, {vertex_count, segment_count, region_count, rest}} <- header(blob),
         :ok <- validate_minimum_size(rest, vertex_count, segment_count, region_count),
         {:ok, {vertices, rest}} <- vertices(rest, vertex_count, []),
         {:ok, {segments, rest}} <- segments(rest, segment_count, []),
         {:ok, {regions, rest}} <- regions(rest, region_count, []),
         :ok <- trailing_bytes(rest),
         network = %__MODULE__{vertices: vertices, segments: segments, regions: regions},
         :ok <- validate(network) do
      scale(network, normalized_size, node_size)
    end
  end

  defp header(
         <<vertex_count::little-unsigned-32, segment_count::little-unsigned-32,
           region_count::little-unsigned-32, rest::binary>>
       ),
       do: {:ok, {vertex_count, segment_count, region_count, rest}}

  defp header(_blob), do: {:error, :truncated_vector_network_header}

  defp validate_minimum_size(rest, vertex_count, segment_count, region_count) do
    minimum = vertex_count * 12 + segment_count * 28 + region_count * 8
    if minimum <= byte_size(rest), do: :ok, else: {:error, :invalid_vector_network_counts}
  end

  defp vertices(rest, 0, values), do: {:ok, {Enum.reverse(values), rest}}

  defp vertices(
         <<_style_id::little-unsigned-32, x::little-float-32, y::little-float-32, rest::binary>>,
         remaining,
         values
       ) do
    vertex = %Vertex{position: %Vector{x: x, y: y}}
    vertices(rest, remaining - 1, [vertex | values])
  end

  defp vertices(_rest, _remaining, _values), do: {:error, :truncated_vector_vertices}

  defp segments(rest, 0, values), do: {:ok, {Enum.reverse(values), rest}}

  defp segments(
         <<_style_id::little-unsigned-32, start::little-unsigned-32,
           tangent_start_x::little-float-32, tangent_start_y::little-float-32,
           finish::little-unsigned-32, tangent_end_x::little-float-32,
           tangent_end_y::little-float-32, rest::binary>>,
         remaining,
         values
       ) do
    segment = %Segment{
      start: start,
      end: finish,
      tangent_start: %Vector{x: tangent_start_x, y: tangent_start_y},
      tangent_end: %Vector{x: tangent_end_x, y: tangent_end_y}
    }

    segments(rest, remaining - 1, [segment | values])
  end

  defp segments(_rest, _remaining, _values), do: {:error, :truncated_vector_segments}

  defp regions(rest, 0, values), do: {:ok, {Enum.reverse(values), rest}}

  defp regions(
         <<winding::little-unsigned-32, loop_count::little-unsigned-32, rest::binary>>,
         remaining,
         values
       ) do
    with {:ok, {loops, rest}} <- loops(rest, loop_count, []) do
      region = %Region{winding_rule: winding_rule(winding), loops: loops}
      regions(rest, remaining - 1, [region | values])
    end
  end

  defp regions(_rest, _remaining, _values), do: {:error, :truncated_vector_regions}

  defp loops(rest, 0, values), do: {:ok, {Enum.reverse(values), rest}}

  defp loops(<<segment_count::little-unsigned-32, rest::binary>>, remaining, values) do
    with {:ok, {segments, rest}} <- indices(rest, segment_count, []) do
      loops(rest, remaining - 1, [segments | values])
    end
  end

  defp loops(_rest, _remaining, _values), do: {:error, :truncated_vector_region_loops}

  defp indices(rest, 0, values), do: {:ok, {Enum.reverse(values), rest}}

  defp indices(<<index::little-unsigned-32, rest::binary>>, remaining, values),
    do: indices(rest, remaining - 1, [index | values])

  defp indices(_rest, _remaining, _values), do: {:error, :truncated_vector_region_indices}

  defp trailing_bytes(<<>>), do: :ok
  defp trailing_bytes(rest), do: {:error, {:trailing_vector_network_bytes, byte_size(rest)}}

  defp validate(network) do
    with :ok <- validate_coordinates(network),
         :ok <- validate_segments(network) do
      validate_regions(network)
    end
  end

  defp validate_coordinates(network) do
    coordinates =
      Enum.flat_map(network.vertices, fn vertex -> [vertex.position.x, vertex.position.y] end) ++
        Enum.flat_map(network.segments, fn segment ->
          [
            segment.tangent_start.x,
            segment.tangent_start.y,
            segment.tangent_end.x,
            segment.tangent_end.y
          ]
        end)

    if Enum.all?(coordinates, &finite?/1), do: :ok, else: {:error, :invalid_vector_coordinate}
  end

  defp validate_segments(network) do
    vertex_count = length(network.vertices)

    network.segments
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {segment, index}, :ok ->
      if segment.start < vertex_count and segment.end < vertex_count,
        do: {:cont, :ok},
        else: {:halt, {:error, {:invalid_vector_segment_vertex, index}}}
    end)
  end

  defp validate_regions(network) do
    segment_count = length(network.segments)

    network.regions
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {region, region_index}, :ok ->
      case validate_region(region, region_index, segment_count) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_region(region, region_index, segment_count) do
    region.loops
    |> Enum.with_index()
    |> Enum.find_value(:ok, fn {loop, loop_index} ->
      if Enum.all?(loop, &(&1 < segment_count)),
        do: nil,
        else: {:error, {:invalid_vector_region_segment, region_index, loop_index}}
    end)
  end

  defp scale(network, nil, _node_size), do: {:ok, network}
  defp scale(network, _normalized_size, nil), do: {:ok, network}

  defp scale(network, %{x: source_x, y: source_y}, %{x: target_x, y: target_y})
       when is_number(source_x) and is_number(source_y) and is_number(target_x) and
              is_number(target_y) and source_x > 0 and source_y > 0 do
    scale_x = target_x / source_x
    scale_y = target_y / source_y

    vertices =
      Enum.map(network.vertices, fn vertex ->
        %{vertex | position: scale_vector(vertex.position, scale_x, scale_y)}
      end)

    segments =
      Enum.map(network.segments, fn segment ->
        %{
          segment
          | tangent_start: scale_vector(segment.tangent_start, scale_x, scale_y),
            tangent_end: scale_vector(segment.tangent_end, scale_x, scale_y)
        }
      end)

    {:ok, %{network | vertices: vertices, segments: segments}}
  end

  defp scale(_network, _normalized_size, _node_size),
    do: {:error, :invalid_vector_normalized_size}

  defp scale_vector(vector, scale_x, scale_y),
    do: %{vector | x: vector.x * scale_x, y: vector.y * scale_y}

  defp finite?(value), do: is_float(value)
  defp winding_rule(0), do: :even_odd
  defp winding_rule(_value), do: :winding
end
