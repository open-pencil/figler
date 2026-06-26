defmodule Figler.NativeSceneGenerator.Focus do
  @moduledoc """
  Generates focused graph decoder Rust splices.

  Focused decoding walks only the message fields needed to find a requested
  subtree and related component references before the Elixir resolver builds an
  effective graph.
  """

  alias Figler.NativeSceneGenerator.Rusty

  def render(definition_map, skip_arm, render_template) do
    message_fields = definition_map |> Map.fetch!("Message") |> then(& &1.fields)
    node_fields = definition_map |> Map.fetch!("NodeChange") |> then(& &1.fields)
    symbol_fields = definition_map |> Map.fetch!("SymbolData") |> then(& &1.fields)

    prop_assignment_fields =
      definition_map |> Map.fetch!("ComponentPropAssignment") |> then(& &1.fields)

    prop_value_fields = definition_map |> Map.fetch!("ComponentPropValue") |> then(& &1.fields)

    render_template.("graph_focus_decoders.rs",
      splice: [
        message_skip_arms: message_skip_arms(message_fields, definition_map, skip_arm),
        node_focus_arms: node_focus_arms(node_fields, definition_map, skip_arm),
        symbol_focus_arms: symbol_focus_arms(symbol_fields, definition_map, skip_arm),
        prop_assignment_arms:
          prop_assignment_arms(prop_assignment_fields, definition_map, skip_arm),
        prop_value_arms: prop_value_arms(prop_value_fields, definition_map, skip_arm)
      ]
    )
  end

  defp message_skip_arms(fields, definition_map, skip_arm) do
    fields
    |> Enum.reject(&(&1.name == "nodeChanges"))
    |> Enum.map(&skip_arm.(&1, definition_map))
  end

  defp node_focus_arms(fields, definition_map, skip_arm) do
    Enum.map(fields, fn field ->
      case field.name do
        "guid" ->
          arm(field, "guid = Some(graph_focus_read_guid(decoder)?);")

        "parentIndex" ->
          arm(field, "parent_guid = Some(graph_focus_read_parent_guid(decoder)?);")

        "symbolData" ->
          arm(field, [
            "let data = graph_focus_read_symbol_data(decoder)?;",
            "symbol_id = graph_focus_extend_symbol_refs(data, &mut refs)?;"
          ])

        "overriddenSymbolID" ->
          arm(field, "graph_focus_push_guid_ref(decoder, &mut refs)?;")

        "componentPropAssignments" ->
          arm(field, "graph_focus_extend_component_prop_assignments(decoder, &mut refs)?;")

        _other ->
          skip_arm.(field, definition_map)
      end
    end)
  end

  defp symbol_focus_arms(fields, definition_map, skip_arm) do
    fields
    |> Enum.reject(&(&1.name in ["symbolID", "symbolOverrides"]))
    |> Enum.map(&skip_arm.(&1, definition_map))
  end

  defp prop_assignment_arms(fields, definition_map, skip_arm) do
    Enum.map(fields, fn field ->
      case field.name do
        "value" ->
          arm(field, "graph_focus_extend_component_prop_value(decoder, &mut refs)?;")

        _other ->
          skip_arm.(field, definition_map)
      end
    end)
  end

  defp prop_value_arms(fields, definition_map, skip_arm) do
    Enum.map(fields, fn field ->
      case field.name do
        "guidValue" ->
          arm(field, "graph_focus_push_guid_ref(decoder, &mut refs)?;")

        _other ->
          skip_arm.(field, definition_map)
      end
    end)
  end

  defp arm(field, lines), do: Rusty.arm(field.id, lines)
end
