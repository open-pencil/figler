defmodule FigKiwi.Schema.TextListData do
  @moduledoc "Generated Kiwi message module for `TextListData`."
  use KiwiCodec, kind: :message
  field(:list_id, 1, type: :int, source_name: "listID")
  field(:bullet_type, 2, type: {:enum, FigKiwi.Schema.BulletType}, source_name: "bulletType")
  field(:indentation_level, 3, type: :int, source_name: "indentationLevel")
  field(:line_number, 4, type: :int, source_name: "lineNumber")
end
