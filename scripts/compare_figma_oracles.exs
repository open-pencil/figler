#!/usr/bin/env elixir

Mix.Task.run("app.start")

fixture =
  System.get_env("FIG_KIWI_ORACLE_FIXTURE") ||
    raise "set FIG_KIWI_ORACLE_FIXTURE to an exported .fig fixture path"

manifest_path =
  System.get_env("FIG_KIWI_ORACLE_MANIFEST") ||
    List.first(System.argv()) ||
    raise "set FIG_KIWI_ORACLE_MANIFEST or pass a manifest JSON path"

base_dir = Path.dirname(Path.expand(manifest_path))

defmodule FigKiwi.OracleComparison do
  @moduledoc false

  @fields [
    "type",
    "name",
    "visible",
    "locked",
    "x",
    "y",
    "width",
    "height",
    "characters",
    "childCount"
  ]

  def run(fixture_binary, base_dir, entry) when is_binary(fixture_binary) do
    node_guid = fetch_string!(entry, "node")

    {build_us, graph} =
      :timer.tc(fn ->
        FigKiwi.Scene.graph(fixture_binary, root: node_guid, until: :stack_layout)
      end)

    graph
    |> run(base_dir, entry)
    |> Map.put(:graph_build_ms, System.convert_time_unit(build_us, :microsecond, :millisecond))
  end

  def run(graph, base_dir, entry) do
    node_guid = fetch_string!(entry, "node")
    depth = Map.get(entry, "depth", 2)
    epsilon = Map.get(entry, "epsilon", 0.0001)
    ignore_null_size? = Map.get(entry, "ignoreNullSize", true)

    oracle_json =
      entry
      |> fetch_string!("json")
      |> expand_path(base_dir)

    figma = oracle_json |> File.read!() |> Jason.decode!()

    figkiwi =
      graph
      |> FigKiwi.Scene.node(node_guid)
      |> serialize(graph, depth)

    diffs = compare(figma, figkiwi, node_guid, epsilon, ignore_null_size?)

    %{
      node: node_guid,
      depth: depth,
      oracle_json: oracle_json,
      graph:
        graph
        |> FigKiwi.Scene.Graph.stats()
        |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count]),
      diff_count: length(diffs),
      diffs: diffs
    }
  end

  defp fetch_string!(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and value != "" -> value
      _other -> raise "manifest entry must include non-empty #{inspect(key)}"
    end
  end

  defp expand_path(path, base_dir) do
    if Path.type(path) == :absolute,
      do: path,
      else: Path.expand(path, base_dir)
  end

  defp serialize(nil, _graph, _remaining_depth), do: nil

  defp serialize(node, graph, remaining_depth) do
    children =
      if remaining_depth > 0 do
        graph
        |> FigKiwi.Scene.children(node.guid)
        |> Enum.map(&serialize(&1, graph, remaining_depth - 1))
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
      "childCount" => length(FigKiwi.Scene.children(graph, node.guid)),
      "children" => children
    }
  end

  defp compare(figma_node, nil, path, _epsilon, _ignore_null_size?) do
    [%{path: path, field: "node", figma: Map.get(figma_node || %{}, "guid"), figkiwi: nil}]
  end

  defp compare(figma_node, figkiwi_node, path, epsilon, ignore_null_size?) do
    field_diffs =
      Enum.flat_map(@fields, fn field ->
        left = Map.get(figma_node, field)
        right = Map.get(figkiwi_node, field)

        ignored_null_size? = ignore_null_size? and field in ["width", "height"] and is_nil(left)

        if ignored_null_size? or equal?(left, right, epsilon) do
          []
        else
          [%{path: path, field: field, figma: left, figkiwi: right}]
        end
      end)

    figma_children = Map.get(figma_node, "children", [])
    figkiwi_children = Map.get(figkiwi_node, "children", [])

    child_count_diff =
      if length(figma_children) == length(figkiwi_children) do
        []
      else
        [
          %{
            path: path,
            field: "children.length",
            figma: length(figma_children),
            figkiwi: length(figkiwi_children)
          }
        ]
      end

    child_diffs =
      figma_children
      |> Enum.zip(figkiwi_children)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{figma_child, figkiwi_child}, index} ->
        child_path =
          "#{path}/#{index}:#{Map.get(figma_child, "name")}~#{Map.get(figkiwi_child, "name")}"

        compare(figma_child, figkiwi_child, child_path, epsilon, ignore_null_size?)
      end)

    field_diffs ++ child_count_diff ++ child_diffs
  end

  defp equal?(left, right, _epsilon) when left == right, do: true

  defp equal?(left, right, epsilon),
    do: is_number(left) and is_number(right) and abs(left - right) <= epsilon
end

entries =
  manifest_path
  |> File.read!()
  |> Jason.decode!()
  |> case do
    entries when is_list(entries) -> entries
    %{"comparisons" => entries} when is_list(entries) -> entries
    _other -> raise "oracle manifest must be a JSON array or an object with a comparisons array"
  end

fixture_payload = fixture |> File.read!() |> FigKiwi.Scene.payload!()
shared_graph? = System.get_env("FIG_KIWI_ORACLE_SHARED_GRAPH") in ["1", "true", "TRUE"]

{build_us, compare_us, results} =
  if shared_graph? do
    node_guids = Enum.map(entries, &Map.fetch!(&1, "node"))

    {build_us, graph} =
      :timer.tc(fn ->
        FigKiwi.Scene.graph(fixture_payload, root: node_guids, until: :stack_layout)
      end)

    {compare_us, results} =
      :timer.tc(fn -> Enum.map(entries, &FigKiwi.OracleComparison.run(graph, base_dir, &1)) end)

    {build_us, compare_us, results}
  else
    {total_us, results} =
      :timer.tc(fn ->
        Enum.map(entries, &FigKiwi.OracleComparison.run(fixture_payload, base_dir, &1))
      end)

    build_us =
      results
      |> Enum.map(&Map.get(&1, :graph_build_ms, 0))
      |> Enum.sum()
      |> System.convert_time_unit(:millisecond, :microsecond)

    compare_us = max(total_us - build_us, 0)
    {build_us, compare_us, results}
  end

summary = %{
  fixture: fixture,
  comparison_count: length(results),
  shared_graph: shared_graph?,
  graph_build_ms: System.convert_time_unit(build_us, :microsecond, :millisecond),
  compare_ms: System.convert_time_unit(compare_us, :microsecond, :millisecond),
  failed_count: Enum.count(results, &(&1.diff_count > 0)),
  results: Enum.map(results, &Map.delete(&1, :diffs))
}

IO.puts(Jason.encode!(summary, pretty: true))

failures = Enum.filter(results, &(&1.diff_count > 0))

if failures == [] do
  IO.puts("Figma oracle comparisons passed")
else
  IO.puts("Figma oracle comparisons failed")

  failures
  |> Enum.map(&Map.take(&1, [:node, :depth, :oracle_json, :diff_count, :diffs]))
  |> Jason.encode!(pretty: true)
  |> IO.puts()

  System.halt(1)
end
