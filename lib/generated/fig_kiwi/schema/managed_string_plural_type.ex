defmodule FigKiwi.Schema.ManagedStringPluralType do
  @moduledoc "Generated Kiwi enum module for `ManagedStringPluralType`."
  use KiwiCodec, kind: :enum
  enum_value(:zero, 0)
  enum_value(:one, 1)
  enum_value(:two, 2)
  enum_value(:few, 3)
  enum_value(:many, 4)
  enum_value(:other, 5)
end
