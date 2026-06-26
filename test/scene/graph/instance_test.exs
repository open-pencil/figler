defmodule Figler.Scene.Graph.InstanceTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "returns instance metadata and provenance for source instances" do
    graph =
      [component({1, 1}, name: "Button"), instance({2, 1}, {1, 1})]
      |> resolve(stages: [:populate_instances])

    assert %{
             guid: "2:1",
             component_guid: "1:1",
             component: %Node{name: "Button"},
             provenance: %{source: :projected_index, source_guid: {2, 1}}
           } = Graph.instance(graph, "2:1")
  end

  test "returns clone provenance for nested instance clones" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {3, 1}, parent_guid: {1, 1}),
        instance({2, 1}, {1, 1}),
        component({3, 1}, name: "Leaf")
      ]
      |> resolve(stages: [:populate_instances])

    assert %{
             guid: "clone:2:1/1:2",
             component_guid: "3:1",
             component: %Node{name: "Leaf"},
             provenance: %{source: :instance_clone, source_guid: {1, 2}, instance_guid: {2, 1}}
           } = Graph.instance(graph, "clone:2:1/1:2")
  end

  test "returns nil for non-instance nodes" do
    graph = [component({1, 1}, name: "Button")] |> resolve(stages: [])

    assert Graph.instance(graph, "1:1") == nil
  end
end
