defmodule Figler.Schema.ChildReadingDirection do
  @moduledoc "Generated Kiwi enum module for `ChildReadingDirection`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:left_to_right, 1)
  enum_value(:right_to_left, 2)
end
