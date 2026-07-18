defmodule Figler.Codegen.Native do
  @moduledoc """
  Generates Fig-specific Rust scene decoder fragments that are appended to the
  generic Kiwi Rustler decoder source.
  """

  alias Figler.Codegen.Native.SupportFunction
  alias Figler.Codegen.Native.Focus
  alias Figler.Codegen.Native.Scene
  alias KiwiCodec.RustlerGenerator.Skip
  alias KiwiCodec.Schema
  alias RustQ.Rust
  alias RustQ.Rust.AST
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rust.AST.PatternBuilder, as: P

  def render_splices(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [
      graph_focus_helpers: SupportFunction.focus_helper_items(),
      node_type_name_arms: node_type_name_arms(definition_map),
      graph_focus_decoders:
        Focus.render(definition_map, &Skip.message_arm/2, &Scene.render_template/2)
    ] ++ Scene.render(definition_map)
  end

  def source(%Schema{} = schema) do
    {graph_seed_record, splices} =
      schema
      |> render_splices()
      |> Keyword.pop!(:graph_seed_record)

    {render_projection_record, splices} = Keyword.pop!(splices, :render_projection_record)

    RustQ.render!(
      """
      __rq_include!("templates/scene_types.rs");
      __rq_graph_focus_helpers!();
      __rq_graph_focus_decoders!();
      __rq_include!("templates/graph_seed_decoders.rs");
      __rq_include!("templates/render_projection_decoders.rs");
      __rq_include!("templates/scene_xpath_runtime.rs");
      __rq_include!("templates/scene_summary_decoders.rs");
      __rq_include!("templates/scene_nifs.rs");
      """,
      "native/src/generated.scene.rs",
      include_dir: "native/src",
      bind: [
        graph_seed_record: {:expr, Rust.render(graph_seed_record)},
        render_projection_record: {:expr, Rust.render(render_projection_record)}
      ],
      splice: splices
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
      %AST.Arm{
        pattern: P.lit(field.value),
        body: [%AST.Return{expr: A.lit(Macro.underscore(field.name))}]
      }
    end)
  end
end
