defmodule Figler.Scene.Graph.DerivedSymbolDataTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "applies derived symbol layout data to cloned children" do
    transform = %{m00: 1.0, m01: 0.0, m02: 10.0, m10: 0.0, m11: 1.0, m12: 20.0}

    graph =
      [
        component({1, 1}, name: "Card"),
        node({1, 2}, :frame, parent_guid: {1, 1}, size: %{x: 100.0, y: 40.0}),
        instance({2, 1}, {1, 1},
          derived_symbol_data: [
            derived_symbol_data([{1, 1}, {1, 2}],
              size: %{x: 120.0, y: 50.0},
              transform: transform
            )
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :derived_symbol_data])

    assert [%Node{guid: clone_guid, size: %{x: 120.0, y: 50.0}, transform: ^transform}] =
             Scene.children(graph, "2:1")

    assert clone_guid == "clone:2:1/1:2"

    applied = Graph.explain(graph, clone_guid).applied
    assert {:derived_symbol_data, :size, %{x: 100.0, y: 40.0}, %{x: 120.0, y: 50.0}} in applied
    assert {:derived_symbol_data, :transform, nil, transform} in applied
  end

  test "uses guided derived data target before fallback source target" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {3, 1}, parent_guid: {1, 1}),
        instance({2, 1}, {1, 1},
          derived_symbol_data: [derived_symbol_data([{1, 2}, {3, 2}], size: %{x: 9.0, y: 9.0})]
        ),
        component({3, 1}, name: "Leaf"),
        node({3, 2}, :vector, parent_guid: {3, 1}, size: %{x: 4.0, y: 4.0})
      ]
      |> resolve(stages: [:populate_instances, :derived_symbol_data])

    assert Scene.node(graph, "clone:2:1/1:2/3:2").size == %{x: 9.0, y: 9.0}

    assert {:derived_symbol_data, :size, %{x: 4.0, y: 4.0}, %{x: 9.0, y: 9.0}} in Graph.explain(
             graph,
             "clone:2:1/1:2/3:2"
           ).applied
  end
end
