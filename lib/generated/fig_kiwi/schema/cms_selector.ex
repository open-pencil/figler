defmodule FigKiwi.Schema.CMSSelector do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:cms_collection_id, 1, type: :string, source_name: "cmsCollectionId")
  field(:filter_criteria, 2, type: FigKiwi.Schema.CMSFilterCritera, source_name: "filterCriteria")
  field(:sorts, 3, repeated: true, type: FigKiwi.Schema.CMSSelectorSort, source_name: "sorts")
  field(:limit, 4, type: :uint, source_name: "limit")
end
