defmodule FigKiwi.Schema.ObjectAnimationList do
  @moduledoc "Generated Kiwi message module for `ObjectAnimationList`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.ObjectAnimationListItem,
    source_name: "entries"
  )
end
