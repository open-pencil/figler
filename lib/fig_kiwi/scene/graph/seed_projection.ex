defmodule FigKiwi.Scene.Graph.SeedProjection do
  @moduledoc false

  alias FigKiwi.Scene.Graph.SeedExtraction

  @resolver_metadata_fields [
    :override_key,
    :stack_mode,
    :stack_spacing,
    :stack_horizontal_padding,
    :stack_vertical_padding,
    :stack_padding_right,
    :stack_padding_bottom,
    :symbol_overrides,
    :component_prop_defs,
    :component_prop_refs,
    :component_prop_assignments,
    :derived_symbol_data,
    :variable_consumption,
    :variable_data_values
  ]

  @identity_fields [:component_guid, :symbol_id]

  @list_fields [
    :symbol_overrides,
    :component_prop_defs,
    :component_prop_refs,
    :component_prop_assignments,
    :derived_symbol_data,
    :variable_consumption,
    :variable_data_values
  ]

  def resolver_metadata_fields, do: @resolver_metadata_fields
  def identity_fields, do: @identity_fields

  def struct_fields do
    metadata_fields =
      Enum.map(@resolver_metadata_fields, fn field ->
        if list_field?(field), do: {field, []}, else: field
      end)

    metadata_fields ++ @identity_fields ++ [origin: :source, source: nil]
  end

  def default_value(field) when field in @list_fields, do: []
  def default_value(:origin), do: :source
  def default_value(_field), do: nil

  def value_kind(:override_key), do: :guid
  def value_kind(:symbol_overrides), do: :symbol_overrides
  def value_kind(:component_prop_defs), do: :component_prop_defs
  def value_kind(:component_prop_refs), do: :component_prop_refs
  def value_kind(:component_prop_assignments), do: :component_prop_assignments
  def value_kind(:derived_symbol_data), do: :derived_symbol_data
  def value_kind(:variable_consumption), do: {:multiplayer_entries, :variable_consumption_map}
  def value_kind(:variable_data_values), do: {:multiplayer_entries, :variable_data_values}
  def value_kind(field), do: {:field, field}

  def metadata(node_change), do: SeedExtraction.metadata(node_change)

  def list_field?(:symbol_overrides), do: true
  def list_field?(:component_prop_defs), do: true
  def list_field?(:component_prop_refs), do: true
  def list_field?(:component_prop_assignments), do: true
  def list_field?(:derived_symbol_data), do: true
  def list_field?(:variable_consumption), do: true
  def list_field?(:variable_data_values), do: true
  def list_field?(_field), do: false
end
