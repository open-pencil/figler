defmodule Figler.Schema.EditorType do
  @moduledoc "Generated Kiwi enum module for `EditorType`."
  use KiwiCodec, kind: :enum
  enum_value(:design, 0)
  enum_value(:whiteboard, 1)
  enum_value(:slides, 2)
  enum_value(:dev_handoff, 3)
  enum_value(:sites, 4)
  enum_value(:cooper, 5)
  enum_value(:illustration, 6)
  enum_value(:figmake, 7)
  enum_value(:figspec, 8)
end
