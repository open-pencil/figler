defmodule FigKiwi.Schema.KeyTrigger do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key_codes, 1, repeated: true, type: :int, source_name: "keyCodes")

  field(:trigger_device, 2,
    type: {:enum, FigKiwi.Schema.TriggerDevice},
    source_name: "triggerDevice"
  )
end
