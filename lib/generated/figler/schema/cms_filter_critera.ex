defmodule Figler.Schema.CMSFilterCritera do
  @moduledoc "Generated Kiwi message module for `CMSFilterCritera`."
  use KiwiCodec, kind: :message

  field(:match_type, 1,
    type: {:enum, Figler.Schema.CMSFilterCriteriaMatchType},
    source_name: "matchType"
  )

  field(:filters, 2,
    repeated: true,
    type: Figler.Schema.CMSSelectorFilter,
    source_name: "filters"
  )
end
