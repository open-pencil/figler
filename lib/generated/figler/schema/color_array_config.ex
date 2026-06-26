defmodule Figler.Schema.ColorArrayConfig do
  @moduledoc "Generated Kiwi message module for `ColorArrayConfig`."
  use KiwiCodec, kind: :message
  field(:min_length, 1, type: :uint, source_name: "minLength")
  field(:max_length, 2, type: :uint, source_name: "maxLength")
end
