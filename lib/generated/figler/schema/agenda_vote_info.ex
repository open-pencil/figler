defmodule Figler.Schema.AgendaVoteInfo do
  @moduledoc "Generated Kiwi message module for `AgendaVoteInfo`."
  use KiwiCodec, kind: :message
  field(:vote_count, 1, type: :uint, source_name: "voteCount")
end
