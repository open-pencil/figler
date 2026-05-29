defmodule FigKiwi.Schema.PasteAssetType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:unknown, 0)
  enum_value(:variable, 1)
end
