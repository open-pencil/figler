defmodule Figler.Schema.AIChatContentPartType do
  @moduledoc "Generated Kiwi enum module for `AIChatContentPartType`."
  use KiwiCodec, kind: :enum
  enum_value(:invalid, 0)
  enum_value(:text, 1)
  enum_value(:selected_node_ids, 2)
end
