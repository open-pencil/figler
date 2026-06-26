defmodule Figler.NativeSceneGeneratorTest do
  use ExUnit.Case, async: true

  alias Figler.NativeSceneGenerator
  alias Figler.NativeSceneGenerator.Focus
  alias Figler.NativeSceneGenerator.Rusty
  alias Figler.NativeSceneGenerator.Scene
  alias Figler.NativeSceneGenerator.Skip
  alias Figler.NativeSceneGenerator.Sparse

  test "root generator exposes expected splice groups" do
    splices = NativeSceneGenerator.render_splices(Figler.schema())

    assert Keyword.has_key?(splices, :sparse_decoders)
    assert Keyword.has_key?(splices, :skip_decoders)
    assert Keyword.has_key?(splices, :graph_focus_decoders)
    assert Keyword.has_key?(splices, :scene_record_fields)
  end

  test "split generator modules render focused fragments" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    assert Sparse.render(schema.definitions, definition_map) |> List.flatten() |> Enum.join("\n") =~
             "decode_sparse_message_from_decoder"

    assert Skip.render(schema.definitions, definition_map) |> List.flatten() |> Enum.join("\n") =~
             "skip_message_from_decoder"

    assert Scene.render(definition_map)[:scene_record_fields]
  end

  test "sparse decoder generation caches field atoms and preserves present fields" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    guid_decoder =
      schema.definitions
      |> Sparse.render(definition_map)
      |> List.flatten()
      |> Enum.find(&String.contains?(&1, "decode_sparse_guid_from_decoder"))

    assert guid_decoder =~ ~s|cached_atom(env, &MODULE_ATOM, "Elixir.Figler.Schema.GUID")|
    assert guid_decoder =~ "static FIELD_ATOM_1: OnceLock<Atom> = OnceLock::new();"
    assert guid_decoder =~ ~s|let field_atom = cached_atom(env, &FIELD_ATOM_1, "session_id");|
    assert guid_decoder =~ "let value = decoder.read_var_uint()?.encode(env);"
    assert guid_decoder =~ "keys.push(field_atom.encode(env));"
    assert guid_decoder =~ "values.push(value);"
  end

  test "skip decoder generation consumes nested arrays without allocating values" do
    schema = Figler.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    text_data_skipper =
      schema.definitions
      |> Skip.render(definition_map)
      |> List.flatten()
      |> Enum.find(&String.contains?(&1, "skip_text_data_from_decoder"))

    assert text_data_skipper =~ "fn skip_text_data_from_decoder"
    assert text_data_skipper =~ "decoder.skip_string()?;"
    refute text_data_skipper =~ "Vec::with_capacity"
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
