defmodule Figler.SceneTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node
  alias Figler.Scene.Summary

  import Figler.Test.SceneFixture

  test "summarizes raw message payloads" do
    assert Scene.summary(message_payload()) == %Summary{
             node_count: 2,
             parented_count: 1,
             root_count: 1,
             type_counts: [{"canvas", 1}, {"document", 1}]
           }
  end

  test "queries raw message payloads" do
    assert Scene.query(message_payload(), "//canvas[@name='Page 1']") == [scene_canvas()]

    assert Scene.query(message_payload(), "//canvas[@width='100' and @visible='true']") == [
             scene_canvas()
           ]

    assert Scene.query(message_payload(), "//canvas[contains(@text, 'Hello')]") == [
             scene_canvas()
           ]

    assert Scene.query(message_payload(), "//canvas", fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]
  end

  test "reuses projected scene indexes across XPath queries" do
    index = Scene.index(message_payload())

    assert Scene.query(index, "//canvas") == [scene_canvas()]
    assert Scene.query(index, "id('0:1')") == [scene_canvas()]
    assert Scene.query(index, "//*[@parent_guid='0:0']") == [scene_canvas()]
  end

  test "builds effective graph handles" do
    graph = Scene.graph(message_payload())

    assert %Graph{mode: :interpreted} = graph
    assert Scene.node(graph, "0:1") == scene_canvas()
    assert Graph.stats(graph).node_count == 2
  end

  test "accepts canvas.fig containers" do
    assert Scene.summary(canvas_container()) == Scene.summary(message_payload())
  end

  test "accepts .fig ZIPs containing canvas.fig" do
    assert Scene.query(fig_zip(), "//*[@parent_guid='0:0']") == [scene_canvas()]
  end

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

  describe "errors" do
    alias Figler.Error
    alias Figler.Scene
    alias Figler.Scene.Graph

    import Figler.Test.SceneFixture

    test "normalizes native document and XPath failures" do
      assert_raise Error, "invalid Figma document during summary", fn ->
        Scene.summary(<<1, 2, 3>>)
      end

      error =
        assert_raise Error, "invalid scene query during query", fn ->
          Scene.query(message_payload(), "[")
        end

      assert error.code == :invalid_query
      assert error.operation == :query
      assert is_binary(error.context.reason)

      assert_raise Error, "invalid Figma document during graph", fn ->
        Scene.graph(<<1, 2, 3>>)
      end
    end

    test "rejects malformed GUIDs consistently across navigation surfaces" do
      index = Scene.index(message_payload())
      graph = Scene.graph(index)

      for {operation, fun} <- [
            node: fn -> Scene.node(index, "invalid") end,
            parent: fn -> Scene.parent(index, "invalid") end,
            children: fn -> Scene.children(graph, "invalid") end,
            siblings: fn -> Scene.siblings(index, "invalid") end,
            ancestors: fn -> Scene.ancestors(index, "invalid") end,
            descendants: fn -> Scene.descendants(index, "invalid") end
          ] do
        error = assert_raise Error, fun
        assert error.code == :invalid_guid
        assert error.operation == operation
        assert error.context == %{guid: "invalid"}
      end
    end

    test "rejects unknown and malformed query options" do
      assert_error(:query, :fields, :invalid_fields, fn ->
        Scene.query(message_payload(), "//*", fields: :name)
      end)

      assert_error(:query, :unknown, :unknown_option, fn ->
        Scene.by_type(message_payload(), :canvas, unknown: true)
      end)

      assert_error(:find, :name_contains, :invalid_string, fn ->
        Scene.find(message_payload(), name_contains: :page)
      end)

      assert_error(:tree, :depth, :invalid_depth, fn ->
        Scene.tree(message_payload(), depth: -1)
      end)
    end

    test "rejects ambiguous and unsupported graph options" do
      assert_error(:graph, :until, :unknown_option, fn ->
        Scene.graph(message_payload(), until: :variables)
      end)

      assert_error(:graph, :selection, :conflicting_focus_selection, fn ->
        Scene.graph(message_payload(), focus: "0:1", root: "0:1")
      end)

      assert_error(:graph, :resolve_variables, :invalid_resolution_mode, fn ->
        Scene.graph(message_payload(), resolve_variables: :all)
      end)

      graph = Scene.graph(message_payload())

      assert_error(:graph_tree, :depth, :invalid_depth, fn ->
        Graph.tree(graph, depth: -1)
      end)

      assert_error(:graph_unresolved, :limit, :invalid_limit, fn ->
        Graph.unresolved(graph, limit: -1)
      end)
    end

    defp assert_error(operation, option, code, fun) do
      error = assert_raise Error, fun

      assert error.code == :invalid_options
      assert error.operation == operation
      assert [%{option: ^option, code: ^code}] = error.context.errors
    end
  end

  describe "OpenPencil fixtures" do
    fixtures = [
      {"gold-preview", "gold-preview.fig", 3_519},
      {"material3", "material3.fig", 87_237},
      {"nuxtui", "nuxtui.fig", 315_274}
    ]

    if fixture_dir = System.get_env("FIGLER_OPEN_PENCIL_FIXTURE_DIR") do
      alias Figler.Scene.Graph

      if System.get_env("FIGLER_OPEN_PENCIL_GRAPH_FIXTURE") do
        path = Path.join(fixture_dir, "gold-preview.fig")

        if File.exists?(path) do
          @tag timeout: 120_000
          test "builds graph for OpenPencil gold preview fixture" do
            graph = unquote(path) |> File.read!() |> Figler.Scene.graph()
            stats = Graph.stats(graph)

            assert stats.node_count >= 3_519
            assert stats.seed_count >= 3_519
            assert is_integer(stats.clone_count)
            assert is_integer(stats.unresolved_count)
            assert is_list(Graph.unresolved(graph, limit: 20))
          end
        end
      end

      for {name, file, expected_nodes} <- fixtures do
        path = Path.join(fixture_dir, file)

        if File.exists?(path) do
          @tag timeout: 120_000
          test "summarizes OpenPencil fixture #{name}" do
            summary = unquote(path) |> File.read!() |> Figler.Scene.summary()

            assert summary.node_count == unquote(expected_nodes)
            assert summary.parented_count > 0
            assert summary.root_count > 0
            assert {"canvas", canvas_count} = List.keyfind(summary.type_counts, "canvas", 0)
            assert canvas_count > 0
          end

          @tag timeout: 120_000
          test "projects text fields from OpenPencil fixture #{name}" do
            index = unquote(path) |> File.read!() |> Figler.Scene.index()

            text_nodes =
              Figler.Scene.query(index, "//text[@text]", fields: [:name, :text, :font_family])

            assert [%Figler.Scene.Node{node_type: "text", text: text} | _] = text_nodes
            assert is_binary(text)
            assert text != ""

            assert Enum.any?(text_nodes, &(&1.text == text))
          end

          @tag timeout: 120_000
          test "projects component and paint summary fields from OpenPencil fixture #{name}" do
            index = unquote(path) |> File.read!() |> Figler.Scene.index()

            assert [%Figler.Scene.Node{component_key: component_key} | _] =
                     Figler.Scene.components(index)

            assert is_binary(component_key)
            assert component_key != ""

            assert [%Figler.Scene.Node{fill_count: fill_count} | _] =
                     Figler.Scene.with_fills(index)

            assert fill_count > 0

            assert [%Figler.Scene.Node{stroke_count: stroke_count} | _] =
                     Figler.Scene.with_strokes(index)

            assert stroke_count > 0
          end
        end
      end
    else
      @tag :external_fixture
      test "OpenPencil fixture tests are disabled" do
        assert System.get_env("FIGLER_OPEN_PENCIL_FIXTURE_DIR") in [nil, ""]
      end
    end
  end

  describe "OpenPencil Node CLI" do
    @describetag :external_fixture

    @cli_env "FIGLER_OPEN_PENCIL_NODE_CLI"
    @fixture_env "FIGLER_OPEN_PENCIL_FIXTURE_DIR"

    if System.get_env(@cli_env) && System.get_env(@fixture_env) do
      @tag timeout: 120_000
      test "compares document info with OpenPencil Node CLI" do
        fixture = Path.join(System.fetch_env!(@fixture_env), "gold-preview.fig")
        cli = System.fetch_env!(@cli_env)

        assert File.regular?(fixture)

        open_pencil = open_pencil_info!(cli, fixture)
        summary = fixture |> File.read!() |> Figler.Scene.summary()

        assert summary.node_count == open_pencil["totalNodes"]
        assert {"canvas", canvas_count} = List.keyfind(summary.type_counts, "canvas", 0)
        assert canvas_count == open_pencil["pages"]

        figler_types = Map.new(summary.type_counts)
        open_pencil_types = normalize_type_counts(open_pencil["types"])

        for type <- ["text", "frame", "component", "instance"],
            Map.has_key?(open_pencil_types, type) do
          assert figler_types[type] == open_pencil_types[type]
        end
      end

      defp open_pencil_info!(cli, fixture) do
        {json, 0} = System.cmd("node", [cli, "info", fixture, "--json"], stderr_to_stdout: true)
        Jason.decode!(json)
      end

      defp normalize_type_counts(types) do
        Map.new(types, fn {type, count} -> {Macro.underscore(type), count} end)
      end
    else
      test "OpenPencil Node oracle tests are disabled" do
        assert System.get_env(@cli_env) in [nil, ""] or System.get_env(@fixture_env) in [nil, ""]
      end
    end
  end
end
