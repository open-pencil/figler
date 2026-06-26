defmodule Figler.Schema.TextDecoration do
  @moduledoc "Generated Kiwi enum module for `TextDecoration`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:underline, 1)
  enum_value(:strikethrough, 2)
end
