defmodule Figler.Native.GraphTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Native.Module, as: Native
  alias Figler.Scene.Graph.Occurrence.Interpreter
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

  test "interprets every page as the Elixir interpreter does" do
    {payload, schema} = source = @fixture |> File.read!() |> Input.source!()

    index =
      source
      |> CodecNifs.decode_sparse_message()
      |> Map.fetch!(:node_changes)
      |> SourceIndex.new()

    [document] = for {id, %{type: :document}} <- index.sources, do: id

    for page <- SourceIndex.children(index, document), id = SourceIndex.id(page) do
      {occurrence, diagnostics} = Interpreter.interpret(index, id)
      {native, native_diagnostics} = Native.graph_interpret(payload, schema, id)

      assert comparable(native) == comparable(Map.from_struct(occurrence))
      assert native_diagnostics == diagnostics
    end
  end

  # The native tree omits nil fields and keeps no binding rank for slot content, which only
  # instance expansion reads; sets come back as lists.
  defp comparable(occurrence) do
    occurrence
    |> Map.update!(:children, fn children ->
      Enum.map(children, &comparable(if is_struct(&1), do: Map.from_struct(&1), else: &1))
    end)
    |> Map.update!(:bound_fields, &Map.delete(&1, :slot_content))
    |> Map.update!(:overridden, &(&1 |> Enum.to_list() |> Enum.sort()))
    |> Map.update!(:properties, &without_nil/1)
    |> Map.update!(:derived_size, &without_nil/1)
    |> Map.update!(:property_claims, &without_nil/1)
  end

  defp without_nil(%{} = map) when not is_struct(map),
    do:
      map
      |> Map.delete(:__kiwi_module__)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new(fn {key, value} -> {key, without_nil(value)} end)

  defp without_nil(list) when is_list(list), do: Enum.map(list, &without_nil/1)
  defp without_nil(value), do: value

  defp without_module(%{} = map) when not is_struct(map),
    do:
      map
      |> Map.delete(:__kiwi_module__)
      |> Map.new(fn {key, value} -> {key, without_module(value)} end)

  defp without_module(list) when is_list(list), do: Enum.map(list, &without_module/1)
  defp without_module(value), do: value
end
