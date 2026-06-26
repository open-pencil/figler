defmodule FigKiwi.Schema.CooperTemplateData do
  @moduledoc "Generated Kiwi message module for `CooperTemplateData`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.CooperTemplateType}, source_name: "type")
end
