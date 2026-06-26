defmodule Figler.Schema.FontMetaData do
  @moduledoc "Generated Kiwi message module for `FontMetaData`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: Figler.Schema.FontName, source_name: "key")
  field(:font_line_height, 2, type: :float, source_name: "fontLineHeight")
  field(:font_digest, 3, repeated: true, type: :byte, source_name: "fontDigest")
  field(:font_style, 4, type: {:enum, Figler.Schema.FontStyle}, source_name: "fontStyle")
  field(:font_weight, 5, type: :int, source_name: "fontWeight")
end
