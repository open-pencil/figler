defmodule Figler.Schema.ARIAAttributeDataType do
  @moduledoc "Generated Kiwi enum module for `ARIAAttributeDataType`."
  use KiwiCodec, kind: :enum
  enum_value(:boolean, 0)
  enum_value(:string, 1)
  enum_value(:float, 2)
  enum_value(:int, 3)
  enum_value(:string_list, 4)
end
