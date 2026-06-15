defmodule FigKiwi.OracleFixtureTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene

  @fixture "test/fixtures/oracles/basic/basic.fig"
  @manifest "test/fixtures/oracles/basic/manifest.json"

  test "committed oracle fixture matches effective graph projection" do
    entries =
      @manifest
      |> File.read!()
      |> Jason.decode!()
      |> Map.fetch!("comparisons")

    fixture = File.read!(@fixture)

    assert Enum.map(entries, &diffs(fixture, Path.dirname(@manifest), &1)) == [[]]
  end

  defp diffs(fixture, base_dir, entry) do
    graph = Scene.graph(fixture, root: Map.fetch!(entry, "node"), until: :stack_layout)

    actual =
      graph |> Scene.node(Map.fetch!(entry, "node")) |> serialize(graph, entry["depth"] || 2)

    expected =
      entry
      |> Map.fetch!("json")
      |> then(&Path.expand(&1, base_dir))
      |> File.read!()
      |> Jason.decode!()

    compare(expected, actual, Map.fetch!(entry, "node"))
  end

  defp serialize(nil, _graph, _depth), do: nil

  defp serialize(node, graph, depth) do
    children =
      if depth > 0 do
        graph
        |> Scene.children(node.guid)
        |> Enum.map(&serialize(&1, graph, depth - 1))
      else
        []
      end

    %{
      "guid" => node.guid,
      "type" => String.upcase(node.node_type || ""),
      "name" => node.name,
      "visible" => node.visible,
      "locked" => node.locked,
      "x" => get_in(node.transform || %{}, [:m02]),
      "y" => get_in(node.transform || %{}, [:m12]),
      "width" => get_in(node.size || %{}, [:x]),
      "height" => get_in(node.size || %{}, [:y]),
      "characters" => node.text,
      "parent" => node.parent_guid,
      "childCount" => length(Scene.children(graph, node.guid)),
      "children" => children
    }
  end

  defp compare(expected, actual, path) when is_map(expected) and is_map(actual) do
    fields = Map.keys(expected) -- ["children"]

    field_diffs =
      fields
      |> Enum.reject(&(Map.get(expected, &1) == Map.get(actual, &1)))
      |> Enum.map(fn field -> {path, field, Map.get(expected, field), Map.get(actual, field)} end)

    expected_children = Map.get(expected, "children", [])
    actual_children = Map.get(actual, "children", [])

    child_count_diffs =
      if length(expected_children) == length(actual_children) do
        []
      else
        [{path, "children.length", length(expected_children), length(actual_children)}]
      end

    child_diffs =
      expected_children
      |> Enum.zip(actual_children)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{expected_child, actual_child}, index} ->
        compare(expected_child, actual_child, "#{path}/#{index}")
      end)

    field_diffs ++ child_count_diffs ++ child_diffs
  end
end
