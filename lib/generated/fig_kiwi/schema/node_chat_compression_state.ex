defmodule FigKiwi.Schema.NodeChatCompressionState do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:start_index, 1, type: :uint, source_name: "startIndex")
  field(:summary, 2, type: :string, source_name: "summary")
end
