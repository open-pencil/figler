defmodule Figler.Native.CodecNifs do
  @moduledoc """
  Thin Elixir wrapper around native sparse Kiwi codec entrypoints.

  Dense schema decoding is provided by generated Elixir modules via
  `KiwiCodec.decode/2`; the native codec surface is reserved for sparse and
  focus-oriented map decoding that avoids materializing full schema structs.
  """

  alias Figler.Native.Module

  @delegates [
    :decode_sparse_message
  ]

  for name <- @delegates do
    defdelegate unquote(name)(binary), to: Module
  end

  defdelegate decode_graph_focused_sparse_message(binary, focus), to: Module
end
