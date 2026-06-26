defmodule Figler.Schema.OptionalVector do
  @moduledoc "Generated Kiwi message module for `OptionalVector`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: Figler.Schema.Vector, source_name: "value")
end
