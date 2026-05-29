defmodule FigKiwi.Schema.FirstDraftData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:generation_id, 1, type: :string, source_name: "generationId")
  field(:kit, 2, type: FigKiwi.Schema.FirstDraftKit, source_name: "kit")
end
