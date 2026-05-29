defmodule FigKiwi.Schema.MultiplayerMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:value, 2, type: :string, source_name: "value")
end
