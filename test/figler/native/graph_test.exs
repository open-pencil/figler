defmodule Figler.Native.GraphTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Native.Module, as: Native
  alias Figler.Scene.Graph.Occurrence.SourceIndex
  alias Figler.Scene.Input

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  test "indexes and prepares records as the Elixir interpreter does" do
    {payload, schema} = source = @fixture |> File.read!() |> Input.source!()
    {sources, children} = Native.graph_source_index(payload, schema)

    records = CodecNifs.decode_sparse_message(source).node_changes
    index = SourceIndex.new(records)

    # Maps the Elixir preparation builds carry no schema module; native records always do.
    assert Map.new(sources, fn {id, record} -> {id, without_module(record)} end) ==
             Map.new(index.sources, fn {id, record} -> {id, without_module(record)} end)

    assert children ==
             Map.new(index.children, fn {parent, siblings} ->
               {parent, Enum.map(siblings, &SourceIndex.id/1)}
             end)
  end

  defp without_module(%{} = map) when not is_struct(map),
    do:
      map
      |> Map.delete(:__kiwi_module__)
      |> Map.new(fn {key, value} -> {key, without_module(value)} end)

  defp without_module(list) when is_list(list), do: Enum.map(list, &without_module/1)
  defp without_module(value), do: value
end
