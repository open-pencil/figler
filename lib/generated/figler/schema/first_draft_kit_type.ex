defmodule Figler.Schema.FirstDraftKitType do
  @moduledoc "Generated Kiwi enum module for `FirstDraftKitType`."
  use KiwiCodec, kind: :enum
  enum_value(:local, 0)
  enum_value(:library, 1)
  enum_value(:none, 2)
end
