defmodule FigKiwi.Schema.GitRepoRef do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:provider, 1, type: {:enum, FigKiwi.Schema.GitRepoRefProvider}, source_name: "provider")
  field(:git_repo, 2, type: :string, source_name: "gitRepo")
  field(:git_ref, 3, type: :string, source_name: "gitRef")
end
