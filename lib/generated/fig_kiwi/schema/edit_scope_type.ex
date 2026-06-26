defmodule FigKiwi.Schema.EditScopeType do
  @moduledoc "Generated Kiwi enum module for `EditScopeType`."
  use KiwiCodec, kind: :enum
  enum_value(:invalid, 0)
  enum_value(:test_setup, 1)
  enum_value(:user, 2)
  enum_value(:plugin, 3)
  enum_value(:system, 4)
  enum_value(:rest_api, 5)
  enum_value(:onboarding, 6)
  enum_value(:autosave, 7)
  enum_value(:ai, 8)
end
