defmodule FigKiwi.Schema.LinkPreviewData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:url, 1, type: :string, source_name: "url")
  field(:title, 2, type: :string, source_name: "title")
  field(:provider, 3, type: :string, source_name: "provider")
  field(:description, 4, type: :string, source_name: "description")
  field(:thumbnail_image_hash, 5, type: :string, source_name: "thumbnailImageHash")
  field(:favicon_image_hash, 6, type: :string, source_name: "faviconImageHash")
  field(:thumbnail_image_width, 7, type: :float, source_name: "thumbnailImageWidth")
  field(:thumbnail_image_height, 8, type: :float, source_name: "thumbnailImageHeight")
end
