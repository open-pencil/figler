defmodule Figler.RenderTest do
  use ExUnit.Case, async: true

  alias Figler.Render
  alias Figler.Render.Bounds
  alias Figler.Render.PixelDiff
  alias Figler.Render.Skia, as: SkiaBackend
  alias Figler.Render.SourceNode
  alias Figler.Scene.Graph.GUID
  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  import Figler.Test.SceneFixture, only: [fig_zip: 1]

  test "retains archive assets while preparing the effective scene" do
    archive = fig_zip([{~c"images/cafebabe", <<4, 5, 6>>}])

    assert {:ok, scene} = Render.prepare(archive)
    assert scene.document.source == :archive
    assert scene.document.images == %{"cafebabe" => <<4, 5, 6>>}
    assert scene.document.pages == [%Figler.Document.Page{guid: "0:1", name: "Page 1"}]
    assert scene.root == {0, 1}
    assert {:ok, %{root: {0, 1}}} = Render.prepare(scene.document, page: "Page 1")
    assert {:error, :render_root_not_found} = Render.prepare(scene.document, page: 1)
    assert {:error, :render_root_not_found} = Render.render(scene, page: 1)
  end

  test "compiles and renders a solid rectangle through one Skia document" do
    payload = render_payload(:solid)

    assert {:ok, scene} = Render.prepare(payload)
    assert {:ok, result} = SkiaBackend.compile(scene)
    assert result.root == "0:1"
    assert result.bounds == %Bounds{min_x: 10.0, min_y: 20.0, max_x: 110.0, max_y: 70.0}
    assert result.warnings == []
    assert map_size(scene.source_nodes) == 3

    assert %SourceNode{node_type: "rectangle", fill_paints: [%{type: :solid}]} =
             scene.source_nodes[{1, 1}]

    bounds = result.bounds
    assert {:ok, root_scene} = Render.prepare(payload, root: "1:1")
    assert {:ok, %{root: "1:1", bounds: ^bounds}} = SkiaBackend.compile(root_scene)

    assert Enum.any?(Skia.commands(result.document), &(&1.op == :rect))
    assert {:ok, raw} = Skia.to_raw(result.document)

    expected = %{width: 100, height: 50, data: :binary.copy(<<255, 0, 0, 255>>, 5_000)}
    assert {:ok, %{passed?: true, changed_pixels: 0}} = PixelDiff.compare(expected, raw)

    assert {:ok, <<137, 80, 78, 71, _rest::binary>>, metadata} = Render.render(scene)
    assert metadata.root == "0:1"
    assert metadata.warnings == []
  end

  test "batches opacity, clipping, basic shapes, strokes, and text" do
    assert {:ok, scene} = phase_one_payload() |> Render.prepare()
    assert {:ok, result} = SkiaBackend.compile(scene)

    operations = result.document |> Skia.commands() |> Enum.map(& &1.op)

    assert :save_layer in operations
    assert :clip_rect in operations
    assert :rect in operations
    assert :oval in operations
    assert :line in operations
    assert :text in operations
    assert {:ok, %{width: 120, height: 80}} = Skia.to_raw(result.document)
  end

  test "renders populated instance clones from projected source metadata" do
    assert {:ok, scene} = instance_payload() |> Render.prepare()

    assert {clone_guid, %{source: :instance_clone, source_guid: {1, 2}}} =
             Enum.find(scene.graph.provenance, fn {_guid, provenance} ->
               provenance[:source] == :instance_clone and provenance[:source_guid] == {1, 2}
             end)

    assert Map.has_key?(scene.graph.nodes, clone_guid)
    assert %SourceNode{fill_paints: [%{type: :solid}]} = scene.source_nodes[{1, 2}]
    assert {:ok, result} = SkiaBackend.compile(scene)
    assert Enum.count(Skia.commands(result.document), &(&1.op == :rect)) >= 2

    assert {:ok, clone_scene} = Render.prepare(instance_payload(), root: GUID.format(clone_guid))
    assert %SourceNode{fill_paints: [%{type: :solid}]} = clone_scene.source_nodes[{1, 2}]
    assert {:ok, %{root: clone_root}} = SkiaBackend.compile(clone_scene)
    assert clone_root == GUID.format(clone_guid)
  end

  test "renders positioned linear gradients" do
    gradient =
      struct(Figler.Schema.Paint,
        type: :gradient_linear,
        visible: true,
        opacity: 1.0,
        transform: matrix(0, 0),
        stops: [gradient_stop(1.0, 0.0, 0.0, 0.0), gradient_stop(0.0, 0.0, 1.0, 1.0)]
      )

    assert {:ok, scene} = paint_payload(gradient) |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)
    assert {:ok, %{data: data, width: 100}} = Skia.to_raw(document)

    <<left_r, _left_g, left_b, 255, _rest::binary>> = data
    <<right_r, _right_g, right_b, 255>> = binary_part(data, 99 * 4, 4)
    assert left_b > left_r
    assert right_r > right_b
  end

  test "loads archive images into reusable image shaders" do
    hash = <<0xCA, 0xFE>>

    image_paint =
      struct(Figler.Schema.Paint,
        type: :image,
        visible: true,
        opacity: 1.0,
        image: struct(Figler.Schema.Image, hash: hash),
        image_scale_mode: :fill
      )

    {:ok, image_png} = Skia.canvas(1, 1) |> Skia.clear({:rgba, 0, 255, 0, 255}) |> Skia.to_png()
    archive = fig_archive(paint_payload(image_paint), [{~c"images/cafe", image_png}])

    assert {:ok, scene} = Render.prepare(archive)
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)
    assert {:ok, raw} = Skia.to_raw(document)

    expected = %{width: 100, height: 50, data: :binary.copy(<<0, 255, 0, 255>>, 5_000)}
    assert {:ok, %{passed?: true}} = PixelDiff.compare(expected, raw)
  end

  test "resolves image fills from message blobs" do
    {:ok, image_png} = Skia.canvas(1, 1) |> Skia.clear({:rgba, 255, 255, 0, 255}) |> Skia.to_png()

    image_paint =
      struct(Figler.Schema.Paint,
        type: :image,
        visible: true,
        image: struct(Figler.Schema.Image, data_blob: 0),
        image_scale_mode: :fill
      )

    blob = struct(Figler.Schema.Blob, bytes: image_png)
    assert {:ok, scene} = paint_payload(image_paint, [blob]) |> Render.prepare()
    assert scene.document.blobs == [image_png]
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)
    assert {:ok, %{data: <<255, 255, 0, 255, _rest::binary>>}} = Skia.to_raw(document)
  end

  test "reports missing image assets and supports strict mode" do
    image_paint =
      struct(Figler.Schema.Paint,
        type: :image,
        visible: true,
        image: struct(Figler.Schema.Image, hash: <<0xDE, 0xAD>>),
        image_scale_mode: :fill
      )

    assert {:ok, scene} = paint_payload(image_paint) |> Render.prepare()

    assert {:ok, %{warnings: [%{feature: :fill, value: :missing_image_asset}]}} =
             SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "reports unsupported visible paints and supports strict mode" do
    assert {:ok, scene} = render_payload(:gradient_linear) |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %{feature: :fill, value: {:gradient_linear, :missing_gradient_transform}}
              ]
            }} = SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  defp instance_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    component_guid = guid(1, 1)
    fill = solid_paint(0.8, 0.2, 0.1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(component_guid, :symbol, "Button", canvas_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true
      ),
      node(guid(1, 2), :rectangle, "Background", component_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [fill]
      ),
      node(guid(2, 1), :instance, "Button instance", canvas_guid,
        size: vector(40, 20),
        transform: matrix(60, 0),
        visible: true,
        symbol_data: struct(Figler.Schema.SymbolData, symbol_id: component_guid)
      )
    ]
    |> encode_nodes()
  end

  defp phase_one_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    frame_guid = guid(1, 1)
    fill = solid_paint(0.1, 0.2, 0.8)

    nodes = [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(frame_guid, :frame, "Frame", canvas_guid,
        size: vector(120, 80),
        transform: matrix(0, 0),
        visible: true,
        opacity: 0.5,
        frame_mask_disabled: false,
        corner_radius: 5.0,
        fill_paints: [fill]
      ),
      node(guid(1, 2), :ellipse, "Dot", frame_guid,
        size: vector(20, 20),
        transform: matrix(10, 10),
        visible: true,
        fill_paints: [fill]
      ),
      node(guid(1, 3), :line, "Rule", frame_guid,
        size: vector(20, 0),
        transform: matrix(40, 10),
        visible: true,
        stroke_weight: 2.0,
        stroke_paints: [fill]
      ),
      node(guid(1, 4), :text, "Label", frame_guid,
        size: vector(50, 20),
        transform: matrix(10, 40),
        visible: true,
        text_data: struct(Figler.Schema.TextData, characters: "Hello"),
        font_name:
          struct(Figler.Schema.FontName,
            family: "Arial",
            style: "Regular",
            postscript: "Arial-Regular"
          ),
        font_size: 14.0,
        fill_paints: [fill]
      )
    ]

    encode_nodes(nodes)
  end

  defp render_payload(paint_type) do
    paint =
      struct(Figler.Schema.Paint,
        type: paint_type,
        visible: true,
        opacity: 1.0,
        color: struct(Figler.Schema.Color, r: 1.0, g: 0.0, b: 0.0, a: 1.0)
      )

    paint_payload(paint)
  end

  defp paint_payload(paint, blobs \\ []) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

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

    encode_nodes(nodes, blobs)
  end

  defp gradient_stop(r, g, b, position) do
    struct(Figler.Schema.ColorStop,
      color: struct(Figler.Schema.Color, r: r, g: g, b: b, a: 1.0),
      position: position
    )
  end

  defp fig_archive(payload, entries) do
    schema = Figler.schema() |> SchemaBinary.encode() |> Figler.Container.deflate()
    canvas = Figler.Container.build([schema, Figler.Container.deflate(payload)])

    {:ok, {_name, archive}} =
      :zip.create(~c"render.fig", [{~c"canvas.fig", canvas} | entries], [:memory])

    archive
  end

  defp node(guid, type, name, parent_guid \\ nil, attrs \\ []) do
    parent_index =
      if parent_guid,
        do: struct(Figler.Schema.ParentIndex, guid: parent_guid, position: "!"),
        else: nil

    Figler.Schema.NodeChange
    |> struct([guid: guid, type: type, name: name, parent_index: parent_index] ++ attrs)
  end

  defp solid_paint(r, g, b) do
    struct(Figler.Schema.Paint,
      type: :solid,
      visible: true,
      opacity: 1.0,
      color: struct(Figler.Schema.Color, r: r, g: g, b: b, a: 1.0)
    )
  end

  defp vector(x, y), do: struct(Figler.Schema.Vector, x: x / 1, y: y / 1)

  defp matrix(x, y) do
    struct(Figler.Schema.Matrix,
      m00: 1.0,
      m01: 0.0,
      m02: x / 1,
      m10: 0.0,
      m11: 1.0,
      m12: y / 1
    )
  end

  defp encode_nodes(nodes, blobs \\ []) do
    Figler.Schema.Message
    |> struct(type: :node_changes, session_id: 0, node_changes: nodes, blobs: blobs)
    |> KiwiCodec.encode()
  end

  defp guid(session_id, local_id),
    do: struct(Figler.Schema.GUID, session_id: session_id, local_id: local_id)
end
