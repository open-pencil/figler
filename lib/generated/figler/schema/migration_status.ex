defmodule Figler.Schema.MigrationStatus do
  @moduledoc "Generated Kiwi message module for `MigrationStatus`."
  use KiwiCodec, kind: :message
  field(:dsd_cleanup, 1, type: :bool, source_name: "dsdCleanup")
end
