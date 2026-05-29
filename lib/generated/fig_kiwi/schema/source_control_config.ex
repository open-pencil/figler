defmodule FigKiwi.Schema.SourceControlConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:origin, 1, type: FigKiwi.Schema.GitRepoRef, source_name: "origin")
  field(:upstream, 2, type: FigKiwi.Schema.GitRepoRef, source_name: "upstream")
end
