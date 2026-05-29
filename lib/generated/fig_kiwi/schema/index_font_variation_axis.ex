defmodule FigKiwi.Schema.IndexFontVariationAxis do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:tag, 1, type: :string, source_name: "tag")
  field(:name, 2, type: :string, source_name: "name")
  field(:min, 3, type: :float, source_name: "min")
  field(:max, 4, type: :float, source_name: "max")
  field(:default_value, 5, type: :float, source_name: "defaultValue")
end
