defmodule Figler.Render.SourceNode do
  @moduledoc """
  Render-specific source metadata projected from a Figma `NodeChange`.

  This keeps generated schema structs and their hundreds of unrelated fields
  out of backend compilers.
  """

  alias Figler.Scene.Graph.GUID

  @enforce_keys [:guid]
  defstruct [
    :guid,
    :node_type,
    :name,
    :corner_radius,
    :stroke_weight,
    :frame_mask_disabled,
    :boolean_operation,
    fill_paints: [],
    stroke_paints: [],
    fill_geometry: [],
    stroke_geometry: []
  ]

  @type t :: %__MODULE__{
          guid: GUID.figma_guid(),
          node_type: String.t() | nil,
          name: String.t() | nil,
          fill_paints: [map()],
          stroke_paints: [map()],
          fill_geometry: [map()],
          stroke_geometry: [map()],
          boolean_operation: atom() | nil,
          corner_radius: float() | nil,
          stroke_weight: float() | nil,
          frame_mask_disabled: boolean() | nil
        }

  @doc false
  def from_native(
        {guid, node_type, name, fill_paints, stroke_paints, fill_geometry, stroke_geometry,
         boolean_operation, corner_radius, stroke_weight, frame_mask_disabled}
      ) do
    %__MODULE__{
      guid: guid,
      node_type: node_type,
      name: name,
      fill_paints: fill_paints,
      stroke_paints: stroke_paints,
      fill_geometry: fill_geometry,
      stroke_geometry: stroke_geometry,
      boolean_operation: boolean_operation,
      corner_radius: corner_radius,
      stroke_weight: stroke_weight,
      frame_mask_disabled: frame_mask_disabled
    }
  end
end
