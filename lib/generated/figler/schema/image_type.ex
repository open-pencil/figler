defmodule Figler.Schema.ImageType do
  @moduledoc "Generated Kiwi enum module for `ImageType`."
  use KiwiCodec, kind: :enum
  enum_value(:png, 0)
  enum_value(:jpeg, 1)
  enum_value(:svg, 2)
  enum_value(:pdf, 3)
  enum_value(:mp4, 4)
  enum_value(:gif, 5)
end
