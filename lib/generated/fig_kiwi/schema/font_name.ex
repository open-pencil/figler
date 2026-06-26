defmodule FigKiwi.Schema.FontName do
  @moduledoc "Generated Kiwi struct module for `FontName`."
  use KiwiCodec, kind: :struct
  field(:family, 1, type: :string, source_name: "family")
  field(:style, 2, type: :string, source_name: "style")
  field(:postscript, 3, type: :string, source_name: "postscript")
end
