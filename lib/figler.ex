defmodule Figler do
  @moduledoc """
  Figma schema helpers built on `KiwiCodec`.
  """

  alias Figler.Native.CodecNifs

  @schema_path :figler |> :code.priv_dir() |> Path.join("schema/fig.kiwi")
  @external_resource @schema_path
  @schema_version @schema_path |> File.read!() |> :erlang.md5()
  @schema_cache_key {__MODULE__, :schema}
  @prepared_schema_cache_key {__MODULE__, :prepared_schema}

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
    cached(@schema_cache_key, fn -> schema_text() |> KiwiCodec.parse_schema!() end)
  end

  @doc """
  Decodes a Figma `Message` payload into generated schema structs.
  """
  @spec decode_message(binary()) :: Figler.Schema.Message.t()
  def decode_message(binary) when is_binary(binary) do
    KiwiCodec.decode(binary, Figler.Schema.Message)
  end

  @doc """
  Decodes a Figma `Message` payload into sparse schema-backed maps.

  Sparse maps include `:__kiwi_module__` and only fields present on the wire.
  This avoids materializing hundreds of nil fields per large `NodeChange`.
  """
  @spec decode_sparse_message(binary()) :: map()
  def decode_sparse_message(binary) when is_binary(binary) do
    CodecNifs.decode_sparse_message(binary)
  end

  @doc """
  Encodes a generated Figma `Message` struct.
  """
  @spec encode_message(Figler.Schema.Message.t()) :: binary()
  def encode_message(%Figler.Schema.Message{} = message) do
    KiwiCodec.encode(message)
  end

  @doc """
  Decodes a Figma `Message` payload with the runtime schema interpreter.
  """
  @spec decode_message_runtime(binary()) :: map()
  def decode_message_runtime(binary) when is_binary(binary) do
    prepared_schema()
    |> KiwiCodec.SchemaInterpreter.decode("Message", binary)
  end

  @doc """
  Encodes a Figma `Message` map with the runtime schema interpreter.
  """
  @spec encode_message_runtime(map()) :: binary()
  def encode_message_runtime(message) when is_map(message) do
    prepared_schema()
    |> KiwiCodec.SchemaInterpreter.encode("Message", message)
  end

  defp prepared_schema do
    cached(@prepared_schema_cache_key, fn -> KiwiCodec.SchemaInterpreter.prepare(schema()) end)
  end

  defp cached(key, build) do
    case :persistent_term.get(key, :missing) do
      {@schema_version, value} ->
        value

      _missing_or_stale ->
        value = build.()
        :persistent_term.put(key, {@schema_version, value})
        value
    end
  end
end
