defmodule FigKiwi.Schema.FlappType do
  @moduledoc "Generated Kiwi enum module for `FlappType`."
  use KiwiCodec, kind: :enum
  enum_value(:poll, 0)
  enum_value(:embed, 1)
  enum_value(:facepile, 2)
  enum_value(:alignment, 3)
  enum_value(:youtube, 4)
end
