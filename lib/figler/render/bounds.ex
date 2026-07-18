defmodule Figler.Render.Bounds do
  @moduledoc "Axis-aligned output bounds for a prepared rendering."

  @enforce_keys [:min_x, :min_y, :max_x, :max_y]
  defstruct [:min_x, :min_y, :max_x, :max_y]

  @type t :: %__MODULE__{
          min_x: float(),
          min_y: float(),
          max_x: float(),
          max_y: float()
        }
end
