defmodule FigKiwi.Schema.WidgetPropertyMenuSelectorOption do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:option, 1, type: :string, source_name: "option")
  field(:tooltip, 2, type: :string, source_name: "tooltip")
end
