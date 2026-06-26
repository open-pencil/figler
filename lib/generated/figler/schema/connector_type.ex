defmodule Figler.Schema.ConnectorType do
  @moduledoc "Generated Kiwi enum module for `ConnectorType`."
  use KiwiCodec, kind: :enum
  enum_value(:manual, 0)
  enum_value(:diagram, 1)
end
