defmodule Figler.Scene.ErrorContractTest do
  use ExUnit.Case, async: true

  alias Figler.Error
  alias Figler.Scene
  alias Figler.Scene.Graph

  import Figler.Test.SceneFixture

  test "normalizes native document and XPath failures" do
    assert_raise Error, "invalid Figma document during summary", fn ->
      Scene.summary(<<1, 2, 3>>)
    end

    error =
      assert_raise Error, "invalid scene query during query", fn ->
        Scene.query(message_payload(), "[")
      end

    assert error.code == :invalid_query
    assert error.operation == :query
    assert is_binary(error.context.reason)

    assert_raise Error, "invalid Figma document during graph", fn ->
      Scene.graph(<<1, 2, 3>>)
    end
  end

  test "rejects malformed GUIDs consistently across navigation surfaces" do
    index = Scene.index(message_payload())
    graph = Scene.graph(index)

    for {operation, fun} <- [
          node: fn -> Scene.node(index, "invalid") end,
          parent: fn -> Scene.parent(index, "invalid") end,
          children: fn -> Scene.children(graph, "invalid") end,
          siblings: fn -> Scene.siblings(index, "invalid") end,
          ancestors: fn -> Scene.ancestors(index, "invalid") end,
          descendants: fn -> Scene.descendants(index, "invalid") end
        ] do
      error = assert_raise Error, fun
      assert error.code == :invalid_guid
      assert error.operation == operation
      assert error.context == %{guid: "invalid"}
    end
  end

  test "rejects unknown and malformed query options" do
    assert_error(:query, :fields, :invalid_fields, fn ->
      Scene.query(message_payload(), "//*", fields: :name)
    end)

    assert_error(:query, :unknown, :unknown_option, fn ->
      Scene.by_type(message_payload(), :canvas, unknown: true)
    end)

    assert_error(:find, :name_contains, :invalid_string, fn ->
      Scene.find(message_payload(), name_contains: :page)
    end)

    assert_error(:tree, :depth, :invalid_depth, fn ->
      Scene.tree(message_payload(), depth: -1)
    end)
  end

  test "rejects ambiguous and unsupported graph options" do
    assert_error(:graph, :until, :unknown_option, fn ->
      Scene.graph(message_payload(), until: :variables)
    end)

    assert_error(:graph, :selection, :conflicting_focus_selection, fn ->
      Scene.graph(message_payload(), focus: "0:1", root: "0:1")
    end)

    assert_error(:graph, :resolve_variables, :invalid_resolution_mode, fn ->
      Scene.graph(message_payload(), resolve_variables: :all)
    end)

    graph = Scene.graph(message_payload())

    assert_error(:graph_tree, :depth, :invalid_depth, fn ->
      Graph.tree(graph, depth: -1)
    end)

    assert_error(:graph_unresolved, :limit, :invalid_limit, fn ->
      Graph.unresolved(graph, limit: -1)
    end)
  end

  defp assert_error(operation, option, code, fun) do
    error = assert_raise Error, fun

    assert error.code == :invalid_options
    assert error.operation == operation
    assert [%{option: ^option, code: ^code}] = error.context.errors
  end
end
