defmodule Figler.Schema.CodeSyntaxMapEntry do
  @moduledoc "Generated Kiwi message module for `CodeSyntaxMapEntry`."
  use KiwiCodec, kind: :message
  field(:platform, 1, type: {:enum, Figler.Schema.CodeSyntaxPlatform}, source_name: "platform")
  field(:value, 2, type: :string, source_name: "value")
end
