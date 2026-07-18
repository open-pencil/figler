defmodule Figler.Render.Geometry.Path do
  @moduledoc "A decoded Figma geometry path and its winding rule."

  @enforce_keys [:path, :fill_rule]
  defstruct [:path, :fill_rule]

  @type t :: %__MODULE__{path: Skia.Path.t(), fill_rule: :winding | :even_odd}
end

defmodule Figler.Render.Geometry do
  @moduledoc "Decodes Figma geometry command blobs into backend-ready Skia paths."
  @compile {:no_warn_undefined, [Skia.Path]}

  alias Figler.Render.Geometry.Path, as: GeometryPath

  @doc "Decodes projected Figma path references using the document blob table."
  @spec paths([map()], [binary()]) :: {:ok, [GeometryPath.t()]} | {:error, term()}
  def paths(references, blobs) when is_list(references) and is_list(blobs) do
    references
    |> Enum.reduce_while({:ok, []}, fn reference, {:ok, paths} ->
      case path(reference, blobs) do
        {:ok, path} -> {:cont, {:ok, [path | paths]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> reverse_paths()
  end

  @doc "Decodes one Figma geometry command blob."
  @spec decode(binary()) :: {:ok, Skia.Path.t()} | {:error, term()}
  def decode(blob) when is_binary(blob), do: decode_commands(blob, Skia.Path.new())

  defp path(reference, blobs) do
    with index when is_integer(index) <- Map.get(reference, :commands_blob),
         blob when is_binary(blob) <- Enum.at(blobs, index),
         {:ok, path} <- decode(blob) do
      {:ok,
       %GeometryPath{
         path: path,
         fill_rule: fill_rule(Map.get(reference, :winding_rule))
       }}
    else
      nil -> {:error, :missing_geometry_blob}
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_commands(<<>>, path), do: {:ok, path}

  defp decode_commands(<<0, rest::binary>>, path),
    do: decode_commands(rest, Skia.Path.close(path))

  defp decode_commands(
         <<1, x::little-float-size(32), y::little-float-size(32), rest::binary>>,
         path
       ),
       do: decode_commands(rest, Skia.Path.move_to(path, x, y))

  defp decode_commands(
         <<2, x::little-float-size(32), y::little-float-size(32), rest::binary>>,
         path
       ),
       do: decode_commands(rest, Skia.Path.line_to(path, x, y))

  defp decode_commands(
         <<3, cx::little-float-size(32), cy::little-float-size(32), x::little-float-size(32),
           y::little-float-size(32), rest::binary>>,
         path
       ),
       do: decode_commands(rest, Skia.Path.quad_to(path, cx, cy, x, y))

  defp decode_commands(
         <<4, c1x::little-float-size(32), c1y::little-float-size(32), c2x::little-float-size(32),
           c2y::little-float-size(32), x::little-float-size(32), y::little-float-size(32),
           rest::binary>>,
         path
       ),
       do: decode_commands(rest, Skia.Path.cubic_to(path, c1x, c1y, c2x, c2y, x, y))

  defp decode_commands(<<command, _rest::binary>>, _path) when command in 1..4,
    do: {:error, {:malformed_geometry_command, command}}

  defp decode_commands(<<command, _rest::binary>>, _path),
    do: {:error, {:unsupported_geometry_command, command}}

  defp reverse_paths({:ok, paths}), do: {:ok, Enum.reverse(paths)}
  defp reverse_paths(error), do: error

  defp fill_rule(:odd), do: :even_odd
  defp fill_rule(_winding), do: :winding
end
