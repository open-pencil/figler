defmodule Figler.Schema.NodeGenerationData do
  @moduledoc "Generated Kiwi message module for `NodeGenerationData`."
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: Figler.Schema.NodeChange, source_name: "overrides")
  field(:use_fine_grained_syncing, 2, type: :bool, source_name: "useFineGrainedSyncing")

  field(:diff_only_removals, 3,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "diffOnlyRemovals"
  )
end
