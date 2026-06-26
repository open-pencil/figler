defmodule Figler.Schema.ConnectorControlPoint do
  @moduledoc "Generated Kiwi message module for `ConnectorControlPoint`."
  use KiwiCodec, kind: :message
  field(:position, 1, type: Figler.Schema.Vector, source_name: "position")
  field(:axis, 2, type: Figler.Schema.Vector, source_name: "axis")
end
