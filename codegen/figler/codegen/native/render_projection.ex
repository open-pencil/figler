defmodule Figler.Codegen.Native.RenderProjection do
  @moduledoc """
  Generates schema-derived field constants for the native rendering projection.

  The decoder template owns wire traversal while this module keeps Figma field
  numbers structural and tied to the vendored Kiwi schema.
  """

  alias RustQ.Rust.AST.Builder, as: A

  @fields [
    guid: "guid",
    node_type: "type",
    name: "name",
    blend_mode: "blendMode",
    mask: "mask",
    mask_type: "maskType",
    effects: "effects",
    corner_radius: "cornerRadius",
    stroke_weight: "strokeWeight",
    fill_paints: "fillPaints",
    stroke_paints: "strokePaints",
    fill_geometry: "fillGeometry",
    stroke_geometry: "strokeGeometry",
    boolean_operation: "booleanOperation",
    frame_mask_disabled: "frameMaskDisabled"
  ]

  @spec field_constants(%{String.t() => map()}) ::
          [RustQ.Rust.AST.Const.t()]
  def field_constants(definition_map) do
    fields = definition_map |> Map.fetch!("NodeChange") |> then(& &1.fields)
    ids = Map.new(fields, &{&1.name, &1.id})

    render_fields =
      Enum.map(@fields, fn {name, source_name} ->
        constant_name = name |> Atom.to_string() |> String.upcase() |> then(&"RENDER_FIELD_#{&1}")
        A.const(constant_name, :u32, A.lit(Map.fetch!(ids, source_name)))
      end)

    render_fields ++ document_constants(definition_map)
  end

  defp document_constants(definition_map) do
    message_fields = definition_map |> Map.fetch!("Message") |> then(& &1.fields)
    message_ids = Map.new(message_fields, &{&1.name, &1.id})

    canvas =
      definition_map |> Map.fetch!("NodeType") |> then(& &1.variants) |> enum_value!("CANVAS")

    [
      A.const("DOCUMENT_FIELD_NODE_CHANGES", :u32, A.lit(Map.fetch!(message_ids, "nodeChanges"))),
      A.const("DOCUMENT_FIELD_BLOBS", :u32, A.lit(Map.fetch!(message_ids, "blobs"))),
      A.const("DOCUMENT_NODE_TYPE_CANVAS", :u32, A.lit(canvas))
    ]
  end

  defp enum_value!(variants, name),
    do: Enum.find_value(variants, &if(&1.name == name, do: &1.value))
end
