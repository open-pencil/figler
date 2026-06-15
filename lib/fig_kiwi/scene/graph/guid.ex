defmodule FigKiwi.Scene.Graph.GUID do
  @moduledoc """
  Internal GUID representation for Elixir graph resolution.

  Public scene APIs expose GUIDs as strings like `"1:23"`. The graph resolver
  keeps real Figma GUIDs as `{session_id, local_id}` tuples and synthetic clone
  IDs as `{:clone, instance_guid, source_guid}` tagged tuples.
  """

  @type figma_guid :: {non_neg_integer(), non_neg_integer()}
  @type graph_guid :: figma_guid() | {:clone, figma_guid(), figma_guid()}

  @doc """
  Parses a public GUID string or returns an already parsed graph GUID.
  """
  @spec parse(String.t() | graph_guid() | nil) :: graph_guid() | nil
  def parse(nil), do: nil
  def parse({:clone, {_s1, _l1}, {_s2, _l2}} = guid), do: guid
  def parse({_session_id, _local_id} = guid), do: guid

  def parse("clone:" <> clone) do
    with [instance, source] <- String.split(clone, "/", parts: 2),
         {instance_guid, ""} <- parse_figma(instance),
         {source_guid, ""} <- parse_figma(source) do
      {:clone, instance_guid, source_guid}
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

  def format({:clone, instance_guid, source_guid}),
    do: "clone:#{format(instance_guid)}/#{format(source_guid)}"

  @doc """
  Converts a generated schema GUID struct to an internal tuple.
  """
  @spec from_schema(FigKiwi.Schema.GUID.t() | nil) :: figma_guid() | nil
  def from_schema(nil), do: nil

  def from_schema(%FigKiwi.Schema.GUID{session_id: session_id, local_id: local_id}) do
    {session_id, local_id}
  end

  @doc """
  Builds a synthetic clone graph GUID.
  """
  @spec clone(figma_guid(), figma_guid()) :: graph_guid()
  def clone(
        {_session_id, _local_id} = instance_guid,
        {_source_session, _source_local} = source_guid
      ) do
    {:clone, instance_guid, source_guid}
  end

  defp parse_figma(value) do
    with {session_id, ":" <> rest} <- Integer.parse(value),
         {local_id, rest} <- Integer.parse(rest) do
      {{session_id, local_id}, rest}
    end
  end
end
