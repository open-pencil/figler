defmodule Figler.Codegen.Native.Focus do
  @moduledoc """
  Generates focused graph decoder Rust splices.

  Focused decoding walks only the message fields needed to find a requested
  subtree and related component references before the Elixir resolver builds an
  effective graph.
  """

  alias Figler.Codegen.Native.Focus.Decode

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
          [arm(field, Decode.guid())]

        "parentIndex" ->
          [arm(field, Decode.parent_guid())]

        "symbolData" ->
          [arm(field, Decode.symbol_data())]

        "overriddenSymbolID" ->
          [arm(field, Decode.push_guid_ref())]

        "componentPropAssignments" ->
          [arm(field, Decode.component_prop_assignments())]

        _other ->
          []
      end
    end)
  end

  defp prop_assignment_arms(fields) do
    fields
    |> Enum.flat_map(fn field ->
      case field.name do
        "value" -> [arm(field, Decode.component_prop_value())]
        _other -> []
      end
    end)
  end

  defp prop_value_arms(fields) do
    fields
    |> Enum.flat_map(fn field ->
      case field.name do
        "guidValue" -> [arm(field, Decode.push_guid_ref())]
        _other -> []
      end
    end)
  end

  defp arm(field, %Decode.Operation{} = operation), do: Decode.arm(field.id, operation)
end
