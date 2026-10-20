defmodule Figler.Scene.Graph.VariablesTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Variables
  alias Figler.Scene.Graph.Variables.Formula

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

  test "reads collections and resolves variables in their default mode", %{binary: binary} do
    {payload, schema} = Scene.source!(binary)
    message = CodecNifs.decode_sparse_message({payload, schema})
    records = Map.new(message.node_changes, &{{&1.guid.session_id, &1.guid.local_id}, &1})
    vars = Variables.new(records)

    assert map_size(vars.collections) > 0

    for {id, %{type: type}} <- vars.variables do
      assert Formula.type(Variables.resolve(vars, id, %{})) == type
    end
  end

  describe "formulas" do
    test "evaluate operators with Figma's operand types" do
      resolve = fn {1, 1} -> 4.0 end

      assert Formula.evaluate({:multiply, [2.0, {:alias, {1, 1}}]}, resolve) == 8.0
      assert Formula.evaluate({:addition, ["n=", {:alias, {1, 1}}]}, resolve) == "n=4"
      assert Formula.evaluate({:ternary, [true, "a", "b"]}, resolve) == "a"
      assert Formula.evaluate({:is_truthy, ["off"]}, resolve) == false

      assert_raise ArgumentError, fn -> Formula.evaluate({:divide, [1.0, 0.0]}, resolve) end
      assert_raise ArgumentError, fn -> Formula.evaluate({:subtraction, ["a", 1.0]}, resolve) end
    end

    test "write numbers as text the way Figma does" do
      assert Formula.text(0.0000001) == "0"
      assert Formula.text(3.0) == "3"
      assert Formula.text(0.125) == "0.12"
      assert Formula.text(0.999) == "1.00"
      assert Formula.text(-0.004) == "-0.00"
      assert Formula.text(true) == "true"
    end

    test "read text and numbers as true or false" do
      assert Formula.truthy("No ") == false
      assert Formula.truthy("yes") == true
      assert Formula.truthy(0) == false
      assert Formula.truthy("") == false
    end
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
