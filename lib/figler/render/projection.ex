defmodule Figler.Render.Projection do
  @moduledoc """
  Structural source of truth for render-specific `NodeChange` projection fields.

  Native tuple generation, Elixir decoding, and rich instance override
  extraction derive their field order from this schema.
  """

  @fields [
    %{name: :guid, source_name: "guid"},
    %{name: :node_type, source_name: "type", override?: false},
    %{name: :name, source_name: "name"},
    %{name: :text_data, source_name: "textData", override?: false},
    %{name: :blend_mode, source_name: "blendMode"},
    %{name: :mask, source_name: "mask"},
    %{name: :mask_type, source_name: "maskType"},
    %{name: :effects, source_name: "effects", list?: true},
    %{name: :fill_paints, source_name: "fillPaints", list?: true},
    %{name: :stroke_paints, source_name: "strokePaints", list?: true},
    %{name: :fill_geometry, source_name: "fillGeometry", list?: true},
    %{name: :stroke_geometry, source_name: "strokeGeometry", list?: true},
    %{name: :boolean_operation, source_name: "booleanOperation"},
    %{name: :corner_radius, source_name: "cornerRadius"},
    %{name: :stroke_weight, source_name: "strokeWeight"},
    %{name: :frame_mask_disabled, source_name: "frameMaskDisabled"}
  ]

  @spec fields() :: [map()]
  def fields, do: @fields

  @spec field_names() :: [atom()]
  def field_names, do: Enum.map(@fields, & &1.name)

  @spec override_field_names() :: [atom()]
  def override_field_names do
    @fields
    |> Enum.filter(&Map.get(&1, :override?, &1.name != :guid))
    |> Enum.map(& &1.name)
  end

  @spec struct_fields() :: [atom() | {atom(), list()}]
  def struct_fields do
    Enum.map(@fields, fn field ->
      if Map.get(field, :list?, false), do: {field.name, []}, else: field.name
    end)
  end
end
