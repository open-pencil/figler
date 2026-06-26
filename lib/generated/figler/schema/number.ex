defmodule Figler.Schema.Number do
  @moduledoc "Generated Kiwi struct module for `Number`."
  use KiwiCodec, kind: :struct
  field(:value, 1, type: :float, source_name: "value")
  field(:units, 2, type: {:enum, Figler.Schema.NumberUnits}, source_name: "units")
end
