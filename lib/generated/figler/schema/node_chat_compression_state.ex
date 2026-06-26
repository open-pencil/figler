defmodule Figler.Schema.NodeChatCompressionState do
  @moduledoc "Generated Kiwi message module for `NodeChatCompressionState`."
  use KiwiCodec, kind: :message
  field(:start_index, 1, type: :uint, source_name: "startIndex")
  field(:summary, 2, type: :string, source_name: "summary")
end
