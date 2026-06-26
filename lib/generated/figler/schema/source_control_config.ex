defmodule Figler.Schema.SourceControlConfig do
  @moduledoc "Generated Kiwi message module for `SourceControlConfig`."
  use KiwiCodec, kind: :message
  field(:origin, 1, type: Figler.Schema.GitRepoRef, source_name: "origin")
  field(:upstream, 2, type: Figler.Schema.GitRepoRef, source_name: "upstream")
end
