defmodule Figler.Render.GeometryRef do
  @moduledoc "Normalized reference to a Figma geometry command blob."

  defstruct [:winding_rule, :commands_blob, :style_id]

  @type t :: %__MODULE__{
          winding_rule: atom() | nil,
          commands_blob: non_neg_integer() | nil,
          style_id: non_neg_integer() | nil
        }

  @doc false
  def from_sparse(value) when is_map(value) do
    struct(__MODULE__, Map.take(value, [:winding_rule, :commands_blob, :style_id]))
  end
end
