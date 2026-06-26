defmodule Figler.Schema.KeyTrigger do
  @moduledoc "Generated Kiwi message module for `KeyTrigger`."
  use KiwiCodec, kind: :message
  field(:key_codes, 1, repeated: true, type: :int, source_name: "keyCodes")

  field(:trigger_device, 2,
    type: {:enum, Figler.Schema.TriggerDevice},
    source_name: "triggerDevice"
  )
end
