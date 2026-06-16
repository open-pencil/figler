defmodule FigKiwi.Scene.Graph.SeedProjection do
  @moduledoc false

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

  def resolver_metadata_fields, do: @resolver_metadata_fields
end
