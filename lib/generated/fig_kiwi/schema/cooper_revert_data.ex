defmodule FigKiwi.Schema.CooperRevertData do
  @moduledoc "Generated Kiwi message module for `CooperRevertData`."
  use KiwiCodec, kind: :message
  field(:original_values, 1, type: FigKiwi.Schema.NodeChange, source_name: "originalValues")
end
