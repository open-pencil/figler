defmodule FigKiwi.Scene.Index do
  @moduledoc """
  Reusable native scene index.

  Build with `FigKiwi.Scene.index/1` and pass to scene query/navigation helpers
  to avoid rescanning a `.fig` payload for each operation.
  """

  @enforce_keys [:resource]
  defstruct [:resource]

  @opaque t :: %__MODULE__{resource: reference()}
end
