defmodule FigKiwi.Schema.AgendaVoteInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:vote_count, 1, type: :uint, source_name: "voteCount")
end
