defmodule Figler.Schema.CodeSnapshotLayers do
  @moduledoc "Generated Kiwi message module for `CodeSnapshotLayers`."
  use KiwiCodec, kind: :message
  field(:state, 1, type: {:enum, Figler.Schema.CodeSnapshotState}, source_name: "state")
  field(:invalidated_at, 2, type: :uint, source_name: "invalidatedAt")
  field(:layers, 3, repeated: true, type: Figler.Schema.CodeOutputLayer, source_name: "layers")
end
