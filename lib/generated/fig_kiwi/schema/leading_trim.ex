defmodule FigKiwi.Schema.LeadingTrim do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:cap_height, 1)
end
