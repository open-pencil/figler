defmodule Figler.Scene.Graph.DiffTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  setup_all do
    {:ok, graph: @fixture |> File.read!() |> Figler.Scene.graph()}
  end

  test "reports fields an instance's overrides changed in its subtree", %{graph: graph} do
    assert [%{guid: "clone:9:1472/9:1466/9:1462", changed: changed}] =
             graph |> Graph.diff(root: "9:1472") |> Enum.filter(&(&1.guid =~ "9:1462"))

    assert %{field: :text, resolved: "Different"} = Enum.find(changed, &(&1.field == :text))
  end

  test "returns an empty list for an untouched component", %{graph: graph} do
    assert Graph.diff(graph, root: "9:1461") == []
  end
end
