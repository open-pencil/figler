defmodule FigKiwi.Schema.SceneGraphQuery do
  @moduledoc "Generated Kiwi message module for `SceneGraphQuery`."
  use KiwiCodec, kind: :message
  field(:starting_node, 1, type: FigKiwi.Schema.GUID, source_name: "startingNode")
  field(:depth, 2, type: :uint, source_name: "depth")

  field(:behavior, 3,
    type: {:enum, FigKiwi.Schema.SceneGraphQueryBehavior},
    source_name: "behavior"
  )
end
