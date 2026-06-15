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
    body = Enum.map_join(fields, "\n", &sparse_struct_field(&1, definition_map))
    capacity = length(fields) + 1

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        static MODULE_ATOM: OnceLock<Atom> = OnceLock::new();
        static MODULE_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
        let module_atom = cached_atom(env, &MODULE_ATOM, "Elixir.FigKiwi.Schema.#{name}");
        let module_key_atom = cached_atom(env, &MODULE_KEY_ATOM, "__kiwi_module__");
        let mut keys = Vec::with_capacity(#{capacity});
        let mut values = Vec::with_capacity(#{capacity});
        keys.push(module_key_atom.encode(env));
        values.push(module_atom.encode(env));
    #{indent(body, 4)}
        Term::map_from_term_arrays(env, &keys, &values)
    }
    """
  end

  defp sparse_definition(%Definition{kind: :enum, name: name, fields: fields}, _definition_map) do
    arms =
      Enum.map_join(fields, "\n", fn field ->
        "#{field.value} => { static ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new(); Ok(cached_atom(env, &ATOM_#{field.value}, \"#{Macro.underscore(field.name)}\").encode(env)) },"
      end)

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        match decoder.read_var_uint()? {
    #{indent(arms, 8)}
            value => Ok((value as i64).encode(env)),
        }
    }
    """
  end

  defp sparse_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    arms = Enum.map_join(fields, "\n", &sparse_message_arm(&1, definition_map))
    capacity = length(fields) + 1

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        static MODULE_ATOM: OnceLock<Atom> = OnceLock::new();
        static MODULE_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
        let module_atom = cached_atom(env, &MODULE_ATOM, "Elixir.FigKiwi.Schema.#{name}");
        let module_key_atom = cached_atom(env, &MODULE_KEY_ATOM, "__kiwi_module__");
        let mut keys = Vec::with_capacity(#{capacity});
        let mut values = Vec::with_capacity(#{capacity});
        keys.push(module_key_atom.encode(env));
        values.push(module_atom.encode(env));

        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding sparse #{name}", field)))),
            }
        }

        Term::map_from_term_arrays(env, &keys, &values)
    }
    """
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
    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        decoder.read_var_uint()?;
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    body = Enum.map_join(fields, "\n", &skip_field(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
    #{indent(body, 4)}
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    arms = Enum.map_join(fields, "\n", &skip_message_arm(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while skipping #{name}", field)))),
            }
        }
        Ok(())
    }
    """
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
