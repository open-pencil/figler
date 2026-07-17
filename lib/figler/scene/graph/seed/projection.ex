defmodule Figler.Scene.Graph.Seed.Projection do
  @moduledoc """
  Defines generated-schema fields copied into graph seed metadata.

  The projection centralizes resolver metadata field names, default values, and
  extraction kinds so seed node construction and native generation stay aligned.
  """

  alias Figler.Scene.Projection, as: SceneProjection

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

  {record_metadata_prefix, record_metadata_suffix} =
    Enum.split_while(@resolver_metadata_fields, &(&1 != :symbol_overrides))

  @native_record_fields SceneProjection.field_names() ++
                          record_metadata_prefix ++ [:symbol_id] ++ record_metadata_suffix
  @native_record_ignored_fields [:font_style, :font_postscript]

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
  def native_record_fields, do: @native_record_fields

  defmacro native_record_pattern do
    fields =
      Enum.map(@native_record_fields, fn field ->
        name = if field in @native_record_ignored_fields, do: :"_#{field}", else: field
        Macro.var(name, nil)
      end)

    {:{}, [], fields}
  end

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

  def list_field?(:symbol_overrides), do: true
  def list_field?(:component_prop_defs), do: true
  def list_field?(:component_prop_refs), do: true
  def list_field?(:component_prop_assignments), do: true
  def list_field?(:derived_symbol_data), do: true
  def list_field?(:variable_consumption), do: true
  def list_field?(:variable_data_values), do: true
  def list_field?(_field), do: false
end
