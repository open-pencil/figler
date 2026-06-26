defmodule Figler.Scene.Graph.Profile.FinalGraphStats do
  @moduledoc """
  Compact JSON-serializable statistics for the final resolved graph.

  This struct contains the headline counts used in profiling summaries and
  fixture reports.
  """

  use JSONCodec, fast_path: :json

  defstruct [:node_count, :clone_count, :unresolved_count, :applied_count]

  @type t :: %__MODULE__{
          node_count: non_neg_integer(),
          clone_count: non_neg_integer(),
          unresolved_count: non_neg_integer(),
          applied_count: non_neg_integer()
        }
end
