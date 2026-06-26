defmodule Figler.Schema.SelectionRegionFocusType do
  @moduledoc "Generated Kiwi enum module for `SelectionRegionFocusType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:primary, 1)
  enum_value(:secondary, 2)
end
