defmodule Figler.Schema.PrototypeEvent do
  @moduledoc "Generated Kiwi message module for `PrototypeEvent`."
  use KiwiCodec, kind: :message

  field(:interaction_type, 1,
    type: {:enum, Figler.Schema.InteractionType},
    source_name: "interactionType"
  )

  field(:interaction_maintained, 2, type: :bool, source_name: "interactionMaintained")
  field(:interaction_duration, 3, type: :float, source_name: "interactionDuration")
  field(:key_trigger, 4, type: Figler.Schema.KeyTrigger, source_name: "keyTrigger")
  field(:voice_event_phrase, 5, type: :string, source_name: "voiceEventPhrase")
  field(:transition_timeout, 6, type: :float, source_name: "transitionTimeout")
  field(:media_hit_time, 7, type: :float, source_name: "mediaHitTime")
end
