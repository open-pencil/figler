defmodule Figler.Schema.ComponentPropPreferredValues do
  @moduledoc "Generated Kiwi message module for `ComponentPropPreferredValues`."
  use KiwiCodec, kind: :message
  field(:string_values, 1, repeated: true, type: :string, source_name: "stringValues")

  field(:instance_swap_values, 2,
    repeated: true,
    type: Figler.Schema.InstanceSwapPreferredValue,
    source_name: "instanceSwapValues"
  )
end
