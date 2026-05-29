defmodule FigKiwi.Schema.CodeEmbedInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:url, 1, type: :string, source_name: "url")
  field(:src_url, 2, type: :string, source_name: "srcUrl")
  field(:title, 3, type: :string, source_name: "title")
  field(:thumbnail_image_hash, 4, type: :string, source_name: "thumbnailImageHash")
  field(:is_published_site, 5, type: :bool, source_name: "isPublishedSite")
end
