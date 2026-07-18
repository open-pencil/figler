defmodule Figler.Render.PixelDiffTest do
  use ExUnit.Case, async: true

  alias Figler.Render.PixelDiff

  test "accepts identical RGBA buffers" do
    image = raw(<<255, 0, 0, 255, 0, 0, 0, 0>>)

    assert {:ok, metrics} = PixelDiff.compare(image, image)
    assert metrics.changed_pixels == 0
    assert metrics.changed_ratio == 0.0
    assert metrics.mean_channel_delta == 0.0
    assert metrics.max_channel_delta == 0
    assert metrics.passed?
  end

  test "reports thresholded pixel and channel metrics" do
    expected = raw(<<100, 100, 100, 255, 0, 0, 0, 0>>)
    actual = raw(<<103, 98, 100, 255, 20, 0, 0, 0>>)

    assert {:ok, metrics} =
             PixelDiff.compare(expected, actual,
               channel_threshold: 3,
               max_changed_ratio: 0.5,
               max_mean_delta: 4.0,
               max_channel_delta: 20
             )

    assert metrics.changed_pixels == 1
    assert metrics.changed_ratio == 0.5
    assert metrics.mean_channel_delta == 3.125
    assert metrics.max_channel_delta == 20
    assert metrics.passed?
  end

  test "rejects incompatible or malformed buffers" do
    assert {:error, :dimension_mismatch} =
             PixelDiff.compare(raw(<<0, 0, 0, 0>>), %{width: 2, height: 1, data: <<0::64>>})

    assert {:error, :invalid_rgba_buffer} =
             PixelDiff.compare(%{width: 1, height: 1, data: <<0>>}, raw(<<0, 0, 0, 0>>))
  end

  defp raw(data), do: %{width: div(byte_size(data), 4), height: 1, data: data}
end
