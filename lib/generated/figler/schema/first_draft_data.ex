defmodule Figler.Schema.FirstDraftData do
  @moduledoc "Generated Kiwi message module for `FirstDraftData`."
  use KiwiCodec, kind: :message
  field(:generation_id, 1, type: :string, source_name: "generationId")
  field(:kit, 2, type: Figler.Schema.FirstDraftKit, source_name: "kit")
end
