defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias FigKiwi.NativeSceneGenerator.Focus
  alias FigKiwi.NativeSceneGenerator.Scene
  alias FigKiwi.NativeSceneGenerator.Skip
  alias FigKiwi.NativeSceneGenerator.Sparse
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

  def render(%Schema{} = schema) do
    schema
    |> render_splices()
    |> Keyword.values()
    |> List.flatten()
  end

  defp node_type_name_arms(definition_map) do
    definition_map
    |> Map.fetch!("NodeType")
    |> then(& &1.fields)
    |> Enum.map(fn field ->
      Rust.arm(Integer.to_string(field.value), ~s("#{Macro.underscore(field.name)}"))
    end)
  end
end
