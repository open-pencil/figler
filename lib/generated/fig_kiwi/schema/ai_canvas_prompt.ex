defmodule FigKiwi.Schema.AiCanvasPrompt do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:user_prompt, 1, type: :string, source_name: "userPrompt")
  field(:author_id, 2, type: :string, source_name: "authorId")

  field(:parent_node_ids, 3,
    repeated: true,
    type: FigKiwi.Schema.GUID,
    source_name: "parentNodeIds"
  )
end
