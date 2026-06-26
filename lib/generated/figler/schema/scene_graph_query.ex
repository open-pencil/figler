defmodule Figler.Schema.SceneGraphQuery do
  @moduledoc "Generated Kiwi message module for `SceneGraphQuery`."
  use KiwiCodec, kind: :message
  field(:starting_node, 1, type: Figler.Schema.GUID, source_name: "startingNode")
  field(:depth, 2, type: :uint, source_name: "depth")

  field(:behavior, 3,
    type: {:enum, Figler.Schema.SceneGraphQueryBehavior},
    source_name: "behavior"
  )
end
