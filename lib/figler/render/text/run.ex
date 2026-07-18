defmodule Figler.Render.Text.Run do
  @moduledoc "A typed, UTF-16-indexed text style run."

  alias Figler.Render.Font
  alias Figler.Render.Paint
  alias Figler.Render.Text.Measurement

  @enforce_keys [:index, :start, :length, :content, :font]
  defstruct [
    :index,
    :start,
    :length,
    :content,
    :font,
    :style_id,
    :line_height,
    :letter_spacing,
    :text_decoration,
    :text_decoration_style,
    :text_decoration_thickness,
    :text_decoration_skip_ink,
    :text_underline_offset,
    :text_case,
    text_decoration_fill_paints: [],
    fill_paints: [],
    fill_override?: false
  ]

  @type t :: %__MODULE__{
          index: non_neg_integer(),
          start: non_neg_integer(),
          length: non_neg_integer(),
          content: String.t(),
          font: Font.t(),
          style_id: non_neg_integer(),
          line_height: float() | nil,
          letter_spacing: float() | nil,
          fill_paints: [Paint.t()],
          fill_override?: boolean(),
          text_decoration: atom() | nil,
          text_decoration_style: atom() | nil,
          text_decoration_thickness: Measurement.t() | nil,
          text_decoration_skip_ink: boolean() | nil,
          text_underline_offset: Measurement.t() | nil,
          text_decoration_fill_paints: [Paint.t()],
          text_case: atom() | nil
        }
end
