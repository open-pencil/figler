defmodule Figler.Schema.Hyperlink do
  @moduledoc "Generated Kiwi message module for `Hyperlink`."
  use KiwiCodec, kind: :message
  field(:url, 1, type: :string, source_name: "url")
  field(:guid, 2, type: Figler.Schema.GUID, source_name: "guid")
  field(:cms_target, 4, type: Figler.Schema.CMSItemPageTarget, source_name: "cmsTarget")
  field(:open_in_new_tab, 3, type: :bool, source_name: "openInNewTab")
end
