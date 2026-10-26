defmodule Figler.Render.Selection do
  @moduledoc false

  alias Figler.Document.Page
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node

  @spec root(Graph.t(), [Page.t()], keyword()) :: {:ok, GUID.figma_guid()} | {:error, term()}
  def root(graph, pages, opts) do
    case Keyword.get(opts, :root, Keyword.get(opts, :page)) do
      nil -> page_at(pages, 0)
      index when is_integer(index) -> page_at(pages, index)
      value -> named_root(graph, pages, value)
    end
  end

  defp page_at(pages, index) do
    pages
    |> Enum.at(index)
    |> case do
      %Page{guid: guid} -> {:ok, GUID.parse(guid)}
      nil -> {:error, :render_root_not_found}
    end
  end

  defp named_root(graph, pages, value) do
    parsed = GUID.parse(value)

    cond do
      parsed && Graph.node_at(graph, parsed) != nil ->
        {:ok, parsed}

      is_binary(value) ->
        find_named_page(graph, pages, value)

      true ->
        {:error, :render_root_not_found}
    end
  end

  defp find_named_page(graph, pages, name) do
    Enum.find_value(pages, {:error, :render_root_not_found}, fn page ->
      guid = GUID.parse(page.guid)

      case Graph.node_at(graph, guid) do
        %Node{name: ^name} -> {:ok, guid}
        _node -> false
      end
    end)
  end
end
