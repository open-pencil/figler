defmodule FigKiwi.Schema.ConnectorTextSection do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:middle_to_start, 0)
  enum_value(:middle_to_end, 1)
end
