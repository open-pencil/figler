defmodule Figler.NativeSceneGenerator.Sparse do
  @moduledoc """
  Generates sparse Rust decoders for Figma schema definitions.

  Sparse decoders return maps with only present fields, which keeps tooling and
  focused scene extraction from allocating complete generated struct trees.
  """

  alias Figler.NativeSceneGenerator.Rusty
  alias KiwiCodec.Schema.Enum, as: SchemaEnum
  alias KiwiCodec.Schema.{Message, Struct}
  alias RustQ.Rust

  def render(definitions, definition_map) do
    Enum.map(definitions, &definition(&1, definition_map))
  end

  defp definition(%Struct{name: name, fields: fields}, definition_map) do
    render_template("sparse_struct_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_fields: Enum.map(fields, &struct_field(&1, definition_map))]
    )
  end

  defp definition(%SchemaEnum{name: name, variants: variants}, _definition_map) do
    render_template("sparse_enum_decoder.rs",
      name: name,
      splice: [sparse_enum_arms: Enum.map(variants, &enum_arm/1)]
    )
  end

  defp definition(%Message{name: name, fields: fields}, definition_map) do
    render_template("sparse_message_decoder.rs",
      name: name,
      capacity: length(fields) + 1,
      splice: [sparse_field_arms: Enum.map(fields, &message_arm(&1, definition_map))]
    )
  end

  defp enum_arm(field) do
    Rust.arm(
      Integer.to_string(field.value),
      Rusty.enum_atom_result(field.value, Macro.underscore(field.name))
    )
  end

  defp render_template(template, opts) do
    name = Keyword.fetch!(opts, :name)
    path = Path.join(["native", "src", "templates", template])

    RustQ.render!(File.read!(path), path,
      bind: [
        decoder_name: "decode_sparse_#{rust_ident(name)}_from_decoder",
        module_name: {:literal, "Elixir.Figler.Schema.#{name}"},
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
      Integer.to_string(field.id),
      field |> field_block(definition_map) |> Rust.to_fragment()
    )
  end

  defp field_block(field, definition_map) do
    Rust.block([
      Rusty.cached_atom_static("FIELD_ATOM_#{field.id}"),
      Rusty.cached_atom("field_atom", "FIELD_ATOM_#{field.id}", Macro.underscore(field.name)),
      decode_field(field, definition_map),
      Rust.call_stmt("keys", :push, ["field_atom.encode(env)"]),
      Rust.call_stmt("values", :push, ["value"])
    ])
  end

  defp decode_field(%{array?: true, type: "byte"}, _definition_map) do
    Rusty.value("decoder.read_byte_array(env)?")
  end

  defp decode_field(%{array?: true} = field, definition_map) do
    inner = decode_scalar(%{field | array?: false}, definition_map)

    Rusty.array_value(inner)
  end

  defp decode_field(field, definition_map) do
    field |> decode_scalar(definition_map) |> Rusty.value()
  end

  defp decode_scalar(%{type: type}, definition_map) do
    cond do
      primitive = primitive_decode(type) ->
        primitive

      sparse_definition?(Map.get(definition_map, type)) ->
        "decode_sparse_#{rust_ident(type)}_from_decoder(env, decoder)?"

      Map.has_key?(definition_map, type) ->
        "decode_#{rust_ident(type)}_from_decoder(env, decoder)?"
    end
  end

  defp sparse_definition?(%SchemaEnum{}), do: true
  defp sparse_definition?(%Struct{}), do: true
  defp sparse_definition?(%Message{}), do: true
  defp sparse_definition?(_definition), do: false

  defp primitive_decode("bool"), do: "decoder.read_bool()?.encode(env)"
  defp primitive_decode("byte"), do: "decoder.read_byte()?.encode(env)"
  defp primitive_decode("float"), do: "decoder.read_var_float(env)?"
  defp primitive_decode("int"), do: "decoder.read_var_int()?.encode(env)"
  defp primitive_decode("int64"), do: "decoder.read_var_int64()?.encode(env)"
  defp primitive_decode("string"), do: "decoder.read_string(env)?"
  defp primitive_decode("uint"), do: "decoder.read_var_uint()?.encode(env)"
  defp primitive_decode("uint64"), do: "decoder.read_var_uint64()?.encode(env)"
  defp primitive_decode(_type), do: nil

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end
end
