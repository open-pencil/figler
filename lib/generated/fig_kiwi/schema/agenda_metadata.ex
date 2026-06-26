defmodule FigKiwi.Schema.AgendaMetadata do
  @moduledoc "Generated Kiwi message module for `AgendaMetadata`."
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:type, 2, type: {:enum, FigKiwi.Schema.AgendaItemType}, source_name: "type")
  field(:target_node_id, 3, type: FigKiwi.Schema.GUID, source_name: "targetNodeID")
  field(:timer_info, 4, type: FigKiwi.Schema.AgendaTimerInfo, source_name: "timerInfo")
  field(:vote_info, 5, type: FigKiwi.Schema.AgendaVoteInfo, source_name: "voteInfo")
  field(:music_info, 6, type: FigKiwi.Schema.AgendaMusicInfo, source_name: "musicInfo")
end
