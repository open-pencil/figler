defmodule FigKiwi.Schema.VoiceMetadata do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:connected_call_id, 1, type: :string, source_name: "connectedCallId")
end
