defmodule Figler.Codegen.Native.Scene do
  @moduledoc """
  Generates Rust splices for native scene indexing and XPath projection.

  This module translates Figma schema metadata plus `Figler.Scene.Projection`
  into the Rust fragments inserted into the scene NIF templates.
  """

  alias Figler.Codegen.Native.Defrust
  alias Figler.Codegen.Native.Fragment
  alias Figler.Codegen.Native.Scene.Attrs
  alias Figler.Codegen.Native.Scene.Decode
  alias Figler.Codegen.Native.Scene.FieldSkip
  alias Figler.Codegen.Native.Scene.Record
  alias KiwiCodec.RustlerGenerator.Skip
  alias Figler.Scene.Projection

  def render(definition_map) do
    [
      scene_message_skip_field_decoder:
        FieldSkip.decoder(definition_map, %FieldSkip.Decoder{
          definition: "Message",
          function: :skip_fig_message_field,
          error_name: "scene summary"
        }),
      scene_node_skip_field_decoder:
        FieldSkip.decoder(definition_map, %FieldSkip.Decoder{
          definition: "NodeChange",
          function: :skip_fig_node_change_field,
          error_name: "scene node"
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
      scene_query_node_fields: Record.query_node_fields(),
      scene_record_fields: Record.record_fields(),
      scene_query_node_build_fields: Record.query_node_build_fields(),
      scene_record_build_fields: Record.record_build_fields(),
      scene_decode_locals: scene_decode_locals(),
      scene_decode_arms: scene_decode_arms(definition_map),
      scene_attr_lookup: Attrs.xpath_lookup(),
      scene_attr_count: Attrs.xpath_count(),
      scene_query_field_atoms: Attrs.query_field_atoms(),
      scene_query_field_encoders: Attrs.query_field_encoders(),
      scene_reader_helpers: Defrust.scene_reader_items(),
      scene_navigation_nifs: scene_navigation_nifs()
    ]
  end

  def render_template(template, bindings) do
    path = Path.join(["native", "src", "templates", template])
    {splices, bindings} = Keyword.pop(bindings, :splice, [])

    RustQ.render!(File.read!(path), path, bind: bindings, splice: splices)
  end

  defp scene_optional_fields, do: Enum.map(Record.optional_fields(), & &1.name)

  defp scene_decode_locals do
    Enum.map(scene_optional_fields(), &Fragment.let_none/1)
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

  defp scene_navigation_nifs do
    [
      render_template("scene_navigation_node_nif.rs",
        nif_name: "scene_index_node",
        runtime_name: "scene_index_node_value"
      ),
      render_template("scene_navigation_node_nif.rs",
        nif_name: "scene_index_parent",
        runtime_name: "scene_index_parent_value"
      ),
      render_template("scene_navigation_roots_nif.rs",
        nif_name: "scene_index_roots",
        runtime_name: "scene_index_roots_value"
      )
      | scene_list_nifs() ++ scene_filter_field_nifs() ++ scene_noarg_list_nifs()
    ]
  end

  defp scene_list_nifs do
    Enum.map(
      [
        scene_index_children: :scene_index_children_value,
        scene_index_siblings: :scene_index_siblings_value,
        scene_index_by_type: :scene_index_by_type_value,
        scene_index_named: :scene_index_named_value,
        scene_index_name_contains: :scene_index_name_contains_value,
        scene_index_text_contains: :scene_index_text_contains_value,
        scene_index_ancestors: :scene_index_ancestors_value,
        scene_index_descendants: :scene_index_descendants_value
      ],
      fn {name, runtime_name} ->
        render_template("scene_navigation_list_nif.rs",
          nif_name: Atom.to_string(name),
          runtime_name: Atom.to_string(runtime_name)
        )
      end
    )
  end

  defp scene_filter_field_nifs do
    Enum.map(
      [
        scene_index_by_type_fields: :scene_index_by_type_fields_value,
        scene_index_name_contains_fields: :scene_index_name_contains_fields_value,
        scene_index_text_contains_fields: :scene_index_text_contains_fields_value
      ],
      fn {name, runtime_name} ->
        render_template("scene_navigation_filter_fields_nif.rs",
          nif_name: Atom.to_string(name),
          runtime_name: Atom.to_string(runtime_name)
        )
      end
    )
  end

  defp scene_noarg_list_nifs do
    Enum.map(
      [
        scene_index_components: :scene_index_components_value,
        scene_index_with_fills: :scene_index_with_fills_value,
        scene_index_with_strokes: :scene_index_with_strokes_value
      ],
      fn {name, runtime_name} ->
        render_template("scene_navigation_noarg_list_nif.rs",
          nif_name: Atom.to_string(name),
          runtime_name: Atom.to_string(runtime_name)
        )
      end
    )
  end
end
