defmodule Figler.Inspect do
  @moduledoc """
  Shared formatting helpers for generated Figma schema inspect protocols.

  The protocol implementations in this file keep large generated structs
  readable in IEx and test failures by showing the identity and populated field
  counts instead of dumping every schema field.
  """

  def guid(%Figler.Schema.GUID{session_id: session_id, local_id: local_id}) do
    "#{session_id}:#{local_id}"
  end

  def guid(nil), do: "nil"

  def present_fields(%module{} = struct) do
    fields = module.__kiwi_metadata__().ordered_fields
    values = Map.from_struct(struct)

    present =
      Enum.count(fields, fn field ->
        not is_nil(Map.get(values, field.name))
      end)

    {present, length(fields)}
  end

  def compact_name(nil), do: nil
  def compact_name(""), do: nil
  def compact_name(name) when is_binary(name), do: inspect(name)

  def compact_atom(value) when is_atom(value), do: Atom.to_string(value)
  def compact_atom(value), do: inspect(value)

  def put_part(parts, nil), do: parts
  def put_part(parts, part), do: [part | parts]

  def join_parts(parts) do
    parts
    |> Enum.reverse()
    |> Enum.join(" ")
  end
end

for module <- [
      Figler.Schema.GUID,
      Figler.Schema.ParentIndex,
      Figler.Schema.Vector,
      Figler.Schema.Matrix,
      Figler.Schema.NodeChange
    ] do
  Code.ensure_compiled!(module)
end

alias Inspect.Algebra, as: Algebra

defimpl Inspect, for: Figler.Schema.GUID do
  def inspect(guid, _opts) do
    Algebra.concat(["#Figler.Schema.GUID<", Figler.Inspect.guid(guid), ">"])
  end
end

defimpl Inspect, for: Figler.Schema.ParentIndex do
  def inspect(parent_index, opts) do
    Algebra.concat([
      "#Figler.Schema.ParentIndex<parent=",
      Inspect.Algebra.to_doc(parent_index.guid, opts),
      " pos=",
      to_string(parent_index.position),
      ">"
    ])
  end
end

defimpl Inspect, for: Figler.Schema.Vector do
  def inspect(vector, _opts) do
    Algebra.concat([
      "#Figler.Schema.Vector<x=",
      inspect(vector.x),
      " y=",
      inspect(vector.y),
      ">"
    ])
  end
end

defimpl Inspect, for: Figler.Schema.Matrix do
  def inspect(matrix, _opts) do
    values = [matrix.m00, matrix.m01, matrix.m02, matrix.m10, matrix.m11, matrix.m12]

    Algebra.concat([
      "#Figler.Schema.Matrix<",
      values |> Enum.map_join(",", &inspect/1),
      ">"
    ])
  end
end

defimpl Inspect, for: Figler.Schema.NodeChange do
  def inspect(node, _opts) do
    {present, total} = Figler.Inspect.present_fields(node)

    parts =
      []
      |> Figler.Inspect.put_part(Figler.Inspect.compact_atom(node.type))
      |> Figler.Inspect.put_part(Figler.Inspect.compact_name(node.name))
      |> Figler.Inspect.put_part(if(node.guid, do: "guid=#{Figler.Inspect.guid(node.guid)}"))
      |> Figler.Inspect.put_part(
        if(node.parent_index, do: "parent=#{Figler.Inspect.guid(node.parent_index.guid)}")
      )
      |> Figler.Inspect.put_part("present=#{present}/#{total}")
      |> Figler.Inspect.join_parts()

    Algebra.concat(["#Figler.Schema.NodeChange<", parts, ">"])
  end
end

defimpl Inspect, for: Figler.Scene.Node do
  def inspect(node, _opts) do
    parts =
      []
      |> Figler.Inspect.put_part(to_string(node.node_type))
      |> Figler.Inspect.put_part(Figler.Inspect.compact_name(node.name))
      |> Figler.Inspect.put_part(node.guid)
      |> Figler.Inspect.put_part(if(node.parent_guid, do: "parent=#{node.parent_guid}"))
      |> Figler.Inspect.put_part(if(node.position, do: "pos=#{node.position}"))
      |> Figler.Inspect.put_part(size(node.size))
      |> Figler.Inspect.put_part(if(is_boolean(node.visible), do: "visible=#{node.visible}"))
      |> Figler.Inspect.put_part(if(is_boolean(node.locked), do: "locked=#{node.locked}"))
      |> Figler.Inspect.put_part(children(node.children))
      |> Figler.Inspect.join_parts()

    Algebra.concat(["#Figler.Scene.Node<", parts, ">"])
  end

  defp size(%{x: x, y: y}), do: "size=#{x}x#{y}"
  defp size(_size), do: nil

  defp children(children) when is_list(children), do: "children=#{length(children)}"
  defp children(_children), do: nil
end

defimpl Inspect, for: Figler.Scene.Graph do
  def inspect(graph, _opts) do
    Algebra.concat([
      "#Figler.Scene.Graph<mode=",
      to_string(graph.mode),
      " nodes=",
      to_string(Figler.Scene.Graph.node_count(graph)),
      " unresolved=",
      to_string(length(Figler.Scene.Graph.unresolved(graph))),
      ">"
    ])
  end
end

defimpl Inspect, for: Figler.Scene.Summary do
  def inspect(summary, _opts) do
    Algebra.concat([
      "#Figler.Scene.Summary<nodes=",
      to_string(summary.node_count),
      " roots=",
      to_string(summary.root_count),
      " parented=",
      to_string(summary.parented_count),
      " types=",
      to_string(length(summary.type_counts)),
      ">"
    ])
  end
end
