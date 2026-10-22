defmodule Figler.Native.InterpreterTest do
  # Ported from OpenPencil's packages/fig/tests/instance-overrides, with records
  # captured from real Figma files. OpenPencil throws on unresolved paths unless
  # a callback is given; Figler always reports them as diagnostics. Each case reads
  # the occurrence tree the native interpreter builds for one record.
  use ExUnit.Case, async: true

  alias Figler.Native.Module, as: Native
  alias Figler.Test.NodeChangeJSON
  alias Figler.Test.SceneFixture

  @fixtures "test/fixtures/openpencil/instance-overrides"

  defp interpret(records, id) do
    {payload, schema} = SceneFixture.records_source(records)
    Native.graph_interpret(payload, schema, id)
  end

  defp fixture(name), do: NodeChangeJSON.read!(Path.join(@fixtures, name))

  defp texts(%{properties: properties, children: children}) do
    own =
      if Map.get(properties, :type) == :text,
        do: [get_in(properties, [:text_data, :characters]) || ""],
        else: []

    own ++ Enum.flat_map(children, &texts/1)
  end

  defp guid(local_id), do: %{session_id: 1, local_id: local_id}

  describe "Accordion source closure" do
    test "keeps independent labels while reporting stale overrides" do
      {root, diagnostics} = interpret(fixture("accordion-source-closure.json"), {7, 283})

      assert Enum.map(root.children, & &1.main_component_id) == [{7, 251}, {7, 156}, {7, 156}]

      assert Enum.map(root.children, &hd(texts(&1))) == [
               "Is it accessible?",
               "Is it styled?",
               "Is it animated?"
             ]

      # The first item is swapped to 7:251, which has no 7:95 occurrence; only
      # the two triggers that exist in the result report the stale 7:93 path.
      assert diagnostics ==
               List.duplicate(
                 {:unresolved_property, {7, 95}, {7, 94}, [{7, 93}], :missing_target},
                 2
               )
    end
  end

  describe "stale paths" do
    test "reports a stale property override and leaves the replacement vector untouched" do
      {root, diagnostics} = interpret(fixture("stale-chevron-override.json"), {7, 95})

      assert diagnostics == [{:unresolved_property, {7, 95}, {7, 94}, [{7, 93}], :missing_target}]
      assert [%{source_id: {94, 5438}, properties: vector}] = root.children
      refute Map.has_key?(vector, :stroke_paints)
    end

    test "reports a swap whose target layer is gone instead of refusing the file" do
      records = [
        %{guid: guid(1), type: :symbol, name: "navbar"},
        %{
          guid: guid(2),
          type: :frame,
          name: "kept",
          parent_index: %{guid: guid(1), position: "!"}
        },
        %{guid: guid(3), type: :symbol, name: "replacement"},
        %{
          guid: guid(4),
          type: :instance,
          name: "navbar instance",
          symbol_data: %{
            symbol_id: guid(1),
            symbol_overrides: [%{guid_path: %{guids: [guid(99)]}, overridden_symbol_id: guid(3)}]
          }
        }
      ]

      {root, diagnostics} = interpret(records, {1, 4})

      assert [{:unresolved_assignment, {1, 4}, {1, 1}, [{1, 99}], :missing_target}] = diagnostics
      assert Enum.map(root.children, & &1.properties.name) == ["kept"]
    end

    test "reports an ambiguous swap address as ambiguous" do
      records = [
        %{guid: guid(1), type: :symbol, name: "navbar"},
        %{
          guid: guid(2),
          type: :frame,
          name: "a",
          override_key: guid(7),
          parent_index: %{guid: guid(1), position: "!"}
        },
        %{
          guid: guid(3),
          type: :frame,
          name: "b",
          override_key: guid(7),
          parent_index: %{guid: guid(1), position: "\""}
        },
        %{guid: guid(5), type: :symbol, name: "replacement"},
        %{
          guid: guid(4),
          type: :instance,
          symbol_data: %{
            symbol_id: guid(1),
            symbol_overrides: [%{guid_path: %{guids: [guid(7)]}, overridden_symbol_id: guid(5)}]
          }
        }
      ]

      assert {_root, [{:unresolved_assignment, {1, 4}, _, [{1, 7}], :ambiguous_target}]} =
               interpret(records, {1, 4})
    end
  end

  describe "Figma-authored saved swaps" do
    setup do
      {:ok, records: fixture("saved-swap-paths.json")}
    end

    test "uses the replacement default for an untouched top-level swap", %{records: records} do
      {root, []} = interpret(records, {10_965, 1263})

      assert root.main_component_id == {10_965, 1261}
      assert %{x: 160.0, y: 64.0} = root.properties.size
      assert [label] = root.children
      assert label.properties.text_data.characters == "Replacement label"
    end

    test "reads explicit retained size, opacity and text", %{records: records} do
      {root, []} = interpret(records, {10_965, 1266})

      assert %{x: 120.0, y: 50.0} = root.properties.size
      assert_in_delta root.properties.opacity, 0.6, 1.0e-6
      assert hd(root.children).properties.text_data.characters == "Edited label"
    end

    test "replays preserved inherited text onto the replacement child path", %{records: records} do
      {root, []} = interpret(records, {10_965, 1272})
      [swapped] = root.children

      assert swapped.source_id == {10_965, 1270}
      assert %{x: 100.0, y: 40.0} = swapped.properties.size
      assert swapped.main_component_id == {10_965, 1261}
      assert [%{source_id: {10_965, 1262}} = label] = swapped.children
      assert label.properties.text_data.characters == "Inherited edit"
    end

    test "does not carry old text to a replacement without a saved override", %{records: records} do
      {root, []} = interpret(records, {10_965, 1276})
      [swapped] = root.children

      assert %{x: 100.0, y: 40.0} = swapped.properties.size
      assert swapped.main_component_id == {10_965, 1261}
      assert hd(swapped.children).properties.text_data.characters == "Replacement label"
    end
  end

  describe "precedence" do
    # Component 1:1 has a text bound to property 1:50; instance 1:2 assigns it
    # and also claims the text explicitly; outer instance 1:3 assigns it again.
    defp precedence_records(outer_assignment?) do
      text_ref = [%{def_id: guid(50), component_prop_node_field: :text_data}]

      inner_symbol = [
        %{
          guid: guid(1),
          type: :symbol,
          name: "button",
          component_prop_defs: [
            %{id: guid(50), initial_value: %{text_value: %{characters: "Default"}}}
          ]
        },
        %{
          guid: guid(10),
          type: :text,
          name: "label",
          text_data: %{characters: "Default"},
          component_prop_refs: text_ref,
          parent_index: %{guid: guid(1), position: "!"}
        }
      ]

      wrapper = [
        %{
          guid: guid(20),
          type: :symbol,
          name: "card",
          component_prop_defs: [
            %{id: guid(60), initial_value: %{text_value: %{characters: "Card"}}}
          ]
        },
        %{
          guid: guid(2),
          type: :instance,
          name: "button",
          parent_index: %{guid: guid(20), position: "!"},
          component_prop_assignments: [
            %{def_id: guid(50), value: %{text_value: %{characters: "Inner assignment"}}}
          ],
          symbol_data: %{
            symbol_id: guid(1),
            symbol_overrides: [
              %{guid_path: %{guids: [guid(10)]}, text_data: %{characters: "Inner claim"}}
            ]
          }
        }
      ]

      outer =
        if outer_assignment? do
          [
            %{
              guid_path: %{guids: [guid(2)]},
              component_prop_assignments: [
                %{def_id: guid(50), value: %{text_value: %{characters: "Outer assignment"}}}
              ]
            }
          ]
        else
          []
        end

      inner_symbol ++
        wrapper ++
        [
          %{
            guid: guid(3),
            type: :instance,
            name: "card",
            symbol_data: %{symbol_id: guid(20), symbol_overrides: outer}
          }
        ]
    end

    defp label(root), do: root.children |> hd() |> Map.fetch!(:children) |> hd()

    test "an owner's explicit claim overrides its own assignment" do
      {root, []} = interpret(precedence_records(false), {1, 3})
      assert label(root).properties.text_data.characters == "Inner claim"
    end

    test "a strictly outer assignment beats an inner explicit claim" do
      {root, []} = interpret(precedence_records(true), {1, 3})
      assert label(root).properties.text_data.characters == "Outer assignment"
    end
  end
end
