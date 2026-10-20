defmodule Figler.Codegen.Native.Scene do
  @moduledoc """
  Generates Rust splices for native scene indexing and XPath projection.

  This module translates Figma schema metadata plus `Figler.Scene.Projection`
  into the Rust fragments inserted into the scene NIF templates.
  """

  @compile {:no_warn_undefined, [{KiwiCodec.RustlerGenerator.Skip, :message_arm, 2}]}

  alias Figler.Codegen.Native.AtomCache
  alias Figler.Codegen.Native.RenderProjection
  alias Figler.Codegen.Native.SupportFunction
  alias Figler.Codegen.Native.Scene.Decode
  alias Figler.Codegen.Native.Scene.FieldSkip
  alias Figler.Codegen.Native.Scene.Record
  alias Figler.Codegen.Native.Scene.SkipFieldHelpers
  alias Figler.Native.Entrypoints
  alias Figler.Render.Projection, as: RenderSourceProjection
  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Projection
  alias KiwiCodec.RustlerGenerator.Skip
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rustler.Nif

  def render(definition_map) do
    [
      scene_skip_field_helpers: SkipFieldHelpers.fragments(),
      scene_message_skip_field_decoder:
        FieldSkip.decoder(definition_map, %FieldSkip.Decoder{
          definition: "Message",
          function: :skip_fig_message_field
        }),
      scene_node_skip_field_decoder:
        FieldSkip.decoder(definition_map, %FieldSkip.Decoder{
          definition: "NodeChange",
          function: :skip_fig_node_change_field
        }),
      scene_text_data_skip_arms:
        definition_map
        |> Map.fetch!("TextData")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.id == 1))
        |> Enum.map(&Skip.message_arm(&1, definition_map)),
      scene_style_id_skip_arms:
        definition_map
        |> Map.fetch!("StyleId")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.id == 1))
        |> Enum.map(&Skip.message_arm(&1, definition_map)),
      scene_types: SupportFunction.scene_type_items(),
      scene_query_node: [Record.query_node_struct()],
      scene_node_record: [Record.scene_node_record_struct()],
      scene_record_build_fields: Record.record_build_fields(),
      graph_seed_record: Record.seed_record_expr(),
      graph_seed_stage_flags: graph_seed_stage_flags(),
      render_projection_field_constants: RenderProjection.field_constants(definition_map),
      render_projection_record:
        RenderSourceProjection.field_names() |> Enum.map(&A.var/1) |> A.vec(),
      scene_decode_locals: scene_decode_locals(),
      scene_decode_arms: scene_decode_arms(definition_map),
      scene_query_atom_statics: scene_query_atom_statics(),
      scene_nif_wrappers: scene_nif_wrappers(),
      scene_reader_helpers: SupportFunction.scene_reader_items(),
      scene_navigation_nifs: SupportFunction.scene_navigation_nif_items()
    ]
  end

  def scene_nif_wrappers do
    Nif.wrappers_from_source(
      "native/src/templates/scene_nifs.rs",
      Entrypoints.template_nifs(),
      schedule: :dirty_cpu,
      vis: :pub
    )
  end

  def render_template(template, bindings) do
    path = Path.join(["native", "src", "templates", template])
    {splices, bindings} = Keyword.pop(bindings, :splice, [])

    RustQ.render!(File.read!(path), path, bind: bindings, splice: splices)
  end

  defp graph_seed_stage_flags do
    Enum.map(SeedProjection.native_stage_flags(), fn {stage, flag} ->
      name = stage |> Atom.to_string() |> String.upcase() |> then(&"GRAPH_SEED_STAGE_#{&1}")
      A.const(name, :u8, A.lit(flag))
    end)
  end

  defp scene_optional_fields, do: Enum.map(Record.optional_fields(), & &1.name)

  defp scene_decode_locals do
    Enum.map(scene_optional_fields(), &A.let_mut(&1, A.none()))
  end

  defp scene_decode_arms(definition_map) do
    fields_by_source =
      definition_map
      |> Map.fetch!("NodeChange")
      |> then(& &1.fields)
      |> Map.new(&{&1.name, &1.id})

    Projection.fields()
    |> Enum.reject(
      &(Map.get(&1, :required?, false) or match?(%{source: {:parent_index, _field}}, &1))
    )
    |> Enum.map(&scene_decode_arm_for(&1, fields_by_source))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp scene_decode_arm_for(%{decode: :font_name}, fields_by_source) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(:font_name)),
      Decode.font_name()
    )
  end

  defp scene_decode_arm_for(%{decode: :text_data, name: name} = field, fields_by_source) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(field)),
      Decode.text_data(name)
    )
  end

  defp scene_decode_arm_for(%{source: {:style_id, :guid}, name: name} = field, fields_by_source) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(field)),
      Decode.style_id(name)
    )
  end

  defp scene_decode_arm_for(
         %{source: {:node_change, _field}, name: name} = field,
         fields_by_source
       ) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(field)),
      scene_decode_expr(name, field)
    )
  end

  defp scene_decode_arm_for(_field, _fields_by_source), do: nil

  defp scene_decode_expr(name, %{decode: :bool}), do: Decode.bool(name)

  defp scene_decode_expr(name, %{decode: :float}), do: Decode.float(name)

  defp scene_decode_expr(_name, %{value: :vector}), do: Decode.vector()

  defp scene_decode_expr(_name, %{value: :matrix}), do: Decode.matrix()

  defp scene_decode_expr(name, %{decode: :counted_paints}), do: Decode.counted_paints(name)

  defp scene_decode_expr(name, _field), do: Decode.string(name)

  defp scene_decode_arm(id, %Decode.Operation{} = operation), do: Decode.arm(id, operation)

  defp scene_query_atom_statics do
    Projection.field_names()
    |> Enum.map(&AtomCache.static/1)
  end
end
