defmodule FigKiwi.Schema.JsRuntimeAlias do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:lookup_key, 1, type: :string, source_name: "lookupKey")
end
