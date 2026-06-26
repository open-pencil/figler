defmodule Figler.Schema.PresenterInfo do
  @moduledoc "Generated Kiwi message module for `PresenterInfo`."
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:nomination, 2, type: Figler.Schema.PresenterNomination, source_name: "nomination")
  field(:is_reconnected, 3, type: :bool, source_name: "isReconnected")
end
