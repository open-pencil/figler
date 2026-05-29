defmodule FigKiwi.Schema.ClientBroadcast do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:cursor_reaction, 2, type: FigKiwi.Schema.CursorReaction, source_name: "cursorReaction")
  field(:timer, 3, type: FigKiwi.Schema.TimerInfo, source_name: "timer")
  field(:presenter, 4, type: FigKiwi.Schema.PresenterInfo, source_name: "presenter")

  field(:prototype_presenter, 5,
    type: FigKiwi.Schema.PresenterInfo,
    source_name: "prototypePresenter"
  )

  field(:music, 6, type: FigKiwi.Schema.MusicInfo, source_name: "music")
end
