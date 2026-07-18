defmodule Figler.Render.Text.StyleOverride do
  @moduledoc false

  alias Figler.Render.Paint
  alias Figler.Render.Text.Measurement

  defstruct [
    :style_id,
    :font_family,
    :font_style,
    :font_postscript,
    :font_size,
    :fill_paints,
    :line_height,
    :letter_spacing,
    :text_decoration,
    :text_decoration_style,
    :text_decoration_thickness,
    :text_decoration_skip_ink,
    :text_underline_offset,
    :text_decoration_fill_paints,
    :text_case
  ]

  @type t :: %__MODULE__{
          style_id: non_neg_integer() | nil,
          font_family: String.t() | nil,
          font_style: String.t() | nil,
          font_postscript: String.t() | nil,
          font_size: float() | nil,
          fill_paints: [Paint.t()] | nil,
          line_height: Measurement.t() | nil,
          letter_spacing: Measurement.t() | nil,
          text_decoration: atom() | nil,
          text_decoration_style: atom() | nil,
          text_decoration_thickness: Measurement.t() | nil,
          text_decoration_skip_ink: boolean() | nil,
          text_underline_offset: Measurement.t() | nil,
          text_decoration_fill_paints: [Paint.t()] | nil,
          text_case: atom() | nil
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
      fill_paints: paints(sparse, :fill_paints),
      line_height: Measurement.from_sparse(Map.get(sparse, :line_height)),
      letter_spacing: Measurement.from_sparse(Map.get(sparse, :letter_spacing)),
      text_decoration: Map.get(sparse, :text_decoration),
      text_decoration_style: Map.get(sparse, :text_decoration_style),
      text_decoration_thickness:
        Measurement.from_sparse(Map.get(sparse, :text_decoration_thickness)),
      text_decoration_skip_ink: Map.get(sparse, :text_decoration_skip_ink),
      text_underline_offset: Measurement.from_sparse(Map.get(sparse, :text_underline_offset)),
      text_decoration_fill_paints: paints(sparse, :text_decoration_fill_paints),
      text_case: Map.get(sparse, :text_case)
    }
  end

  defp paints(sparse, field) do
    case Map.fetch(sparse, field) do
      {:ok, paints} -> Enum.map(paints || [], &Paint.from_sparse/1)
      :error -> nil
    end
  end
end
