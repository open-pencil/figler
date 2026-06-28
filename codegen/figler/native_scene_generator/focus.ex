defmodule Figler.NativeSceneGenerator.Focus do
  @moduledoc """
  Generates focused graph decoder Rust splices.

  Focused decoding walks only the message fields needed to find a requested
  subtree and related component references before the Elixir resolver builds an
  effective graph.
  """

  alias Figler.NativeSceneGenerator.Rusty

  def render(definition_map, skip_arm, render_template) do
    node_fields = definition_map |> Map.fetch!("NodeChange") |> then(& &1.fields)
    symbol_fields = definition_map |> Map.fetch!("SymbolData") |> then(& &1.fields)

    prop_assignment_fields =
      definition_map |> Map.fetch!("ComponentPropAssignment") |> then(& &1.fields)

    prop_value_fields = definition_map |> Map.fetch!("ComponentPropValue") |> then(& &1.fields)

    render_template.("graph_focus_decoders.rs",
      splice: [
        symbol_skip_field_arms: skip_field_arms(symbol_fields, definition_map, skip_arm),
        prop_assignment_skip_field_arms:
          skip_field_arms(prop_assignment_fields, definition_map, skip_arm),
        prop_value_skip_field_arms: skip_field_arms(prop_value_fields, definition_map, skip_arm),
        node_focus_arms: node_focus_arms(node_fields),
        prop_assignment_arms: prop_assignment_arms(prop_assignment_fields),
        prop_value_arms: prop_value_arms(prop_value_fields)
      ]
    )
  end

  defp skip_field_arms(fields, definition_map, skip_arm) do
    Enum.map(fields, &skip_arm.(&1, definition_map))
  end

  defp node_focus_arms(fields) do
    fields
    |> Enum.flat_map(fn field ->
      case field.name do
        "guid" ->
          [arm(field, "guid = Some(graph_focus_read_guid(decoder)?);")]

        "parentIndex" ->
          [arm(field, "parent_guid = Some(graph_focus_read_parent_guid(decoder)?);")]

        "symbolData" ->
          [
            arm(field, [
              "let data = graph_focus_read_symbol_data(decoder)?;",
              "symbol_id = graph_focus_extend_symbol_refs(data, &mut refs)?;"
            ])
          ]

        "overriddenSymbolID" ->
          [arm(field, "graph_focus_push_guid_ref(decoder, &mut refs)?;")]

        "componentPropAssignments" ->
          [arm(field, "graph_focus_extend_component_prop_assignments(decoder, &mut refs)?;")]

        _other ->
          []
      end
    end)
  end

  defp prop_assignment_arms(fields) do
    fields
    |> Enum.flat_map(fn field ->
      case field.name do
        "value" -> [arm(field, "graph_focus_extend_component_prop_value(decoder, &mut refs)?;")]
        _other -> []
      end
    end)
  end

  defp prop_value_arms(fields) do
    fields
    |> Enum.flat_map(fn field ->
      case field.name do
        "guidValue" -> [arm(field, "graph_focus_push_guid_ref(decoder, &mut refs)?;")]
        _other -> []
      end
    end)
  end

  defp arm(field, lines), do: Rusty.arm(field.id, lines)
end
