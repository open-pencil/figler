defmodule FigKiwi.Schema.AgentInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:logo, 2, type: :string, source_name: "logo")
  field(:oauth_client_id, 3, type: :string, source_name: "oauthClientId")
end
