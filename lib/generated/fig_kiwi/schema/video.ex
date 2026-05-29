defmodule FigKiwi.Schema.Video do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:hash, 1, repeated: true, type: :byte, source_name: "hash")
  field(:s3_url, 2, type: :string, source_name: "s3Url")
end
