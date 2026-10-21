defmodule Figler.Render.Skia.ShapeTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Color
  alias Figler.Render.CornerRadii
  alias Figler.Render.Node
  alias Figler.Render.Paint
  alias Figler.Render.Shape.Arc
  alias Figler.Render.Shape.Star
  alias Figler.Render.Skia.Assets
  alias Figler.Render.Skia.Shape
  alias Figler.Render.Text
  alias Figler.Render.Text.Run

  test "uses primitive paths for effect and aligned-stroke silhouettes" do
    node = %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :star,
      size: %{x: 100.0, y: 80.0},
      shape: %Star{point_count: 5, inner_scale: 0.4}
    }

    document = Skia.canvas(100, 80)
    rendered = Shape.draw_silhouette(document, node, %{}, fill: :white)

    assert [%{op: :path, args: [%{__struct__: Skia.Path}]}] = Skia.commands(rendered)
    assert Shape.stroke_alignment_supported?(node)
    assert Shape.effect_shape_supported?(node)
  end

  test "splits full ellipse sweeps into renderable half arcs" do
    node = %Node{
      guid: {1, 6},
      source_guid: {1, 6},
      node_type: :ellipse,
      size: %{x: 100.0, y: 80.0},
      shape: %Arc{start_angle: 0.0, end_angle: 2 * :math.pi(), inner_radius: 0.0}
    }

    rendered = Shape.draw_silhouette(Skia.canvas(100, 80), node, %{}, fill: :white)
    assert [%{op: :path, args: [path]}] = Skia.commands(rendered)

    assert [
             {:move_to, 100.0, 40.0},
             {:arc_to, +0.0, +0.0, 100.0, 80.0, +0.0, {180.0, false}},
             {:arc_to, +0.0, +0.0, 100.0, 80.0, 180.0, {180.0, false}},
             :close
           ] = Skia.Path.segments(path)
  end

  test "uses one path for independent rectangular corners and their effect silhouette" do
    node = %Node{
      guid: {1, 2},
      source_guid: {1, 2},
      node_type: :rectangle,
      size: %{x: 100.0, y: 80.0},
      corners: %CornerRadii{
        top_left: 4.0,
        top_right: 8.0,
        bottom_right: 12.0,
        bottom_left: 16.0,
        independent?: true,
        smoothing: +0.0
      }
    }

    rendered = Shape.draw_silhouette(Skia.canvas(100, 80), node, %{}, fill: :white)
    assert [%{op: :path, args: [path]}] = Skia.commands(rendered)

    assert [
             {:move_to, 4.0, +0.0},
             {:line_to, 92.0, +0.0},
             {:r_arc_to, 8.0, 8.0, +0.0, {false, :cw, 8.0, 8.0}},
             {:line_to, 100.0, 68.0},
             {:r_arc_to, 12.0, 12.0, +0.0, {false, :cw, -12.0, 12.0}},
             {:line_to, 16.0, 80.0},
             {:r_arc_to, 16.0, 16.0, +0.0, {false, :cw, -16.0, -16.0}},
             {:line_to, +0.0, 4.0},
             {:r_arc_to, 4.0, 4.0, +0.0, {false, :cw, 4.0, -4.0}},
             :close
           ] = Skia.Path.segments(path)
  end

  test "recognizes every supported clipping container type" do
    for type <- [:frame, :instance, :symbol] do
      node = %Node{
        guid: {1, 4},
        source_guid: {1, 4},
        node_type: type,
        frame_mask_disabled: false
      }

      assert Node.clips_children?(node)
    end

    refute Node.clips_children?(%Node{
             guid: {1, 5},
             source_guid: {1, 5},
             node_type: :section,
             frame_mask_disabled: false
           })
  end

  test "rejects malformed rectangular corners instead of drawing them" do
    node = %Node{
      guid: {1, 3},
      source_guid: {1, 3},
      node_type: :rectangle,
      size: %{x: 100.0, y: 80.0},
      corners: CornerRadii.from_source(%{corner_radius: -1.0})
    }

    assert Shape.issues(node) == [
             %{code: :corner_radius_invalid, corner: :uniform, radius: -1.0}
           ]

    rendered = Shape.draw_silhouette(Skia.canvas(100, 80), node, %{}, fill: :white)
    assert Skia.commands(rendered) == []
  end

  test "draws saved glyphs in their style runs' colours and emoji once" do
    red = solid(1.0, 0.0, 0.0)
    blue = solid(0.0, 0.0, 1.0)
    run = %Run{index: 1, start: 1, length: 1, content: "B", font: nil, fill_paints: [blue]}

    node = %Node{
      guid: {1, 7},
      source_guid: {1, 7},
      node_type: :text,
      size: %{x: 40.0, y: 20.0},
      fill_paints: [red],
      text: %Text{content: "AB😀", font: nil, runs: [run]}
    }

    layer = Skia.Path.new() |> Skia.Path.move_to(0, 0) |> Skia.Path.line_to(1, 1)
    coloured = Skia.Path.new() |> Skia.Path.move_to(2, 0) |> Skia.Path.line_to(3, 1)

    assets = %Assets{
      text_glyphs: %{{1, 7} => [{nil, layer}, {run, coloured}]},
      text_emoji: %{{1, 7} => [{"😀", [x: 20.0, y: 4.0, size: 12.0]}]}
    }

    assert [
             %{op: :path, args: [^layer], opts: layer_opts},
             %{op: :path, args: [^coloured], opts: run_opts},
             %{op: :text, args: ["😀"]}
           ] = Shape.draw_node(Skia.canvas(40, 20), node, assets) |> Skia.commands()

    assert Keyword.fetch!(layer_opts, :fill) == resolved(red)
    assert Keyword.fetch!(run_opts, :fill) == resolved(blue)
  end

  defp resolved(paint) do
    {:ok, %{paint: resolved}} = Figler.Render.Skia.Paint.resolve(paint, nil, %{})
    resolved
  end

  defp solid(r, g, b),
    do: %Paint{type: :solid, visible: true, opacity: 1.0, color: %Color{r: r, g: g, b: b, a: 1.0}}
end
