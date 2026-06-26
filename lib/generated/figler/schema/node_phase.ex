defmodule Figler.Schema.NodePhase do
  @moduledoc "Generated Kiwi enum module for `NodePhase`."
  use KiwiCodec, kind: :enum
  enum_value(:created, 0)
  enum_value(:removed, 1)
end
