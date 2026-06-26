defmodule Figler.Schema.AprilFunFigPal do
  @moduledoc "Generated Kiwi message module for `AprilFunFigPal`."
  use KiwiCodec, kind: :message
  field(:customization, 1, type: :string, source_name: "customization")
  field(:name, 2, type: :string, source_name: "name")
end
