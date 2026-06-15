defmodule FigKiwi.Scene.Graph.Oracle.Manifest do
  @moduledoc false

  use JSONCodec, fast_path: :json

  alias FigKiwi.Scene.Graph.Oracle.Entry

  defstruct comparisons: []

  @type t :: %__MODULE__{comparisons: [Entry.t()]}

  def decode_entries!(json) do
    case Jason.decode!(json) do
      entries when is_list(entries) ->
        JSONCodec.from_map!(%{"comparisons" => entries}, __MODULE__).comparisons

      %{} = map ->
        JSONCodec.from_map!(map, __MODULE__).comparisons

      _other ->
        raise "oracle manifest must be a JSON array or an object with a comparisons array"
    end
  end
end
