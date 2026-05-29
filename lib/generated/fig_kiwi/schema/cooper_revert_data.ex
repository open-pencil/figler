defmodule FigKiwi.Schema.CooperRevertData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:original_values, 1, type: FigKiwi.Schema.NodeChange, source_name: "originalValues")
end
