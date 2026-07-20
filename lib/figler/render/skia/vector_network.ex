defmodule Figler.Render.Skia.VectorNetwork do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Path]}

  alias Figler.Render.Geometry.Path, as: GeometryPath
  alias Figler.Render.VectorNetwork

  @spec paths(VectorNetwork.t()) ::
          {:ok, %{fill: [GeometryPath.t()], stroke: [GeometryPath.t()]}} | {:error, term()}
  def paths(%VectorNetwork{regions: []} = network) do
    with {:ok, path} <- open_path(network) do
      geometry = %GeometryPath{path: path, fill_rule: :winding, closed?: false}
      {:ok, %{fill: [geometry], stroke: [geometry]}}
    end
  end

  def paths(%VectorNetwork{} = network) do
    with {:ok, paths} <- region_paths(network) do
      {:ok, %{fill: paths, stroke: paths}}
    end
  end

  defp region_paths(network) do
    network.regions
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {region, region_index}, {:ok, paths} ->
      case region_path(network, region, region_index) do
        {:ok, path} -> {:cont, {:ok, [path | paths]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> reverse_paths()
  end

  defp region_path(network, region, region_index) do
    vertices = List.to_tuple(network.vertices)
    segments = List.to_tuple(network.segments)

    region.loops
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, Skia.Path.new()}, fn {loop, loop_index}, {:ok, path} ->
      case add_loop(path, loop, vertices, segments) do
        {:ok, path} -> {:cont, {:ok, path}}
        {:error, reason} -> {:halt, {:error, {reason, region_index, loop_index}}}
      end
    end)
    |> case do
      {:ok, path} ->
        {:ok, %GeometryPath{path: path, fill_rule: region.winding_rule, closed?: true}}

      error ->
        error
    end
  end

  defp add_loop(path, [], _vertices, _segments), do: {:ok, path}

  defp add_loop(path, [first_index | _] = loop, vertices, segments) do
    first = elem(segments, first_index)
    start = loop_start(loop, first, segments)
    point = elem(vertices, start).position
    path = Skia.Path.move_to(path, point.x, point.y)

    loop
    |> Enum.reduce_while({:ok, path, start}, fn segment_index, {:ok, path, current} ->
      segment = elem(segments, segment_index)

      case add_directed(path, segment, current, vertices) do
        {:ok, path, next} -> {:cont, {:ok, path, next}}
        :error -> {:halt, {:error, :disconnected_vector_loop}}
      end
    end)
    |> case do
      {:ok, path, _current} -> {:ok, Skia.Path.close(path)}
      error -> error
    end
  end

  defp loop_start([_single], first, _segments), do: first.start

  defp loop_start([_first, second_index | _], first, segments) do
    second = elem(segments, second_index)
    if first.end in [second.start, second.end], do: first.start, else: first.end
  end

  defp open_path(network) do
    vertices = List.to_tuple(network.vertices)
    segments = List.to_tuple(network.segments)
    chains = chains(network.segments)

    chains
    |> Enum.reduce_while({:ok, Skia.Path.new()}, fn chain, {:ok, path} ->
      case add_chain(path, chain, vertices, segments) do
        {:ok, path} -> {:cont, {:ok, path}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp add_chain(path, [], _vertices, _segments), do: {:ok, path}

  defp add_chain(path, [first_index | _] = chain, vertices, segments) do
    first = elem(segments, first_index)
    start = chain_start(chain, first, segments)
    point = elem(vertices, start).position
    path = Skia.Path.move_to(path, point.x, point.y)

    chain
    |> Enum.reduce_while({:ok, path, start}, fn segment_index, {:ok, path, current} ->
      segment = elem(segments, segment_index)

      case add_directed(path, segment, current, vertices) do
        {:ok, path, next} -> {:cont, {:ok, path, next}}
        :error -> {:halt, {:error, :disconnected_vector_chain}}
      end
    end)
    |> case do
      {:ok, path, _current} -> {:ok, path}
      error -> error
    end
  end

  defp chain_start([_single], first, _segments), do: first.start

  defp chain_start([_first, second_index | _], first, segments) do
    second = elem(segments, second_index)
    if first.start in [second.start, second.end], do: first.end, else: first.start
  end

  defp add_directed(path, segment, current, vertices) do
    cond do
      segment.start == current ->
        {:ok, draw_segment(path, segment, true, vertices), segment.end}

      segment.end == current ->
        {:ok, draw_segment(path, segment, false, vertices), segment.start}

      true ->
        :error
    end
  end

  defp draw_segment(path, segment, forward?, vertices) do
    start_index = if forward?, do: segment.start, else: segment.end
    end_index = if forward?, do: segment.end, else: segment.start
    start = elem(vertices, start_index).position
    finish = elem(vertices, end_index).position
    first_tangent = if forward?, do: segment.tangent_start, else: segment.tangent_end
    second_tangent = if forward?, do: segment.tangent_end, else: segment.tangent_start

    if zero?(first_tangent) and zero?(second_tangent) do
      Skia.Path.line_to(path, finish.x, finish.y)
    else
      Skia.Path.cubic_to(
        path,
        start.x + first_tangent.x,
        start.y + first_tangent.y,
        finish.x + second_tangent.x,
        finish.y + second_tangent.y,
        finish.x,
        finish.y
      )
    end
  end

  defp chains(segments) do
    adjacency = adjacency(segments)
    indexed_segments = List.to_tuple(segments)

    degree_one =
      Enum.filter(adjacency, fn
        {_vertex, [_segment]} -> true
        _entry -> false
      end)

    starts =
      if degree_one == [], do: initial_start(segments), else: Enum.map(degree_one, &elem(&1, 0))

    {chains, visited} =
      Enum.reduce(starts, {[], MapSet.new()}, fn start, {chains, visited} ->
        {chain, visited} = walk_chain(start, indexed_segments, adjacency, visited, [])
        if chain == [], do: {chains, visited}, else: {[chain | chains], visited}
      end)

    {chains, _visited} =
      segments
      |> Stream.with_index()
      |> Enum.reduce({chains, visited}, fn {segment, index}, {chains, visited} ->
        if MapSet.member?(visited, index) do
          {chains, visited}
        else
          {chain, visited} =
            walk_chain(segment.start, indexed_segments, adjacency, visited, [])

          {[chain | chains], visited}
        end
      end)

    Enum.reverse(chains)
  end

  defp initial_start([]), do: []
  defp initial_start([segment | _]), do: [segment.start]

  defp walk_chain(current, indexed_segments, adjacency, visited, chain) do
    next = Enum.find(Map.get(adjacency, current, []), &(not MapSet.member?(visited, &1)))

    if is_nil(next) do
      {Enum.reverse(chain), visited}
    else
      segment = elem(indexed_segments, next)
      following = if segment.start == current, do: segment.end, else: segment.start

      walk_chain(
        following,
        indexed_segments,
        adjacency,
        MapSet.put(visited, next),
        [next | chain]
      )
    end
  end

  defp adjacency(segments) do
    segments
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn {segment, index}, adjacency ->
      adjacency
      |> Map.update(segment.start, [index], &[index | &1])
      |> Map.update(segment.end, [index], &[index | &1])
    end)
    |> Map.new(fn {vertex, indices} -> {vertex, Enum.reverse(indices)} end)
  end

  defp zero?(vector), do: vector.x == 0.0 and vector.y == 0.0
  defp reverse_paths({:ok, paths}), do: {:ok, Enum.reverse(paths)}
  defp reverse_paths(error), do: error
end
