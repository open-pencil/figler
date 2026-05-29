defmodule FigKiwi.Schema.ComponentPropPreferredValues do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:string_values, 1, repeated: true, type: :string, source_name: "stringValues")

  field(:instance_swap_values, 2,
    repeated: true,
    type: FigKiwi.Schema.InstanceSwapPreferredValue,
    source_name: "instanceSwapValues"
  )
end
