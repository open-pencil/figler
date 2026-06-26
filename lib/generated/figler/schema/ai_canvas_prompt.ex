defmodule Figler.Schema.AiCanvasPrompt do
  @moduledoc "Generated Kiwi message module for `AiCanvasPrompt`."
  use KiwiCodec, kind: :message
  field(:user_prompt, 1, type: :string, source_name: "userPrompt")
  field(:author_id, 2, type: :string, source_name: "authorId")

  field(:parent_node_ids, 3,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "parentNodeIds"
  )
end
