defmodule Figler do
  @moduledoc """
  Fast analysis, transformation, and rendering for Figma `.fig` files.

  Use `Figler.Scene` to inspect large files, `decode/1` and `encode/1` to change
  complete documents with ordinary Elixir data operations, and `Figler.Render`
  to render pages or selected layers.

  Lower-level schema and message codecs are available for tools that already
  manage their own Figma archive or container boundary.
  """

  alias Figler.Document
  alias Figler.Error
  alias Figler.Native.CodecNifs
  alias Figler.Schema.Message

  @schema_path :figler |> :code.priv_dir() |> Path.join("schema/fig.kiwi")
  @external_resource @schema_path
  @schema_version @schema_path |> File.read!() |> :erlang.md5()
  @schema_cache_key {__MODULE__, :schema}
  @prepared_schema_cache_key {__MODULE__, :prepared_schema}

  @doc """
  Decodes a complete `.fig` archive, `fig-kiwi` container, or raw message.

  The returned `Figler.Document` contains the decoded message alongside every
  preserved archive entry. It can be changed with ordinary Elixir struct,
  `Enum`, and `Access` operations before being passed to `encode/1`.
  """
  @spec decode(binary()) :: {:ok, Document.t()} | {:error, Error.t()}
  def decode(input) when is_binary(input) do
    {:ok, decode!(input)}
  rescue
    error in Error -> {:error, error}
  end

  @doc "Like `decode/1`, but raises `Figler.Error` for malformed input."
  @spec decode!(binary()) :: Document.t()
  def decode!(input) when is_binary(input) do
    document = Document.open!(input)

    message =
      Error.protect(:decode_document, fn ->
        KiwiCodec.decode(document.payload, Message)
      end)

    %{document | message: message}
  end

  @doc """
  Encodes a `Figler.Document` back to its original representation.

  Archives retain all entries and replace only their `canvas.fig` container.
  Containers retain their schema, version, compression family, and trailing
  chunks. Documents decoded from raw messages encode back to raw messages.
  """
  @spec encode(Document.t()) :: {:ok, binary()} | {:error, Error.t()}
  def encode(%Document{} = document) do
    {:ok, encode!(document)}
  rescue
    error in Error -> {:error, error}
  end

  @doc "Like `encode/1`, but raises `Figler.Error` for invalid document data."
  @spec encode!(Document.t()) :: binary()
  def encode!(%Document{} = document) do
    Error.protect(:encode_document, fn ->
      payload = encode_document_message!(document)
      Document.encode_payload!(document, payload)
    end)
  end

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
    Error.protect(:decode_message, fn -> KiwiCodec.decode(binary, Figler.Schema.Message) end)
  end

  @doc """
  Decodes a Figma `Message` payload into sparse schema-backed maps.

  Sparse maps include `:__kiwi_module__` and only fields present on the wire.
  This avoids materializing hundreds of nil fields per large `NodeChange`.
  """
  @spec decode_sparse_message(binary()) :: map()
  def decode_sparse_message(binary) when is_binary(binary) do
    Error.protect(:decode_sparse_message, fn -> CodecNifs.decode_sparse_message(binary) end)
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
    Error.protect(:decode_message_runtime, fn ->
      prepared_schema()
      |> KiwiCodec.SchemaInterpreter.decode("Message", binary)
    end)
  end

  @doc """
  Encodes a Figma `Message` map with the runtime schema interpreter.
  """
  @spec encode_message_runtime(map()) :: binary()
  def encode_message_runtime(message) when is_map(message) do
    prepared_schema()
    |> KiwiCodec.SchemaInterpreter.encode("Message", message)
  end

  defp encode_document_message!(%Document{message: nil, payload: payload})
       when is_binary(payload),
       do: payload

  defp encode_document_message!(%Document{message: %Message{} = message}),
    do: KiwiCodec.encode(message)

  defp encode_document_message!(%Document{}) do
    raise Error.new(:invalid_document, :encode_document, %{reason: :invalid_message})
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
