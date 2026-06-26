defmodule Figler.Schema.ScrollPosition do
  @moduledoc "Generated Kiwi struct module for `ScrollPosition`."
  use KiwiCodec, kind: :struct
  field(:node, 1, type: Figler.Schema.GUID, source_name: "node")
  field(:scroll_offset, 2, type: Figler.Schema.Vector, source_name: "scrollOffset")
end
