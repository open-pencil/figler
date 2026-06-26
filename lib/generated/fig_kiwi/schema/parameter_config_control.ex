defmodule FigKiwi.Schema.ParameterConfigControl do
  @moduledoc "Generated Kiwi enum module for `ParameterConfigControl`."
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:slider, 1)
  enum_value(:input, 2)
  enum_value(:select, 3)
end
