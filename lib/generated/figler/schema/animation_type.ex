defmodule Figler.Schema.AnimationType do
  @moduledoc "Generated Kiwi enum module for `AnimationType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:fade, 1)
  enum_value(:slide_from_left, 2)
  enum_value(:slide_from_right, 3)
  enum_value(:slide_from_top, 4)
  enum_value(:slide_from_bottom, 5)
end
