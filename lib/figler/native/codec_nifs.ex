defmodule Figler.Native.CodecNifs do
  @moduledoc """
  Thin Elixir wrapper around native sparse Kiwi codec entrypoints.

  Dense schema decoding is provided by generated Elixir modules via
  `KiwiCodec.decode/2`; the native codec surface is reserved for sparse and
  focus-oriented map decoding that avoids materializing full schema structs.

  Every entrypoint takes a payload binary or a `t:Figler.Scene.source/0`.
  A source's schema lets the decoders skip fields newer Figma files add.
  """

  alias Figler.Native.Module
  alias Figler.Scene.Input

  def decode_sparse_message(source) do
    {payload, schema} = Input.to_source(source)
    Module.decode_sparse_message(payload, schema)
  end

  def decode_document_metadata(source) do
    {payload, schema} = Input.to_source(source)
    Module.decode_document_metadata(payload, schema)
  end

  def decode_graph_focused_sparse_message(source, focus) do
    {payload, schema} = Input.to_source(source)
    Module.decode_graph_focused_sparse_message(payload, schema, focus)
  end

  def decode_render_source_nodes(source, focus) do
    {payload, schema} = Input.to_source(source)
    Module.decode_render_source_nodes(payload, schema, focus)
  end
end
