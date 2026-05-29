defmodule FigKiwi.Schema.InteractiveSlideElementChange do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:user_id, 1, type: :string, source_name: "userID")
  field(:anonymous_user_id, 2, type: :string, source_name: "anonymousUserID")
  field(:node_id, 3, type: FigKiwi.Schema.GUID, source_name: "nodeID")
  field(:response_data, 4, type: :string, source_name: "responseData")
end
