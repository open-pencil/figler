defmodule Figler.NativeSceneGeneratorTest do
  use ExUnit.Case, async: true

  alias Figler.NativeSceneGenerator
  alias Figler.NativeSceneGenerator.Focus
  alias Figler.NativeSceneGenerator.Rusty
  alias Figler.NativeSceneGenerator.Scene
  alias KiwiCodec.RustlerGenerator.{Skip, Sparse}

  test "root generator exposes expected splice groups" do
    splices = NativeSceneGenerator.render_splices(Figler.schema())

    refute Keyword.has_key?(splices, :sparse_decoders)
    refute Keyword.has_key?(splices, :skip_decoders)
    assert Keyword.has_key?(splices, :graph_focus_decoders)
    assert Keyword.has_key?(splices, :scene_record_fields)
  end

  test "split generator modules render focused fragments" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    assert Scene.render(definition_map)[:scene_record_fields]
  end

  test "generic sparse and skip generation are provided by KiwiCodec" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    sparse_source =
      Sparse.fragments(
        schema.definitions,
        "Figler.Schema",
        definition_map
      )
      |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

    skip_source =
      Skip.fragments(schema.definitions, definition_map)
      |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

    assert sparse_source =~ "kiwi_sparse_message_decoder!"
    assert sparse_source =~ "fn decode_sparse_message_from_decoder"
    assert skip_source =~ "kiwi_skip_message_decoder!"
    assert skip_source =~ "fn skip_message_from_decoder"
  end

  test "focused graph decoder generation follows component references" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    focus_source = Focus.render(definition_map, &Skip.message_arm/2, &Scene.render_template/2)
    helper_source = Rusty.helper_items() |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

    assert focus_source =~ "graph_focus_read_symbol_data(decoder)?"
    assert focus_source =~ "graph_focus_extend_symbol_refs(data, &mut refs)?"
    assert focus_source =~ "graph_focus_extend_component_prop_assignments(decoder, &mut refs)?"
    assert focus_source =~ "graph_focus_extend_component_prop_value(decoder, &mut refs)?"
    assert focus_source =~ "graph_focus_push_guid_ref(decoder, &mut refs)?"
    assert helper_source =~ "fn graph_focus_push_guid_ref"
    assert helper_source =~ "fn graph_focus_extend_symbol_refs"
    assert helper_source =~ "fn graph_focus_extend_component_prop_assignments"
    assert helper_source =~ "fn graph_focus_extend_component_prop_assignments_remaining"
    assert helper_source =~ "graph_focus_read_component_prop_assignment(decoder)?"
    assert helper_source =~ "fn graph_focus_extend_component_prop_value"
  end

  test "scene navigation NIF generation stays aligned with native stubs" do
    schema = Figler.schema()
    rendered = NativeSceneGenerator.render_splices(schema)

    navigation_source = rendered[:scene_navigation_nifs] |> List.flatten() |> Enum.join("\n")
    nifs_source = File.read!("native/src/templates/scene_nifs.rs")

    assert navigation_source =~ "pub fn scene_index_node"
    assert navigation_source =~ "pub fn scene_index_text_contains_fields"
    assert nifs_source =~ "__rq_scene_navigation_nifs!();"
  end
end
