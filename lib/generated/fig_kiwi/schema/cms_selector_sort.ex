defmodule FigKiwi.Schema.CMSSelectorSort do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:cms_field_id, 1, type: :string, source_name: "cmsFieldId")
  field(:order_by, 2, type: {:enum, FigKiwi.Schema.CMSFieldOrderBy}, source_name: "orderBy")
end
