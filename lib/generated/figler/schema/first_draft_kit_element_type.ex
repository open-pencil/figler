defmodule Figler.Schema.FirstDraftKitElementType do
  @moduledoc "Generated Kiwi enum module for `FirstDraftKitElementType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:building_block, 1)
  enum_value(:grouped_component, 2)
end
