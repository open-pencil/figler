defmodule Figler.NativeSceneGenerator.Skip do
  @moduledoc """
  Generates Rust decoder helpers that skip schema values.

  Scene and focused graph decoders use these helpers when a field must be
  consumed from the binary stream but is not needed in the projected result.
  """

  alias KiwiCodec.Schema.Enum, as: SchemaEnum
  alias Figler.NativeSceneGenerator.Rusty
  alias KiwiCodec.Schema.{Message, Struct}

  @primitive %{
    "bool" => "decoder.read_bool()?;",
    "byte" => "decoder.read_byte()?;",
    "float" => "decoder.read_var_float_value()?;",
    "int" => "decoder.read_var_int()?;",
    "int64" => "decoder.read_var_int64()?;",
    "string" => "decoder.skip_string()?;",
    "uint" => "decoder.read_var_uint()?;",
    "uint64" => "decoder.read_var_uint64()?;"
  }

  def render(definitions, definition_map) do
    Enum.map(definitions, &definition(&1, definition_map))
  end

  def message_arm(field, definition_map) do
    Rusty.arm(field.id, field(field, definition_map))
  end

  def field(%{array?: true, type: "byte"}, _definition_map) do
    "decoder.skip_byte_array()?;"
  end

  def field(%{array?: true} = schema_field, definition_map) do
    inner = field(%{schema_field | array?: false}, definition_map)

    Rusty.skip_array(inner)
  end

  def field(%{type: type}, definition_map) do
    cond do
      primitive = @primitive[type] ->
        primitive

      Map.has_key?(definition_map, type) ->
        "skip_#{rust_ident(type)}_from_decoder(decoder)?;"
    end
  end

  defp definition(%SchemaEnum{name: name}, _definition_map) do
    render_template("skip_enum_decoder.rs", name: name)
  end

  defp definition(%Struct{name: name, fields: fields}, definition_map) do
    render_template("skip_struct_decoder.rs",
      name: name,
      splice: [skip_fields: Enum.map(fields, &field(&1, definition_map))]
    )
  end

  defp definition(%Message{name: name, fields: fields}, definition_map) do
    render_template("skip_message_decoder.rs",
      name: name,
      splice: [skip_field_arms: Enum.map(fields, &message_arm(&1, definition_map))]
    )
  end

  defp render_template(template, opts) do
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

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end
end
