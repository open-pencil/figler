defmodule FigKiwi.Schema.CMSSelectorFilter do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:cms_field_id, 1, type: :string, source_name: "cmsFieldId")
  field(:op, 2, type: {:enum, FigKiwi.Schema.CMSSelectorFilterOperator}, source_name: "op")
  field(:comparison_value, 3, type: :string, source_name: "comparisonValue")
end
