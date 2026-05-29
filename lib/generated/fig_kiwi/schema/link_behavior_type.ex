defmodule FigKiwi.Schema.LinkBehaviorType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:url, 1)
  enum_value(:page, 2)
end
