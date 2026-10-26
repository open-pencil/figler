defmodule Figler.Render.Affine do
  @moduledoc """
  2D affine transforms as Figma stores them: a `{m00, m01, m02, m10, m11, m12}` tuple mapping
  `(x, y)` to `(m00·x + m01·y + m02, m10·x + m11·y + m12)`.
  """

  @typedoc "An affine transform, `{m00, m01, m02, m10, m11, m12}`."
  @type matrix :: {number(), number(), number(), number(), number(), number()}

  @identity {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}

  @doc "Returns the transform that leaves points where they are."
  @spec identity() :: matrix()
  def identity, do: @identity

  @doc "Reads a Figma `Matrix` value, taking missing entries from the identity."
  @spec from_value(map() | nil) :: matrix()
  def from_value(nil), do: @identity

  def from_value(value) do
    {value.m00 || 1.0, value.m01 || 0.0, value.m02 || 0.0, value.m10 || 0.0, value.m11 || 1.0,
     value.m12 || 0.0}
  end

  @doc "Moves the point `(x, y)` by `matrix`."
  @spec point(matrix(), number(), number()) :: {number(), number()}
  def point({a, b, c, d, e, f}, x, y), do: {a * x + b * y + c, d * x + e * y + f}

  @doc "Returns the transform applying `right`, then `left`."
  @spec multiply(matrix(), matrix()) :: matrix()
  def multiply(left, right)

  def multiply({a, b, c, d, e, f}, {g, h, i, j, k, l}) do
    {a * g + b * j, a * h + b * k, a * i + b * l + c, d * g + e * j, d * h + e * k,
     d * i + e * l + f}
  end
end
