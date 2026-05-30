defmodule FigKiwi.Container do
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

  @spec build([iodata()], keyword()) :: binary()
  def build(chunks, opts \\ []) do
    opts = Keyword.put_new(opts, :magic, "fig-kiwi")
    KiwiCodec.Container.build(chunks, opts)
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

  @spec deflate(iodata()) :: binary()
  defdelegate deflate(data), to: KiwiCodec.Container
end
