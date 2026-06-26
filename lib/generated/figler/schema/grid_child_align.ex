defmodule Figler.Schema.GridChildAlign do
  @moduledoc "Generated Kiwi enum module for `GridChildAlign`."
  use KiwiCodec, kind: :enum
  enum_value(:auto, 0)
  enum_value(:min, 1)
  enum_value(:center, 2)
  enum_value(:max, 3)
end
