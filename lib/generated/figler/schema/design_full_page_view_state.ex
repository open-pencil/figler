defmodule Figler.Schema.DesignFullPageViewState do
  @moduledoc "Generated Kiwi enum module for `DesignFullPageViewState`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:design_system, 1)
  enum_value(:variables, 2)
end
