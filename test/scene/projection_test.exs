defmodule Figler.Scene.ProjectionTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph.SeedNode
  alias Figler.Scene.Graph.SeedProjection
  alias Figler.Scene.Node
  alias Figler.Scene.Projection

  test "projection specs stay aligned with node and seed structs" do
    node_fields = Map.keys(Node.__struct__()) -- [:__struct__]
    seed_fields = Map.keys(SeedNode.__struct__()) -- [:__struct__]

    seed_projection_fields =
      Enum.map(SeedProjection.struct_fields(), fn
        {field, _default} -> field
        field -> field
      end)

    assert MapSet.new(node_fields) == MapSet.new(Projection.field_names() ++ [:children])

    assert MapSet.new(seed_fields) ==
             MapSet.new(Projection.field_names() ++ seed_projection_fields)

    generated = File.read!("native/src/generated.rs")

    for field <- Projection.field_names() -- [:guid, :node_type] do
      assert generated =~ "#{field}:"
    end
  end

  test "scene node projection is backed by generated Kiwi schema metadata" do
    assert Node.source_module() == Figler.Schema.NodeChange

    assert Node.source_fields() == [
             :guid,
             :type,
             :name,
             :parent_index,
             :size,
             :transform,
             :visible,
             :locked,
             :opacity,
             :text_data,
             :font_name,
             :font_size,
             :style_id_for_text,
             :component_key,
             :origin_component_key,
             :style_id_for_fill,
             :style_id_for_stroke_fill,
             :style_id_for_effect,
             :style_id_for_grid,
             :fill_paints,
             :stroke_paints
           ]

    assert Node.parent_index_source_fields() == [:guid, :position]
  end
end
