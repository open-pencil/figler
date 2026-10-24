defmodule Figler.Scene.Graph.OpenPencilOracle do
  @moduledoc """
  Compares effective scene graphs against OpenPencil's occurrence interpreter.

  `scripts/openpencil_oracle.ts` runs OpenPencil's reader on a `.fig` file and
  prints each page's interpreted tree. This module builds the same projection
  from a Figler graph and reports field-level differences, aligning children by
  their saved order.

  With `scene: true`, OpenPencil materializes the document into its scene
  graph, which also resolves variables, modes, and styles, and the comparison
  covers resolved paints, text, and layout values (see `project_scene/2`).
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID

  @fields ["source_id", "type", "name", "visible", "main_component_id", "size", "position"] ++
            ["opacity", "characters", "font_size", "fills", "strokes", "stroke_weight"] ++
            ["corner_radius", "item_spacing", "padding"]

  @type diff :: %{path: String.t(), field: String.t(), openpencil: term(), figler: term()}

  @doc """
  Runs OpenPencil's reader on `fig_path` through `bun` and decodes its output.

  Options:

    * `:openpencil` - OpenPencil checkout with installed dependencies. Defaults to
      `FIGLER_OPENPENCIL_DIR` or `../open-pencil-app`.
    * `:pages` - page GUID strings to read. Defaults to every visible page.
    * `:scene` - dump OpenPencil's materialized scene graph instead of its
      interpreted occurrence trees.
  """
  @spec expected!(Path.t(), keyword()) :: map()
  def expected!(fig_path, opts \\ []) do
    openpencil =
      Keyword.get_lazy(opts, :openpencil, fn ->
        System.get_env("FIGLER_OPENPENCIL_DIR", "../open-pencil-app")
      end)

    pages = Enum.flat_map(Keyword.get(opts, :pages, []), &["--page", &1])
    script = Path.expand("../../../../scripts/openpencil_oracle.ts", __DIR__)
    scene = if Keyword.get(opts, :scene, false), do: ["--scene"], else: []
    args = [script, "--openpencil", openpencil, fig_path] ++ pages ++ scene

    case System.cmd("bun", args, stderr_to_stdout: false) do
      {output, 0} -> JSON.decode!(output)
      {output, status} -> raise "OpenPencil oracle exited with #{status}: #{output}"
    end
  end

  @doc """
  Compares every page in `expected` against `graph`.
  """
  @spec compare(Graph.t(), map()) :: %{pages: [map()], diffs: [diff()], by_field: map()}
  def compare(%Graph{} = graph, expected),
    do: compare_projected(expected, &project(graph, Figler.Scene.node(graph, &1)))

  @doc """
  Compares every page in `expected` against trees already in the oracle's
  shape, which `actual` returns for a page GUID string.
  """
  @spec compare_projected(map(), (String.t() -> map() | nil)) ::
          %{pages: [map()], diffs: [diff()], by_field: map()}
  def compare_projected(%{"pages" => pages}, actual) do
    page_results =
      Enum.map(pages, fn %{"id" => id, "name" => name, "tree" => tree} ->
        diffs = compare_node(tree, actual.(id), name)
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

  @doc """
  Compares every page of OpenPencil's materialized scene against `graph`.
  """
  @spec compare_scene(Graph.t(), map()) :: %{pages: [map()], diffs: [diff()], by_field: map()}
  def compare_scene(%Graph{} = graph, expected) do
    compare_projected(expected, fn page ->
      project_scene(graph, Graph.node_at(graph, GUID.parse!(page)))
    end)
  end

  @doc """
  Projects a graph node's resolved values into the scene oracle's shape.

  OpenPencil's scene graph keeps source identity on layers built from source
  records but not on components, instances, or anything inside them, which
  pair by position.
  Defaults follow OpenPencil's record conversion.
  """
  @spec project_scene(Graph.t(), Figler.Scene.Node.t()) :: map()
  def project_scene(%Graph{} = graph, node, expanded? \\ false) do
    record = Graph.record_at(graph, node.guid) || %{}
    type = scene_type(record)
    strokes = paints(Map.get(record, :stroke_paints))
    expanded? = expanded? or type in ["INSTANCE", "SYMBOL"]

    %{
      "source_id" => if(expanded?, do: nil, else: GUID.format(node.guid)),
      "type" => type,
      "name" => Map.get(record, :name),
      "visible" => Map.get(record, :visible, true),
      "opacity" => if(Map.get(record, :opacity, 1) not in [1, 1.0], do: record.opacity),
      "fills" => paints(Map.get(record, :fill_paints)),
      "strokes" => strokes,
      "stroke_weight" => if(strokes != [], do: Map.get(record, :stroke_weight, 1)),
      "corner_radius" => nonzero(Map.get(record, :corner_radius)),
      "children" =>
        graph
        |> Graph.nodes_at(Graph.child_guids(graph, node.guid))
        |> Enum.map(&project_scene(graph, &1, expanded?))
    }
    |> Map.merge(scene_geometry(type, record))
    |> Map.merge(scene_text(type, record))
    |> Map.merge(scene_layout(record))
  end

  # OpenPencil's node types: a frame with variant properties is a component set,
  # and one that resizes to fit its children without auto layout is a group.
  defp scene_type(%{type: :frame} = record) do
    cond do
      Enum.any?(
        List.wrap(Map.get(record, :component_prop_defs)),
        &(Map.get(&1, :type) == :variant)
      ) ->
        "COMPONENT_SET"

      Map.get(record, :resize_to_fit) == true and Map.get(record, :stack_mode) in [nil, :none] ->
        "GROUP"

      true ->
        "FRAME"
    end
  end

  defp scene_type(%{type: :regular_polygon}), do: "POLYGON"
  defp scene_type(%{type: :text_path}), do: "TEXT"
  defp scene_type(record), do: record |> Map.get(:type) |> to_string() |> String.upcase()

  defp scene_geometry("CANVAS", _record), do: %{}

  defp scene_geometry(_type, record) do
    size = Map.get(record, :size) || %{x: 0, y: 0}
    transform = Map.get(record, :transform) || %{m02: 0, m12: 0}
    %{"size" => [size.x, size.y], "position" => [transform.m02, transform.m12]}
  end

  defp scene_text("TEXT", record) do
    %{
      "characters" => get_in(record, [:text_data, :characters]) || "",
      "font_size" => Map.get(record, :font_size, 14)
    }
  end

  defp scene_text(_type, _record), do: %{}

  # OpenPencil lays out horizontal and vertical stacks; grids read as no layout.
  defp scene_layout(%{stack_mode: mode} = record) when mode in [:horizontal, :vertical] do
    base = Map.get(record, :stack_padding, 0)

    %{
      "item_spacing" => Map.get(record, :stack_spacing, 0),
      "padding" => [
        Map.get(record, :stack_vertical_padding, base),
        Map.get(record, :stack_padding_right, base),
        Map.get(record, :stack_padding_bottom, base),
        Map.get(record, :stack_horizontal_padding, base)
      ]
    }
  end

  defp scene_layout(_record), do: %{}

  defp nonzero(value) when value in [nil, 0, 0.0], do: nil
  defp nonzero(value), do: value

  # Visible solid paints as `#rrggbbaa`, with `@opacity` when not opaque.
  defp paints(paints) do
    for %{type: :solid, color: color} = paint <- List.wrap(paints),
        Map.get(paint, :visible, true) != false do
      alpha =
        case Map.get(paint, :opacity) do
          opacity when opacity in [nil, 1, 1.0] -> ""
          opacity -> "@#{format_number(opacity)}"
        end

      "#" <> hex(color.r) <> hex(color.g) <> hex(color.b) <> hex(Map.get(color, :a, 1)) <> alpha
    end
  end

  defp hex(value) do
    value
    |> max(0)
    |> min(1)
    |> Kernel.*(255)
    |> round()
    |> Integer.to_string(16)
    |> String.downcase()
    |> String.pad_leading(2, "0")
  end

  # Matches JavaScript's `Number(x.toFixed(3))` rendering.
  defp format_number(value) do
    rounded = Float.round(value * 1.0, 3)

    if rounded == trunc(rounded),
      do: Integer.to_string(trunc(rounded)),
      else: Float.to_string(rounded)
  end

  @doc """
  Projects an occurrence tree, as the native `graph_interpret/3` returns it, into the
  oracle's shape.
  """
  @spec project_occurrence(map()) :: map()
  def project_occurrence(%{properties: properties} = occurrence) do
    type = properties |> Map.get(:type) |> to_string() |> String.upcase()
    size = Map.get(properties, :size)
    transform = Map.get(properties, :transform)
    opacity = Map.get(properties, :opacity)

    %{
      "source_id" => GUID.format(occurrence.source_id),
      "type" => type,
      "name" => Map.get(properties, :name),
      "visible" => Map.get(properties, :visible, true),
      "size" => size && [size.x, size.y],
      "position" => transform && [transform.m02, transform.m12],
      "opacity" => if(opacity not in [nil, 1, 1.0], do: opacity),
      "characters" => if(type == "TEXT", do: get_in(properties, [:text_data, :characters]) || ""),
      "main_component_id" =>
        if(type == "INSTANCE", do: GUID.format(occurrence.main_component_id)),
      "children" => Enum.map(occurrence.children, &project_occurrence/1)
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

  defp equal?(left, right)
       when is_list(left) and is_list(right) and length(left) == length(right),
       do: left |> Enum.zip(right) |> Enum.all?(fn {a, b} -> equal?(a, b) end)

  defp equal?(a, b) when is_number(a) and is_number(b), do: abs(a - b) <= 0.01
  defp equal?(_a, _b), do: false
end
