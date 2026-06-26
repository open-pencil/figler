defmodule Figler.Schema.CMSSelectorFilter do
  @moduledoc "Generated Kiwi message module for `CMSSelectorFilter`."
  use KiwiCodec, kind: :message
  field(:cms_field_id, 1, type: :string, source_name: "cmsFieldId")
  field(:op, 2, type: {:enum, Figler.Schema.CMSSelectorFilterOperator}, source_name: "op")
  field(:comparison_value, 3, type: :string, source_name: "comparisonValue")
end
