defmodule FigKiwi.Schema.RichMediaType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:animated_image, 0)
  enum_value(:video, 1)
end
