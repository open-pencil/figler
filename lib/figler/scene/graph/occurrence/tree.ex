defmodule Figler.Scene.Graph.Occurrence.Tree do
  @moduledoc false

  # Traversal shared by source records and occurrences. A search may pass
  # through ordinary containers but never implicitly into an instance, whose
  # contents belong to another owner's scope.

  @type shape :: %{children: (term() -> [term()]), instance?: (term() -> boolean())}

  @doc """
  Finds nodes below `roots` through ordinary containers, never past an
  instance. A match ends its branch.

  Returns `{match, top, index_path}` for every match, where `top` is the root
  holding it and `index_path` the child indexes from `roots` down to it.
  """
  @spec find_within_boundary([term()], shape(), (term() -> boolean())) ::
          [{term(), term(), [non_neg_integer()]}]
  def find_within_boundary(roots, shape, matches?) do
    roots
    |> Enum.with_index()
    |> Enum.flat_map(fn {root, index} -> visit(root, root, [index], shape, matches?) end)
  end

  defp visit(node, top, path, shape, matches?) do
    cond do
      matches?.(node) ->
        [{node, top, Enum.reverse(path)}]

      shape.instance?.(node) ->
        []

      true ->
        node
        |> shape.children.()
        |> Enum.with_index()
        |> Enum.flat_map(fn {child, index} ->
          visit(child, top, [index | path], shape, matches?)
        end)
    end
  end
end
