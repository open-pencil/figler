defmodule FigKiwi.Schema.HyperlinkBox do
  @moduledoc "Generated Kiwi message module for `HyperlinkBox`."
  use KiwiCodec, kind: :message
  field(:bounds, 1, type: FigKiwi.Schema.Rect, source_name: "bounds")
  field(:url, 2, type: :string, source_name: "url")
  field(:guid, 3, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:cms_target, 5, type: FigKiwi.Schema.CMSItemPageTarget, source_name: "cmsTarget")
  field(:open_in_new_tab, 6, type: :bool, source_name: "openInNewTab")
  field(:hyperlink_id, 4, type: :int, source_name: "hyperlinkID")
end
