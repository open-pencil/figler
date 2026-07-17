defmodule Figler.Scene.Graph.Symbol.TargetTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Symbol.Target

  import Figler.Test.GraphBuilder

  test "round-trips structurally shared clone paths" do
    clone_guid = {2, 1} |> GUID.append({1, 2}) |> GUID.append({3, 2})

    assert GUID.format(clone_guid) == "clone:2:1/1:2/3:2"
    assert GUID.parse("clone:2:1/1:2/3:2") == clone_guid
    assert GUID.leaf(clone_guid) == {3, 2}
  end

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
