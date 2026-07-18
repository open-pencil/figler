defmodule Figler.Render.Text.StyleOverride do
  @moduledoc false

  alias Figler.Render.Paint

  defstruct [
    :style_id,
    :font_family,
    :font_style,
    :font_postscript,
    :font_size,
    :fill_paints,
    :text_decoration
  ]

  @type t :: %__MODULE__{
          style_id: non_neg_integer() | nil,
          font_family: String.t() | nil,
          font_style: String.t() | nil,
          font_postscript: String.t() | nil,
          font_size: float() | nil,
          fill_paints: [Paint.t()] | nil,
          text_decoration: atom() | nil
        }

  @spec from_sparse(map()) :: t()
  def from_sparse(sparse) when is_map(sparse) do
    font_name = Map.get(sparse, :font_name) || %{}

    %__MODULE__{
      style_id: Map.get(sparse, :style_id),
      font_family: Map.get(font_name, :family),
      font_style: Map.get(font_name, :style),
      font_postscript: Map.get(font_name, :postscript),
      font_size: Map.get(sparse, :font_size),
      fill_paints: paints(sparse),
      text_decoration: Map.get(sparse, :text_decoration)
    }
  end

  defp paints(sparse) do
    case Map.fetch(sparse, :fill_paints) do
      {:ok, paints} -> Enum.map(paints || [], &Paint.from_sparse/1)
      :error -> nil
    end
  end
end
