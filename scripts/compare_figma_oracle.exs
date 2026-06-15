#!/usr/bin/env elixir

Mix.Task.run("app.start")

fixture =
  System.get_env("FIG_KIWI_ORACLE_FIXTURE") ||
    raise "set FIG_KIWI_ORACLE_FIXTURE to a .fig fixture path"

node_guid =
  System.get_env("FIG_KIWI_ORACLE_NODE") ||
    raise "set FIG_KIWI_ORACLE_NODE to the Figma node GUID/id to compare"

oracle_json =
  System.get_env("FIG_KIWI_ORACLE_JSON") ||
    raise "set FIG_KIWI_ORACLE_JSON to browser oracle JSON output"

depth =
  System.get_env("FIG_KIWI_ORACLE_DEPTH", "2")
  |> String.to_integer()

epsilon =
  System.get_env("FIG_KIWI_ORACLE_EPSILON", "0.0001")
  |> String.to_float()

ignore_null_size? = System.get_env("FIG_KIWI_ORACLE_IGNORE_NULL_SIZE", "1") != "0"

figma =
  oracle_json
  |> File.read!()
  |> Jason.decode!()

{graph_build_us, graph} =
  :timer.tc(fn ->
    fixture
    |> File.read!()
    |> FigKiwi.Scene.payload!()
    |> FigKiwi.Scene.graph(root: node_guid, until: :stack_layout)
  end)

serialize = fn rec, node, remaining_depth ->
  children =
    if remaining_depth > 0 do
      graph
      |> FigKiwi.Scene.children(node.guid)
      |> Enum.map(&rec.(rec, &1, remaining_depth - 1))
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

figkiwi =
  graph
  |> FigKiwi.Scene.node(node_guid)
  |> then(&serialize.(serialize, &1, depth))

number_equal? = fn left, right ->
  is_number(left) and is_number(right) and abs(left - right) <= epsilon
end

equal? = fn
  left, right when left == right -> true
  left, right -> number_equal?.(left, right)
end

fields = [
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

compare = fn rec, figma_node, figkiwi_node, path ->
  field_diffs =
    Enum.flat_map(fields, fn field ->
      left = Map.get(figma_node, field)
      right = Map.get(figkiwi_node, field)

      ignored_null_size? = ignore_null_size? and field in ["width", "height"] and is_nil(left)

      if ignored_null_size? or equal?.(left, right) do
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

      rec.(rec, figma_child, figkiwi_child, child_path)
    end)

  field_diffs ++ child_count_diff ++ child_diffs
end

diffs = compare.(compare, figma, figkiwi, node_guid)

summary = %{
  node: node_guid,
  depth: depth,
  graph_build_ms: System.convert_time_unit(graph_build_us, :microsecond, :millisecond),
  graph:
    FigKiwi.Scene.Graph.stats(graph)
    |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count]),
  diff_count: length(diffs)
}

IO.puts(Jason.encode!(summary, pretty: true))

if diffs == [] do
  IO.puts("Figma oracle comparison passed")
else
  IO.puts("Figma oracle comparison failed")
  IO.puts(Jason.encode!(diffs, pretty: true))
  System.halt(1)
end
