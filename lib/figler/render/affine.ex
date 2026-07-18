defmodule Figler.Render.Affine do
  @moduledoc false

  @type matrix :: {number(), number(), number(), number(), number(), number()}

  @spec multiply(matrix(), matrix()) :: matrix()
  def multiply({a, b, c, d, e, f}, {g, h, i, j, k, l}) do
    {a * g + b * j, a * h + b * k, a * i + b * l + c, d * g + e * j, d * h + e * k,
     d * i + e * l + f}
  end
end
