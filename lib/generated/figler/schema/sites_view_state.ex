defmodule Figler.Schema.SitesViewState do
  @moduledoc "Generated Kiwi enum module for `SitesViewState`."
  use KiwiCodec, kind: :enum
  enum_value(:file, 0)
  enum_value(:code, 1)
  enum_value(:dakota, 2)
  enum_value(:settings, 3)
  enum_value(:insert, 4)
  enum_value(:variables, 5)
end
