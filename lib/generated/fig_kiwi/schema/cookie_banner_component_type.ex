defmodule FigKiwi.Schema.CookieBannerComponentType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:banner, 0)
  enum_value(:modal, 1)
end
