defmodule Figler.Schema.CooperRevertData do
  @moduledoc "Generated Kiwi message module for `CooperRevertData`."
  use KiwiCodec, kind: :message
  field(:original_values, 1, type: Figler.Schema.NodeChange, source_name: "originalValues")
end
