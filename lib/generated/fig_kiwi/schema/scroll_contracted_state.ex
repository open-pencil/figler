defmodule FigKiwi.Schema.ScrollContractedState do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:expanded, 0)
  enum_value(:contracted, 1)
end
