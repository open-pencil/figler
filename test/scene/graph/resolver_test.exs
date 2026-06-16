defmodule FigKiwi.Scene.Graph.ResolverTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.SymbolOverride

  test "extracts graph seed metadata from generated node changes" do
    target_guid = struct(FigKiwi.Schema.GUID, session_id: 1, local_id: 2)

    seed =
      struct(FigKiwi.Schema.NodeChange,
        guid: struct(FigKiwi.Schema.GUID, session_id: 2, local_id: 1),
        type: :instance,
        name: "Button instance",
        override_key: struct(FigKiwi.Schema.GUID, session_id: 2, local_id: 9),
        symbol_data:
          struct(FigKiwi.Schema.SymbolData,
            symbol_id: struct(FigKiwi.Schema.GUID, session_id: 1, local_id: 1),
            symbol_overrides: [
              struct(FigKiwi.Schema.NodeChange,
                guid_path: struct(FigKiwi.Schema.GUIDPath, guids: [target_guid]),
                text_data: struct(FigKiwi.Schema.TextData, characters: "Submit"),
                visible: false
              )
            ]
          )
      )
      |> SeedNode.from_node_change()

    assert %SeedNode{
             guid: {2, 1},
             node_type: "instance",
             name: "Button instance",
             symbol_id: {1, 1},
             component_guid: {1, 1},
             override_key: {2, 9},
             symbol_overrides: [
               %SymbolOverride{guid_path: [{1, 2}], fields: %{text: "Submit", visible: false}}
             ]
           } = seed
  end
end
