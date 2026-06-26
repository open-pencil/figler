defmodule Figler.Schema.CMSFilterCriteriaMatchType do
  @moduledoc "Generated Kiwi enum module for `CMSFilterCriteriaMatchType`."
  use KiwiCodec, kind: :enum
  enum_value(:match_all, 0)
  enum_value(:match_any, 1)
end
