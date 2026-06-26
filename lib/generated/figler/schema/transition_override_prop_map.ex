defmodule Figler.Schema.TransitionOverridePropMap do
  @moduledoc "Generated Kiwi message module for `TransitionOverridePropMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.TransitionOverridePropMapEntry,
    source_name: "entries"
  )
end
