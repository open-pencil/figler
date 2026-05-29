defmodule FigKiwi.Schema.MigrationStatus do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:dsd_cleanup, 1, type: :bool, source_name: "dsdCleanup")
end
