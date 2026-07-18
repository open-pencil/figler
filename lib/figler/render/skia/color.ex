defmodule Figler.Render.Skia.Color do
  @moduledoc false

  @spec rgba(map() | nil, number() | nil) :: {:rgba, 0..255, 0..255, 0..255, 0..255}
  def rgba(value, opacity \\ 1.0) do
    value = value || %{}
    alpha = (opacity || 1.0) * (Map.get(value, :a) || 1.0)

    {:rgba, channel(Map.get(value, :r)), channel(Map.get(value, :g)), channel(Map.get(value, :b)),
     channel(alpha)}
  end

  defp channel(nil), do: 0
  defp channel(value), do: value |> Kernel.*(255) |> round() |> max(0) |> min(255)
end
