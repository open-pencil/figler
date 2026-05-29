defmodule FigKiwi.Schema.CMSFilterCriteriaMatchType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:match_all, 0)
  enum_value(:match_any, 1)
end
