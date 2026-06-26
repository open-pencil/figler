defmodule Figler.OpenPencilFixtureSceneTest do
  use ExUnit.Case, async: true

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
