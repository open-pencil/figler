defmodule Figler.NativeSceneGenerator do
  @moduledoc """
  Generates Fig-specific Rust scene decoder fragments that are appended to the
  generic Kiwi Rustler decoder source.
  """

  alias Figler.NativeSceneGenerator.Focus
  alias Figler.NativeSceneGenerator.Scene
  alias Figler.NativeSceneGenerator.Skip
  alias Figler.NativeSceneGenerator.Sparse
  alias KiwiCodec.Schema
  alias RustQ.Rust

  def render_splices(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [
      node_type_name_arms: node_type_name_arms(definition_map),
      sparse_decoders: Sparse.render(schema.definitions, definition_map),
      skip_decoders: Skip.render(schema.definitions, definition_map),
      graph_focus_decoders:
        Focus.render(definition_map, &Skip.message_arm/2, &Scene.render_template/2)
    ] ++ Scene.render(definition_map)
  end

  def source(%Schema{} = schema) do
    RustQ.render!(
      """
      __rq_include!("templates/scene_types.rs");
      __rq_sparse_decoders!();
      __rq_skip_decoders!();
      __rq_graph_focus_decoders!();
      __rq_include!("templates/scene_xpath_runtime.rs");
      __rq_include!("templates/scene_summary_decoders.rs");
      __rq_include!("templates/scene_nifs.rs");
      """,
      "native/src/generated.scene.rs",
      include_dir: "native/src",
      splice: render_splices(schema)
    )
  end

  def render(%Schema{} = schema) do
    schema
    |> render_splices()
    |> Keyword.values()
    |> List.flatten()
  end

  defp node_type_name_arms(definition_map) do
    definition_map
    |> Map.fetch!("NodeType")
    |> then(& &1.variants)
    |> Enum.map(fn field ->
      Rust.arm(Integer.to_string(field.value), ~s("#{Macro.underscore(field.name)}"))
    end)
  end
end
