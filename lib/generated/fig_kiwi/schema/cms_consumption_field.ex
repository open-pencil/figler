defmodule FigKiwi.Schema.CMSConsumptionField do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:missing, 0)
  enum_value(:text_data, 1)
end
