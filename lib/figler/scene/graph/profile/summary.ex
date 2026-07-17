defmodule Figler.Scene.Graph.Profile.Summary do
  @moduledoc """
  JSON-serializable summary for a graph profiling run.

  A summary records fixture identity, payload decode time, resolver timings,
  selected roots, and final graph statistics for benchmark comparison.
  """

  use JSONCodec, fast_path: :json

  alias Figler.Scene.Graph.Profile.FinalGraphStats
  alias Figler.Scene.Graph.Profile.Stage

  defstruct [
    :fixture,
    :until,
    :payload_ms,
    :initial_ms,
    :total_ms,
    :final_graph,
    roots: [],
    stages: []
  ]

  @type t :: %__MODULE__{
          fixture: String.t(),
          roots: [String.t()],
          until: String.t(),
          payload_ms: non_neg_integer() | float(),
          initial_ms: non_neg_integer() | float(),
          total_ms: non_neg_integer() | float(),
          final_graph: FinalGraphStats.t(),
          stages: [Stage.t()]
        }
end
