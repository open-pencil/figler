defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias KiwiCodec.Schema
  alias KiwiCodec.Schema.Definition

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
      skip_decoders: Enum.map(schema.definitions, &skip_definition(&1, definition_map))
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
      "#{field.value} => \"#{Macro.underscore(field.name)}\","
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
            "#{field.value} => { static ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new(); Ok(cached_atom(env, &ATOM_#{field.value}, \"#{Macro.underscore(field.name)}\").encode(env)) },"
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
    """
    {
        static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();
        let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");
    #{indent(sparse_decode_field(field, definition_map), 4)}
        keys.push(field_atom.encode(env));
        values.push(value);
    }
    """
  end

  defp sparse_message_arm(field, definition_map) do
    """
    #{field.value} => {
        static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();
        let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");
    #{indent(sparse_decode_field(field, definition_map), 4)}
        keys.push(field_atom.encode(env));
        values.push(value);
    },
    """
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
        |> Enum.reject(&(&1.value in [1, 3, 4, 5, 6, 7, 11, 12]))
        |> Enum.map(&skip_message_arm(&1, definition_map))
    ]
  end

  defp skip_message_arm(field, definition_map) do
    "#{field.value} => { #{skip_field(field, definition_map)} },"
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
