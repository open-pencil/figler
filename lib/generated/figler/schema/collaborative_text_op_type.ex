defmodule Figler.Schema.CollaborativeTextOpType do
  @moduledoc "Generated Kiwi enum module for `CollaborativeTextOpType`."
  use KiwiCodec, kind: :enum
  enum_value(:insert, 0)
  enum_value(:delete, 1)
end
