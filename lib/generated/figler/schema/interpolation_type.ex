defmodule Figler.Schema.InterpolationType do
  @moduledoc "Generated Kiwi enum module for `InterpolationType`."
  use KiwiCodec, kind: :enum
  enum_value(:hold, 0)
  enum_value(:bezier, 1)
  enum_value(:spring, 2)
end
