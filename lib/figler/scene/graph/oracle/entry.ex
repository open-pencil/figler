defmodule Figler.Scene.Graph.Oracle.Entry do
  @moduledoc """
  One oracle comparison entry from a fixture manifest.

  Entries identify the source node, expected JSON file, traversal depth, and
  numeric comparison settings used by `Figler.Scene.Graph.Oracle`.
  """

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
