defmodule FigKiwi.Schema.AprilFunFigPal do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:customization, 1, type: :string, source_name: "customization")
  field(:name, 2, type: :string, source_name: "name")
end
