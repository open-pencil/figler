defmodule Figler.Scene.Graph.DiffTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph

  import Figler.Test.GraphBuilder

  test "diff reports effective changes in a graph subtree" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1}, symbol_overrides: [symbol_override([{1, 2}], %{text: "Submit"})])
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert [
             %{
               guid: "clone:2:1/1:2",
               changed: [%{field: :text, source: "Default", resolved: "Submit"}]
             }
           ] =
             Graph.diff(graph, root: "2:1")
  end

  test "diff returns empty list when effective nodes match sources" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1})
      ]
      |> resolve(stages: [:populate_instances])

    assert Graph.diff(graph, root: "2:1") == []
  end
end
