defmodule FigKiwi.NativeSceneGenerator.Sparse do
  @moduledoc false

  alias KiwiCodec.Schema.Definition
  alias RustQ.Rust

  def render(definitions, definition_map) do
    Enum.map(definitions, &definition(&1, definition_map))
  end

  defp definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    render_template("sparse_struct_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_fields: Enum.map(fields, &struct_field(&1, definition_map))]
    )
  end

  defp definition(%Definition{kind: :enum, name: name, fields: fields}, _definition_map) do
    render_template("sparse_enum_decoder.rs",
      name: name,
      splice: [sparse_enum_arms: Enum.map(fields, &enum_arm/1)]
    )
  end

  defp definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    render_template("sparse_message_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_field_arms: Enum.map(fields, &message_arm(&1, definition_map))]
    )
  end

  defp enum_arm(field) do
    Rust.arm(
      Integer.to_string(field.value),
      "{ static ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new(); Ok(cached_atom(env, &ATOM_#{field.value}, \"#{Macro.underscore(field.name)}\").encode(env)) }"
    )
  end

  defp render_template(template, opts) do
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

  defp struct_field(field, definition_map) do
    field
    |> field_block(definition_map)
    |> Rust.to_fragment()
  end

  defp message_arm(field, definition_map) do
    Rust.arm(
      Integer.to_string(field.value),
      field |> field_block(definition_map) |> Rust.to_fragment()
    )
  end

  defp field_block(field, definition_map) do
    Rust.block([
      "static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();",
      ~s|let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");|,
      decode_field(field, definition_map),
      "keys.push(field_atom.encode(env));",
      "values.push(value);"
    ])
  end

  defp decode_field(%{array?: true, type: "byte"}, _definition_map) do
    "let value = decoder.read_byte_array(env)?;"
  end

  defp decode_field(%{array?: true} = field, definition_map) do
    inner = decode_scalar(%{field | array?: false}, definition_map)

    rust_statements([
      Rust.let_("len", "decoder.read_var_uint()? as usize"),
      Rust.let_mut("items", "Vec::with_capacity(len)"),
      Rust.stmt("for _ in 0..len { let item = #{inner}; items.push(item); }"),
      Rust.let_("value", "items.encode(env)")
    ])
  end

  defp decode_field(field, definition_map) do
    "let value = #{decode_scalar(field, definition_map)};"
  end

  defp decode_scalar(%{type: type}, definition_map) do
    cond do
      primitive = primitive_decode(type) ->
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

  defp primitive_decode("bool"), do: "decoder.read_bool()?.encode(env)"
  defp primitive_decode("byte"), do: "decoder.read_byte()?.encode(env)"
  defp primitive_decode("float"), do: "decoder.read_var_float(env)?"
  defp primitive_decode("int"), do: "decoder.read_var_int()?.encode(env)"
  defp primitive_decode("int64"), do: "decoder.read_var_int64()?.encode(env)"
  defp primitive_decode("string"), do: "decoder.read_string(env)?"
  defp primitive_decode("uint"), do: "decoder.read_var_uint()?.encode(env)"
  defp primitive_decode("uint64"), do: "decoder.read_var_uint64()?.encode(env)"
  defp primitive_decode(_type), do: nil

  defp rust_statements(statements), do: Enum.map_join(statements, "\n", &Rust.to_fragment/1)

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end
end
