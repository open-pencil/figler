defmodule FigKiwi.Schema.InstanceSwapPreferredValue do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:type, 1,
    type: {:enum, FigKiwi.Schema.InstanceSwapPreferredValueType},
    source_name: "type"
  )

  field(:key, 2, type: :string, source_name: "key")
end
