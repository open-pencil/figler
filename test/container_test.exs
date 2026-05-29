defmodule FigKiwi.ContainerTest do
  use ExUnit.Case, async: true

  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  test "decodes inflated schema and data chunks" do
    schema_binary = FigKiwi.schema() |> SchemaBinary.encode() |> FigKiwi.Container.deflate()

    data_binary = FigKiwi.Container.deflate(<<1, 1, 0>>)

    decoded = FigKiwi.Container.decode(FigKiwi.Container.build([schema_binary, data_binary]))

    assert decoded.version == 101
    assert KiwiCodec.Schema.definition(decoded.schema, "Message")
    assert decoded.data == <<1, 1, 0>>
  end
end
