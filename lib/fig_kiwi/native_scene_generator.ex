defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias FigKiwi.Scene.Projection
  alias KiwiCodec.Schema
  alias KiwiCodec.Schema.Definition
  alias RustQ.Rust

  @primitive_skip %{
    "bool" => "decoder.read_bool()?;",
    "byte" => "decoder.read_byte()?;",
    "float" => "decoder.read_var_float_value()?;",
    "int" => "decoder.read_var_int()?;",
    "int64" => "decoder.read_var_int64()?;",
    "string" => "decoder.skip_string()?;",
    "uint" => "decoder.read_var_uint()?;",
    "uint64" => "decoder.read_var_uint64()?;"
  }

  def render_splices(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [
      node_type_name_arms: node_type_name_arms(definition_map),
      sparse_decoders: Enum.map(schema.definitions, &sparse_definition(&1, definition_map)),
      skip_decoders: Enum.map(schema.definitions, &skip_definition(&1, definition_map)),
      graph_focus_decoders: graph_focus_decoders(definition_map)
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

  defp sparse_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    render_sparse_template("sparse_struct_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_fields: Enum.map(fields, &sparse_struct_field(&1, definition_map))]
    )
  end

  defp sparse_definition(%Definition{kind: :enum, name: name, fields: fields}, _definition_map) do
    render_sparse_template("sparse_enum_decoder.rs",
      name: name,
      splice: [
        sparse_enum_arms:
          Enum.map(fields, fn field ->
            Rust.arm(
              Integer.to_string(field.value),
              "{ static ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new(); Ok(cached_atom(env, &ATOM_#{field.value}, \"#{Macro.underscore(field.name)}\").encode(env)) }"
            )
          end)
      ]
    )
  end

  defp sparse_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    render_sparse_template("sparse_message_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_field_arms: Enum.map(fields, &sparse_message_arm(&1, definition_map))]
    )
  end

  defp render_sparse_template(template, opts) do
    name = Keyword.fetch!(opts, :name)
    path = Path.join(["native", "src", "templates", template])

    RustQ.render!(File.read!(path), path,
      bind: [
        decoder_name: "decode_sparse_#{rust_ident(name)}_from_decoder",
        module_name: {:literal, "Elixir.FigKiwi.Schema.#{name}"},
        definition_name: {:literal, name},
        capacity: {:expr, opts |> Keyword.get(:capacity, 0) |> Integer.to_string()}
      ],
      splice: Keyword.get(opts, :splice, [])
    )
  end

  defp render_skip_template(template, opts) do
    name = Keyword.fetch!(opts, :name)
    path = Path.join(["native", "src", "templates", template])

    RustQ.render!(File.read!(path), path,
      bind: [
        skip_decoder_name: "skip_#{rust_ident(name)}_from_decoder",
        definition_name: {:literal, name}
      ],
      splice: Keyword.get(opts, :splice, [])
    )
  end

  defp sparse_struct_field(field, definition_map) do
    field
    |> sparse_field_block(definition_map)
    |> Rust.to_fragment()
  end

  defp sparse_message_arm(field, definition_map) do
    Rust.arm(
      Integer.to_string(field.value),
      field |> sparse_field_block(definition_map) |> Rust.to_fragment()
    )
  end

  defp sparse_field_block(field, definition_map) do
    Rust.block([
      "static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();",
      ~s|let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");|,
      sparse_decode_field(field, definition_map),
      "keys.push(field_atom.encode(env));",
      "values.push(value);"
    ])
  end

  defp sparse_decode_field(%{array?: true, type: "byte"}, _definition_map) do
    "let value = decoder.read_byte_array(env)?;"
  end

  defp sparse_decode_field(%{array?: true} = field, definition_map) do
    inner = sparse_decode_scalar(%{field | array?: false}, definition_map)

    """
    let len = decoder.read_var_uint()? as usize;
    let mut items = Vec::with_capacity(len);
    for _ in 0..len {
    #{indent("let item = #{inner};", 4)}
        items.push(item);
    }
    let value = items.encode(env);
    """
  end

  defp sparse_decode_field(field, definition_map) do
    "let value = #{sparse_decode_scalar(field, definition_map)};"
  end

  defp sparse_decode_scalar(%{type: type}, definition_map) do
    cond do
      primitive = sparse_primitive_decode(type) ->
        primitive

      Map.get(definition_map, type) && Map.fetch!(definition_map, type).kind == :enum ->
        "decode_sparse_#{rust_ident(type)}_from_decoder(env, decoder)?"

      Map.get(definition_map, type) &&
          Map.fetch!(definition_map, type).kind in [:message, :struct] ->
        "decode_sparse_#{rust_ident(type)}_from_decoder(env, decoder)?"

      Map.has_key?(definition_map, type) ->
        "decode_#{rust_ident(type)}_from_decoder(env, decoder)?"
    end
  end

  defp sparse_primitive_decode("bool"), do: "decoder.read_bool()?.encode(env)"
  defp sparse_primitive_decode("byte"), do: "decoder.read_byte()?.encode(env)"
  defp sparse_primitive_decode("float"), do: "decoder.read_var_float(env)?"
  defp sparse_primitive_decode("int"), do: "decoder.read_var_int()?.encode(env)"
  defp sparse_primitive_decode("int64"), do: "decoder.read_var_int64()?.encode(env)"
  defp sparse_primitive_decode("string"), do: "decoder.read_string(env)?"
  defp sparse_primitive_decode("uint"), do: "decoder.read_var_uint()?.encode(env)"
  defp sparse_primitive_decode("uint64"), do: "decoder.read_var_uint64()?.encode(env)"
  defp sparse_primitive_decode(_type), do: nil

  defp skip_definition(%Definition{kind: :enum, name: name}, _definition_map) do
    render_skip_template("skip_enum_decoder.rs", name: name)
  end

  defp skip_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    render_skip_template("skip_struct_decoder.rs",
      name: name,
      splice: [skip_fields: Enum.map(fields, &skip_field(&1, definition_map))]
    )
  end

  defp skip_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    render_skip_template("skip_message_decoder.rs",
      name: name,
      splice: [skip_field_arms: Enum.map(fields, &skip_message_arm(&1, definition_map))]
    )
  end

  defp graph_focus_decoders(definition_map) do
    message_fields = definition_map |> Map.fetch!("Message") |> then(& &1.fields)
    node_fields = definition_map |> Map.fetch!("NodeChange") |> then(& &1.fields)
    symbol_fields = definition_map |> Map.fetch!("SymbolData") |> then(& &1.fields)

    prop_assignment_fields =
      definition_map |> Map.fetch!("ComponentPropAssignment") |> then(& &1.fields)

    prop_value_fields = definition_map |> Map.fetch!("ComponentPropValue") |> then(& &1.fields)

    message_skip_arms =
      message_fields
      |> Enum.reject(&(&1.name == "nodeChanges"))
      |> Enum.map_join("\n", &skip_message_arm_text(&1, definition_map))

    node_focus_arms =
      Enum.map_join(node_fields, "\n", fn field ->
        case field.name do
          "guid" ->
            graph_focus_arm(field, "guid = Some(graph_focus_read_guid(decoder)?);")

          "parentIndex" ->
            graph_focus_arm(field, "parent_guid = Some(graph_focus_read_parent_guid(decoder)?);")

          "symbolData" ->
            graph_focus_arm(field, [
              "let data = graph_focus_read_symbol_data(decoder)?;",
              "symbol_id = data.symbol_id;",
              "graph_focus_extend_refs(&mut refs, data.refs);"
            ])

          "overriddenSymbolID" ->
            graph_focus_arm(
              field,
              "graph_focus_push_ref(&mut refs, graph_focus_read_guid(decoder)?);"
            )

          "componentPropAssignments" ->
            graph_focus_arm(field, [
              "let len = decoder.read_var_uint()? as usize;",
              "for _ in 0..len { let next = graph_focus_read_component_prop_assignment(decoder)?; graph_focus_extend_refs(&mut refs, next); }"
            ])

          _other ->
            skip_message_arm_text(field, definition_map)
        end
      end)

    symbol_focus_arms =
      symbol_fields
      |> Enum.reject(&(&1.name in ["symbolID", "symbolOverrides"]))
      |> Enum.map_join("\n", &skip_message_arm_text(&1, definition_map))

    prop_assignment_arms =
      graph_focus_prop_assignment_arms(prop_assignment_fields, definition_map)

    prop_value_arms = graph_focus_prop_value_arms(prop_value_fields, definition_map)

    [
      """
      #[derive(Clone, Copy, Eq, Hash, PartialEq)]
      struct GraphFocusGuid { session_id: u32, local_id: u32 }

      struct GraphFocusMeta {
          guid: Option<GraphFocusGuid>,
          parent_guid: Option<GraphFocusGuid>,
          symbol_id: Option<GraphFocusGuid>,
          refs: Option<Vec<GraphFocusGuid>>,
          byte_start: usize,
          byte_end: usize,
      }

      struct GraphFocusSymbolData {
          symbol_id: Option<GraphFocusGuid>,
          refs: Option<Vec<GraphFocusGuid>>,
      }

      fn graph_focus_parse_guid(value: &str) -> Option<GraphFocusGuid> {
          let (session_id, local_id) = value.split_once(':')?;
          Some(GraphFocusGuid { session_id: session_id.parse().ok()?, local_id: local_id.parse().ok()? })
      }

      fn graph_focus_read_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
          Ok(GraphFocusGuid { session_id: decoder.read_var_uint()?, local_id: decoder.read_var_uint()? })
      }

      fn graph_focus_read_parent_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
          let guid = graph_focus_read_guid(decoder)?;
          decoder.skip_string()?;
          Ok(guid)
      }

      fn graph_focus_push_ref(refs: &mut Option<Vec<GraphFocusGuid>>, guid: GraphFocusGuid) {
          refs.get_or_insert_with(Vec::new).push(guid);
      }

      fn graph_focus_extend_refs(refs: &mut Option<Vec<GraphFocusGuid>>, next: Option<Vec<GraphFocusGuid>>) {
          if let Some(next) = next {
              refs.get_or_insert_with(Vec::new).extend(next);
          }
      }

      fn graph_focus_read_symbol_data(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusSymbolData> {
          let mut symbol_id = None;
          let mut refs = None;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  1 => { symbol_id = Some(graph_focus_read_guid(decoder)?); },
                  2 => {
                      let len = decoder.read_var_uint()? as usize;
                      for _ in 0..len {
                          let meta = graph_focus_index_node_change(decoder)?;
                          graph_focus_extend_refs(&mut refs, meta.refs);
                      }
                  },
                  #{symbol_focus_arms}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while indexing SymbolData", field)))),
              }
          }
          Ok(GraphFocusSymbolData { symbol_id, refs })
      }

      fn graph_focus_read_component_prop_value(decoder: &mut Decoder<'_>) -> NifResult<Option<Vec<GraphFocusGuid>>> {
          let mut refs = None;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  #{prop_value_arms}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while indexing ComponentPropValue", field)))),
              }
          }
          Ok(refs)
      }

      fn graph_focus_read_component_prop_assignment(decoder: &mut Decoder<'_>) -> NifResult<Option<Vec<GraphFocusGuid>>> {
          let mut refs = None;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  #{prop_assignment_arms}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while indexing ComponentPropAssignment", field)))),
              }
          }
          Ok(refs)
      }

      fn graph_focus_index_node_change(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusMeta> {
          let mut guid = None;
          let mut parent_guid = None;
          let mut symbol_id = None;
          let mut refs = None;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  #{node_focus_arms}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while indexing NodeChange", field)))),
              }
          }
          Ok(GraphFocusMeta { guid, parent_guid, symbol_id, refs, byte_start: 0, byte_end: 0 })
      }

      fn graph_focus_index_message(decoder: &mut Decoder<'_>) -> NifResult<Vec<GraphFocusMeta>> {
          let mut nodes = Vec::new();
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  4 => {
                      let len = decoder.read_var_uint()? as usize;
                      nodes.reserve(len);
                      for _ in 0..len {
                          let byte_start = decoder.position();
                          let mut meta = graph_focus_index_node_change(decoder)?;
                          meta.byte_start = byte_start;
                          meta.byte_end = decoder.position();
                          nodes.push(meta);
                      }
                  },
                  #{message_skip_arms}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while indexing Message", field)))),
              }
          }
          Ok(nodes)
      }

      fn graph_focus_collect_subtree(
          wanted: &mut std::collections::HashSet<GraphFocusGuid>,
          guid: GraphFocusGuid,
          by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
          children: &std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>>,
      ) {
          if !by_guid.contains_key(&guid) || !wanted.insert(guid) { return; }
          if let Some(child_guids) = children.get(&guid) {
              for child_guid in child_guids {
                  graph_focus_collect_subtree(wanted, *child_guid, by_guid, children);
              }
          }
      }

      fn graph_focus_collect_ancestors(
          wanted: &mut std::collections::HashSet<GraphFocusGuid>,
          guid: GraphFocusGuid,
          metas: &[GraphFocusMeta],
          by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
      ) {
          let mut current = guid;
          while let Some(index) = by_guid.get(&current) {
              let Some(parent_guid) = metas[*index].parent_guid else { break; };
              wanted.insert(parent_guid);
              current = parent_guid;
          }
      }

      fn graph_focus_wanted(metas: &[GraphFocusMeta], focus: &[String]) -> std::collections::HashSet<GraphFocusGuid> {
          let mut by_guid = std::collections::HashMap::new();
          let mut children: std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>> = std::collections::HashMap::new();
          for (index, meta) in metas.iter().enumerate() {
              if let Some(guid) = meta.guid {
                  by_guid.insert(guid, index);
                  if let Some(parent_guid) = meta.parent_guid {
                      children.entry(parent_guid).or_default().push(guid);
                  }
              }
          }

          let mut wanted = std::collections::HashSet::new();
          for guid in focus.iter().filter_map(|value| graph_focus_parse_guid(value)) {
              graph_focus_collect_subtree(&mut wanted, guid, &by_guid, &children);
          }

          loop {
              let before = wanted.len();
              let current = wanted.iter().copied().collect::<Vec<_>>();
              for guid in current {
                  if let Some(index) = by_guid.get(&guid) {
                      if let Some(symbol_id) = metas[*index].symbol_id {
                          graph_focus_collect_subtree(&mut wanted, symbol_id, &by_guid, &children);
                      }
                      if let Some(refs) = &metas[*index].refs {
                          for ref_id in refs {
                              graph_focus_collect_subtree(&mut wanted, *ref_id, &by_guid, &children);
                          }
                      }
                  }
              }
              if wanted.len() == before { break; }
          }

          let current = wanted.iter().copied().collect::<Vec<_>>();
          for guid in current {
              graph_focus_collect_ancestors(&mut wanted, guid, metas, &by_guid);
          }

          wanted
      }

      fn graph_focus_sparse_message_from_slices<'a>(
          env: Env<'a>,
          bytes: &[u8],
          metas: &[GraphFocusMeta],
          wanted: &std::collections::HashSet<GraphFocusGuid>,
      ) -> NifResult<Term<'a>> {
          static NODE_CHANGES_ATOM: OnceLock<Atom> = OnceLock::new();
          let node_changes_atom = cached_atom(env, &NODE_CHANGES_ATOM, "node_changes");
          let mut node_changes = Vec::new();

          for meta in metas {
              let keep = meta.guid.map(|guid| wanted.contains(&guid)).unwrap_or(false);
              if keep {
                  let mut decoder = Decoder::new(&bytes[meta.byte_start..meta.byte_end]);
                  node_changes.push(decode_sparse_node_change_from_decoder(env, &mut decoder)?);
                  decoder.finish()?;
              }
          }

          Term::map_from_term_arrays(env, &[node_changes_atom.encode(env)], &[node_changes.encode(env)])
      }
      """
    ]
  end

  defp graph_focus_arm(field, lines) do
    field.value
    |> Integer.to_string()
    |> Rust.arm(lines |> List.wrap() |> Rust.block() |> Rust.to_fragment())
    |> Rust.to_fragment()
  end

  defp graph_focus_prop_assignment_arms(fields, definition_map) do
    Enum.map_join(fields, "\n", fn field ->
      case field.name do
        "value" ->
          graph_focus_arm(field, [
            "let next = graph_focus_read_component_prop_value(decoder)?;",
            "graph_focus_extend_refs(&mut refs, next);"
          ])

        _other ->
          skip_message_arm_text(field, definition_map)
      end
    end)
  end

  defp graph_focus_prop_value_arms(fields, definition_map) do
    Enum.map_join(fields, "\n", fn field ->
      case field.name do
        "guidValue" ->
          graph_focus_arm(
            field,
            "graph_focus_push_ref(&mut refs, graph_focus_read_guid(decoder)?);"
          )

        _other ->
          skip_message_arm_text(field, definition_map)
      end
    end)
  end

  defp scene_splices(definition_map) do
    [
      scene_message_skip_arms:
        definition_map
        |> Map.fetch!("Message")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 4))
        |> Enum.map(&skip_message_arm(&1, definition_map)),
      scene_node_skip_arms:
        definition_map
        |> Map.fetch!("NodeChange")
        |> then(& &1.fields)
        |> Enum.reject(
          &(&1.value in [
              1,
              3,
              4,
              5,
              6,
              7,
              11,
              12,
              38,
              39,
              41,
              42,
              216,
              252,
              332,
              333,
              334,
              335,
              336
            ])
        )
        |> Enum.map(&skip_message_arm(&1, definition_map)),
      scene_text_data_skip_arms:
        definition_map
        |> Map.fetch!("TextData")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 1))
        |> Enum.map(&skip_message_arm(&1, definition_map)),
      scene_style_id_skip_arms:
        definition_map
        |> Map.fetch!("StyleId")
        |> then(& &1.fields)
        |> Enum.reject(&(&1.value == 1))
        |> Enum.map(&skip_message_arm(&1, definition_map)),
      scene_query_node_fields: scene_optional_struct_fields(),
      scene_record_fields: scene_optional_struct_fields(),
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

  defp scene_optional_fields do
    Projection.field_names() -- Projection.required_field_names()
  end

  defp scene_optional_struct_fields do
    Enum.map(scene_optional_fields(), fn field ->
      "#{field}: #{scene_rust_field_type(field)},"
    end)
  end

  defp scene_node_build_fields do
    Enum.map(scene_optional_fields(), fn field ->
      name = Atom.to_string(field)

      value =
        cond do
          field == :parent_guid -> "node.parent_guid.map(|guid| guid.to_string())"
          field in [:visible, :locked, :fill_count, :stroke_count] -> "node.#{name}"
          true -> "node.#{name}.clone()"
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
    node_fields = definition_map |> Map.fetch!("NodeChange") |> then(& &1.fields)

    field_id = fn source ->
      node_fields |> Enum.find(&(&1.name == source)) |> Map.fetch!(:value)
    end

    [
      {field_id.("name"), "name = Some(decoder.read_string_value()?)"},
      {field_id.("visible"), "visible = Some(decoder.read_bool()?)"},
      {field_id.("locked"), "locked = Some(decoder.read_bool()?)"},
      {field_id.("size"), "size = Some(read_scene_size_value(decoder)?)"},
      {field_id.("transform"), "transform = Some(read_scene_transform_value(decoder)?)"},
      {field_id.("fontName"),
       "{ let (family, style, postscript) = read_scene_font_name_value(decoder)?; font_family = family; font_style = style; font_postscript = postscript; }"},
      {field_id.("textData"), "text = read_scene_text_data_value(decoder)?"},
      {field_id.("componentKey"), "component_key = Some(decoder.read_string_value()?)"},
      {field_id.("originComponentKey"),
       "origin_component_key = Some(decoder.read_string_value()?)"},
      {field_id.("styleIdForFill"), "fill_style_guid = read_scene_style_id_value(decoder)?"},
      {field_id.("styleIdForStrokeFill"),
       "stroke_style_guid = read_scene_style_id_value(decoder)?"},
      {field_id.("styleIdForText"), "text_style_guid = read_scene_style_id_value(decoder)?"},
      {field_id.("styleIdForEffect"), "effect_style_guid = read_scene_style_id_value(decoder)?"},
      {field_id.("styleIdForGrid"), "grid_style_guid = read_scene_style_id_value(decoder)?"},
      {field_id.("fillPaints"),
       "fill_count = read_scene_counted_array_value(decoder, skip_paint_from_decoder)?"},
      {field_id.("strokePaints"),
       "stroke_count = read_scene_counted_array_value(decoder, skip_paint_from_decoder)?"}
    ]
    |> Enum.map(fn {id, expr} -> "#{id} => #{expr}," end)
  end

  defp scene_rust_field_type(:size), do: "Option<SceneSize>"
  defp scene_rust_field_type(:transform), do: "Option<SceneTransform>"
  defp scene_rust_field_type(:visible), do: "Option<bool>"
  defp scene_rust_field_type(:locked), do: "Option<bool>"
  defp scene_rust_field_type(:fill_count), do: "Option<usize>"
  defp scene_rust_field_type(:stroke_count), do: "Option<usize>"
  defp scene_rust_field_type(_field), do: "Option<String>"

  defp scene_attr_lookup do
    entries =
      scene_optional_fields()
      |> Enum.flat_map(fn
        :size ->
          [
            {:size, "x", "value.x.to_string()", []},
            {:size, "y", "value.y.to_string()", []},
            {:size, "width", "value.x.to_string()", []},
            {:size, "height", "value.y.to_string()", []}
          ]

        :transform ->
          [
            {:transform, "transform",
             "format!(\"{},{},{},{},{},{}\", value.m00, value.m01, value.m02, value.m10, value.m11, value.m12)",
             []}
          ]

        field when field in [:visible, :locked, :fill_count, :stroke_count] ->
          [{field, Atom.to_string(field), "value.to_string()", by_ref?: false}]

        :parent_guid ->
          [{:parent_guid, "parent_guid", "value.to_string()", []}]

        field ->
          [{field, Atom.to_string(field), "value.clone()", []}]
      end)

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

    increment = unless Keyword.get(opts, :last?, false), do: "cursor += 1"

    """
    if let Some(value) = #{accessor} {
        if index == cursor {
            return Some(("#{attr}", #{value_expr}));
        }
        #{increment && "#{increment};"}
    }
    """
  end

  defp scene_attr_count do
    Enum.map(scene_optional_fields(), fn
      :size -> "if self.size.is_some() { count += 4; }"
      field -> "if self.#{field}.is_some() { count += 1; }"
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

      """
      if wants_field(fields, "#{name}") {
          keys.push(cached_atom(env, &#{atom}_ATOM, "#{name}").encode(env));
          values.push(#{value});
      }
      """
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

    RustQ.render!(File.read!(path), path, bind: bindings)
  end

  defp skip_message_arm(field, definition_map) do
    Rust.arm(Integer.to_string(field.value), "{ #{skip_field(field, definition_map)} }")
  end

  defp skip_message_arm_text(field, definition_map) do
    field
    |> skip_message_arm(definition_map)
    |> Rust.to_fragment()
  end

  defp skip_field(%{array?: true, type: "byte"}, _definition_map) do
    "decoder.skip_byte_array()?;"
  end

  defp skip_field(%{array?: true} = field, definition_map) do
    inner = skip_field(%{field | array?: false}, definition_map)

    """
    {
        let len = decoder.read_var_uint()? as usize;
        for _ in 0..len {
    #{indent(inner, 8)}
        }
    }
    """
  end

  defp skip_field(%{type: type}, definition_map) do
    cond do
      primitive = @primitive_skip[type] ->
        primitive

      Map.has_key?(definition_map, type) ->
        "skip_#{rust_ident(type)}_from_decoder(decoder)?;"
    end
  end

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end

  defp indent(text, spaces) do
    padding = String.duplicate(" ", spaces)

    text
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map_join("\n", &(padding <> &1))
  end
end
