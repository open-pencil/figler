defmodule FigKiwi.Schema.ClientRenderedMetadata do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:load_id, 1, type: :string, source_name: "loadID")
  field(:tracking_session_id, 2, type: :string, source_name: "trackingSessionId")
  field(:tracking_session_sequence_id, 3, type: :uint, source_name: "trackingSessionSequenceId")
  field(:reconnect_id, 4, type: :string, source_name: "reconnectID")
end
