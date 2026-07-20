defmodule FiglerRenderConsumerTest do
  use ExUnit.Case, async: true

  test "renders through the packaged native and optional Skia dependencies" do
    assert FiglerRenderConsumer.verify()
  end
end
