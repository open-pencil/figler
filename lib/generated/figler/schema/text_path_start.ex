defmodule Figler.Schema.TextPathStart do
  @moduledoc "Generated Kiwi message module for `TextPathStart`."
  use KiwiCodec, kind: :message
  field(:t_value, 1, type: :float, source_name: "tValue")
  field(:forward, 2, type: :bool, source_name: "forward")
end
