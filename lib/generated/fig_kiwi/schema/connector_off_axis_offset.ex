defmodule FigKiwi.Schema.ConnectorOffAxisOffset do
  @moduledoc "Generated Kiwi enum module for `ConnectorOffAxisOffset`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:above, 1)
  enum_value(:below, 2)
end
