defmodule FigKiwi.Schema.ImageParameterValue do
  @moduledoc "Generated Kiwi message module for `ImageParameterValue`."
  use KiwiCodec, kind: :message
  field(:image, 1, type: FigKiwi.Schema.Image, source_name: "image")
  field(:image_thumbnail, 2, type: FigKiwi.Schema.Image, source_name: "imageThumbnail")
  field(:animated_image, 6, type: FigKiwi.Schema.Image, source_name: "animatedImage")
  field(:alt_text, 3, type: :string, source_name: "altText")
  field(:original_image_height, 4, type: :uint, source_name: "originalImageHeight")
  field(:original_image_width, 5, type: :uint, source_name: "originalImageWidth")
  field(:animation_frame, 7, type: :uint, source_name: "animationFrame")
end
