defmodule FigKiwi.Schema.AssetRef do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:version, 2, type: :string, source_name: "version")
end
