defmodule Figler.Schema.WindingRule do
  @moduledoc "Generated Kiwi enum module for `WindingRule`."
  use KiwiCodec, kind: :enum
  enum_value(:nonzero, 0)
  enum_value(:odd, 1)
end
