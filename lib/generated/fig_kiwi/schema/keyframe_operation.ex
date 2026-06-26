defmodule FigKiwi.Schema.KeyframeOperation do
  @moduledoc "Generated Kiwi enum module for `KeyframeOperation`."
  use KiwiCodec, kind: :enum
  enum_value(:set, 0)
  enum_value(:scale, 1)
  enum_value(:offset, 2)
end
