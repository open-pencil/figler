defmodule FigKiwi.Inspect do
  @moduledoc false

  def guid(%FigKiwi.Schema.GUID{session_id: session_id, local_id: local_id}) do
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
      FigKiwi.Schema.GUID,
      FigKiwi.Schema.ParentIndex,
      FigKiwi.Schema.Vector,
      FigKiwi.Schema.Matrix,
      FigKiwi.Schema.NodeChange
    ] do
  Code.ensure_compiled!(module)
end

alias Inspect.Algebra, as: Algebra

defimpl Inspect, for: FigKiwi.Schema.GUID do
  def inspect(guid, _opts) do
    Algebra.concat(["#FigKiwi.Schema.GUID<", FigKiwi.Inspect.guid(guid), ">"])
  end
end

defimpl Inspect, for: FigKiwi.Schema.ParentIndex do
  def inspect(parent_index, opts) do
    Algebra.concat([
      "#FigKiwi.Schema.ParentIndex<parent=",
      Inspect.Algebra.to_doc(parent_index.guid, opts),
      " pos=",
      to_string(parent_index.position),
      ">"
    ])
  end
end

defimpl Inspect, for: FigKiwi.Schema.Vector do
  def inspect(vector, _opts) do
    Algebra.concat([
      "#FigKiwi.Schema.Vector<x=",
      inspect(vector.x),
      " y=",
      inspect(vector.y),
      ">"
    ])
  end
end

defimpl Inspect, for: FigKiwi.Schema.Matrix do
  def inspect(matrix, _opts) do
    values = [matrix.m00, matrix.m01, matrix.m02, matrix.m10, matrix.m11, matrix.m12]

    Algebra.concat([
      "#FigKiwi.Schema.Matrix<",
      values |> Enum.map_join(",", &inspect/1),
      ">"
    ])
  end
end

defimpl Inspect, for: FigKiwi.Schema.NodeChange do
  def inspect(node, _opts) do
    {present, total} = FigKiwi.Inspect.present_fields(node)

    parts =
      []
      |> FigKiwi.Inspect.put_part(FigKiwi.Inspect.compact_atom(node.type))
      |> FigKiwi.Inspect.put_part(FigKiwi.Inspect.compact_name(node.name))
      |> FigKiwi.Inspect.put_part(if(node.guid, do: "guid=#{FigKiwi.Inspect.guid(node.guid)}"))
      |> FigKiwi.Inspect.put_part(
        if(node.parent_index, do: "parent=#{FigKiwi.Inspect.guid(node.parent_index.guid)}")
      )
      |> FigKiwi.Inspect.put_part("present=#{present}/#{total}")
      |> FigKiwi.Inspect.join_parts()

    Algebra.concat(["#FigKiwi.Schema.NodeChange<", parts, ">"])
  end
end

defimpl Inspect, for: FigKiwi.Scene.Node do
  def inspect(node, _opts) do
    parts =
      []
      |> FigKiwi.Inspect.put_part(to_string(node.node_type))
      |> FigKiwi.Inspect.put_part(FigKiwi.Inspect.compact_name(node.name))
      |> FigKiwi.Inspect.put_part(node.guid)
      |> FigKiwi.Inspect.put_part(if(node.parent_guid, do: "parent=#{node.parent_guid}"))
      |> FigKiwi.Inspect.put_part(if(node.position, do: "pos=#{node.position}"))
      |> FigKiwi.Inspect.put_part(size(node.size))
      |> FigKiwi.Inspect.put_part(if(is_boolean(node.visible), do: "visible=#{node.visible}"))
      |> FigKiwi.Inspect.put_part(if(is_boolean(node.locked), do: "locked=#{node.locked}"))
      |> FigKiwi.Inspect.put_part(children(node.children))
      |> FigKiwi.Inspect.join_parts()

    Algebra.concat(["#FigKiwi.Scene.Node<", parts, ">"])
  end

  defp size(%{x: x, y: y}), do: "size=#{x}x#{y}"
  defp size(_size), do: nil

  defp children(children) when is_list(children), do: "children=#{length(children)}"
  defp children(_children), do: nil
end

defimpl Inspect, for: FigKiwi.Scene.Graph do
  def inspect(graph, _opts) do
    Algebra.concat([
      "#FigKiwi.Scene.Graph<mode=",
      to_string(graph.mode),
      " stages=",
      to_string(length(graph.stages)),
      " resolver=",
      to_string(Map.get(graph.stats, :resolver, :unknown)),
      ">"
    ])
  end
end

defimpl Inspect, for: FigKiwi.Scene.Summary do
  def inspect(summary, _opts) do
    Algebra.concat([
      "#FigKiwi.Scene.Summary<nodes=",
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
