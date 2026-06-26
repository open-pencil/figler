defmodule Figler.Schema.TransformSchemaType do
  @moduledoc "Generated Kiwi enum module for `TransformSchemaType`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:fixed_order, 1)
  enum_value(:freeform, 2)
end
