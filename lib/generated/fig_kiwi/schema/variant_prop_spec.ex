defmodule FigKiwi.Schema.VariantPropSpec do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:prop_def_id, 1, type: FigKiwi.Schema.GUID, source_name: "propDefId")
  field(:value, 2, type: :string, source_name: "value")
end
