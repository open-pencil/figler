defmodule FigKiwi.Schema.KeyframeValueType do
  @moduledoc "Generated Kiwi enum module for `KeyframeValueType`."
  use KiwiCodec, kind: :enum
  enum_value(:float, 0)
  enum_value(:invalid, 1)
  enum_value(:color, 2)
  enum_value(:text_data, 3)
  enum_value(:vector, 4)
end
