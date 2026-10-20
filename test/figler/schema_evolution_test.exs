defmodule Figler.SchemaEvolutionTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Input
  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  setup_all do
    {:ok, binary: File.read!(@fixture)}
  end

  test "extracts the schema a file was written with", %{binary: binary} do
    {payload, schema} = Input.source!(binary)

    assert byte_size(payload) > 0

    assert %KiwiCodec.Schema{} = embedded = SchemaBinary.decode(schema)
    assert Enum.any?(embedded.definitions, &(&1.name == "NodeChange"))
  end

  test "decodes fields newer Figma versions add through the embedded schema", %{binary: binary} do
    assert %Figler.Scene.Summary{node_count: node_count} = Figler.Scene.summary(binary)
    assert node_count > 0

    assert [_ | _] = Figler.Scene.query(binary, "//instance")
    assert %Figler.Scene.Graph{} = Figler.Scene.graph(binary)
    assert %Figler.Document{pages: [_ | _]} = Figler.Document.open!(binary)
    assert %{node_changes: [_ | _]} = Figler.decode_sparse_message(binary)
    assert %Figler.Schema.Message{node_changes: [_ | _]} = Figler.decode_message(binary)
  end

  test "rejects the same payload without its schema", %{binary: binary} do
    {payload, _schema} = Input.source!(binary)

    assert_raise Figler.Error, fn -> Figler.Scene.summary(payload) end
  end
end
