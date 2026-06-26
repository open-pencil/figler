defmodule Figler.Schema.MouseCursor do
  @moduledoc "Generated Kiwi enum module for `MouseCursor`."
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:crosshair, 1)
  enum_value(:eyedropper, 2)
  enum_value(:hand, 3)
  enum_value(:paint_bucket, 4)
  enum_value(:pen, 5)
  enum_value(:pencil, 6)
  enum_value(:marker, 7)
  enum_value(:eraser, 8)
  enum_value(:highlighter, 9)
  enum_value(:lasso, 10)
end
