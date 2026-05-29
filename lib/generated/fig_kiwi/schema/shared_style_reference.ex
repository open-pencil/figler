defmodule FigKiwi.Schema.SharedStyleReference do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:style_key, 1, type: :string, source_name: "styleKey")
  field(:version_hash, 2, type: :string, source_name: "versionHash")
end
