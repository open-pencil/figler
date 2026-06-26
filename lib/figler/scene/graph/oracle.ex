defmodule Figler.Scene.Graph.Oracle do
  @moduledoc """
  Compares resolved scene graph output against checked-in oracle fixtures.

  Oracle comparisons serialize selected graph subtrees into a stable JSON shape
  and report field-level differences for resolver validation.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Oracle.Diff
  alias Figler.Scene.Graph.Oracle.Entry
  alias Figler.Scene.Graph.Oracle.Manifest
  alias Figler.Scene.Graph.Oracle.Node, as: OracleNode

  @fields [
    :type,
    :name,
    :visible,
    :locked,
    :x,
    :y,
    :width,
    :height,
    :characters,
    :child_count
  ]

  @doc false
  def run(fixture_binary, base_dir, %Entry{} = entry) when is_binary(fixture_binary) do
    {build_us, graph} =
      :timer.tc(fn ->
        Figler.Scene.graph(fixture_binary, root: entry.node, until: :stack_layout)
      end)

    graph
    |> run(base_dir, entry)
    |> Map.put(:graph_build_ms, ms(build_us))
  end

  def run(graph, base_dir, %Entry{} = entry) do
    oracle_json = expand_path(entry.json, base_dir)
    expected = oracle_json |> File.read!() |> OracleNode.decode!()

    actual =
      graph
      |> Figler.Scene.node(entry.node)
      |> serialize(graph, entry.depth)

    diffs = compare(expected, actual, entry.node, entry.epsilon, entry.ignore_null_size)

    %{
      node: entry.node,
      depth: entry.depth,
      oracle_json: oracle_json,
      graph:
        graph
        |> Graph.stats()
        |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count]),
      diff_count: length(diffs),
      diffs: diffs
    }
  end

  @doc false
  def entries!(manifest_path) do
    manifest_path
    |> File.read!()
    |> Manifest.decode_entries!()
  end

  @doc false
  def serialize(nil, _graph, _remaining_depth), do: nil

  def serialize(node, graph, remaining_depth) do
    children =
      if remaining_depth > 0 do
        graph
        |> Figler.Scene.children(node.guid)
        |> Enum.map(&serialize(&1, graph, remaining_depth - 1))
      else
        []
      end

    %OracleNode{
      guid: node.guid,
      type: String.upcase(node.node_type || ""),
      name: node.name,
      visible: node.visible,
      locked: node.locked,
      x: get_in(node.transform || %{}, [:m02]),
      y: get_in(node.transform || %{}, [:m12]),
      width: get_in(node.size || %{}, [:x]),
      height: get_in(node.size || %{}, [:y]),
      characters: node.text,
      parent: node.parent_guid,
      child_count: length(Figler.Scene.children(graph, node.guid)),
      children: children
    }
  end

  @doc false
  def compare(expected_node, actual_node, path, epsilon \\ 0.0001, ignore_null_size? \\ true)

  def compare(expected_node, nil, path, _epsilon, _ignore_null_size?) do
    [%Diff{path: path, field: "node", figma: expected_node && expected_node.guid, figkiwi: nil}]
  end

  def compare(
        %OracleNode{} = expected_node,
        %OracleNode{} = actual_node,
        path,
        epsilon,
        ignore_null_size?
      ) do
    field_diffs =
      Enum.flat_map(@fields, fn field ->
        expected = Map.fetch!(expected_node, field)
        actual = Map.fetch!(actual_node, field)
        ignored_null_size? = ignore_null_size? and field in [:width, :height] and is_nil(expected)

        if ignored_null_size? or equal?(expected, actual, epsilon) do
          []
        else
          [%Diff{path: path, field: field_name(field), figma: expected, figkiwi: actual}]
        end
      end)

    child_count_diff =
      if length(expected_node.children) == length(actual_node.children) do
        []
      else
        [
          %Diff{
            path: path,
            field: "children.length",
            figma: length(expected_node.children),
            figkiwi: length(actual_node.children)
          }
        ]
      end

    child_diffs =
      expected_node.children
      |> Enum.zip(actual_node.children)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{expected_child, actual_child}, index} ->
        child_path = "#{path}/#{index}:#{expected_child.name}~#{actual_child.name}"
        compare(expected_child, actual_child, child_path, epsilon, ignore_null_size?)
      end)

    field_diffs ++ child_count_diff ++ child_diffs
  end

  defp expand_path(path, base_dir) do
    if Path.type(path) == :absolute,
      do: path,
      else: Path.expand(path, base_dir)
  end

  defp field_name(:child_count), do: "childCount"
  defp field_name(field), do: Atom.to_string(field)

  defp equal?(left, right, _epsilon) when left == right, do: true

  defp equal?(left, right, epsilon),
    do: is_number(left) and is_number(right) and abs(left - right) <= epsilon

  defp ms(us), do: System.convert_time_unit(us, :microsecond, :millisecond)
end
