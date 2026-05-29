defmodule FigKiwi.Schema.IndexStyleRename do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:old_style, 1, type: :string, source_name: "oldStyle")
  field(:new_style, 2, type: :string, source_name: "newStyle")
end
