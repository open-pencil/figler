defmodule Figler.Schema.Rotation3DConfig do
  @moduledoc "Generated Kiwi message module for `Rotation3DConfig`."
  use KiwiCodec, kind: :message
  field(:mode, 1, type: {:enum, Figler.Schema.PointMode}, source_name: "mode")
end
