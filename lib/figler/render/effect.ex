defmodule Figler.Render.Effect do
  @moduledoc "Rendering-neutral normalized Figma effect."

  alias Figler.Render.Color
  alias Figler.Render.Vector

  defstruct [
    :type,
    :offset,
    :radius,
    :visible,
    :blend_mode,
    :spread,
    :show_shadow_behind_node,
    :color,
    :opacity
  ]

  @type t :: %__MODULE__{
          type: atom() | integer() | nil,
          offset: Figler.Render.Vector.t() | nil,
          radius: float() | nil,
          visible: boolean() | nil,
          blend_mode: atom() | nil,
          spread: float() | nil,
          show_shadow_behind_node: boolean() | nil,
          color: Figler.Render.Color.t() | nil,
          opacity: float() | nil
        }

  @doc false
  def from_sparse(value) when is_map(value) do
    %__MODULE__{
      type: Map.get(value, :type),
      offset: Vector.from_sparse(Map.get(value, :offset)),
      radius: Map.get(value, :radius),
      visible: Map.get(value, :visible),
      blend_mode: Map.get(value, :blend_mode),
      spread: Map.get(value, :spread),
      show_shadow_behind_node: Map.get(value, :show_shadow_behind_node),
      color: Color.from_sparse(Map.get(value, :color)),
      opacity: Map.get(value, :opacity)
    }
  end
end
