defmodule FigKiwi.Scene.Graph.GUID do
  @moduledoc """
  Internal GUID representation for Elixir graph resolution.

  Public scene APIs expose GUIDs as strings like `"1:23"`. The graph resolver
  keeps real Figma GUIDs as `{session_id, local_id}` tuples and synthetic clone
  IDs as `{:clone, root_instance_guid, source_path}` tagged tuples.
  """

  @type figma_guid :: {non_neg_integer(), non_neg_integer()}
  @type graph_guid :: figma_guid() | {:clone, figma_guid(), [figma_guid()]}

  @doc """
  Parses a public GUID string or returns an already parsed graph GUID.
  """
  @spec parse(String.t() | graph_guid() | nil) :: graph_guid() | nil
  def parse(nil), do: nil
  def parse({:clone, {_session_id, _local_id}, path} = guid) when is_list(path), do: guid
  def parse({_session_id, _local_id} = guid), do: guid

  def parse("clone:" <> clone) do
    with [root | path] <- String.split(clone, "/"),
         {root_guid, ""} <- parse_figma(root),
         path when path != [] <- parse_path(path) do
      {:clone, root_guid, path}
    else
      _ -> nil
    end
  end

  def parse(value) when is_binary(value) do
    case parse_figma(value) do
      {guid, ""} -> guid
      _other -> nil
    end
  end

  @doc """
  Parses a public GUID string, raising when it is invalid.
  """
  @spec parse!(String.t() | graph_guid()) :: graph_guid()
  def parse!(guid) do
    parse(guid) || raise ArgumentError, "invalid scene graph GUID: #{inspect(guid)}"
  end

  @doc """
  Formats an internal graph GUID for public scene APIs.
  """
  @spec format(graph_guid() | nil) :: String.t() | nil
  def format(nil), do: nil
  def format({session_id, local_id}), do: "#{session_id}:#{local_id}"

  def format({:clone, root_guid, source_path}) do
    path = Enum.map_join(source_path, "/", &format/1)
    "clone:#{format(root_guid)}/#{path}"
  end

  @doc """
  Converts a generated schema GUID struct to an internal tuple.
  """
  @spec from_schema(FigKiwi.Schema.GUID.t() | nil) :: figma_guid() | nil
  def from_schema(nil), do: nil

  def from_schema(%FigKiwi.Schema.GUID{session_id: session_id, local_id: local_id}) do
    {session_id, local_id}
  end

  @doc """
  Builds a synthetic clone graph GUID under a root instance.
  """
  @spec clone(figma_guid(), figma_guid()) :: graph_guid()
  def clone({_session_id, _local_id} = root_guid, {_source_session, _source_local} = source_guid) do
    {:clone, root_guid, [source_guid]}
  end

  @doc """
  Appends a source GUID or source clone path to a clone path.
  """
  @spec append(graph_guid(), graph_guid()) :: graph_guid()
  def append(parent_guid, {:clone, _source_root, source_path}) do
    Enum.reduce(source_path, parent_guid, &append(&2, &1))
  end

  def append({:clone, root_guid, source_path}, {_source_session, _source_local} = source_guid) do
    {:clone, root_guid, source_path ++ [source_guid]}
  end

  def append({_session_id, _local_id} = root_guid, {_source_session, _source_local} = source_guid) do
    clone(root_guid, source_guid)
  end

  @doc """
  Returns the root instance GUID for graph GUIDs.
  """
  @spec root(graph_guid()) :: figma_guid()
  def root({:clone, root_guid, _source_path}), do: root_guid
  def root({_session_id, _local_id} = guid), do: guid

  defp parse_path(parts) do
    Enum.reduce_while(parts, [], fn part, acc ->
      case parse_figma(part) do
        {guid, ""} -> {:cont, [guid | acc]}
        _other -> {:halt, nil}
      end
    end)
    |> case do
      nil -> nil
      path -> Enum.reverse(path)
    end
  end

  defp parse_figma(value) do
    with {session_id, ":" <> rest} <- Integer.parse(value),
         {local_id, rest} <- Integer.parse(rest) do
      {{session_id, local_id}, rest}
    end
  end
end
