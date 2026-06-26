defmodule FigKiwi.Schema.PropRefValue do
  @moduledoc "Generated Kiwi message module for `PropRefValue`."
  use KiwiCodec, kind: :message
  field(:def_id, 1, type: FigKiwi.Schema.GUID, source_name: "defId")
end
