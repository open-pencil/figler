defmodule Figler.Schema.InternalDataForTest do
  @moduledoc "Generated Kiwi message module for `InternalDataForTest`."
  use KiwiCodec, kind: :message
  field(:test_field_a, 1, type: :int, source_name: "testFieldA")
end
