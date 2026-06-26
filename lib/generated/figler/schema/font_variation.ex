defmodule Figler.Schema.FontVariation do
  @moduledoc "Generated Kiwi message module for `FontVariation`."
  use KiwiCodec, kind: :message
  field(:axis_tag, 1, type: :uint, source_name: "axisTag")
  field(:axis_name, 2, type: :string, source_name: "axisName")
  field(:value, 3, type: :float, source_name: "value")
end
