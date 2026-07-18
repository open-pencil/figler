defmodule Figler.Render.Affine do
  @moduledoc false

  @type matrix :: {number(), number(), number(), number(), number(), number()}

  @identity {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}

  @spec identity() :: matrix()
  def identity, do: @identity

  @spec from_value(map() | nil) :: matrix()
  def from_value(nil), do: @identity

  def from_value(value) do
    {value.m00 || 1.0, value.m01 || 0.0, value.m02 || 0.0, value.m10 || 0.0, value.m11 || 1.0,
     value.m12 || 0.0}
  end

  @spec point(matrix(), number(), number()) :: {number(), number()}
  def point({a, b, c, d, e, f}, x, y), do: {a * x + b * y + c, d * x + e * y + f}

  @spec multiply(matrix(), matrix()) :: matrix()
  def multiply({a, b, c, d, e, f}, {g, h, i, j, k, l}) do
    {a * g + b * j, a * h + b * k, a * i + b * l + c, d * g + e * j, d * h + e * k,
     d * i + e * l + f}
  end
end
