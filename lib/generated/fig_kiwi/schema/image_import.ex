defmodule FigKiwi.Schema.ImageImport do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:image, 2, type: FigKiwi.Schema.Image, source_name: "image")
end
