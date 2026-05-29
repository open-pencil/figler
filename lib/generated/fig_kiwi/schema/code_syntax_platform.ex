defmodule FigKiwi.Schema.CodeSyntaxPlatform do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:web, 0)
  enum_value(:android, 1)
  enum_value(:i_os, 2)
end
