defmodule FigKiwi.Schema.PointMode do
  @moduledoc "Generated Kiwi enum module for `PointMode`."
  use KiwiCodec, kind: :enum
  enum_value(:canvas_and_ui, 0)
  enum_value(:canvas, 1)
  enum_value(:ui, 2)
end
