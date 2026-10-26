defmodule Figler.Render.Text.Glyph do
  @moduledoc """
  A glyph Figma laid out and saved with the text: its outline blob, pen position, and the
  character it draws.
  """

  @enforce_keys [:commands_blob, :x, :y, :font_size]
  defstruct [
    :commands_blob,
    :x,
    :y,
    :font_size,
    :first_character,
    :advance,
    :emoji,
    rotation: 0.0
  ]

  @type t :: %__MODULE__{
          commands_blob: non_neg_integer(),
          x: float(),
          y: float(),
          font_size: float(),
          first_character: non_neg_integer() | nil,
          advance: float() | nil,
          rotation: float(),
          emoji: String.t() | nil
        }
end
