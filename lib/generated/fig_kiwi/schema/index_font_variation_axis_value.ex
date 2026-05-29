defmodule FigKiwi.Schema.IndexFontVariationAxisValue do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:tag, 1, type: :string, source_name: "tag")
  field(:value, 2, type: :float, source_name: "value")
end
