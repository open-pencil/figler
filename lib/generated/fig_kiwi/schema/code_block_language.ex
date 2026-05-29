defmodule FigKiwi.Schema.CodeBlockLanguage do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:typescript, 0)
  enum_value(:cpp, 1)
  enum_value(:ruby, 2)
  enum_value(:css, 3)
  enum_value(:javascript, 4)
  enum_value(:html, 5)
  enum_value(:json, 6)
  enum_value(:graphql, 7)
  enum_value(:python, 8)
  enum_value(:go, 9)
  enum_value(:sql, 10)
  enum_value(:swift, 11)
  enum_value(:kotlin, 12)
  enum_value(:rust, 13)
  enum_value(:bash, 14)
  enum_value(:plaintext, 15)
  enum_value(:markdown, 16)
end
