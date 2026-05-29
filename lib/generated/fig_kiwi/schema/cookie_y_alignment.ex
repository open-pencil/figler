defmodule FigKiwi.Schema.CookieYAlignment do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:top, 0)
  enum_value(:center, 1)
  enum_value(:bottom, 2)
end
