defmodule Figler.Schema.TriggerDevice do
  @moduledoc "Generated Kiwi enum module for `TriggerDevice`."
  use KiwiCodec, kind: :enum
  enum_value(:keyboard, 0)
  enum_value(:unknown_controller, 1)
  enum_value(:xbox_one, 2)
  enum_value(:ps4, 3)
  enum_value(:switch_pro, 4)
end
