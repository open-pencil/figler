defmodule FigKiwi.Schema.GitRepoRefProvider do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:ugit, 0)
  enum_value(:github, 1)
  enum_value(:other, 2)
end
