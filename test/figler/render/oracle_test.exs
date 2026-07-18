defmodule Figler.Render.OracleTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Oracle

  test "compares reference PNGs with decoded RGBA output" do
    document =
      Skia.canvas(2, 1)
      |> Skia.rect(x: 0, y: 0, width: 1, height: 1, fill: :red)
      |> Skia.rect(x: 1, y: 0, width: 1, height: 1, fill: :blue)

    assert {:ok, png} = Skia.to_png(document)
    assert {:ok, actual} = Skia.to_raw(document)
    assert {:ok, %{passed?: true, changed_pixels: 0}} = Oracle.compare_png(png, actual)
  end
end
