defmodule Figler.Scene.NavigationTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Node

  import Figler.Test.SceneFixture

  test "navigates projected scene indexes" do
    index = Scene.index(message_payload())

    assert Scene.pages(index) == [scene_canvas()]
    assert Scene.roots(index) == [scene_document()]
    assert Scene.node(index, "0:1") == scene_canvas()
    assert Scene.parent(index, "0:1") == scene_document()
    assert Scene.children(index, "0:0") == [scene_canvas()]
    assert Scene.siblings(index, "0:1") == []
    assert Scene.ancestors(index, "0:1") == [scene_document()]
    assert Scene.descendants(index, "0:0") == [scene_canvas()]
    assert %Figler.Scene.Index{} = index
    assert Scene.by_type(index, :canvas) == [scene_canvas()]
    assert Scene.named(index, "Page 1") == [scene_canvas()]
    assert Scene.name_contains(index, "Page") == [scene_canvas()]
    assert Scene.text_nodes(index) == []
    assert Scene.text_contains(index, "Hello") == [scene_canvas()]

    assert Scene.by_type(index, :canvas, fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    assert Scene.name_contains(index, "Page", fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    assert Scene.text_contains(index, "Hello", fields: [:text]) == [
             %Node{guid: "0:1", node_type: "canvas", text: "Hello world"}
           ]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.name_contains("Page")
           |> Scene.text_contains("Hello") == [scene_canvas()]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.attribute(:name) == ["Page 1"]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.text(sep: "\n") == "Hello world"

    assert Scene.components(index) == []
    assert Scene.with_fills(index) == []
    assert Scene.with_strokes(index) == []

    assert Scene.find(index, type: :canvas, name_contains: "Page", text_contains: "Hello") == [
             scene_canvas()
           ]

    %Node{} = document = scene_document()
    %Node{} = canvas = scene_canvas()

    assert Scene.tree(index, depth: 1) == [
             %Node{document | children: [%Node{canvas | children: []}]}
           ]
  end
end
