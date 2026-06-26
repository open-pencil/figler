defmodule Figler.Schema.PropRefValue do
  @moduledoc "Generated Kiwi message module for `PropRefValue`."
  use KiwiCodec, kind: :message
  field(:def_id, 1, type: Figler.Schema.GUID, source_name: "defId")
end
