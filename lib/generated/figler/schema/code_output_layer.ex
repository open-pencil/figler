defmodule Figler.Schema.CodeOutputLayer do
  @moduledoc "Generated Kiwi message module for `CodeOutputLayer`."
  use KiwiCodec, kind: :message
  field(:node, 1, type: Figler.Schema.NodeChange, source_name: "node")
end
