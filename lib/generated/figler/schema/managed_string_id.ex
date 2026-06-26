defmodule Figler.Schema.ManagedStringId do
  @moduledoc "Generated Kiwi message module for `ManagedStringId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
  field(:asset_ref, 2, type: Figler.Schema.AssetRef, source_name: "assetRef")
end
