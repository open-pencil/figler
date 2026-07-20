defmodule Figler.RenderTest do
  use ExUnit.Case, async: true

  alias Figler.Render
  alias Figler.Render.Bounds
  alias Figler.Render.Node, as: RenderNode
  alias Figler.Render.Oracle.Runner
  alias Figler.Render.PixelDiff
  alias Figler.Render.Skia, as: SkiaBackend
  alias Figler.Render.SourceNode
  alias Figler.Render.Warning
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

    assert {:error,
            {:invalid_render_options, [%{option: :unknown, code: :unknown_option, value: true}]}} =
             Render.prepare(scene.document, unknown: true)
  end

  test "compiles and renders a solid rectangle through one Skia document" do
    payload = render_payload(:solid)

    assert {:ok, scene} = Render.prepare(payload)
    assert {:ok, result} = SkiaBackend.compile(scene)

    assert {:ok, backend_only_result} =
             scene
             |> Map.merge(%{graph: nil, source_nodes: %{}})
             |> SkiaBackend.compile()

    assert Skia.commands(backend_only_result.document) == Skia.commands(result.document)
    assert result.root == "0:1"
    assert result.bounds == %Bounds{min_x: 10.0, min_y: 20.0, max_x: 110.0, max_y: 70.0}
    assert result.warnings == []
    assert map_size(scene.source_nodes) == 3
    assert %RenderNode{node_type: :rectangle} = scene.render_nodes[{1, 1}]

    assert %SourceNode{
             node_type: "rectangle",
             fill_paints: [%Figler.Render.Paint{type: :solid, color: %Figler.Render.Color{}}]
           } = scene.source_nodes[{1, 1}]

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

  @tag :tmp_dir
  test "runs same-scene visual oracle manifests", %{tmp_dir: tmp_dir} do
    payload = render_payload(:solid)
    fixture_path = Path.join(tmp_dir, "fixture.fig")
    reference_path = Path.join(tmp_dir, "rectangle.png")
    manifest_path = Path.join(tmp_dir, "render-manifest.json")

    File.write!(fixture_path, payload)
    assert {:ok, reference_png, _metadata} = Render.render(payload, root: "1:1", format: :png)
    File.write!(reference_path, reference_png)

    File.write!(
      manifest_path,
      Jason.encode!(%{
        "fig" => "fixture.fig",
        "oracle" => %{"renderer" => "test", "source_root" => "fixture-root"},
        "cases" => [
          %{
            "name" => "solid rectangle",
            "reference" => "rectangle.png",
            "oracle" => %{"source_root" => "source-rectangle"},
            "root" => "1:1",
            "scale" => 1.0,
            "background" => "transparent",
            "expected_warning_codes" => []
          }
        ]
      })
    )

    assert {:ok,
            %{
              passed?: true,
              failed_count: 0,
              oracle: %{"renderer" => "test", "source_root" => "fixture-root"},
              cases: [
                %{
                  passed?: true,
                  oracle: %{"source_root" => "source-rectangle"},
                  metrics: %{changed_pixels: 0},
                  warning_check: %{checked?: true, passed?: true, expected: [], actual: []}
                }
              ]
            } = result} = Runner.run(manifest_path)

    assert is_binary(Jason.encode!(result))
  end

  test "batches opacity, clipping, basic shapes, strokes, and text" do
    assert {:ok, scene} = phase_one_payload() |> Render.prepare()
    assert %Figler.Render.Text{content: "Hello", font: font} = scene.render_nodes[{1, 4}].text
    assert font.family == "Arial"
    assert font.style == "Regular"
    assert font.postscript == "Arial-Regular"
    assert font.weight == 400
    assert font.slant == :upright
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

  test "clips transformed path children to independent container corners and bounds" do
    assert {:ok, scene} = clipped_path_payload(:frame) |> Render.prepare()

    assert {:ok, %{warnings: [], bounds: bounds, document: document}} =
             SkiaBackend.compile(scene)

    assert bounds == %Bounds{min_x: 10.0, min_y: 10.0, max_x: 50.0, max_y: 50.0}
    assert {:ok, %{width: 40, height: 40}} = Skia.to_raw(document)

    commands = Skia.commands(document)
    assert Enum.any?(commands, &(&1.op == :clip_path))

    clip_index = Enum.find_index(commands, &(&1.op == :clip_path))

    child_transform_index =
      Enum.find_index(commands, fn
        %{op: :concat, opts: opts} -> elem(Keyword.fetch!(opts, :matrix), 0) < 0.8
        _command -> false
      end)

    assert clip_index < child_transform_index
  end

  test "rejects clipping flags on unsupported container types" do
    assert {:ok, scene} = clipped_path_payload(:section) |> Render.prepare()

    assert {:ok,
            %{warnings: [%Warning{code: :container_clip_unsupported, severity: :unsupported}]}} =
             SkiaBackend.compile(scene)

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :container_clip_unsupported, severity: :unsupported}]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "normalizes UTF-16-indexed rich text style runs" do
    assert {:ok, scene} = rich_text_payload() |> Render.prepare()
    text = scene.render_nodes[{1, 1}].text

    assert [%Figler.Render.Text.Run{} = first, emoji, last] = text.runs

    assert {first.index, first.start, first.length, first.content, first.font.family} ==
             {0, 0, 1, "A", "Inter"}

    assert {emoji.index, emoji.start, emoji.length, emoji.content, emoji.font.family} ==
             {1, 1, 2, "😀", "Noto Color Emoji"}

    assert emoji.font.size == 18.0

    assert {
             emoji.line_height,
             emoji.letter_spacing,
             emoji.text_decoration,
             emoji.text_decoration_style,
             emoji.text_decoration_skip_ink
           } == {27.0, 2.0, :underline, :dotted, true}

    assert [%Figler.Render.Paint{color: %{g: 1.0}}] = emoji.fill_paints

    assert {last.index, last.start, last.length, last.content, last.font.weight, last.text_case} ==
             {2, 3, 1, "B", 700, :lower}

    assert [%Figler.Render.Paint{color: %{b: 1.0}}] = last.fill_paints
    assert [%Figler.Render.Font{family: "Noto Color Emoji"}] = text.fallback_fonts

    assert {text.align_horizontal, text.align_vertical, text.auto_resize} ==
             {:center, :bottom, :height}

    assert {text.truncation, text.max_lines} == {:ending, 2}
    assert text.issues == []

    assert {:ok, %{document: document}} =
             SkiaBackend.compile(scene, system_font_fallback: false)

    text_command = Enum.find(Skia.commands(document), &(&1.op == :text))
    assert text_command.opts[:width] == 80.0
    assert text_command.opts[:height] == 24.0
    assert text_command.opts[:align] == :center
    assert text_command.opts[:vertical_align] == :bottom
    assert text_command.opts[:max_lines] == 2
    assert text_command.opts[:ellipsis] == "…"

    assert [{"A", first_opts}, {"😀", emoji_opts}, {"b", last_opts}] =
             text_command.opts[:spans]

    assert {first_opts[:line_height], first_opts[:letter_spacing], first_opts[:decoration]} ==
             {21.0, 0.25, :underline}

    assert {
             emoji_opts[:line_height],
             emoji_opts[:letter_spacing],
             emoji_opts[:decoration],
             emoji_opts[:decoration_style],
             emoji_opts[:decoration_mode],
             emoji_opts[:decoration_color]
           } == {27.0, 2.0, :underline, :dotted, :gaps, {:rgba, 255, 255, 0, 255}}

    assert {last_opts[:line_height], last_opts[:letter_spacing], last_opts[:decoration]} ==
             {21.0, 0.25, :underline}

    assert first_opts[:fill] == {:rgba, 255, 0, 0, 255}
    assert emoji_opts[:fill] == {:rgba, 0, 255, 0, 255}
    assert last_opts[:fill] == {:rgba, 0, 0, 255, 255}
  end

  test "reports malformed UTF-16 rich-text ranges and rejects them in strict mode" do
    assert {:ok, scene} = rich_text_payload([0, 1]) |> Render.prepare()
    text = scene.render_nodes[{1, 1}].text

    assert text.issues == [
             %{code: :text_style_length_mismatch, expected: 4, actual: 2}
           ]

    assert {:ok, %{warnings: warnings}} =
             SkiaBackend.compile(scene, system_font_fallback: false)

    warning = Enum.find(warnings, &(&1.feature == :text))
    assert warning.value.code == :text_style_length_mismatch

    assert {:error, {:unsupported_render_features, strict_warnings}} =
             SkiaBackend.compile(scene, strict: true, system_font_fallback: false)

    assert Enum.any?(strict_warnings, &(&1.value.code == :text_style_length_mismatch))
  end

  test "reports unsupported text case and decoration metrics in strict mode" do
    assert {:ok, scene} = rich_text_payload() |> Render.prepare()

    node = scene.render_nodes[{1, 1}]
    [first | rest] = node.text.runs

    first = %{
      first
      | text_case: :small_caps,
        text_decoration_thickness: %Figler.Render.Text.Measurement{
          value: 2.0,
          units: :pixels
        },
        text_underline_offset: %Figler.Render.Text.Measurement{value: 1.0, units: :pixels}
    }

    text = %{node.text | runs: [first | rest], max_lines: nil}
    scene = %{scene | render_nodes: Map.put(scene.render_nodes, node.guid, %{node | text: text})}

    assert {:ok, %{warnings: warnings, document: document}} =
             SkiaBackend.compile(scene, system_font_fallback: false)

    text_command = Enum.find(Skia.commands(document), &(&1.op == :text))
    assert text_command.opts[:max_lines] == 1
    assert text_command.opts[:ellipsis] == "…"
    assert Enum.any?(warnings, &(&1.value.code == :text_case_unsupported))
    assert Enum.any?(warnings, &(&1.value.code == :text_decoration_thickness_unsupported))
    assert Enum.any?(warnings, &(&1.value.code == :text_underline_offset_unsupported))

    assert {:error, {:unsupported_render_features, strict_warnings}} =
             SkiaBackend.compile(scene,
               strict: true,
               system_font_fallback: false
             )

    assert Enum.any?(strict_warnings, &(&1.value.code == :text_case_unsupported))

    assert Enum.any?(
             strict_warnings,
             &(&1.value.code == :text_decoration_thickness_unsupported)
           )

    assert Enum.any?(strict_warnings, &(&1.value.code == :text_underline_offset_unsupported))
  end

  test "reports font substitutions and rejects them in strict mode" do
    assert {:ok, scene} = phase_one_payload() |> Render.prepare()

    assert {:ok, fallback} = Skia.Typeface.match_character("T")
    node = scene.render_nodes[{1, 4}]
    missing_font = %{node.text.font | family: "__Figler Missing Font__"}
    runs = Enum.map(node.text.runs, &%{&1 | font: missing_font})
    text = %{node.text | font: missing_font, runs: runs}
    scene = %{scene | render_nodes: Map.put(scene.render_nodes, node.guid, %{node | text: text})}
    fallback_opts = [fallback_typefaces: [fallback], system_font_fallback: false]

    assert {:ok, %{warnings: warnings, document: document}} =
             SkiaBackend.compile(scene, fallback_opts)

    text_command = Enum.find(Skia.commands(document), &(&1.op == :text))
    assert %Skia.Font{} = text_command.opts[:font]
    refute Keyword.has_key?(text_command.opts, :font_family)

    assert [%{feature: :font, value: %{code: :font_substituted}}] =
             Enum.filter(warnings, &(&1.feature == :font))

    assert {:error, {:unsupported_render_features, strict_warnings}} =
             SkiaBackend.compile(scene, [strict: true] ++ fallback_opts)

    assert Enum.any?(strict_warnings, &match?(%{value: %{code: :font_substituted}}, &1))
  end

  test "applies rich paint overrides to effective instance render nodes" do
    payload = instance_paint_override_payload()
    assert {:ok, scene} = Render.prepare(payload)

    assert {clone_guid, %{source: :instance_clone, source_guid: {1, 2}}} =
             Enum.find(scene.graph.provenance, fn {_guid, provenance} ->
               provenance[:source] == :instance_clone and provenance[:source_guid] == {1, 2}
             end)

    assert %RenderNode{
             guid: ^clone_guid,
             source_guid: {1, 2},
             node_type: :rectangle,
             fill_paints: [%Figler.Render.Paint{color: color}]
           } = scene.render_nodes[clone_guid]

    assert color.b == 1.0
    assert color.r == 0.0

    assert {:ok, clone_scene} = Render.prepare(payload, root: GUID.format(clone_guid))
    assert {:ok, %{document: document, warnings: []}} = SkiaBackend.compile(clone_scene)
    assert {:ok, %{data: <<0, 0, 255, 255, _rest::binary>>}} = Skia.to_raw(document)
  end

  test "applies paragraph typography overrides to effective instance text" do
    payload = instance_typography_override_payload()
    assert {:ok, scene} = Render.prepare(payload)

    assert {clone_guid, %{source: :instance_clone, source_guid: {3, 2}}} =
             Enum.find(scene.graph.provenance, fn {_guid, provenance} ->
               provenance[:source] == :instance_clone and provenance[:source_guid] == {3, 2}
             end)

    text = scene.render_nodes[clone_guid].text

    assert {text.align_horizontal, text.align_vertical, text.truncation, text.max_lines} ==
             {:right, :bottom, :ending, 1}

    assert [run] = text.runs

    assert {
             run.line_height,
             run.letter_spacing,
             run.text_decoration,
             run.text_decoration_style,
             run.text_decoration_skip_ink
           } == {30.0, 2.0, :underline, :wavy, false}

    assert {:ok, clone_scene} = Render.prepare(payload, root: GUID.format(clone_guid))

    assert {:ok, %{document: document}} = SkiaBackend.compile(clone_scene)

    text_command = Enum.find(Skia.commands(document), &(&1.op == :text))
    assert text_command.opts[:align] == :right
    assert text_command.opts[:vertical_align] == :bottom
    assert text_command.opts[:max_lines] == 1
    assert text_command.opts[:ellipsis] == "…"
  end

  test "applies editable vector network overrides to instance clones" do
    payload = instance_vector_override_payload()
    assert {:ok, scene} = Render.prepare(payload)

    assert {clone_guid, %{source: :instance_clone, source_guid: {5, 2}}} =
             Enum.find(scene.graph.provenance, fn {_guid, provenance} ->
               provenance[:source] == :instance_clone and provenance[:source_guid] == {5, 2}
             end)

    assert %RenderNode{vector_network: %{blob_index: 1}} = scene.render_nodes[clone_guid]
    assert {:ok, clone_scene} = Render.prepare(payload, root: GUID.format(clone_guid))
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(clone_scene)
    assert {:ok, %{width: 100, height: 100, data: data}} = Skia.to_raw(document)
    assert <<0, 0, 0, 0, _rest::binary>> = data
    assert <<_prefix::binary-size(39_800), 51, 153, 242, 255, _rest::binary>> = data
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

  test "renders imported vector and boolean fill geometry from message blobs" do
    assert {:ok, scene} = geometry_payload() |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)

    commands = Skia.commands(document)
    paths = Enum.filter(commands, &(&1.op == :path))
    assert [_, _, _] = paths
    assert Enum.all?(paths, &(Keyword.get(&1.opts, :fill_rule) == :even_odd))

    fill_command = Enum.find(paths, &Keyword.has_key?(&1.opts, :fill))
    assert match?({:radial_gradient, _, _, _, :clamp, _}, fill_command.opts[:fill])

    stroke_command = Enum.find(paths, &Keyword.has_key?(&1.opts, :stroke))
    assert stroke_command.opts[:stroke_cap] == :round
    assert stroke_command.opts[:stroke_join] == :bevel
    assert stroke_command.opts[:stroke_miter] == 6.0
    assert stroke_command.opts[:path_effect] == {:dash_path_effect, [8.0, 4.0], 0.0}
    refute Enum.any?(commands, &(&1.op == :rect))

    assert %SourceNode{fill_geometry: [%{commands_blob: 0}]} = scene.source_nodes[{1, 1}]

    assert %SourceNode{boolean_operation: :subtract, fill_geometry: [%{commands_blob: 0}]} =
             scene.source_nodes[{1, 2}]

    assert {:ok, %{data: data}} = Skia.to_raw(document)
    assert Enum.any?(:binary.bin_to_list(data), &(&1 != 0))
  end

  test "preserves aligned dashed strokes on transformed compound closed paths" do
    assert {:ok, scene} = audited_path_stroke_payload(:closed) |> Render.prepare()

    assert {:ok, %{warnings: [], bounds: bounds, document: document}} =
             SkiaBackend.compile(scene)

    assert bounds == %Bounds{min_x: 36.0, min_y: 16.0, max_x: 104.0, max_y: 124.0}

    stroke_command =
      document
      |> Skia.commands()
      |> Enum.find(fn command ->
        command.op == :path and Keyword.get(command.opts, :stroke_width) == 8.0
      end)

    assert stroke_command.opts[:stroke_join] == :miter
    assert stroke_command.opts[:stroke_miter] == 4.0
    assert stroke_command.opts[:stroke_cap] == :square
    assert stroke_command.opts[:path_effect] == {:dash_path_effect, [6.0, 3.0], 0.0}
    assert Enum.count(Skia.Path.segments(hd(stroke_command.args)), &(&1 == :close)) == 2
  end

  test "approximates inside and outside alignment on open paths explicitly" do
    assert {:ok, scene} = audited_path_stroke_payload(:open) |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %Warning{
                  code: :stroke_align_approximated,
                  severity: :approximation,
                  context: %{details: [:inside]}
                }
              ],
              document: document
            }} = SkiaBackend.compile(scene)

    assert Enum.any?(Skia.commands(document), fn command ->
             command.op == :path and Keyword.get(command.opts, :stroke_width) == 4.0
           end)

    refute Enum.any?(Skia.commands(document), fn command ->
             command.op == :path and Keyword.get(command.opts, :stroke_width) == 8.0
           end)

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :stroke_align_approximated, severity: :approximation}]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "rejects unresolved live boolean operations while accepting flattened geometry" do
    assert {:ok, scene} = unresolved_boolean_payload() |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %Warning{
                  code: :live_boolean_geometry_unresolved,
                  severity: :unsupported,
                  context: %{operation: :subtract}
                }
              ],
              document: document
            }} = SkiaBackend.compile(scene)

    refute Enum.any?(Skia.commands(document), &(&1.op in [:path, :rect]))

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :live_boolean_geometry_unresolved, severity: :unsupported}]}} =
             SkiaBackend.compile(scene, strict: true)

    assert {:ok, flattened_scene} = geometry_payload() |> Render.prepare()
    assert {:ok, %{warnings: []}} = SkiaBackend.compile(flattened_scene)
  end

  test "renders typed polygons, stars, and partial ellipse arcs as paths" do
    assert {:ok, scene} = primitive_shape_payload() |> Render.prepare()

    assert %RenderNode{shape: %Figler.Render.Shape.Polygon{point_count: 3}} =
             scene.render_nodes[{1, 1}]

    assert %RenderNode{
             shape: %Figler.Render.Shape.Star{point_count: 5, inner_scale: inner_scale}
           } = scene.render_nodes[{1, 2}]

    assert_in_delta inner_scale, 0.4, 1.0e-6

    assert %RenderNode{
             shape: %Figler.Render.Shape.Arc{
               start_angle: start_angle,
               end_angle: end_angle,
               inner_radius: inner_radius
             }
           } = scene.render_nodes[{1, 3}]

    assert_in_delta start_angle, 0.0, 1.0e-6
    assert_in_delta end_angle, :math.pi() * 1.5, 1.0e-6
    assert_in_delta inner_radius, 0.5, 1.0e-6
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)

    paths = Enum.filter(Skia.commands(document), &(&1.op == :path))
    fill_paths = Enum.filter(paths, &Keyword.has_key?(&1.opts, :fill))
    stroke_paths = Enum.filter(paths, &Keyword.has_key?(&1.opts, :stroke))
    assert [polygon, star, arc] = fill_paths
    assert [_polygon_stroke] = stroke_paths

    assert [{:move_to, polygon_x, polygon_y} | _polygon_segments] =
             Skia.Path.segments(hd(polygon.args))

    assert_in_delta polygon_x, 50.0, 1.0e-6
    assert_in_delta polygon_y, 0.0, 1.0e-6
    assert Enum.count_until(Skia.Path.segments(hd(polygon.args)), 5) == 4
    assert Enum.count_until(Skia.Path.segments(hd(star.args)), 12) == 11

    assert [
             {:move_to, arc_start_x, arc_start_y},
             {:arc_to, arc_x, arc_y, 100.0, 80.0, arc_start_degrees, {_sweep, false}}
             | _arc_segments
           ] = Skia.Path.segments(hd(arc.args))

    for value <- [arc_start_y - 40.0, arc_x, arc_y, arc_start_degrees] do
      assert_in_delta value, 0.0, 1.0e-6
    end

    assert_in_delta arc_start_x, 100.0, 1.0e-6
    assert Enum.count_until(Skia.Path.segments(hd(arc.args)), 6) == 5
    refute Enum.any?(Skia.commands(document), &(&1.op in [:rect, :oval]))
    assert {:ok, %{data: data}} = Skia.to_raw(document)
    assert Enum.any?(:binary.bin_to_list(data), &(&1 != 0))
  end

  test "renders independent corner radii and reports smooth-corner approximation" do
    assert {:ok, scene} = corner_geometry_payload() |> Render.prepare()

    assert %RenderNode{
             corner_radius: 3.0,
             corners: %Figler.Render.CornerRadii{
               top_left: 4.0,
               top_right: 8.0,
               bottom_right: 16.0,
               bottom_left: 12.0,
               independent?: true,
               smoothing: smoothing
             }
           } = scene.render_nodes[{1, 1}]

    assert_in_delta smoothing, 0.4, 1.0e-6

    assert {:ok,
            %{
              warnings: [
                %Warning{
                  code: :corner_smoothing_approximated,
                  severity: :approximation,
                  context: %{smoothing: warning_smoothing}
                }
              ],
              document: document
            }} = SkiaBackend.compile(scene)

    assert_in_delta warning_smoothing, 0.4, 1.0e-6

    assert [%{op: :path, args: [%{__struct__: Skia.Path}]}] =
             Enum.filter(Skia.commands(document), &(&1.op == :path))

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :corner_smoothing_approximated, severity: :approximation}]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "reports malformed primitive geometry and rejects it in strict mode" do
    assert {:ok, scene} = invalid_primitive_shape_payload() |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %Warning{code: :star_inner_scale_invalid, severity: :invalid, context: context}
              ],
              document: document
            }} = SkiaBackend.compile(scene)

    assert context == %{inner_scale: 1.5}
    refute Enum.any?(Skia.commands(document), &(&1.op == :path))

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :star_inner_scale_invalid, severity: :invalid}]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "renders editable vector networks without derived geometry blobs" do
    assert {:ok, scene} = editable_vector_payload() |> Render.prepare()
    node = scene.render_nodes[{1, 1}]

    assert %RenderNode{
             vector_network: %Figler.Render.VectorNetwork.Ref{
               blob_index: 0,
               normalized_size: %{x: 100.0, y: 100.0}
             },
             fill_geometry: [],
             stroke_geometry: []
           } = node

    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)
    assert [%{op: :path} | _] = Enum.filter(Skia.commands(document), &(&1.op == :path))
    refute Enum.any?(Skia.commands(document), &(&1.op == :rect))

    assert {:ok, %{width: 200, height: 50, data: data}} = Skia.to_raw(document)
    assert <<229, 51, 26, 255, _rest::binary>> = data
  end

  test "renders inside and outside strokes with bounded shape masks" do
    for {alignment, expected_bounds, mask_blend} <- [
          {:inside, %Bounds{min_x: 0.0, min_y: 0.0, max_x: 20.0, max_y: 20.0}, :dst_in},
          {:outside, %Bounds{min_x: -4.0, min_y: -4.0, max_x: 24.0, max_y: 24.0}, :dst_out}
        ] do
      assert {:ok, scene} = stroke_alignment_payload(alignment) |> Render.prepare()

      assert {:ok, %{warnings: [], document: document, bounds: ^expected_bounds}} =
               SkiaBackend.compile(scene, strict: true)

      commands = Skia.commands(document)

      assert Enum.any?(commands, fn command ->
               command.op == :save_layer and command.opts[:blend_mode] == mask_blend
             end)

      assert Enum.any?(commands, fn command ->
               command.op == :rect and command.opts[:stroke_width] == 8.0
             end)

      assert {:ok, %{data: data}} = Skia.to_raw(document)
      assert Enum.any?(:binary.bin_to_list(data), &(&1 != 0))
    end
  end

  test "applies inner-shadow spread to editable vector silhouettes" do
    assert {:ok, scene} = editable_vector_payload() |> Render.prepare()
    node = scene.render_nodes[{1, 1}]

    effect = %{
      type: :inner_shadow,
      visible: true,
      radius: 4.0,
      spread: 2.0,
      offset: %{x: 2.0, y: 2.0},
      color: %{r: 0.0, g: 0.0, b: 0.0, a: 0.8}
    }

    scene = %{
      scene
      | render_nodes: Map.put(scene.render_nodes, node.guid, %{node | effects: [effect]})
    }

    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene, strict: true)

    assert Enum.any?(Skia.commands(document), fn command ->
             command.op == :save_layer and
               match?({:morphology_filter, :erode, 2.0, 2.0, _}, command.opts[:image_filter])
           end)
  end

  test "reports unsupported stroke styles in strict mode" do
    assert {:ok, scene} = geometry_payload() |> Render.prepare()
    node = scene.render_nodes[{1, 1}]

    stroke = %{
      node.stroke
      | align: :inside,
        cap: :arrow_equilateral,
        cap_size: %Figler.Render.Text.Measurement{value: 2.0, units: :pixels},
        miter_limit: 0.0,
        dash_pattern: [4.0]
    }

    scene = %{
      scene
      | render_nodes: Map.put(scene.render_nodes, node.guid, %{node | stroke: stroke})
    }

    assert {:ok, %{warnings: warnings}} = SkiaBackend.compile(scene)
    codes = Enum.map(warnings, & &1.value)
    refute {:stroke_align_approximated, :inside} in codes
    assert {:stroke_cap_unsupported, :arrow_equilateral} in codes
    assert :stroke_cap_size_unsupported in codes
    assert {:dash_pattern_invalid, [4.0]} in codes
    assert {:stroke_miter_invalid, 0.0} in codes

    assert {:error, {:unsupported_render_features, strict_warnings}} =
             SkiaBackend.compile(scene, strict: true)

    assert [_, _, _, _ | _] = strict_warnings
  end

  test "applies node blend modes and drop-shadow image filters" do
    assert {:ok, scene} = effects_payload() |> Render.prepare()
    assert {:ok, %{warnings: [], document: document, bounds: bounds}} = SkiaBackend.compile(scene)

    assert bounds == %Bounds{min_x: 12.0, min_y: 12.0, max_x: 78.0, max_y: 73.0}

    commands = Skia.commands(document)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and Keyword.get(command.opts, :blend_mode) == :multiply and
               command.opts[:bounds] == {-8.0, -8.0, 66.0, 61.0} and
               is_nil(Keyword.get(command.opts, :image_filter))
           end)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and is_nil(Keyword.get(command.opts, :blend_mode)) and
               command.opts[:bounds] == {-8.0, -8.0, 66.0, 61.0} and
               match?(
                 {:drop_shadow_filter, _, _, _, _, _, _},
                 Keyword.get(command.opts, :image_filter)
               )
           end)

    assert Enum.count(commands, &(&1.op == :rect)) == 2
    assert {:ok, %{width: 66, height: 61}} = Skia.to_raw(document)
  end

  test "rejects unsupported shapes instead of silently drawing rectangles" do
    assert {:ok, scene} = unsupported_shape_payload() |> Render.prepare()

    assert {:ok,
            %{
              warnings: [%{feature: :shape, value: {:shape_unsupported, :slice}}],
              document: document
            }} =
             SkiaBackend.compile(scene)

    refute Enum.any?(Skia.commands(document), &(&1.op == :rect))

    assert {:error,
            {:unsupported_render_features,
             [%Warning{code: :shape_unsupported, severity: :unsupported}]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "bounds instance isolation around cloned child effects" do
    assert {:ok, scene} = instance_effect_payload() |> Render.prepare(root: "2:1")

    assert {:ok, %{warnings: [], document: document, bounds: bounds}} =
             SkiaBackend.compile(scene, strict: true)

    assert bounds == %Bounds{min_x: 52.0, min_y: -8.0, max_x: 110.0, max_y: 28.0}

    commands = Skia.commands(document)

    instance_layer_index =
      Enum.find_index(commands, fn command ->
        opacity = command.opts[:opacity]
        command.op == :save_layer and is_number(opacity) and abs(opacity - 0.6) < 1.0e-6
      end)

    child_effect_index =
      Enum.find_index(commands, fn command ->
        command.op == :save_layer and
          match?({:drop_shadow_filter, _, _, _, _, _, _}, command.opts[:image_filter])
      end)

    assert instance_layer_index < child_effect_index
    assert Enum.at(commands, instance_layer_index).opts[:bounds] == {-8.0, -8.0, 58.0, 36.0}
    assert Enum.at(commands, child_effect_index).opts[:bounds] == {-8.0, -8.0, 58.0, 36.0}
  end

  test "renders bounded inner shadows above shape paints" do
    assert {:ok, scene} = inner_shadow_payload() |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene, strict: true)
    assert {:ok, %{width: 20, height: 20, data: data}} = Skia.to_raw(document)

    <<edge_red, _edge_green, _edge_blue, 255>> = binary_part(data, 0, 4)
    <<center_red, _center_green, _center_blue, 255>> = binary_part(data, 4 * (10 * 20 + 10), 4)
    assert edge_red < center_red

    commands = Skia.commands(document)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and command.opts[:blend_mode] == :dst_in
           end)

    assert Enum.any?(commands, fn command ->
             command.op == :rect and command.opts[:blend_mode] == :clear
           end)
  end

  test "uses glyph silhouettes for text inner shadows and background blur" do
    assert {:ok, scene} = text_effect_payload() |> Render.prepare()
    assert {:ok, %{warnings: warnings, document: document}} = SkiaBackend.compile(scene)
    refute Enum.any?(warnings, &(&1.feature == :effect))

    commands = Skia.commands(document)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and not is_nil(command.opts[:backdrop_filter])
           end)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and command.opts[:blend_mode] == :dst_out and
               match?({:morphology_filter, :erode, 1.0, 1.0, _}, command.opts[:image_filter])
           end)

    assert {:ok, %{data: data}} = Skia.to_raw(document)
    assert Enum.any?(:binary.bin_to_list(data), &(&1 != 0))
  end

  test "renders bounded background blur through the shape mask" do
    assert {:ok, scene} = background_blur_payload() |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene, strict: true)
    assert {:ok, %{width: 20, height: 5, data: data}} = Skia.to_raw(document)

    <<edge, edge, edge, 255>> = binary_part(data, 4 * (2 * 20 + 9), 4)
    assert edge in 1..254

    assert Enum.any?(Skia.commands(document), fn command ->
             command.op == :save_layer and command.opts[:bounds] == {0.0, 0.0, 20.0, 5.0} and
               match?({:blur_filter, 3.0, 3.0, :decal}, command.opts[:backdrop_filter])
           end)
  end

  test "composites alpha mask siblings without drawing masks independently" do
    assert {:ok, scene} = mask_payload(:alpha, solid_paint(1.0, 1.0, 1.0)) |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene)

    assert {:ok, %{width: 40, height: 40, data: data}} = Skia.to_raw(document)

    <<_::binary-size(4 * 5), _r, _g, _b, left_alpha, _rest::binary>> = data
    <<_r, _g, _b, right_alpha>> = binary_part(data, 4 * 30, 4)
    assert left_alpha == 255
    assert right_alpha == 0

    commands = Skia.commands(document)

    assert Enum.any?(commands, fn command ->
             command.op == :save_layer and command.opts[:blend_mode] == :dst_in and
               command.opts[:bounds] == {0.0, 0.0, 40.0, 40.0}
           end)

    assert Enum.count(commands, &(&1.op == :rect)) == 2
  end

  test "applies bounded mask-node effects inside mask compositing" do
    assert {:ok, scene} = mask_effect_payload() |> Render.prepare()
    assert {:ok, %{warnings: [], document: document}} = SkiaBackend.compile(scene, strict: true)

    commands = Skia.commands(document)

    mask_layer_index =
      Enum.find_index(commands, &(&1.op == :save_layer and &1.opts[:blend_mode] == :dst_in))

    opacity_layer_index =
      Enum.find_index(commands, &(&1.op == :save_layer and &1.opts[:opacity] == 0.5))

    effect_layer_index =
      Enum.find_index(commands, fn command ->
        command.op == :save_layer and
          match?({:drop_shadow_filter, _, _, _, _, _, _}, command.opts[:image_filter])
      end)

    assert mask_layer_index < opacity_layer_index
    assert opacity_layer_index < effect_layer_index
    assert Enum.at(commands, opacity_layer_index).opts[:bounds] == {-8.0, -8.0, 38.0, 56.0}
    assert Enum.at(commands, effect_layer_index).opts[:bounds] == {-8.0, -8.0, 38.0, 56.0}
  end

  test "reports outline-mask approximation in strict mode" do
    assert {:ok, scene} = mask_payload(:outline, solid_paint(1.0, 1.0, 1.0)) |> Render.prepare()

    assert {:ok, %{warnings: [%{feature: :mask, value: :outline_mask_approximated}]}} =
             SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "uses luminance for luminance masks" do
    assert {:ok, scene} = mask_payload(:luminance, solid_paint(0.0, 0.0, 0.0)) |> Render.prepare()
    assert {:ok, %{document: document}} = SkiaBackend.compile(scene)
    assert {:ok, %{data: <<_r, _g, _b, alpha, _rest::binary>>}} = Skia.to_raw(document)
    assert alpha == 0
  end

  test "weights luminance masks by their original alpha" do
    mask = solid_paint(1.0, 1.0, 1.0, 0.5)
    assert {:ok, scene} = mask_payload(:luminance, mask) |> Render.prepare()
    assert {:ok, %{document: document}} = SkiaBackend.compile(scene)
    assert {:ok, %{data: <<_r, _g, _b, alpha, _rest::binary>>}} = Skia.to_raw(document)
    assert alpha in 127..128
  end

  test "reports missing vector geometry and supports strict mode" do
    assert {:ok, scene} = missing_geometry_payload() |> Render.prepare()

    assert {:ok, %{warnings: [%{feature: :fill, value: :geometry_missing}]}} =
             SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "reports malformed editable vector networks in strict mode" do
    malformed = <<4::little-unsigned-32, 4::little-unsigned-32, 1::little-unsigned-32>>
    assert {:ok, scene} = editable_vector_payload(malformed) |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %{
                  feature: :fill,
                  value: {:invalid_vector_network, :invalid_vector_network_counts}
                }
              ]
            }} = SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
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

    assert {:ok,
            %{
              warnings: [
                %{
                  code: :missing_image_asset,
                  feature: :fill,
                  context: %{paint_type: :image}
                }
              ]
            }} = SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "reports malformed image matrices and supports strict mode" do
    {:ok, image_png} = Skia.canvas(1, 1) |> Skia.clear(:white) |> Skia.to_png()

    image_paint =
      struct(Figler.Schema.Paint,
        type: :image,
        visible: true,
        image: struct(Figler.Schema.Image, data_blob: 0),
        image_scale_mode: :tile,
        scale: 0.0
      )

    blob = struct(Figler.Schema.Blob, bytes: image_png)
    assert {:ok, scene} = paint_payload(image_paint, [blob]) |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %{
                  code: :invalid_image_scale,
                  feature: :fill,
                  context: %{paint_type: :image}
                }
              ]
            }} = SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  test "reports unsupported visible paints and supports strict mode" do
    assert {:ok, scene} = render_payload(:gradient_linear) |> Render.prepare()

    assert {:ok,
            %{
              warnings: [
                %{
                  code: :missing_gradient_transform,
                  feature: :fill,
                  context: %{paint_type: :gradient_linear}
                }
              ]
            }} = SkiaBackend.compile(scene)

    assert {:error, {:unsupported_render_features, [_warning]}} =
             SkiaBackend.compile(scene, strict: true)
  end

  defp primitive_shape_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    arc_data =
      struct(Figler.Schema.ArcData,
        starting_angle: 0.0,
        ending_angle: :math.pi() * 1.5,
        inner_radius: 0.5
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :regular_polygon, "Triangle", canvas_guid,
        size: vector(100, 80),
        transform: matrix(0, 0),
        visible: true,
        count: 3,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)],
        stroke_paints: [solid_paint(0.0, 0.0, 0.0)],
        stroke_weight: 2.0
      ),
      node(guid(1, 2), :star, "Star", canvas_guid,
        size: vector(100, 80),
        transform: matrix(120, 0),
        visible: true,
        count: 5,
        star_inner_scale: 0.4,
        fill_paints: [solid_paint(0.0, 1.0, 0.0)]
      ),
      node(guid(1, 3), :ellipse, "Arc", canvas_guid,
        size: vector(100, 80),
        transform: matrix(240, 0),
        visible: true,
        arc_data: arc_data,
        fill_paints: [solid_paint(0.0, 0.0, 1.0)]
      )
    ]
    |> encode_nodes()
  end

  defp corner_geometry_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Independent corners", canvas_guid,
        size: vector(100, 80),
        transform: matrix(0, 0),
        visible: true,
        corner_radius: 3.0,
        rectangle_top_left_corner_radius: 4.0,
        rectangle_top_right_corner_radius: 8.0,
        rectangle_bottom_left_corner_radius: 12.0,
        rectangle_bottom_right_corner_radius: 16.0,
        rectangle_corner_radii_independent: true,
        corner_smoothing: 0.4,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp invalid_primitive_shape_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :star, "Invalid Star", canvas_guid,
        size: vector(100, 80),
        transform: matrix(0, 0),
        visible: true,
        count: 5,
        star_inner_scale: 1.5,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp unsupported_shape_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :slice, "Slice", canvas_guid,
        size: vector(20, 20),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp inner_shadow_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    effect =
      struct(Figler.Schema.Effect,
        type: :inner_shadow,
        visible: true,
        radius: 4.0,
        offset: vector(3, 3),
        color: struct(Figler.Schema.Color, r: 0.0, g: 0.0, b: 0.0, a: 0.7)
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Inner shadow", canvas_guid,
        size: vector(20, 20),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)],
        effects: [effect]
      )
    ]
    |> encode_nodes()
  end

  defp text_effect_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    inner_shadow =
      struct(Figler.Schema.Effect,
        type: :inner_shadow,
        visible: true,
        radius: 3.0,
        spread: 1.0,
        offset: vector(2, 2),
        color: struct(Figler.Schema.Color, r: 0.0, g: 0.0, b: 0.0, a: 0.8)
      )

    background_blur =
      struct(Figler.Schema.Effect, type: :background_blur, visible: true, radius: 4.0)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Backdrop left", canvas_guid,
        parent_position: "a",
        size: vector(60, 40),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(0.1, 0.3, 0.9)]
      ),
      node(guid(1, 2), :rectangle, "Backdrop right", canvas_guid,
        parent_position: "b",
        size: vector(60, 40),
        transform: matrix(60, 0),
        visible: true,
        fill_paints: [solid_paint(0.9, 0.2, 0.3)]
      ),
      node(guid(1, 3), :text, "Effect text", canvas_guid,
        parent_position: "c",
        size: vector(100, 28),
        transform: matrix(10, 6),
        visible: true,
        text_data: struct(Figler.Schema.TextData, characters: "Effects"),
        font_name:
          struct(Figler.Schema.FontName,
            family: "Arial",
            style: "Bold",
            postscript: "Arial-BoldMT"
          ),
        font_size: 24.0,
        fill_paints: [solid_paint(1.0, 1.0, 1.0, 0.35)],
        effects: [background_blur, inner_shadow]
      )
    ]
    |> encode_nodes()
  end

  defp background_blur_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    blur = struct(Figler.Schema.Effect, type: :background_blur, visible: true, radius: 6.0)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Black", canvas_guid,
        size: vector(10, 5),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(0.0, 0.0, 0.0)]
      ),
      node(guid(1, 2), :rectangle, "White", canvas_guid,
        size: vector(10, 5),
        transform: matrix(10, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 1.0, 1.0)]
      ),
      node(guid(1, 3), :rectangle, "Backdrop", canvas_guid,
        size: vector(20, 5),
        transform: matrix(0, 0),
        visible: true,
        effects: [blur]
      )
    ]
    |> encode_nodes()
  end

  defp effects_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    shadow =
      struct(Figler.Schema.Effect,
        type: :drop_shadow,
        visible: true,
        radius: 4.0,
        offset: vector(10, 5),
        color: struct(Figler.Schema.Color, r: 0.0, g: 0.0, b: 0.0, a: 0.8),
        blend_mode: :normal
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :frame, "Shadow card", canvas_guid,
        size: vector(40, 40),
        transform: matrix(20, 20),
        visible: true,
        blend_mode: :multiply,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)],
        effects: [shadow]
      ),
      node(guid(1, 2), :rectangle, "Unaffected child", guid(1, 1),
        size: vector(10, 10),
        transform: matrix(5, 5),
        visible: true,
        fill_paints: [solid_paint(0.0, 1.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp mask_payload(mask_type, mask_paint) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Mask", canvas_guid,
        parent_position: "a",
        size: vector(20, 40),
        transform: matrix(0, 0),
        visible: true,
        mask: true,
        mask_type: mask_type,
        fill_paints: [mask_paint]
      ),
      node(guid(1, 2), :rectangle, "Masked content", canvas_guid,
        parent_position: "b",
        size: vector(40, 40),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp mask_effect_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    shadow =
      struct(Figler.Schema.Effect,
        type: :drop_shadow,
        visible: true,
        radius: 4.0,
        offset: vector(2, 0),
        color: struct(Figler.Schema.Color, r: 0.0, g: 0.0, b: 0.0, a: 0.8),
        blend_mode: :normal
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Effect mask", canvas_guid,
        parent_position: "a",
        size: vector(20, 40),
        transform: matrix(0, 0),
        visible: true,
        opacity: 0.5,
        mask: true,
        mask_type: :alpha,
        effects: [shadow],
        fill_paints: [solid_paint(1.0, 1.0, 1.0)]
      ),
      node(guid(1, 2), :rectangle, "Masked content", canvas_guid,
        parent_position: "b",
        size: vector(40, 40),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp missing_geometry_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :vector, "Missing path", canvas_guid,
        size: vector(40, 40),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      )
    ]
    |> encode_nodes()
  end

  defp stroke_alignment_payload(alignment) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :rectangle, "Aligned stroke", canvas_guid,
        size: vector(20, 20),
        transform: matrix(0, 0),
        visible: true,
        stroke_paints: [solid_paint(0.2, 0.7, 1.0)],
        stroke_weight: 4.0,
        stroke_align: alignment,
        stroke_join: :round
      )
    ]
    |> encode_nodes()
  end

  defp audited_path_stroke_payload(kind) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    geometry = struct(Figler.Schema.Path, winding_rule: :odd, commands_blob: 0)

    transform =
      struct(Figler.Schema.Matrix,
        m00: 0.0,
        m01: -1.0,
        m02: 100.0,
        m10: 1.0,
        m11: 0.0,
        m12: 20.0
      )

    {blob, fill_geometry, fill_paints} =
      case kind do
        :closed ->
          {compound_closed_geometry_blob(), [geometry], [solid_paint(0.2, 0.4, 0.8)]}

        :open ->
          {open_geometry_blob(), [], []}
      end

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :vector, "Audited path stroke", canvas_guid,
        size: vector(100, 60),
        transform: transform,
        visible: true,
        fill_paints: fill_paints,
        stroke_paints: [solid_paint(1.0, 0.5, 0.1)],
        stroke_weight: 4.0,
        stroke_align: if(kind == :closed, do: :outside, else: :inside),
        stroke_cap: :square,
        stroke_join: :miter,
        miter_limit: 4.0,
        dash_pattern: [6.0, 3.0],
        fill_geometry: fill_geometry,
        stroke_geometry: [geometry]
      )
    ]
    |> encode_nodes([struct(Figler.Schema.Blob, bytes: blob)])
  end

  defp open_geometry_blob do
    <<1, f32(0.0)::binary, f32(30.0)::binary, 2, f32(50.0)::binary, f32(0.0)::binary, 2,
      f32(100.0)::binary, f32(30.0)::binary>>
  end

  defp compound_closed_geometry_blob do
    <<1, f32(0.0)::binary, f32(0.0)::binary, 2, f32(100.0)::binary, f32(0.0)::binary, 2,
      f32(100.0)::binary, f32(60.0)::binary, 2, f32(0.0)::binary, f32(60.0)::binary, 0, 1,
      f32(30.0)::binary, f32(20.0)::binary, 2, f32(70.0)::binary, f32(20.0)::binary, 2,
      f32(70.0)::binary, f32(40.0)::binary, 2, f32(30.0)::binary, f32(40.0)::binary, 0>>
  end

  defp unresolved_boolean_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    boolean_guid = guid(1, 1)

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(boolean_guid, :boolean_operation, "Live subtract", canvas_guid,
        size: vector(40, 40),
        transform: matrix(0, 0),
        visible: true,
        boolean_operation: :subtract,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      ),
      node(guid(1, 2), :rectangle, "Left", boolean_guid,
        size: vector(30, 30),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      ),
      node(guid(1, 3), :ellipse, "Right", boolean_guid,
        size: vector(30, 30),
        transform: matrix(10, 10),
        visible: true,
        fill_paints: [solid_paint(0.0, 0.0, 1.0)]
      )
    ]
    |> encode_nodes()
  end

  defp clipped_path_payload(container_type) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    container_guid = guid(1, 1)
    geometry = struct(Figler.Schema.Path, winding_rule: :nonzero, commands_blob: 0)

    child_transform =
      struct(Figler.Schema.Matrix,
        m00: 0.70710678,
        m01: -0.70710678,
        m02: 20.0,
        m10: 0.70710678,
        m11: 0.70710678,
        m12: -20.0
      )

    nodes = [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(container_guid, container_type, "Clipping container", canvas_guid,
        size: vector(40, 40),
        transform: matrix(10, 10),
        visible: true,
        frame_mask_disabled: false,
        rectangle_top_left_corner_radius: 4.0,
        rectangle_top_right_corner_radius: 8.0,
        rectangle_bottom_right_corner_radius: 12.0,
        rectangle_bottom_left_corner_radius: 16.0,
        rectangle_corner_radii_independent: true,
        fill_paints: [solid_paint(0.1, 0.1, 0.1)]
      ),
      node(guid(1, 2), :vector, "Transformed path", container_guid,
        size: vector(80, 80),
        transform: child_transform,
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)],
        fill_geometry: [geometry]
      )
    ]

    blob =
      <<1, f32(0.0)::binary, f32(80.0)::binary, 2, f32(40.0)::binary, f32(0.0)::binary, 2,
        f32(80.0)::binary, f32(80.0)::binary, 0>>

    encode_nodes(nodes, [struct(Figler.Schema.Blob, bytes: blob)])
  end

  defp geometry_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    geometry = struct(Figler.Schema.Path, winding_rule: :odd, commands_blob: 0)

    fill =
      struct(Figler.Schema.Paint,
        type: :gradient_radial,
        visible: true,
        opacity: 1.0,
        transform: matrix(0, 0),
        stops: [gradient_stop(0.8, 0.1, 0.5, 0.0), gradient_stop(0.1, 0.3, 0.9, 1.0)]
      )

    stroke = solid_paint(0.9, 0.9, 1.0)

    nodes = [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :vector, "Triangle", canvas_guid,
        size: vector(40, 40),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [fill],
        stroke_paints: [stroke],
        stroke_weight: 3.0,
        stroke_align: :center,
        stroke_cap: :round,
        stroke_join: :bevel,
        miter_limit: 6.0,
        dash_pattern: [8.0, 4.0],
        fill_geometry: [geometry],
        stroke_geometry: [geometry]
      ),
      node(guid(1, 2), :boolean_operation, "Boolean", canvas_guid,
        size: vector(40, 40),
        transform: matrix(50, 0),
        visible: true,
        boolean_operation: :subtract,
        fill_paints: [fill],
        fill_geometry: [geometry]
      ),
      node(guid(1, 3), :rectangle, "Boolean source", guid(1, 2),
        size: vector(20, 20),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [fill]
      )
    ]

    blob =
      <<1, f32(0.0)::binary, f32(40.0)::binary, 2, f32(20.0)::binary, f32(0.0)::binary, 2,
        f32(40.0)::binary, f32(40.0)::binary, 0>>

    encode_nodes(nodes, [struct(Figler.Schema.Blob, bytes: blob)])
  end

  defp editable_vector_payload(blob \\ editable_square_blob()) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    vector_data =
      struct(Figler.Schema.VectorData,
        vector_network_blob: 0,
        normalized_size: vector(100, 100),
        style_override_table: [struct(Figler.Schema.NodeChange, style_id: 1)]
      )

    nodes = [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :vector, "Editable rectangle", canvas_guid,
        size: vector(200, 50),
        transform: matrix(0, 0),
        visible: true,
        vector_data: vector_data,
        fill_paints: [solid_paint(0.9, 0.2, 0.1)]
      )
    ]

    encode_nodes(nodes, [struct(Figler.Schema.Blob, bytes: blob)])
  end

  defp editable_square_blob do
    vertices = [{0.0, 0.0}, {100.0, 0.0}, {100.0, 100.0}, {0.0, 100.0}]
    segments = [{0, 1}, {1, 2}, {2, 3}, {3, 0}]

    <<4::little-unsigned-32, 4::little-unsigned-32, 1::little-unsigned-32>> <>
      Enum.map_join(vertices, fn {x, y} ->
        <<0::little-unsigned-32, x::little-float-32, y::little-float-32>>
      end) <>
      Enum.map_join(segments, fn {start, finish} ->
        <<0::little-unsigned-32, start::little-unsigned-32, 0.0::little-float-32,
          0.0::little-float-32, finish::little-unsigned-32, 0.0::little-float-32,
          0.0::little-float-32>>
      end) <>
      <<0::little-unsigned-32, 1::little-unsigned-32, 4::little-unsigned-32,
        0::little-unsigned-32, 1::little-unsigned-32, 2::little-unsigned-32,
        3::little-unsigned-32>>
  end

  defp instance_paint_override_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    component_guid = guid(1, 1)
    child_guid = guid(1, 2)

    override =
      struct(Figler.Schema.NodeChange,
        guid_path: struct(Figler.Schema.GUIDPath, guids: [child_guid]),
        fill_paints: [solid_paint(0.0, 0.0, 1.0)]
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(component_guid, :symbol, "Card", canvas_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true
      ),
      node(child_guid, :rectangle, "Background", component_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
      ),
      node(guid(2, 1), :instance, "Card instance", canvas_guid,
        size: vector(40, 20),
        transform: matrix(60, 0),
        visible: true,
        symbol_data:
          struct(Figler.Schema.SymbolData,
            symbol_id: component_guid,
            symbol_overrides: [override]
          )
      )
    ]
    |> encode_nodes()
  end

  defp instance_typography_override_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    component_guid = guid(3, 1)
    child_guid = guid(3, 2)

    override =
      struct(Figler.Schema.NodeChange,
        guid_path: struct(Figler.Schema.GUIDPath, guids: [child_guid]),
        line_height: struct(Figler.Schema.Number, value: 30.0, units: :pixels),
        letter_spacing: struct(Figler.Schema.Number, value: 2.0, units: :pixels),
        text_decoration: :underline,
        text_decoration_style: :wavy,
        text_decoration_skip_ink: false,
        text_align_horizontal: :right,
        text_align_vertical: :bottom,
        text_truncation: :ending,
        max_lines: 1
      )

    text_data = struct(Figler.Schema.TextData, characters: "Override")

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(component_guid, :symbol, "Label", canvas_guid,
        size: vector(100, 40),
        transform: matrix(0, 0),
        visible: true
      ),
      node(child_guid, :text, "Text", component_guid,
        size: vector(100, 40),
        transform: matrix(0, 0),
        visible: true,
        text_data: text_data,
        font_name:
          struct(Figler.Schema.FontName,
            family: "Arial",
            style: "Regular",
            postscript: "Arial-Regular"
          ),
        font_size: 14.0,
        line_height: struct(Figler.Schema.Number, value: 20.0, units: :pixels),
        fill_paints: [solid_paint(1.0, 1.0, 1.0)]
      ),
      node(guid(4, 1), :instance, "Label instance", canvas_guid,
        size: vector(100, 40),
        transform: matrix(120, 0),
        visible: true,
        symbol_data:
          struct(Figler.Schema.SymbolData,
            symbol_id: component_guid,
            symbol_overrides: [override]
          )
      )
    ]
    |> encode_nodes()
  end

  defp instance_vector_override_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    component_guid = guid(5, 1)
    child_guid = guid(5, 2)

    base_vector_data =
      struct(Figler.Schema.VectorData,
        vector_network_blob: 0,
        normalized_size: vector(100, 100)
      )

    override_vector_data =
      struct(Figler.Schema.VectorData,
        vector_network_blob: 1,
        normalized_size: vector(100, 100)
      )

    override =
      struct(Figler.Schema.NodeChange,
        guid_path: struct(Figler.Schema.GUIDPath, guids: [child_guid]),
        vector_data: override_vector_data
      )

    nodes = [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(component_guid, :symbol, "Editable component", canvas_guid,
        size: vector(100, 100),
        transform: matrix(0, 0),
        visible: true
      ),
      node(child_guid, :vector, "Editable shape", component_guid,
        size: vector(100, 100),
        transform: matrix(0, 0),
        visible: true,
        vector_data: base_vector_data,
        fill_paints: [solid_paint(0.2, 0.6, 0.95)]
      ),
      node(guid(6, 1), :instance, "Editable instance", canvas_guid,
        size: vector(100, 100),
        transform: matrix(120, 0),
        visible: true,
        symbol_data:
          struct(Figler.Schema.SymbolData,
            symbol_id: component_guid,
            symbol_overrides: [override]
          )
      )
    ]

    encode_nodes(nodes, [
      struct(Figler.Schema.Blob, bytes: editable_square_blob()),
      struct(Figler.Schema.Blob, bytes: editable_triangle_blob())
    ])
  end

  defp editable_triangle_blob do
    vertices = [{0.0, 100.0}, {50.0, 0.0}, {100.0, 100.0}]
    segments = [{0, 1}, {1, 2}, {2, 0}]

    <<3::little-unsigned-32, 3::little-unsigned-32, 1::little-unsigned-32>> <>
      Enum.map_join(vertices, fn {x, y} ->
        <<0::little-unsigned-32, x::little-float-32, y::little-float-32>>
      end) <>
      Enum.map_join(segments, fn {start, finish} ->
        <<0::little-unsigned-32, start::little-unsigned-32, 0.0::little-float-32,
          0.0::little-float-32, finish::little-unsigned-32, 0.0::little-float-32,
          0.0::little-float-32>>
      end) <>
      <<1::little-unsigned-32, 1::little-unsigned-32, 3::little-unsigned-32,
        0::little-unsigned-32, 1::little-unsigned-32, 2::little-unsigned-32>>
  end

  defp instance_effect_payload do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)
    component_guid = guid(1, 1)

    shadow =
      struct(Figler.Schema.Effect,
        type: :drop_shadow,
        visible: true,
        radius: 4.0,
        offset: vector(2, 0),
        color: struct(Figler.Schema.Color, r: 0.0, g: 0.0, b: 0.0, a: 0.8),
        blend_mode: :normal
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(component_guid, :symbol, "Effect source", canvas_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true
      ),
      node(guid(1, 2), :rectangle, "Shadow child", component_guid,
        size: vector(40, 20),
        transform: matrix(0, 0),
        visible: true,
        effects: [shadow],
        fill_paints: [solid_paint(0.8, 0.2, 0.1)]
      ),
      node(guid(2, 1), :instance, "Effect instance", canvas_guid,
        size: vector(40, 20),
        transform: matrix(60, 0),
        visible: true,
        opacity: 0.6,
        symbol_data: struct(Figler.Schema.SymbolData, symbol_id: component_guid)
      )
    ]
    |> encode_nodes()
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

  defp rich_text_payload(style_ids \\ [0, 1, 1, 2]) do
    document_guid = guid(0, 0)
    canvas_guid = guid(0, 1)

    emoji_style =
      struct(Figler.Schema.NodeChange,
        style_id: 1,
        font_name:
          struct(Figler.Schema.FontName,
            family: "Noto Color Emoji",
            style: "Regular",
            postscript: "NotoColorEmoji"
          ),
        font_size: 18.0,
        line_height: struct(Figler.Schema.Number, value: 150.0, units: :percent),
        letter_spacing: struct(Figler.Schema.Number, value: 2.0, units: :pixels),
        text_decoration: :underline,
        text_decoration_style: :dotted,
        text_decoration_skip_ink: true,
        text_decoration_fill_paints: [solid_paint(1.0, 1.0, 0.0)],
        fill_paints: [solid_paint(0.0, 1.0, 0.0)]
      )

    bold_style =
      struct(Figler.Schema.NodeChange,
        style_id: 2,
        font_name:
          struct(Figler.Schema.FontName,
            family: "Inter",
            style: "Bold",
            postscript: "Inter-Bold"
          ),
        text_case: :lower,
        fill_paints: [solid_paint(0.0, 0.0, 1.0)]
      )

    text_data =
      struct(Figler.Schema.TextData,
        characters: "A😀B",
        character_style_i_ds: style_ids,
        style_override_table: [emoji_style, bold_style],
        fallback_fonts: [
          struct(Figler.Schema.FontName,
            family: "Noto Color Emoji",
            style: "Regular",
            postscript: "NotoColorEmoji"
          )
        ]
      )

    [
      node(document_guid, :document, "Document"),
      node(canvas_guid, :canvas, "Page 1", document_guid),
      node(guid(1, 1), :text, "Rich text", canvas_guid,
        size: vector(80, 24),
        transform: matrix(0, 0),
        visible: true,
        text_data: text_data,
        font_name:
          struct(Figler.Schema.FontName,
            family: "Inter",
            style: "Regular",
            postscript: "Inter-Regular"
          ),
        font_size: 14.0,
        line_height: struct(Figler.Schema.Number, value: 1.5, units: :raw),
        letter_spacing: struct(Figler.Schema.Number, value: 0.25, units: :raw),
        text_decoration: :underline,
        text_case: :upper,
        text_align_horizontal: :center,
        text_align_vertical: :bottom,
        text_auto_resize: :height,
        text_truncation: :ending,
        max_lines: 2,
        fill_paints: [solid_paint(1.0, 0.0, 0.0)]
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
    {position, attrs} = Keyword.pop(attrs, :parent_position, "!")

    parent_index =
      if parent_guid,
        do: struct(Figler.Schema.ParentIndex, guid: parent_guid, position: position),
        else: nil

    Figler.Schema.NodeChange
    |> struct([guid: guid, type: type, name: name, parent_index: parent_index] ++ attrs)
  end

  defp solid_paint(r, g, b, alpha \\ 1.0) do
    struct(Figler.Schema.Paint,
      type: :solid,
      visible: true,
      opacity: 1.0,
      color: struct(Figler.Schema.Color, r: r, g: g, b: b, a: alpha)
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

  defp f32(value), do: <<value::little-float-size(32)>>

  defp guid(session_id, local_id),
    do: struct(Figler.Schema.GUID, session_id: session_id, local_id: local_id)
end
