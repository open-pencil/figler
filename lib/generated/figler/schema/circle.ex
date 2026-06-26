defmodule Figler.Schema.Circle do
  @moduledoc "Generated Kiwi message module for `Circle`."
  use KiwiCodec, kind: :message
  field(:center, 1, type: Figler.Schema.Vector, source_name: "center")
  field(:radius, 2, type: :float, source_name: "radius")
end
