defmodule FigKiwi.Schema.CooperTemplateData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.CooperTemplateType}, source_name: "type")
end
