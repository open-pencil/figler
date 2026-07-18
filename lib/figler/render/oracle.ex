defmodule Figler.Render.Oracle do
  @moduledoc """
  Decodes reference PNGs and compares them with Figler RGBA renders.

  Reference images may be produced by OpenPencil or another visual oracle. Keep
  large `.fig` fixtures and their reference images outside git, then compare
  identical page/root, scale, bounds, and background selections.
  """

  @compile {:no_warn_undefined, [Skia, Skia.Image]}

  alias Figler.Render.PixelDiff

  @doc "Compares a reference PNG with a tightly packed RGBA render."
  @spec compare_png(binary(), PixelDiff.raw_image(), keyword()) ::
          {:ok, PixelDiff.metrics()} | {:error, term()}
  def compare_png(reference_png, actual, opts \\ []) when is_binary(reference_png) do
    with {:ok, reference} <- decode_png(reference_png) do
      PixelDiff.compare(reference, actual, opts)
    end
  end

  @doc "Decodes a PNG into a tightly packed RGBA buffer."
  @spec decode_png(binary()) :: {:ok, PixelDiff.raw_image()} | {:error, term()}
  def decode_png(png) when is_binary(png) do
    with {:ok, image} <- Skia.Image.decode(png),
         {:ok, raw} <-
           image.width
           |> Skia.canvas(image.height)
           |> Skia.image(image, x: 0, y: 0)
           |> Skia.to_raw() do
      {:ok, Map.take(raw, [:width, :height, :data])}
    end
  end
end
