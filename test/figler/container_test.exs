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
end
