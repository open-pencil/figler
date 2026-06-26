defmodule Figler.Schema.ExportConstraintType do
  @moduledoc "Generated Kiwi enum module for `ExportConstraintType`."
  use KiwiCodec, kind: :enum
  enum_value(:content_scale, 0)
  enum_value(:content_width, 1)
  enum_value(:content_height, 2)
end
