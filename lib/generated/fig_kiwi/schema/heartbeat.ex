defmodule FigKiwi.Schema.Heartbeat do
  @moduledoc "Generated Kiwi enum module for `Heartbeat`."
  use KiwiCodec, kind: :enum
  enum_value(:foreground, 0)
  enum_value(:background, 1)
end
