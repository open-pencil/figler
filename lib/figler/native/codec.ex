defmodule Figler.Native.Codec do
  @moduledoc """
  Thin Elixir wrapper around native Kiwi codec NIFs.

  The functions in this module intentionally mirror NIF names and return raw
  decoded terms for callers that need sparse or full schema decoding without
  the higher-level convenience functions.
  """

  alias Figler.Native.Nif

  @delegates [
    :decode_guid,
    :decode_vector,
    :decode_matrix,
    :decode_parent_index,
    :decode_image,
    :decode_node_change,
    :decode_message,
    :decode_sparse_message
  ]

  for name <- @delegates do
    defdelegate unquote(name)(binary), to: Nif
  end

  defdelegate decode_graph_focused_sparse_message(binary, focus), to: Nif
end
