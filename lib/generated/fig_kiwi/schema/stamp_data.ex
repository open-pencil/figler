defmodule FigKiwi.Schema.StampData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:user_id, 1, type: :string, source_name: "userId")
  field(:voting_session_id, 2, type: :string, source_name: "votingSessionId")
  field(:stamped_by_user_id, 3, type: :string, source_name: "stampedByUserId")
end
