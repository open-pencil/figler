defmodule FigKiwi.Scene.Graph.Oracle.Entry do
  @moduledoc false

  use JSONCodec, case: :camel, fast_path: :json

  defstruct [:node, :json, depth: 2, epsilon: 0.0001, ignore_null_size: true]

  @type t :: %__MODULE__{
          node: String.t(),
          json: String.t(),
          depth: non_neg_integer(),
          epsilon: float(),
          ignore_null_size: boolean()
        }
end
