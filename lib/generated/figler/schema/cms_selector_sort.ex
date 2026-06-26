defmodule Figler.Schema.CMSSelectorSort do
  @moduledoc "Generated Kiwi message module for `CMSSelectorSort`."
  use KiwiCodec, kind: :message
  field(:cms_field_id, 1, type: :string, source_name: "cmsFieldId")
  field(:order_by, 2, type: {:enum, Figler.Schema.CMSFieldOrderBy}, source_name: "orderBy")
end
