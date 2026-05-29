defmodule FigKiwi.Schema.CodeSnapshotState do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:initial, 0)
  enum_value(:snapshotting, 1)
  enum_value(:ok, 2)
  enum_value(:snapshot_error, 3)
  enum_value(:llm_in_progress, 4)
end
