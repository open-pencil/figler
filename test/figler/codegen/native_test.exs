defmodule Figler.Codegen.NativeTest do
  use ExUnit.Case, async: true

  alias Figler.Codegen.Native
  alias Figler.Codegen.Native.Focus
  alias Figler.Codegen.Native.Scene
  alias Figler.Codegen.Native.SupportFunction
  alias KiwiCodec.RustlerGenerator.{Skip, Sparse}

  test "root generator exposes expected splice groups" do
    splices = Native.render_splices(Figler.schema())

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

    helper_source =
      SupportFunction.focus_helper_items() |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

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

  test "scene XPath attrs and query fields are authored as support functions" do
    helper_source =
      SupportFunction.scene_reader_items() |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

    assert helper_source =~ "fn scene_node_record_attr"
    assert helper_source =~ "return Some((\"guid\", record.guid.to_string()))"
    assert helper_source =~ "fn scene_node_record_attr_count"
    assert helper_source =~ "fn scene_query_node_term"
    assert helper_source =~ "let node = &scene.nodes[node_index]"
    assert helper_source =~ "if wants_field(fields, \"name\")"
    assert helper_source =~ "Term::map_from_term_arrays(env, &keys, &values)"
  end

  test "scene navigation NIF wrappers are authored as support functions" do
    schema = Figler.schema()
    rendered = Native.render_splices(schema)

    navigation_source =
      rendered[:scene_navigation_nifs]
      |> List.flatten()
      |> Enum.map_join("\n", &RustQ.Rust.to_fragment/1)

    nifs_source = File.read!("native/src/templates/scene_nifs.rs")

    assert navigation_source =~ ~s|#[rustler::nif(schedule = "DirtyCpu")]|
    assert navigation_source =~ "fn scene_index_node"
    assert navigation_source =~ "scene_xpath_runtime::scene_index_node_value(env, resource, guid)"
    assert navigation_source =~ "fn scene_index_text_contains_fields"

    assert navigation_source =~ "scene_xpath_runtime::scene_index_text_contains_fields_value("
    assert navigation_source =~ "needle,"
    assert navigation_source =~ "fields,"

    assert nifs_source =~ "__rq_scene_navigation_nifs!();"
  end
end
