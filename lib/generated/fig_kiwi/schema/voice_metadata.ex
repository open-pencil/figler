defmodule FigKiwi.Schema.VoiceMetadata do
  @moduledoc "Generated Kiwi message module for `VoiceMetadata`."
  use KiwiCodec, kind: :message
  field(:connected_call_id, 1, type: :string, source_name: "connectedCallId")
end
