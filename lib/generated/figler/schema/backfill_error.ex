defmodule Figler.Schema.BackfillError do
  @moduledoc "Generated Kiwi enum module for `BackfillError`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:transient_retrying, 1)
  enum_value(:permanently_failed, 2)
  enum_value(:paste_failed, 3)
end
