defmodule FigKiwi.Schema.PresenterNomination do
  @moduledoc "Generated Kiwi message module for `PresenterNomination`."
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:is_cancelled, 2, type: :bool, source_name: "isCancelled")
end
