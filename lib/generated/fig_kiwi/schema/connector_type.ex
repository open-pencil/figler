defmodule FigKiwi.Schema.ConnectorType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:manual, 0)
  enum_value(:diagram, 1)
end
