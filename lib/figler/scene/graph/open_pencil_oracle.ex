defmodule Figler.Scene.Graph.OpenPencilOracle do
  @moduledoc """
  Compares effective scene graphs against OpenPencil's occurrence interpreter.

  `scripts/openpencil_oracle.ts` runs OpenPencil's reader on a `.fig` file and
  prints each page's interpreted tree. This module builds the same projection
  from a Figler graph and reports field-level differences, aligning children by
  their saved order.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID

  @fields ["source_id", "type", "name", "visible", "main_component_id", "size", "position"] ++
            ["opacity", "characters"]

  @type diff :: %{path: String.t(), field: String.t(), openpencil: term(), figler: term()}

  @doc """
  Runs OpenPencil's reader on `fig_path` through `bun` and decodes its output.

  Options:

    * `:openpencil` - OpenPencil checkout with installed dependencies. Defaults to
      `FIGLER_OPENPENCIL_DIR` or `../open-pencil-app`.
    * `:pages` - page GUID strings to read. Defaults to every visible page.
  """
  @spec expected!(Path.t(), keyword()) :: map()
  def expected!(fig_path, opts \\ []) do
    openpencil =
      Keyword.get_lazy(opts, :openpencil, fn ->
        System.get_env("FIGLER_OPENPENCIL_DIR", "../open-pencil-app")
      end)

    pages = Enum.flat_map(Keyword.get(opts, :pages, []), &["--page", &1])
    script = Path.expand("../../../../scripts/openpencil_oracle.ts", __DIR__)
    args = [script, "--openpencil", openpencil, fig_path] ++ pages

    case System.cmd("bun", args, stderr_to_stdout: false) do
      {output, 0} -> JSON.decode!(output)
      {output, status} -> raise "OpenPencil oracle exited with #{status}: #{output}"
    end
  end

  @doc """
  Compares every page in `expected` against `graph`.
  """
  @spec compare(Graph.t(), map()) :: %{pages: [map()], diffs: [diff()], by_field: map()}
  def compare(%Graph{} = graph, %{"pages" => pages}) do
    page_results =
      Enum.map(pages, fn %{"id" => id, "name" => name, "tree" => tree} ->
        diffs = compare_node(tree, project(graph, Figler.Scene.node(graph, id)), name)
        %{id: id, name: name, diff_count: length(diffs), diffs: diffs}
      end)

    diffs = Enum.flat_map(page_results, & &1.diffs)
    %{pages: page_results, diffs: diffs, by_field: Enum.frequencies_by(diffs, & &1.field)}
  end

  @doc """
  Projects a graph node and its descendants into the oracle's shape.
  """
  @spec project(Graph.t(), Figler.Scene.Node.t() | nil) :: map() | nil
  def project(_graph, nil), do: nil

  def project(%Graph{} = graph, node) do
    type = String.upcase(node.node_type || "")

    %{
      "source_id" => source_id(node.guid),
      "type" => type,
      "name" => node.name,
      "visible" => node.visible != false,
      "size" => node.size && [node.size.x, node.size.y],
      "position" => node.transform && [node.transform.m02, node.transform.m12],
      "opacity" => if(node.opacity not in [nil, 1, 1.0], do: node.opacity),
      "characters" => if(type == "TEXT", do: node.text || ""),
      "main_component_id" => main_component_id(graph, type, node.guid),
      "children" => graph |> Figler.Scene.children(node.guid) |> Enum.map(&project(graph, &1))
    }
  end

  defp source_id(guid), do: guid |> GUID.parse!() |> GUID.leaf() |> GUID.format()

  defp main_component_id(graph, "INSTANCE", guid) do
    case Graph.instance(graph, guid) do
      %{component_guid: component_guid} -> component_guid
      nil -> nil
    end
  end

  defp main_component_id(_graph, _type, _guid), do: nil

  defp compare_node(expected, nil, path),
    do: [diff(path, "node", expected["source_id"], nil)]

  defp compare_node(expected, actual, path) do
    field_diffs =
      for field <- @fields,
          Map.has_key?(expected, field) or not is_nil(actual[field]),
          not equal?(expected[field], actual[field]),
          do: diff(path, field, expected[field], actual[field])

    expected_children = Map.get(expected, "children", [])
    actual_children = actual["children"]

    {pairs, missing, extra} = align_children(expected_children, actual_children)

    structure_diffs =
      if Map.has_key?(expected, "children") do
        Enum.map(missing, &diff(path, "missing_child", child_label(&1), nil)) ++
          Enum.map(extra, &diff(path, "extra_child", nil, child_label(&1))) ++
          order_diff(path, pairs)
      else
        []
      end

    child_diffs =
      Enum.flat_map(pairs, fn {{expected_child, index}, {actual_child, _actual_index}} ->
        compare_node(expected_child, actual_child, "#{path}/#{index}:#{expected_child["name"]}")
      end)

    field_diffs ++ structure_diffs ++ child_diffs
  end

  # Children pair by source id in saved order, so one missing or reordered layer
  # does not misalign every sibling after it.
  defp align_children(expected, actual) do
    available =
      actual
      |> Enum.with_index()
      |> Enum.group_by(fn {child, _index} -> child["source_id"] end)

    {pairs, unmatched} =
      expected
      |> Enum.with_index()
      |> Enum.map_reduce(available, &take_match/2)

    {matched, missing} = Enum.split_with(pairs, fn {_entry, match} -> match end)

    extra =
      unmatched
      |> Map.values()
      |> List.flatten()
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.map(&elem(&1, 0))

    {matched, Enum.map(missing, fn {{child, _index}, nil} -> child end), extra}
  end

  defp take_match({child, _index} = entry, available) do
    case Map.get(available, child["source_id"], []) do
      [match | rest] -> {{entry, match}, Map.put(available, child["source_id"], rest)}
      [] -> {{entry, nil}, available}
    end
  end

  defp order_diff(path, pairs) do
    actual_order = Enum.map(pairs, fn {_expected, {_child, index}} -> index end)

    if actual_order == Enum.sort(actual_order),
      do: [],
      else: [diff(path, "children.order", nil, actual_order)]
  end

  defp child_label(child), do: "#{child["source_id"]} #{child["name"]}"

  defp diff(path, field, expected, actual),
    do: %{path: path, field: field, openpencil: expected, figler: actual}

  defp equal?(same, same), do: true
  defp equal?([a, b], [c, d]), do: equal?(a, c) and equal?(b, d)
  defp equal?(a, b) when is_number(a) and is_number(b), do: abs(a - b) <= 0.01
  defp equal?(_a, _b), do: false
end
