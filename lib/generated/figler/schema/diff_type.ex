defmodule Figler.Schema.DiffType do
  @moduledoc "Generated Kiwi enum module for `DiffType`."
  use KiwiCodec, kind: :enum
  enum_value(:branching, 0)
  enum_value(:node_changes_only, 1)
end
