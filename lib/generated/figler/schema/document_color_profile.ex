defmodule Figler.Schema.DocumentColorProfile do
  @moduledoc "Generated Kiwi enum module for `DocumentColorProfile`."
  use KiwiCodec, kind: :enum
  enum_value(:legacy, 0)
  enum_value(:srgb, 1)
  enum_value(:display_p3, 2)
end
