defmodule Figler.Scene.Graph.Symbol.DerivedData do
  alias Figler.Scene.Graph.GUID

  @moduledoc """
  Figma-derived symbol metadata used by graph resolution.
  """

  defstruct guid_path: [],
            size: nil,
            transform: nil,
            font_size: nil,
            line_height: nil,
            letter_spacing: nil,
            stroke_weight: nil,
            derived_text_data: nil,
            fill_geometry: [],
            stroke_geometry: []

  @type t :: %__MODULE__{
          guid_path: [GUID.figma_guid()],
          size: map() | nil,
          transform: map() | nil,
          font_size: number() | nil,
          line_height: term(),
          letter_spacing: term(),
          stroke_weight: number() | nil,
          derived_text_data: term(),
          fill_geometry: [term()],
          stroke_geometry: [term()]
        }
end
