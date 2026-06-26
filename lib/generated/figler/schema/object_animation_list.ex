defmodule Figler.Schema.ObjectAnimationList do
  @moduledoc "Generated Kiwi message module for `ObjectAnimationList`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.ObjectAnimationListItem,
    source_name: "entries"
  )
end
