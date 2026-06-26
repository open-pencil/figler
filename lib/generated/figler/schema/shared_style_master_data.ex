defmodule Figler.Schema.SharedStyleMasterData do
  @moduledoc "Generated Kiwi message module for `SharedStyleMasterData`."
  use KiwiCodec, kind: :message
  field(:style_key, 1, type: :string, source_name: "styleKey")
  field(:sort_position, 2, type: :string, source_name: "sortPosition")
  field(:file_key, 3, type: :string, source_name: "fileKey")
end
