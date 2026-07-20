defmodule Figler.DocumentTest do
  use ExUnit.Case, async: true

  alias Figler.Document
  alias Figler.Document.Page
  alias Figler.Error

  import Figler.Test.SceneFixture

  test "preserves canvas, archive entries, images, payload, and page metadata" do
    archive =
      fig_zip([
        {~c"images/deadbeef", <<1, 2, 3>>},
        {~c"metadata.json", ~s({"name":"Fixture"})}
      ])

    assert %Document{} = document = Document.open!(archive)
    assert document.source == :archive
    assert document.canvas == canvas_container()
    assert document.payload == message_payload()
    assert document.entries["metadata.json"] == ~s({"name":"Fixture"})
    assert document.entries["images/deadbeef"] == <<1, 2, 3>>
    assert document.images == %{"deadbeef" => <<1, 2, 3>>}
    assert document.pages == [%Page{guid: "0:1", name: "Page 1"}]
  end

  test "retains message blobs from raw payloads" do
    message = Figler.decode_message(message_payload())
    blob = struct(Figler.Schema.Blob, bytes: [0, 127, 255])
    payload = message |> Map.put(:blobs, [blob]) |> KiwiCodec.encode()

    assert {:ok, %Document{source: :payload, canvas: nil, entries: %{}} = document} =
             Document.open(payload)

    assert document.blobs == [<<0, 127, 255>>]
  end

  test "returns structured errors for invalid archives" do
    {:ok, {_name, archive}} =
      :zip.create(~c"invalid.fig", [{~c"metadata.json", "{}"}], [:memory])

    assert {:error,
            %Error{code: :missing_canvas, operation: :open_document, context: %{}} = error} =
             Document.open(archive)

    assert Exception.message(error) == "FIG archive is missing canvas.fig during open_document"

    assert_raise Error, "FIG archive is missing canvas.fig during open_document", fn ->
      Document.open!(archive)
    end
  end

  test "normalizes malformed archive, container, and Kiwi payload failures" do
    assert {:error, %Error{code: :invalid_archive, operation: :open_document}} =
             Document.open(<<"PK", 0, 1, 2>>)

    for input <- [<<"fig-kiwi", 0, 1, 2>>, <<1, 2, 3>>] do
      assert {:error,
              %Error{
                code: :invalid_document,
                operation: :open_document,
                context: %{reason: reason}
              }} = Document.open(input)

      assert is_binary(reason)
    end
  end
end
