defmodule FigKiwi.Schema.CodeObjectType do
  @moduledoc "Generated Kiwi enum module for `CodeObjectType`."
  use KiwiCodec, kind: :enum
  enum_value(:web_layer, 0)
  enum_value(:web_interaction, 1)
  enum_value(:native_layer, 2)
  enum_value(:animation_preset, 3)
  enum_value(:tool, 4)
  enum_value(:custom_effect, 5)
  enum_value(:plugin, 6)
  enum_value(:web_layer_generic, 7)
  enum_value(:custom_fill, 8)
end
