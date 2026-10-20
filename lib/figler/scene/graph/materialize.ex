defmodule Figler.Scene.Graph.Materialize do
  @moduledoc false

  # Builds the effective graph from interpreted occurrence trees.
  #
  # Every page is interpreted on its own, as OpenPencil reads pages. Layers
  # inside an instance expansion get clone GUIDs that append each source GUID
  # to the path from the outermost instance, so every occurrence has its own
  # identity. Records outside the document tree become roots of their own.

  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Occurrence
  alias Figler.Scene.Graph.Occurrence.GUID, as: OccurrenceGUID
  alias Figler.Scene.Graph.Occurrence.Interpreter
  alias Figler.Scene.Graph.Occurrence.SourceIndex
  alias Figler.Scene.Node

  defmodule Acc do
    @moduledoc false
    defstruct nodes: %{},
              records: %{},
              children: %{},
              roots: [],
              by_type: %{},
              by_name: %{},
              provenance: %{},
              unresolved: []
  end

  @doc """
  Interprets every root of `index` and returns graph fields.
  """
  @spec graph(SourceIndex.t()) :: map()
  def graph(%SourceIndex{} = index) do
    acc =
      index
      |> root_ids()
      |> Enum.reduce(%Acc{}, &put_root(&2, index, &1))

    %{
      nodes: acc.nodes,
      records: acc.records,
      children:
        Map.new(acc.children, fn {parent, children} -> {parent, Enum.reverse(children)} end),
      roots: Enum.reverse(acc.roots),
      by_type: reverse_values(acc.by_type),
      by_name: reverse_values(acc.by_name),
      provenance: acc.provenance,
      unresolved: acc.unresolved |> Enum.reverse() |> Enum.concat()
    }
  end

  # Records without a parent in the index, in GUID order.
  defp root_ids(index) do
    index.sources
    |> Enum.filter(fn {_id, record} ->
      not Map.has_key?(index.sources, SourceIndex.parent_id(record))
    end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  # A document holds pages, which are interpreted one by one.
  defp put_root(acc, index, id) do
    record = Map.fetch!(index.sources, id)
    acc = %{acc | roots: [id | acc.roots]}

    if Map.get(record, :type) == :document do
      acc = put_node(acc, id, record, nil, nil)

      index
      |> SourceIndex.children(id)
      |> Enum.reduce(acc, &put_interpreted(&2, index, SourceIndex.id(&1), id))
    else
      put_interpreted(acc, index, id, nil)
    end
  end

  defp put_interpreted(acc, index, id, parent) do
    {occurrence, diagnostics} = Interpreter.interpret(index, id)
    acc = %{acc | unresolved: [diagnostics | acc.unresolved]}
    put_occurrence(acc, occurrence, id, parent, nil)
  end

  defp put_occurrence(acc, %Occurrence{} = occurrence, guid, parent, owner) do
    acc = put_node(acc, guid, occurrence.properties, parent, provenance(occurrence, guid, owner))
    child_owner = if Occurrence.instance?(occurrence), do: guid, else: owner

    Enum.reduce(occurrence.children, acc, fn child, acc ->
      put_occurrence(acc, child, child_guid(guid, occurrence, child), guid, child_owner)
    end)
  end

  # Layers of an instance expansion, and everything below them, are clones.
  defp child_guid({:clone, _root, _path} = guid, _occurrence, child),
    do: GUID.append(guid, child.source_id)

  defp child_guid(guid, occurrence, child) do
    if Occurrence.instance?(occurrence),
      do: GUID.append(guid, child.source_id),
      else: child.source_id
  end

  defp put_node(acc, guid, record, parent, provenance) do
    node = node(record, guid, parent)

    %{
      acc
      | nodes: Map.put(acc.nodes, guid, node),
        records: Map.put(acc.records, guid, record),
        children: put_child(acc.children, parent, guid),
        by_type: prepend(acc.by_type, node.node_type, guid),
        by_name: prepend(acc.by_name, node.name, guid),
        provenance: put_provenance(acc.provenance, guid, provenance)
    }
  end

  defp put_child(children, nil, _guid), do: children
  defp put_child(children, parent, guid), do: Map.update(children, parent, [guid], &[guid | &1])

  defp prepend(index, nil, _guid), do: index
  defp prepend(index, key, guid), do: Map.update(index, key, [guid], &[guid | &1])

  defp put_provenance(provenance, _guid, nil), do: provenance
  defp put_provenance(provenance, guid, entry), do: Map.put(provenance, guid, entry)

  defp reverse_values(index),
    do: Map.new(index, fn {key, guids} -> {key, Enum.reverse(guids)} end)

  # Source nodes keep the default projected provenance unless they are
  # instances or carry claims; every clone records where it came from.
  defp provenance(%Occurrence{} = occurrence, guid, owner) do
    clone? = match?({:clone, _root, _path}, guid)
    instance? = Occurrence.instance?(occurrence)

    if clone? or instance? or occurrence.property_claims != [] or occurrence.binding_claims != [] do
      %{
        source: if(clone?, do: :instance_clone, else: :source),
        source_guid: occurrence.source_id,
        instance_guid: owner,
        component_guid: occurrence.main_component_id,
        applied: Enum.map(occurrence.property_claims, &claim/1),
        bindings: occurrence.binding_claims,
        unresolved: []
      }
    end
  end

  defp claim(%{declared_by: declared_by, path: path, properties: properties}) do
    %{declared_by: declared_by, path: path, fields: properties |> Map.keys() |> Enum.sort()}
  end

  @doc """
  Projects an effective sparse record into a scene node. GUIDs stay graph
  GUIDs; `Figler.Scene.Query.public_node/1` formats them.
  """
  @spec node(map(), GUID.graph_guid(), GUID.graph_guid() | nil) :: Node.t()
  def node(record, guid, parent) do
    text_data = Map.get(record, :text_data) || %{}
    font_name = Map.get(record, :font_name) || %{}

    %Node{
      guid: guid,
      node_type: record |> Map.get(:type) |> node_type(),
      name: Map.get(record, :name),
      parent_guid: parent,
      position: get_in(record, [:parent_index, :position]),
      size: vector(Map.get(record, :size)),
      transform: matrix(Map.get(record, :transform)),
      visible: Map.get(record, :visible),
      locked: Map.get(record, :locked),
      opacity: Map.get(record, :opacity),
      text: Map.get(text_data, :characters),
      font_family: Map.get(font_name, :family),
      font_style: Map.get(font_name, :style),
      font_postscript: Map.get(font_name, :postscript),
      font_size: Map.get(record, :font_size),
      text_style_guid: style_guid(Map.get(record, :style_id_for_text)),
      component_key: Map.get(record, :component_key),
      origin_component_key: Map.get(record, :origin_component_key),
      fill_style_guid: style_guid(Map.get(record, :style_id_for_fill)),
      stroke_style_guid: style_guid(Map.get(record, :style_id_for_stroke_fill)),
      effect_style_guid: style_guid(Map.get(record, :style_id_for_effect)),
      grid_style_guid: style_guid(Map.get(record, :style_id_for_grid)),
      fill_count: count(Map.get(record, :fill_paints)),
      stroke_count: count(Map.get(record, :stroke_paints))
    }
  end

  defp node_type(nil), do: nil
  defp node_type(type) when is_atom(type), do: Atom.to_string(type)
  defp node_type(type), do: type |> to_string() |> Macro.underscore()

  defp vector(%{x: x, y: y}), do: %{x: x, y: y}
  defp vector(_value), do: nil

  defp matrix(%{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}),
    do: %{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}

  defp matrix(_value), do: nil

  defp style_guid(%{guid: guid}), do: guid |> OccurrenceGUID.key() |> GUID.format()
  defp style_guid(_style), do: nil

  defp count(values) when is_list(values), do: length(values)
  defp count(_values), do: nil
end
