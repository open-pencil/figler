defmodule FigKiwi.Schema.AIChatContentPartType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:invalid, 0)
  enum_value(:text, 1)
  enum_value(:selected_node_ids, 2)
end
