defmodule FigKiwi.Schema.InternalDataForTest do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:test_field_a, 1, type: :int, source_name: "testFieldA")
end
