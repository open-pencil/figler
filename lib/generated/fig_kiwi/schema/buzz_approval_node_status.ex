defmodule FigKiwi.Schema.BuzzApprovalNodeStatus do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:in_review, 1)
  enum_value(:approved, 2)
  enum_value(:changes_requested, 3)
end
