defmodule FigKiwi.Schema.GitRepoRefProvider do
  @moduledoc "Generated Kiwi enum module for `GitRepoRefProvider`."
  use KiwiCodec, kind: :enum
  enum_value(:ugit, 0)
  enum_value(:github, 1)
  enum_value(:other, 2)
end
