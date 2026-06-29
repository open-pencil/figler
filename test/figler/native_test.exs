defmodule Figler.NativeTest do
  use ExUnit.Case, async: true

  alias Figler.Native.SceneNifs, as: Scene

  test "decodes generated primitive structs through Elixir codec" do
    guid = struct(Figler.Schema.GUID, session_id: 12, local_id: 34)
    vector = struct(Figler.Schema.Vector, x: 100.0, y: 50.0)

    parent_index = struct(Figler.Schema.ParentIndex, guid: guid, position: "!")
    image = struct(Figler.Schema.Image, hash: <<1, 2, 3>>, name: "Preview", data_blob: 7)
    partial_image = struct(Figler.Schema.Image, name: "Preview")

    assert KiwiCodec.decode(KiwiCodec.encode(guid), Figler.Schema.GUID) == guid
    assert KiwiCodec.decode(KiwiCodec.encode(vector), Figler.Schema.Vector) == vector

    assert KiwiCodec.decode(KiwiCodec.encode(parent_index), Figler.Schema.ParentIndex) ==
             parent_index

    node_change =
      struct(Figler.Schema.NodeChange,
        guid: guid,
        phase: :created,
        parent_index: parent_index,
        type: :rectangle,
        name: "Rect 1",
        size: vector
      )

    message =
      struct(Figler.Schema.Message,
        type: :node_changes,
        session_id: 12,
        node_changes: [node_change]
      )

    partial_message = struct(Figler.Schema.Message, session_id: 12)
    unknown_enum_message = struct(Figler.Schema.Message, type: 999)

    assert KiwiCodec.decode(KiwiCodec.encode(image), Figler.Schema.Image) == image
    assert KiwiCodec.decode(KiwiCodec.encode(partial_image), Figler.Schema.Image) == partial_image

    assert KiwiCodec.decode(KiwiCodec.encode(node_change), Figler.Schema.NodeChange) ==
             node_change

    assert Figler.decode_message(KiwiCodec.encode(message)) == message
    assert Figler.decode_message(KiwiCodec.encode(partial_message)) == partial_message

    assert Figler.decode_message(KiwiCodec.encode(unknown_enum_message)) == unknown_enum_message
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

  test "decodes scene summary without materializing schema structs" do
    message = scene_message()

    assert Scene.decode_summary(KiwiCodec.encode(message)) == %{
             node_count: 2,
             parented_count: 1,
             root_count: 1,
             type_counts: [{"canvas", 1}, {"document", 1}]
           }
  end

  test "queries projected scene index with XPath" do
    assert Scene.query_xpath(
             KiwiCodec.encode(scene_message()),
             "//canvas[@name='Page 1']"
           ) == [
             %{
               guid: "0:1",
               node_type: "canvas",
               name: "Page 1",
               parent_guid: "0:0",
               position: "!",
               size: nil,
               transform: nil,
               visible: nil,
               locked: nil,
               opacity: nil,
               text: nil,
               font_family: nil,
               font_style: nil,
               font_postscript: nil,
               font_size: nil,
               text_style_guid: nil,
               component_key: nil,
               origin_component_key: nil,
               fill_style_guid: nil,
               stroke_style_guid: nil,
               effect_style_guid: nil,
               grid_style_guid: nil,
               fill_count: nil,
               stroke_count: nil
             }
           ]
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

  defp scene_message do
    guid = struct(Figler.Schema.GUID, session_id: 0, local_id: 0)

    struct(Figler.Schema.Message,
      type: :node_changes,
      session_id: 0,
      node_changes: [
        struct(Figler.Schema.NodeChange,
          guid: guid,
          type: :document,
          name: "Document"
        ),
        struct(Figler.Schema.NodeChange,
          guid: struct(Figler.Schema.GUID, session_id: 0, local_id: 1),
          parent_index: struct(Figler.Schema.ParentIndex, guid: guid, position: "!"),
          type: :canvas,
          name: "Page 1"
        )
      ]
    )
  end
end
