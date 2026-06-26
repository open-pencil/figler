defmodule Figler.Schema.SectionPresetState do
  @moduledoc "Generated Kiwi enum module for `SectionPresetState`."
  use KiwiCodec, kind: :enum
  enum_value(:inserted, 0)
  enum_value(:user_edited, 1)
end
