defmodule FigKiwi.Schema.AgentInfo do
  @moduledoc "Generated Kiwi message module for `AgentInfo`."
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:logo, 2, type: :string, source_name: "logo")
  field(:oauth_client_id, 3, type: :string, source_name: "oauthClientId")
end
