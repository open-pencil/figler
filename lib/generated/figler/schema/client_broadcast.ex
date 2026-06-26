defmodule Figler.Schema.ClientBroadcast do
  @moduledoc "Generated Kiwi message module for `ClientBroadcast`."
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:cursor_reaction, 2, type: Figler.Schema.CursorReaction, source_name: "cursorReaction")
  field(:timer, 3, type: Figler.Schema.TimerInfo, source_name: "timer")
  field(:presenter, 4, type: Figler.Schema.PresenterInfo, source_name: "presenter")

  field(:prototype_presenter, 5,
    type: Figler.Schema.PresenterInfo,
    source_name: "prototypePresenter"
  )

  field(:music, 6, type: Figler.Schema.MusicInfo, source_name: "music")
end
