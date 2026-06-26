defmodule Figler.Schema.EmbedData do
  @moduledoc "Generated Kiwi message module for `EmbedData`."
  use KiwiCodec, kind: :message
  field(:url, 1, type: :string, source_name: "url")
  field(:src_url, 2, type: :string, source_name: "srcUrl")
  field(:title, 3, type: :string, source_name: "title")
  field(:thumbnail_url, 4, type: :string, source_name: "thumbnailUrl")
  field(:width, 5, type: :float, source_name: "width")
  field(:height, 6, type: :float, source_name: "height")
  field(:embed_type, 7, type: :string, source_name: "embedType")
  field(:thumbnail_image_hash, 8, type: :string, source_name: "thumbnailImageHash")
  field(:favicon_image_hash, 9, type: :string, source_name: "faviconImageHash")
  field(:provider, 10, type: :string, source_name: "provider")
  field(:original_text, 11, type: :string, source_name: "originalText")
  field(:description, 12, type: :string, source_name: "description")
  field(:embed_version_id, 13, type: :string, source_name: "embedVersionId")
  field(:is_published_site, 14, type: :bool, source_name: "isPublishedSite")
end
