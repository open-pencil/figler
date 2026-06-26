defmodule FigKiwi.Schema.PrototypeStartingPoint do
  @moduledoc "Generated Kiwi message module for `PrototypeStartingPoint`."
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:description, 2, type: :string, source_name: "description")
  field(:position, 3, type: :string, source_name: "position")
end
