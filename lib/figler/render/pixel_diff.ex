defmodule Figler.Render.PixelDiff do
  @moduledoc """
  Thresholded RGBA comparison for rendering-oracle tests.

  Inputs are decoded, tightly packed RGBA buffers such as the maps returned by
  `Skia.to_raw/1`. Metrics remain backend-neutral so OpenPencil reference
  renders can be decoded by any test adapter.
  """

  @type raw_image :: %{
          required(:width) => pos_integer(),
          required(:height) => pos_integer(),
          required(:data) => binary()
        }

  @type metrics :: %{
          width: pos_integer(),
          height: pos_integer(),
          changed_pixels: non_neg_integer(),
          changed_ratio: float(),
          mean_channel_delta: float(),
          max_channel_delta: 0..255,
          passed?: boolean()
        }

  @doc "Compares two decoded RGBA buffers using configurable error thresholds."
  @spec compare(raw_image(), raw_image(), keyword()) :: {:ok, metrics()} | {:error, term()}
  def compare(expected, actual, opts \\ []) do
    with :ok <- same_dimensions(expected, actual),
         :ok <- valid_rgba(expected),
         :ok <- valid_rgba(actual) do
      metrics(expected, actual, opts)
    end
  end

  defp same_dimensions(%{width: width, height: height}, %{width: width, height: height}),
    do: :ok

  defp same_dimensions(_expected, _actual), do: {:error, :dimension_mismatch}

  defp valid_rgba(%{width: width, height: height, data: data})
       when is_integer(width) and width > 0 and is_integer(height) and height > 0 and
              is_binary(data) do
    if byte_size(data) == width * height * 4, do: :ok, else: {:error, :invalid_rgba_buffer}
  end

  defp valid_rgba(_image), do: {:error, :invalid_rgba_buffer}

  defp metrics(expected, actual, opts) do
    channel_threshold = Keyword.get(opts, :channel_threshold, 0)
    pixel_count = expected.width * expected.height

    {changed_pixels, channel_delta_sum, max_channel_delta} =
      compare_pixels(expected.data, actual.data, channel_threshold, {0, 0, 0})

    changed_ratio = changed_pixels / pixel_count
    mean_channel_delta = channel_delta_sum / (pixel_count * 4)

    result = %{
      width: expected.width,
      height: expected.height,
      changed_pixels: changed_pixels,
      changed_ratio: changed_ratio,
      mean_channel_delta: mean_channel_delta,
      max_channel_delta: max_channel_delta,
      passed?:
        changed_ratio <= Keyword.get(opts, :max_changed_ratio, 0.0) and
          mean_channel_delta <= Keyword.get(opts, :max_mean_delta, channel_threshold * 1.0) and
          max_channel_delta <= Keyword.get(opts, :max_channel_delta, 255)
    }

    {:ok, result}
  end

  defp compare_pixels(<<>>, <<>>, _threshold, totals), do: totals

  defp compare_pixels(
         <<er, eg, eb, ea, expected::binary>>,
         <<ar, ag, ab, aa, actual::binary>>,
         threshold,
         {changed, sum, maximum}
       ) do
    red_delta = abs(er - ar)
    green_delta = abs(eg - ag)
    blue_delta = abs(eb - ab)
    alpha_delta = abs(ea - aa)
    pixel_max = max(max(red_delta, green_delta), max(blue_delta, alpha_delta))
    pixel_sum = red_delta + green_delta + blue_delta + alpha_delta
    next_changed = if pixel_max > threshold, do: changed + 1, else: changed

    compare_pixels(
      expected,
      actual,
      threshold,
      {next_changed, sum + pixel_sum, max(maximum, pixel_max)}
    )
  end
end
