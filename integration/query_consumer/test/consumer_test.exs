defmodule FiglerQueryConsumerTest do
  use ExUnit.Case, async: true

  test "runs native query APIs without Skia or development generators" do
    assert FiglerQueryConsumer.verify()
  end
end
