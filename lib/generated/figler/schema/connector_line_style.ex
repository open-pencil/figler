defmodule Figler.Schema.ConnectorLineStyle do
  @moduledoc "Generated Kiwi enum module for `ConnectorLineStyle`."
  use KiwiCodec, kind: :enum
  enum_value(:elbowed, 0)
  enum_value(:straight, 1)
  enum_value(:curved, 2)
end
