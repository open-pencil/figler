defmodule FigKiwi.Schema.GridTrackSizingType do
  @moduledoc "Generated Kiwi enum module for `GridTrackSizingType`."
  use KiwiCodec, kind: :enum
  enum_value(:flex, 0)
  enum_value(:fixed, 1)
  enum_value(:hug, 2)
end
