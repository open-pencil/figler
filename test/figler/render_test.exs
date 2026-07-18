defmodule Figler.RenderTest do
  use ExUnit.Case, async: true

  alias Figler.Render
  alias Figler.Render.Bounds
  alias Figler.Render.Skia, as: SkiaBackend

  test "compiles and renders a solid rectangle through one Skia document" do
    payload = render_payload(:solid)

    assert {:ok, scene} = Render.prepare(payload)
    assert {:ok, result} = SkiaBackend.compile(scene)
    assert result.root == "0:1"
    assert result.bounds == %Bounds{min_x: 10.0, min_y: 20.0, max_x: 110.0, max_y: 70.0}
    assert result.warnings == []

    bounds = result.bounds
    assert {:ok, %{root: "1:1", bounds: ^bounds}} = SkiaBackend.compile(scene, root: "1:1")

    assert Enum.any?(Skia.commands(result.document), &(&1.op == :rect))
    assert {:ok, %{data: <<255, 0, 0, 255, _rest::binary>>}} = Skia.to_raw(result.document)

    assert {:ok, <<137, 80, 78, 71, _rest::binary>>, metadata} = Render.render(scene)
    assert metadata.root == "0:1"
    assert metadata.warnings == []
  end

  test "reports unsupported visible paints and supports strict mode" do
    assert {:ok, scene} = render_payload(:gradient_linear) |> Render.prepare()

    assert {:ok, %{warnings: [%{feature: :fill, value: :gradient_linear}]}} =
             SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  defp render_payload(paint_type) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    paint =
      struct(Figler.Schema.Paint,
        type: paint_type,
        visible: true,
        opacity: 1.0,
        color: struct(Figler.Schema.Color, r: 1.0, g: 0.0, b: 0.0, a: 1.0)
      )

    nodes = [
      struct(Figler.Schema.NodeChange,
        guid: document_guid,
        type: :document,
        name: "Document"
      ),
      struct(Figler.Schema.NodeChange,
        guid: canvas_guid,
        parent_index: struct(Figler.Schema.ParentIndex, guid: document_guid, position: "!"),
        type: :canvas,
        name: "Page 1"
      ),
      struct(Figler.Schema.NodeChange,
        guid: guid(1, 1),
        parent_index: struct(Figler.Schema.ParentIndex, guid: canvas_guid, position: "!"),
        type: :rectangle,
        name: "Card",
        size: struct(Figler.Schema.Vector, x: 100.0, y: 50.0),
        transform:
          struct(Figler.Schema.Matrix,
            m00: 1.0,
            m01: 0.0,
            m02: 10.0,
            m10: 0.0,
            m11: 1.0,
            m12: 20.0
          ),
        visible: true,
        fill_paints: [paint]
      )
    ]

    Figler.Schema.Message
    |> struct(type: :node_changes, session_id: 0, node_changes: nodes)
    |> KiwiCodec.encode()
  end

  defp guid(session_id, local_id),
    do: struct(Figler.Schema.GUID, session_id: session_id, local_id: local_id)
end
