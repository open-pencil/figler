defmodule FigKiwi.Schema.Path do
  @moduledoc "Generated Kiwi message module for `Path`."
  use KiwiCodec, kind: :message
  field(:winding_rule, 1, type: {:enum, FigKiwi.Schema.WindingRule}, source_name: "windingRule")
  field(:commands_blob, 2, type: :uint, source_name: "commandsBlob")
  field(:style_id, 3, type: :uint, source_name: "styleID")
end
