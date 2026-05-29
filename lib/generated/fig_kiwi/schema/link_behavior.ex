defmodule FigKiwi.Schema.LinkBehavior do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.LinkBehaviorType}, source_name: "type")
  field(:url, 2, type: :string, source_name: "url")
  field(:page, 3, type: FigKiwi.Schema.GUID, source_name: "page")
  field(:open_in_new_window, 4, type: :bool, source_name: "openInNewWindow")
end
