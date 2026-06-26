defmodule Figler.Schema.GitRepoRef do
  @moduledoc "Generated Kiwi message module for `GitRepoRef`."
  use KiwiCodec, kind: :message
  field(:provider, 1, type: {:enum, Figler.Schema.GitRepoRefProvider}, source_name: "provider")
  field(:git_repo, 2, type: :string, source_name: "gitRepo")
  field(:git_ref, 3, type: :string, source_name: "gitRef")
end
