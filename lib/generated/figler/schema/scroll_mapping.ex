defmodule Figler.Schema.ScrollMapping do
  @moduledoc "Generated Kiwi message module for `ScrollMapping`."
  use KiwiCodec, kind: :message
  field(:blueprint_id, 1, type: Figler.Schema.GUIDPath, source_name: "blueprintID")
  field(:overlay_index, 2, type: :uint, source_name: "overlayIndex")
  field(:scroll_offset, 3, type: Figler.Schema.Vector, source_name: "scrollOffset")
end
