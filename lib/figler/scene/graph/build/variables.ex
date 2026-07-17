defmodule Figler.Scene.Graph.Build.Variables do
  @moduledoc """
  Preserves variable/style references and records variable provenance.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode

  @style_fields [
    :text_style_guid,
    :fill_style_guid,
    :stroke_style_guid,
    :effect_style_guid,
    :grid_style_guid
  ]

  @doc """
  Applies variable/style resolution policy to graph provenance.

  Known variable data is recorded as applied provenance. Preserved or unknown
  references are recorded as unresolved diagnostics according to graph options.
  """
  @spec apply(Graph.t()) :: Graph.t()
  def apply(%Graph{} = graph) do
    Enum.reduce(graph.seed_nodes, graph, fn {_guid, seed}, acc -> apply_seed(acc, seed) end)
  end

  defp apply_seed(%Graph{} = graph, seed) do
    if relevant?(graph, seed) do
      {graph, variable_applied, variable_unresolved} = apply_variable_refs(graph, seed)
      unresolved = Enum.reverse(variable_unresolved, style_refs(graph, seed))
      applied = Enum.reverse(variable_applied, variable_values(graph, seed))

      graph
      |> put_applied(seed.guid, applied)
      |> put_unresolved(seed.guid, unresolved)
    else
      graph
    end
  end

  defp relevant?(%Graph{options: options}, seed) do
    variables? =
      Keyword.get(options, :resolve_variables, :known) != false and
        (seed.variable_consumption != [] or seed.variable_data_values != [])

    styles? =
      Keyword.get(options, :resolve_styles, false) != false and
        Enum.any?(@style_fields, &(not is_nil(Map.get(seed, &1))))

    variables? or styles?
  end

  defp apply_variable_refs(%Graph{options: options} = graph, seed) do
    case Keyword.get(options, :resolve_variables, :known) do
      false -> {graph, [], []}
      mode -> apply_variable_refs(graph, seed, seed.variable_consumption, mode)
    end
  end

  defp apply_variable_refs(%Graph{} = graph, _seed, [], _mode), do: {graph, [], []}

  defp apply_variable_refs(%Graph{} = graph, seed, refs, :preserve) do
    Enum.reduce(refs, {graph, [], []}, fn ref, {acc, applied, unresolved} ->
      case apply_variable_ref(acc, seed, ref) do
        {:ok, next, item} -> {next, [item | applied], unresolved}
        :unknown -> {acc, applied, [{:variable_ref_preserved, ref} | unresolved]}
      end
    end)
  end

  defp apply_variable_refs(%Graph{} = graph, seed, refs, _mode) do
    Enum.reduce(refs, {graph, [], []}, fn ref, {acc, applied, unresolved} ->
      case apply_variable_ref(acc, seed, ref) do
        {:ok, next, item} -> {next, [item | applied], unresolved}
        :unknown -> {acc, applied, unresolved}
      end
    end)
  end

  defp variable_values(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_variables, :known) do
      false -> []
      _mode -> variable_values(seed)
    end
  end

  defp variable_values(%SeedNode{variable_data_values: []}), do: []

  defp variable_values(%SeedNode{variable_data_values: values}) do
    values
    |> Enum.map(&variable_value/1)
    |> Enum.reject(&is_nil/1)
  end

  defp variable_value(entry) do
    case known_variable_data(get(entry, :variable_data)) do
      {:ok, value} -> {:variable_value_resolved, entry |> get(:mode_id) |> guid_string(), value}
      :unknown -> nil
    end
  end

  defp known_variable_data(nil), do: :unknown

  defp known_variable_data(data) do
    value = get(data, :value)
    data_type = get(data, :data_type)
    resolved_data_type = get(data, :resolved_data_type)

    with {:ok, value} <- known_variable_value(value) do
      {:ok, %{value: value, data_type: data_type, resolved_data_type: resolved_data_type}}
    end
  end

  defp known_variable_value(nil), do: :unknown

  defp known_variable_value(value) do
    cond do
      is_boolean(get(value, :bool_value)) -> {:ok, {:bool, get(value, :bool_value)}}
      is_binary(get(value, :text_value)) -> {:ok, {:text, get(value, :text_value)}}
      is_number(get(value, :float_value)) -> {:ok, {:float, get(value, :float_value)}}
      vector = vector(get(value, :vector_value)) -> {:ok, {:vector, vector}}
      color = color(get(value, :color_value)) -> {:ok, {:color, color}}
      true -> :unknown
    end
  end

  defp apply_variable_ref(%Graph{} = graph, seed, ref) do
    field = get(ref, :variable_field)

    with {:ok, data} <- known_variable_data(get(ref, :variable_data)),
         {:ok, next, old, new} <- apply_known_value(graph, seed.guid, field, data.value) do
      {:ok, next, {:variable_value_applied, field, old, new, data}}
    else
      _value -> :unknown
    end
  end

  defp apply_known_value(%Graph{} = graph, guid, :visible, {:bool, value}) do
    update_node(graph, guid, :visible, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :text_data, {:text, value}) do
    update_node(graph, guid, :text, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :width, {:float, value}) do
    update_node(graph, guid, :size, fn size ->
      size = size || %{}
      {Map.get(size, :x), Map.put(size, :x, value), value}
    end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :height, {:float, value}) do
    update_node(graph, guid, :size, fn size ->
      size = size || %{}
      {Map.get(size, :y), Map.put(size, :y, value), value}
    end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :font_family, {:text, value}) do
    update_node(graph, guid, :font_family, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :font_style, {:text, value}) do
    update_node(graph, guid, :font_style, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :font_size, {:float, value}) do
    update_node(graph, guid, :font_size, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :opacity, {:float, value}) do
    update_node(graph, guid, :opacity, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :stack_spacing, {:float, value}) do
    update_seed_node(graph, guid, :stack_spacing, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :stack_padding_left, {:float, value}) do
    update_seed_node(graph, guid, :stack_horizontal_padding, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :stack_padding_top, {:float, value}) do
    update_seed_node(graph, guid, :stack_vertical_padding, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :stack_padding_right, {:float, value}) do
    update_seed_node(graph, guid, :stack_padding_right, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :stack_padding_bottom, {:float, value}) do
    update_seed_node(graph, guid, :stack_padding_bottom, fn old -> {old, value, value} end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :x_position, {:float, value}) do
    update_node(graph, guid, :transform, fn transform ->
      transform = transform || %{}
      {Map.get(transform, :m02), Map.put(transform, :m02, value), value}
    end)
  end

  defp apply_known_value(%Graph{} = graph, guid, :y_position, {:float, value}) do
    update_node(graph, guid, :transform, fn transform ->
      transform = transform || %{}
      {Map.get(transform, :m12), Map.put(transform, :m12, value), value}
    end)
  end

  defp apply_known_value(_graph, _guid, _field, _value), do: :unknown

  defp update_node(%Graph{} = graph, guid, field, fun) do
    case Map.fetch(graph.nodes, guid) do
      {:ok, node} ->
        {old, new_field_value, new_applied_value} = fun.(Map.get(node, field))
        next_node = Map.put(node, field, new_field_value)

        {:ok, %Graph{graph | nodes: Map.put(graph.nodes, guid, next_node)}, old,
         new_applied_value}

      :error ->
        :unknown
    end
  end

  defp update_seed_node(%Graph{} = graph, guid, field, fun) do
    case Map.fetch(graph.seed_nodes, guid) do
      {:ok, seed} ->
        {old, new_field_value, new_applied_value} = fun.(Map.get(seed, field))
        next_seed = Map.put(seed, field, new_field_value)

        next_nodes =
          if Map.has_key?(graph.nodes, guid) do
            Map.update!(graph.nodes, guid, &Map.put(&1, field, new_field_value))
          else
            graph.nodes
          end

        {:ok,
         %Graph{
           graph
           | seed_nodes: Map.put(graph.seed_nodes, guid, next_seed),
             nodes: next_nodes
         }, old, new_applied_value}

      :error ->
        :unknown
    end
  end

  defp style_refs(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_styles, false) do
      false -> []
      _mode -> style_refs(seed)
    end
  end

  defp style_refs(seed) do
    @style_fields
    |> Enum.flat_map(fn field ->
      case Map.get(seed, field) do
        nil -> []
        guid -> [{:style_ref_preserved, field, guid}]
      end
    end)
  end

  defp put_applied(%Graph{} = graph, _guid, []), do: graph

  defp put_applied(%Graph{} = graph, guid, applied) do
    provenance =
      Map.update(graph.provenance, guid, %{applied: applied, unresolved: []}, fn existing ->
        Map.update(existing, :applied, applied, &(applied ++ &1))
      end)

    %Graph{graph | provenance: provenance}
  end

  defp put_unresolved(%Graph{} = graph, _guid, []), do: graph

  defp put_unresolved(%Graph{} = graph, guid, unresolved) do
    provenance =
      Map.update(graph.provenance, guid, %{applied: [], unresolved: unresolved}, fn existing ->
        Map.update(existing, :unresolved, unresolved, &(unresolved ++ &1))
      end)

    %Graph{graph | provenance: provenance, unresolved: unresolved ++ graph.unresolved}
  end

  defp vector(nil), do: nil
  defp vector(%{x: x, y: y}), do: %{x: x, y: y}
  defp vector(_value), do: nil

  defp color(nil), do: nil
  defp color(%{r: r, g: g, b: b, a: a}), do: %{r: r, g: g, b: b, a: a}
  defp color(_value), do: nil

  defp guid_string(nil), do: nil

  defp guid_string(%{session_id: _session_id, local_id: _local_id} = guid),
    do: guid |> guid() |> GUID.format()

  defp guid_string(value), do: value

  defp guid(%{session_id: session_id, local_id: local_id}), do: {session_id, local_id}

  defp get(nil, _key), do: nil
  defp get(map, key) when is_map(map), do: Map.get(map, key)
end
