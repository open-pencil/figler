defmodule Figler.ContainerTest do
  use ExUnit.Case, async: true

  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  test "decodes inflated schema and data chunks" do
    schema_binary = Figler.schema() |> SchemaBinary.encode() |> Figler.Container.deflate()

    data_binary = Figler.Container.deflate(<<1, 1, 0>>)

    decoded = Figler.Container.decode(Figler.Container.build([schema_binary, data_binary]))

    assert decoded.version == 101
    assert KiwiCodec.Schema.definition(decoded.schema, "Message")
    assert decoded.data == <<1, 1, 0>>
  end

  test "decodes zstd-compressed data chunks" do
    schema_binary = Figler.schema() |> SchemaBinary.encode() |> Figler.Container.deflate()
    data_binary = :ezstd.compress(<<1, 1, 0>>)

    decoded = Figler.Container.decode(Figler.Container.build([schema_binary, data_binary]))

    assert decoded.data == <<1, 1, 0>>
  end

  test "replaces data while preserving container metadata and trailing chunks" do
    schema = Figler.Container.deflate("schema")
    data = :ezstd.compress("old")
    container = Figler.Container.build([schema, data, "trailing"], version: 42)

    replaced = Figler.Container.replace_data(container, "new")
    parsed = Figler.Container.parse(replaced)

    assert parsed.version == 42
    assert parsed.chunks |> Enum.at(0) == schema
    assert parsed.chunks |> Enum.at(1) |> Figler.Container.inflate() == "new"
    assert parsed.chunks |> Enum.at(2) == "trailing"
    assert match?(<<0x28, 0xB5, 0x2F, 0xFD, _rest::binary>>, Enum.at(parsed.chunks, 1))
  end
end
