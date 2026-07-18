defmodule Figler.Render.Color do
  @moduledoc "Normalized RGBA color in Figma's zero-to-one channel space."

  defstruct [:r, :g, :b, :a]

  @type t :: %__MODULE__{r: float() | nil, g: float() | nil, b: float() | nil, a: float() | nil}

  @doc false
  def from_sparse(nil), do: nil

  def from_sparse(value) when is_map(value) do
    struct(__MODULE__, Map.take(value, [:r, :g, :b, :a]))
  end
end

defmodule Figler.Render.Matrix do
  @moduledoc "Normalized 2D affine matrix."

  defstruct [:m00, :m01, :m02, :m10, :m11, :m12]

  @type t :: %__MODULE__{
          m00: float() | nil,
          m01: float() | nil,
          m02: float() | nil,
          m10: float() | nil,
          m11: float() | nil,
          m12: float() | nil
        }

  @doc false
  def from_sparse(nil), do: nil

  def from_sparse(value) when is_map(value) do
    struct(__MODULE__, Map.take(value, [:m00, :m01, :m02, :m10, :m11, :m12]))
  end
end

defmodule Figler.Render.Vector do
  @moduledoc "Normalized two-dimensional vector."

  defstruct [:x, :y]

  @type t :: %__MODULE__{x: float() | nil, y: float() | nil}

  @doc false
  def from_sparse(nil), do: nil

  def from_sparse(value) when is_map(value) do
    struct(__MODULE__, Map.take(value, [:x, :y]))
  end
end
