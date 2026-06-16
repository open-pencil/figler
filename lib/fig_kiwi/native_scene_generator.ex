defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias FigKiwi.NativeSceneGenerator.Focus
  alias FigKiwi.NativeSceneGenerator.Skip
  alias FigKiwi.NativeSceneGenerator.Sparse
  alias FigKiwi.Scene.Projection
  alias FigKiwi.Scene.Projection.Native, as: ProjectionNative
  alias KiwiCodec.Schema
  alias RustQ.Rust

  def render_splices(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [
      node_type_name_arms: node_type_name_arms(definition_map),
      sparse_decoders: Sparse.render(schema.definitions, definition_map),
      skip_decoders: Skip.render(schema.definitions, definition_map),
      graph_focus_decoders:
        Focus.render(definition_map, &Skip.message_arm/2, &render_scene_template/2)
    ] ++ scene_splices(definition_map)
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

  defp scene_splices(definition_map) do
    [
      scene_message_skip_arms:
        definition_map
        |> Map.fetch!("Message")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 4))
        |> Enum.map(&Skip.message_arm(&1, definition_map)),
      scene_node_skip_arms: scene_node_skip_arms(definition_map),
      scene_summary_node_arms: scene_summary_node_arms(definition_map),
      scene_text_data_skip_arms:
        definition_map
        |> Map.fetch!("TextData")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 1))
        |> Enum.map(&Skip.message_arm(&1, definition_map)),
      scene_style_id_skip_arms:
        definition_map
        |> Map.fetch!("StyleId")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 1))
        |> Enum.map(&Skip.message_arm(&1, definition_map)),
      scene_query_node_fields: scene_optional_struct_fields(),
      scene_record_fields: scene_record_struct_fields(),
      scene_query_node_build_fields: scene_node_build_fields(),
      scene_record_build_fields: scene_record_build_fields(),
      scene_decode_locals: scene_decode_locals(),
      scene_decode_arms: scene_decode_arms(definition_map),
      scene_attr_lookup: scene_attr_lookup(),
      scene_attr_count: scene_attr_count(),
      scene_query_field_atoms: scene_query_field_atoms(),
      scene_query_field_encoders: scene_query_field_encoders(),
      scene_navigation_nifs: scene_navigation_nifs()
    ]
  end

  defp scene_node_skip_arms(definition_map) do
    keep_names = Projection.source_fields() |> Enum.map(&Projection.source_name/1) |> MapSet.new()

    definition_map
    |> Map.fetch!("NodeChange")
    |> then(& &1.fields)
    |> Enum.reject(&MapSet.member?(keep_names, &1.name))
    |> Enum.map(&Skip.message_arm(&1, definition_map))
  end

  defp scene_summary_node_arms(definition_map) do
    skip_names =
      [:guid, :parent_index, :type] |> Enum.map(&Projection.source_name/1) |> MapSet.new()

    keep_names = Projection.source_fields() |> Enum.map(&Projection.source_name/1) |> MapSet.new()

    definition_map
    |> Map.fetch!("NodeChange")
    |> then(& &1.fields)
    |> Enum.filter(&MapSet.member?(keep_names, &1.name))
    |> Enum.reject(&MapSet.member?(skip_names, &1.name))
    |> Enum.map(&Skip.message_arm(&1, definition_map))
  end

  defp scene_optional_fields do
    Projection.field_names() -- Projection.required_field_names()
  end

  defp scene_optional_struct_fields do
    Enum.map(scene_optional_fields(), fn field ->
      "#{field}: #{ProjectionNative.rust_type(field)},"
    end)
  end

  defp scene_record_struct_fields do
    Enum.map(scene_optional_fields(), fn
      :parent_guid -> "parent_guid: Option<SceneGuid>,"
      field -> "#{field}: #{ProjectionNative.rust_type(field)},"
    end)
  end

  defp scene_node_build_fields do
    Enum.map(scene_optional_fields(), fn field ->
      name = Atom.to_string(field)

      value =
        cond do
          field == :parent_guid ->
            "node.parent_guid.map(|guid| guid.to_string())"

          ProjectionNative.rust_copy?(field) ->
            "node.#{name}"

          true ->
            "node.#{name}.clone()"
        end

      "#{name}: #{value},"
    end)
  end

  defp scene_record_build_fields do
    Enum.map(scene_optional_fields(), fn field ->
      "#{field},"
    end)
  end

  defp scene_decode_locals do
    Enum.map(scene_optional_fields(), fn field ->
      "let mut #{field} = None;"
    end)
  end

  defp scene_decode_arms(definition_map) do
    fields_by_source =
      definition_map
      |> Map.fetch!("NodeChange")
      |> then(& &1.fields)
      |> Map.new(&{&1.name, &1.value})

    Projection.fields()
    |> Enum.reject(
      &(Map.get(&1, :required?, false) or match?(%{source: {:parent_index, _field}}, &1))
    )
    |> Enum.map(&scene_decode_arm_for(&1, fields_by_source))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp scene_decode_arm_for(%{decode: :font_name}, fields_by_source) do
    scene_decode_arm(Map.fetch!(fields_by_source, Projection.source_name(:font_name)), [
      "let (family, style, postscript) = read_scene_font_name_value(decoder)?;",
      "font_family = family;",
      "font_style = style;",
      "font_postscript = postscript;"
    ])
  end

  defp scene_decode_arm_for(%{decode: :text_data, name: name} = field, fields_by_source) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(field)),
      "#{name} = read_scene_text_data_value(decoder)?"
    )
  end

  defp scene_decode_arm_for(%{source: {:style_id, :guid}, name: name} = field, fields_by_source) do
    scene_decode_arm(
      Map.fetch!(fields_by_source, Projection.source_name(field)),
      "#{name} = read_scene_style_id_value(decoder)?"
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

  defp scene_decode_expr(name, %{decode: :bool}), do: "#{name} = Some(decoder.read_bool()?)"

  defp scene_decode_expr(name, %{decode: :float}),
    do: "#{name} = Some(decoder.read_var_float_value()?)"

  defp scene_decode_expr(_name, %{value: :vector}),
    do: "size = Some(read_scene_size_value(decoder)?)"

  defp scene_decode_expr(_name, %{value: :matrix}),
    do: "transform = Some(read_scene_transform_value(decoder)?)"

  defp scene_decode_expr(name, %{decode: :counted_paints}),
    do: "#{name} = read_scene_counted_array_value(decoder, skip_paint_from_decoder)?"

  defp scene_decode_expr(name, _field), do: "#{name} = Some(decoder.read_string_value()?)"

  defp scene_decode_arm(id, lines) do
    Rust.arm(
      Integer.to_string(id),
      lines |> List.wrap() |> Rust.block() |> Rust.to_fragment()
    )
  end

  defp scene_attr_lookup do
    entries =
      scene_optional_fields()
      |> Enum.flat_map(&ProjectionNative.xpath_attr_entries/1)

    entries
    |> Enum.with_index()
    |> Enum.map(fn {{field, attr, value_expr, opts}, index} ->
      attr_lookup_block(
        field,
        attr,
        value_expr,
        Keyword.put(opts, :last?, index == length(entries) - 1)
      )
    end)
  end

  defp attr_lookup_block(field, attr, value_expr, opts) do
    accessor =
      if Keyword.get(opts, :by_ref?, true), do: "self.#{field}.as_ref()", else: "self.#{field}"

    lines = [
      Rust.stmt("if index == cursor { return Some((#{Rust.literal(attr)}, #{value_expr})); }")
      | if(Keyword.get(opts, :last?, false), do: [], else: [Rust.stmt("cursor += 1")])
    ]

    Rust.to_fragment(Rust.if_let("Some(value)", accessor, lines))
  end

  defp scene_attr_count do
    Enum.map(scene_optional_fields(), fn
      :size -> Rust.if_("self.size.is_some()", [Rust.stmt("count += 4")])
      field -> Rust.if_("self.#{field}.is_some()", [Rust.stmt("count += 1")])
    end)
  end

  defp scene_query_field_atoms do
    Projection.field_names()
    |> Enum.reject(&(&1 in Projection.required_field_names()))
    |> Enum.map(fn field ->
      "static #{field |> Atom.to_string() |> String.upcase()}_ATOM: OnceLock<Atom> = OnceLock::new();"
    end)
  end

  defp scene_query_field_encoders do
    Projection.field_names()
    |> Enum.reject(&(&1 in Projection.required_field_names()))
    |> Enum.map(fn field ->
      name = Atom.to_string(field)
      atom = String.upcase(name)

      value =
        if field == :parent_guid do
          "node.parent_guid.map(|guid| guid.to_string()).encode(env)"
        else
          "node.#{name}.encode(env)"
        end

      Rust.if_("wants_field(fields, #{Rust.literal(name)})", [
        "keys.push(cached_atom(env, &#{atom}_ATOM, #{Rust.literal(name)}).encode(env));",
        "values.push(#{value});"
      ])
    end)
  end

  defp scene_navigation_nifs do
    [
      render_scene_template("scene_navigation_node_nif.rs",
        nif_name: "scene_index_node",
        runtime_name: "scene_index_node_value"
      ),
      render_scene_template("scene_navigation_node_nif.rs",
        nif_name: "scene_index_parent",
        runtime_name: "scene_index_parent_value"
      ),
      render_scene_template("scene_navigation_roots_nif.rs",
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
        render_scene_template("scene_navigation_list_nif.rs",
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
        render_scene_template("scene_navigation_filter_fields_nif.rs",
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
        render_scene_template("scene_navigation_noarg_list_nif.rs",
          nif_name: Atom.to_string(name),
          runtime_name: Atom.to_string(runtime_name)
        )
      end
    )
  end

  defp render_scene_template(template, bindings) do
    path = Path.join(["native", "src", "templates", template])
    {splices, bindings} = Keyword.pop(bindings, :splice, [])

    RustQ.render!(File.read!(path), path, bind: bindings, splice: splices)
  end
end
