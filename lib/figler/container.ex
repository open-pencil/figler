defmodule Figler.Container do
  @moduledoc """
  Figma `fig-kiwi` container helpers.
  """

  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  @spec parse(binary()) :: %{magic: binary(), version: non_neg_integer(), chunks: [binary()]}
  def parse(binary), do: KiwiCodec.Container.parse(binary, "fig-kiwi")

  @doc """
  Parses a `fig-kiwi` container and inflates its schema and data chunks.
  """
  @spec decode(binary()) :: %{
          version: non_neg_integer(),
          schema: KiwiCodec.Schema.t(),
          data: binary()
        }
  def decode(binary) when is_binary(binary) do
    %{version: version, chunks: [schema_chunk, data_chunk | _rest]} = parse(binary)

    %{
      version: version,
      schema: schema_chunk |> inflate() |> SchemaBinary.decode(),
      data: inflate(data_chunk)
    }
  end

  @doc """
  Parses a `fig-kiwi` container and inflates only its data chunk.
  """
  @spec data(binary()) :: binary()
  def data(binary) when is_binary(binary) do
    KiwiCodec.Container.data(binary, "fig-kiwi", &inflate/1)
  end

  @spec build([iodata()], keyword()) :: binary()
  def build(chunks, opts \\ []) do
    opts = Keyword.put_new(opts, :magic, "fig-kiwi")
    KiwiCodec.Container.build(chunks, opts)
  end

  @doc """
  Replaces the encoded message in a `fig-kiwi` container.

  The original schema chunk, container version, and any trailing chunks are
  preserved. The new data uses the same compression family as the original
  data chunk.
  """
  @spec replace_data(binary(), iodata()) :: binary()
  def replace_data(container, data) when is_binary(container) do
    case parse(container) do
      %{magic: magic, version: version, chunks: [schema, encoded_data | trailing]} ->
        build([schema, compress_like(encoded_data, data) | trailing],
          magic: magic,
          version: version
        )

      %{chunks: _incomplete} ->
        raise KiwiCodec.DecodeError, message: "fig-kiwi container is missing its data chunk"
    end
  end

  @spec inflate(binary()) :: binary()
  def inflate(<<0x28, 0xB5, 0x2F, 0xFD, _rest::binary>> = data) do
    case :ezstd.decompress(data) do
      decompressed when is_binary(decompressed) ->
        decompressed

      {:error, reason} ->
        raise KiwiCodec.DecodeError, message: "cannot decompress zstd chunk: #{inspect(reason)}"
    end
  end

  def inflate(data), do: KiwiCodec.Container.inflate(data)

  defp compress_like(<<0x28, 0xB5, 0x2F, 0xFD, _rest::binary>>, data),
    do: data |> IO.iodata_to_binary() |> :ezstd.compress()

  defp compress_like(_encoded_data, data), do: deflate(data)

  @spec deflate(iodata()) :: binary()
  defdelegate deflate(data), to: KiwiCodec.Container
end
