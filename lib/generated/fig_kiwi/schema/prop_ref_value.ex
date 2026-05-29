defmodule FigKiwi.Schema.PropRefValue do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:def_id, 1, type: FigKiwi.Schema.GUID, source_name: "defId")
end
