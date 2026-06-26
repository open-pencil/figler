defmodule FigKiwi.Schema.CodeSyntaxMapEntry do
  @moduledoc "Generated Kiwi message module for `CodeSyntaxMapEntry`."
  use KiwiCodec, kind: :message
  field(:platform, 1, type: {:enum, FigKiwi.Schema.CodeSyntaxPlatform}, source_name: "platform")
  field(:value, 2, type: :string, source_name: "value")
end
