defmodule Figler.Native.CodecNifsTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Scene.Input

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  test "native records encode to the maps the sparse decoder returns" do
    source = @fixture |> File.read!() |> Input.source!()

    assert CodecNifs.decode_record_message(source) == CodecNifs.decode_sparse_message(source)
  end

  test "decodes sparse messages without absent fields" do
    guid = struct(Figler.Schema.GUID, session_id: 12, local_id: 34)
    parent_index = struct(Figler.Schema.ParentIndex, guid: guid, position: "!")
    size = struct(Figler.Schema.Vector, x: 100.0, y: 50.0)

    message =
      struct(Figler.Schema.Message,
        type: :node_changes,
        session_id: 12,
        node_changes: [
          struct(Figler.Schema.NodeChange,
            guid: guid,
            phase: :created,
            parent_index: parent_index,
            type: :rectangle,
            name: "Rect 1",
            size: size
          )
        ]
      )

    sparse = Figler.decode_sparse_message(KiwiCodec.encode(message))

    assert sparse == sparse_equivalent(message)
    refute Map.has_key?(hd(sparse.node_changes), :description)
  end

  defp sparse_equivalent(%module{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {key, value} -> {key, sparse_equivalent(value)} end)
    |> Map.put(:__kiwi_module__, module)
  end

  defp sparse_equivalent(values) when is_list(values), do: Enum.map(values, &sparse_equivalent/1)
  defp sparse_equivalent(value), do: value
end
