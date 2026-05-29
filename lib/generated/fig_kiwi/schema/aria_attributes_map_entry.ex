defmodule FigKiwi.Schema.ARIAAttributesMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:attribute, 1, type: :string, source_name: "attribute")
  field(:value, 2, type: FigKiwi.Schema.ARIAAttributeData, source_name: "value")
end
