defmodule Figler.Schema.TimelineBindingData do
  @moduledoc "Generated Kiwi message module for `TimelineBindingData`."
  use KiwiCodec, kind: :message
  field(:offset_us, 1, type: :int64, source_name: "offsetUs")
  field(:disabled, 2, type: :bool, source_name: "disabled")
end
