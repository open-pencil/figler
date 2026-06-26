defmodule FigKiwi.Schema.ConditionalActions do
  @moduledoc "Generated Kiwi message module for `ConditionalActions`."
  use KiwiCodec, kind: :message
  field(:actions, 1, repeated: true, type: FigKiwi.Schema.PrototypeAction, source_name: "actions")
  field(:condition, 2, type: FigKiwi.Schema.VariableData, source_name: "condition")
end
