defmodule Figler.Schema.ExportBackgroundType do
  @moduledoc "Generated Kiwi enum module for `ExportBackgroundType`."
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:transparent, 1)
  enum_value(:grid, 2)
end
