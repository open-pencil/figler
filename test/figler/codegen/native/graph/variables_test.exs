defmodule Figler.Codegen.Native.Graph.VariablesTest do
  use ExUnit.Case, async: true

  alias Figler.Native.Module, as: Native
  alias Figler.Scene
  alias Figler.Scene.Graph

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  # Ported from OpenPencil's variable-override-precedence test: the file was
  # authored in Figma, and these are the strings Figma renders. An owner's
  # consumption entry carrying variable data binds the text, which then wins
  # over the literal the instance records; a bare entry clears the binding.
  @figma_renders %{
    "same-literal" => "Button-sm",
    "different-literal" => "Button-sm",
    "return-to-inherited" => "Button-sm",
    "staged" => "Learn more"
  }

  setup_all do
    {:ok, binary: File.read!(@fixture)}
  end

  test "resolves text bindings against instance overrides as Figma renders them", %{
    binary: binary
  } do
    graph = Scene.graph(binary)
    instances = Scene.by_type(graph, :instance)

    rendered =
      Map.new(@figma_renders, fn {name, _text} ->
        instance = Enum.find(instances, &(&1.name == name))
        {name, first_text(graph, instance.guid)}
      end)

    assert rendered == @figma_renders
  end

  test "keeps saved values when variable resolution is off", %{binary: binary} do
    graph = Scene.graph(binary, resolve_variables: false)
    different = graph |> Scene.by_type(:instance) |> Enum.find(&(&1.name == "different-literal"))

    assert first_text(graph, different.guid) == "Different"
  end

  test "resolves every variable in each mode of its collection", %{binary: binary} do
    {payload, schema} = Scene.source!(binary)
    {resolved, diagnostics} = Native.graph_resolve_variables(payload, schema)

    assert resolved != []
    assert Enum.all?(resolved, fn {_variable, _mode, value} -> value != nil end)
    assert diagnostics == []
  end

  defp first_text(graph, guid) do
    graph
    |> Scene.children(guid)
    |> Enum.find_value(fn child ->
      if child.node_type == "text", do: child.text, else: first_text(graph, child.guid)
    end)
  end

  test "exposes the effective record with resolved text", %{binary: binary} do
    graph = Scene.graph(binary)
    same = graph |> Scene.by_type(:instance) |> Enum.find(&(&1.name == "same-literal"))
    [button] = Scene.children(graph, same.guid)
    [label] = Scene.children(graph, button.guid)

    assert %{text_data: %{characters: "Button-sm"}} = Graph.record(graph, label.guid)
  end
end
