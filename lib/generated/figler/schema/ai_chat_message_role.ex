defmodule Figler.Schema.AIChatMessageRole do
  @moduledoc "Generated Kiwi enum module for `AIChatMessageRole`."
  use KiwiCodec, kind: :enum
  enum_value(:user, 0)
  enum_value(:assistant, 1)
  enum_value(:tool, 2)
  enum_value(:system, 3)
end
