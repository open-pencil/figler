defmodule Figler.Native.CodecNifs do
  @moduledoc """
  Thin Elixir wrapper around native sparse Kiwi codec entrypoints.

  Dense schema decoding is provided by generated Elixir modules via
  `KiwiCodec.decode/2`; the native codec surface is reserved for sparse and
  focus-oriented map decoding that avoids materializing full schema structs.
  """

  alias Figler.Native.Module
  alias Figler.Scene.Graph.Seed.Projection

  @delegates [:decode_sparse_message]

  for name <- @delegates do
    defdelegate unquote(name)(binary), to: Module
  end

  def decode_graph_seed_records(binary) when is_binary(binary) do
    Module.decode_graph_seed_records(binary, Projection.native_all_stage_mask())
  end

  def decode_graph_seed_records(binary, stages) when is_binary(binary) and is_list(stages) do
    Module.decode_graph_seed_records(binary, Projection.native_stage_mask(stages))
  end

  defdelegate decode_graph_focused_sparse_message(binary, focus), to: Module
end
