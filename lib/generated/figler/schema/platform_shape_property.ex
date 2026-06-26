defmodule Figler.Schema.PlatformShapeProperty do
  @moduledoc "Generated Kiwi enum module for `PlatformShapeProperty`."
  use KiwiCodec, kind: :enum
  enum_value(:fill, 0)
  enum_value(:stroke, 1)
  enum_value(:text, 2)
  enum_value(:stroke_color, 3)
end
