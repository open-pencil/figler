defmodule Figler.Schema.StyleSetContentType do
  @moduledoc "Generated Kiwi enum module for `StyleSetContentType`."
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:gradient, 1)
  enum_value(:image, 2)
end
