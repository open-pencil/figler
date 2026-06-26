defmodule FigKiwi.Schema.SelectConfig do
  @moduledoc "Generated Kiwi message module for `SelectConfig`."
  use KiwiCodec, kind: :message
  field(:options, 1, repeated: true, type: FigKiwi.Schema.SelectOption, source_name: "options")
end
