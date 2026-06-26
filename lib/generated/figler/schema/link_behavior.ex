defmodule Figler.Schema.LinkBehavior do
  @moduledoc "Generated Kiwi message module for `LinkBehavior`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.LinkBehaviorType}, source_name: "type")
  field(:url, 2, type: :string, source_name: "url")
  field(:page, 3, type: Figler.Schema.GUID, source_name: "page")
  field(:open_in_new_window, 4, type: :bool, source_name: "openInNewWindow")
end
