defmodule FigKiwi.Scene.Graph.VariablesTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph

  import FigKiwi.Test.GraphBuilder

  test "preserves refs as unresolved provenance" do
    graph =
      [node({1, 1}, :rectangle, variable_consumption: [%{field: :width, variable: "var:1"}])]
      |> resolve(stages: [:variables], options: [resolve_variables: :preserve])

    assert Graph.unresolved(graph) == [
             {:variable_ref_preserved, %{field: :width, variable: "var:1"}}
           ]

    assert Graph.explain(graph, "1:1").unresolved == [
             {:variable_ref_preserved, %{field: :width, variable: "var:1"}}
           ]
  end

  test "skips unknown refs in known mode" do
    graph =
      [node({1, 1}, :rectangle, variable_consumption: [%{field: :width, variable: "var:1"}])]
      |> resolve(stages: [:variables])

    assert Graph.unresolved(graph) == []
    assert Graph.explain(graph, "1:1").unresolved == []
  end

  test "applies known variable refs to clear node fields" do
    graph =
      [
        node({1, 1}, :rectangle,
          size: %{x: 10.0, y: 20.0},
          variable_consumption: [variable_ref(:width, 42.0)]
        )
      ]
      |> resolve(stages: [:variables])

    assert Scene.node(graph, "1:1").size == %{x: 42.0, y: 20.0}

    assert [
             {:variable_value_applied, :width, 10.0, 42.0,
              %{value: {:float, 42.0}, data_type: :float, resolved_data_type: :float}}
           ] = Graph.explain(graph, "1:1").applied
  end

  test "applies known font variable refs" do
    graph =
      [
        node({1, 1}, :text,
          font_family: "Inter",
          variable_consumption: [
            struct(FigKiwi.Schema.VariableDataMapEntry,
              variable_field: :font_family,
              variable_data:
                struct(FigKiwi.Schema.VariableData,
                  data_type: :string,
                  resolved_data_type: :string,
                  value: struct(FigKiwi.Schema.VariableAnyValue, text_value: "Roboto")
                )
            )
          ]
        )
      ]
      |> resolve(stages: [:variables])

    assert Scene.node(graph, "1:1").font_family == "Roboto"

    assert [
             {:variable_value_applied, :font_family, "Inter", "Roboto",
              %{value: {:text, "Roboto"}, data_type: :string, resolved_data_type: :string}}
           ] = Graph.explain(graph, "1:1").applied
  end

  test "applies known numeric style and stack variable refs" do
    graph =
      [
        node({1, 1}, :text,
          font_size: 12.0,
          opacity: 1.0,
          stack_spacing: 4.0,
          stack_horizontal_padding: 8.0,
          variable_consumption: [
            variable_ref(:font_size, 16.0),
            variable_ref(:opacity, 0.5),
            variable_ref(:stack_spacing, 12.0),
            variable_ref(:stack_padding_left, 20.0)
          ]
        )
      ]
      |> resolve(stages: [:variables])

    node = Scene.node(graph, "1:1")

    assert node.font_size == 16.0
    assert node.opacity == 0.5
    assert Map.get(node, :stack_spacing) == 12.0
    assert Map.get(node, :stack_horizontal_padding) == 20.0

    assert graph.seed_nodes[{1, 1}].stack_spacing == 12.0
    assert graph.seed_nodes[{1, 1}].stack_horizontal_padding == 20.0

    assert Enum.any?(
             Graph.explain(graph, "1:1").applied,
             &match?({:variable_value_applied, :font_size, 12.0, 16.0, _}, &1)
           )

    assert Enum.any?(
             Graph.explain(graph, "1:1").applied,
             &match?({:variable_value_applied, :stack_padding_left, 8.0, 20.0, _}, &1)
           )
  end

  test "records known variable data values as provenance" do
    graph =
      [
        node({1, 1}, :variable,
          variable_data_values: [
            struct(FigKiwi.Schema.VariableDataValuesEntry,
              mode_id: struct(FigKiwi.Schema.GUID, session_id: 9, local_id: 1),
              variable_data:
                struct(FigKiwi.Schema.VariableData,
                  data_type: :float,
                  resolved_data_type: :float,
                  value: struct(FigKiwi.Schema.VariableAnyValue, float_value: 12.5)
                )
            )
          ]
        )
      ]
      |> resolve(stages: [:variables])

    assert Graph.explain(graph, "1:1").applied == [
             {:variable_value_resolved, "9:1",
              %{value: {:float, 12.5}, data_type: :float, resolved_data_type: :float}}
           ]
  end

  test "preserves style refs when style resolution is requested" do
    graph =
      [node({1, 1}, :text, text_style_guid: "2:1")]
      |> resolve(stages: [:variables], options: [resolve_styles: :refs])

    assert Graph.unresolved(graph) == [{:style_ref_preserved, :text_style_guid, "2:1"}]
  end
end
