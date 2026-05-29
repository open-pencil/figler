defmodule FigKiwi.Schema.CodeOutputLayer do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:node, 1, type: FigKiwi.Schema.NodeChange, source_name: "node")
end
