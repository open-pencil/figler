defmodule Figler.Schema.NavigationType do
  @moduledoc "Generated Kiwi enum module for `NavigationType`."
  use KiwiCodec, kind: :enum
  enum_value(:navigate, 0)
  enum_value(:overlay, 1)
  enum_value(:swap, 2)
  enum_value(:swap_state, 3)
  enum_value(:scroll_to, 4)
end
