defmodule FigKiwi.Scene.Graph.Variables do
  @moduledoc """
  Preserves variable/style references and records variable provenance.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.SeedNode

  @style_fields [
    :text_style_guid,
    :fill_style_guid,
    :stroke_style_guid,
    :effect_style_guid,
    :grid_style_guid
  ]

  @doc false
  @spec apply(Graph.t()) :: Graph.t()
  def apply(%Graph{} = graph) do
    Enum.reduce(graph.seed_nodes, graph, fn {_guid, seed}, acc ->
      unresolved = unresolved_refs(graph, seed)
      applied = applied_values(graph, seed)

      acc
      |> put_applied(seed.guid, applied)
      |> put_unresolved(seed.guid, unresolved)
    end)
  end

  defp unresolved_refs(%Graph{} = graph, %SeedNode{} = seed) do
    variable_refs(graph, seed) ++ style_refs(graph, seed)
  end

  defp applied_values(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_variables, :known) do
      false -> []
      _mode -> variable_values(seed)
    end
  end

  defp variable_refs(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_variables, :known) do
      false -> []
      _mode -> variable_refs(seed)
    end
  end

  defp variable_refs(%SeedNode{variable_consumption: []}), do: []

  defp variable_refs(%SeedNode{variable_consumption: refs}) do
    Enum.map(refs, &{:variable_ref_preserved, &1})
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
