defmodule FigKiwi do
  @moduledoc """
  Figma schema helpers built on `KiwiCodec`.
  """

  @schema_path :fig_kiwi |> :code.priv_dir() |> Path.join("schema/fig.kiwi")

  @doc """
  Returns the vendored Figma Kiwi schema text.
  """
  @spec schema_text() :: String.t()
  def schema_text do
    File.read!(@schema_path)
  end

  @doc """
  Parses the vendored Figma Kiwi schema.
  """
  @spec schema() :: KiwiCodec.Schema.t()
  def schema do
    schema_text()
    |> KiwiCodec.parse_schema!()
  end

  @doc """
  Decodes a Figma `Message` payload into generated schema structs.
  """
  @spec decode_message(binary()) :: FigKiwi.Schema.Message.t()
  def decode_message(binary) when is_binary(binary) do
    KiwiCodec.decode(binary, FigKiwi.Schema.Message)
  end

  @doc """
  Encodes a generated Figma `Message` struct.
  """
  @spec encode_message(FigKiwi.Schema.Message.t()) :: binary()
  def encode_message(%FigKiwi.Schema.Message{} = message) do
    KiwiCodec.encode(message)
  end

  @doc """
  Decodes a Figma `Message` payload with the runtime schema interpreter.
  """
  @spec decode_message_runtime(binary()) :: map()
  def decode_message_runtime(binary) when is_binary(binary) do
    schema()
    |> KiwiCodec.Runtime.decode("Message", binary)
  end

  @doc """
  Encodes a Figma `Message` map with the runtime schema interpreter.
  """
  @spec encode_message_runtime(map()) :: binary()
  def encode_message_runtime(message) when is_map(message) do
    schema()
    |> KiwiCodec.Runtime.encode("Message", message)
  end
end
