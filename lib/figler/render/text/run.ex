defmodule Figler.Render.Text.Run do
  @moduledoc "A typed, UTF-16-indexed text style run."

  alias Figler.Render.Font
  alias Figler.Render.Paint

  @enforce_keys [:index, :start, :length, :content, :font]
  defstruct [
    :index,
    :start,
    :length,
    :content,
    :font,
    :style_id,
    :text_decoration,
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
          fill_paints: [Paint.t()],
          fill_override?: boolean(),
          text_decoration: atom() | nil
        }
end
