defmodule FigKiwi.Schema.CMSConsumptionMapEntry do
  @moduledoc "Generated Kiwi message module for `CMSConsumptionMapEntry`."
  use KiwiCodec, kind: :message

  field(:consumption_field, 1,
    type: {:enum, FigKiwi.Schema.CMSConsumptionField},
    source_name: "consumptionField"
  )

  field(:cms_field_id, 2, type: :string, source_name: "cmsFieldId")
end
