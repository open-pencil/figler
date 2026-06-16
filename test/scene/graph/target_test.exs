defmodule FigKiwi.Scene.Graph.TargetTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Target

  import FigKiwi.Test.GraphBuilder

  test "falls back to deepest source target for invalid nested override paths" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {3, 1}, parent_guid: {1, 1}),
        instance({2, 1}, {1, 1}),
        component({3, 1}, name: "Leaf"),
        text({3, 2}, {3, 1}, "Default")
      ]
      |> resolve(stages: [:populate_instances])

    assert {:ok, target} = Target.resolve(graph, {2, 1}, [{1, 2}, {3, 2}])
    assert GUID.format(target) == "clone:2:1/1:2/3:2"
  end
end
