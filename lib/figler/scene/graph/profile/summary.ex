defmodule Figler.Scene.Graph.Profile.Summary do
  @moduledoc """
  JSON-serializable summary for a graph profiling run.

  A summary records fixture identity, payload extraction time, per-phase
  timings, selected roots, and final graph statistics for benchmark comparison.
  """

  use JSONCodec, fast_path: :json

  alias Figler.Scene.Graph.Profile.FinalGraphStats
  alias Figler.Scene.Graph.Profile.Phase

  defstruct [
    :fixture,
    :payload_ms,
    :total_ms,
    :final_graph,
    roots: [],
    phases: []
  ]

  @type t :: %__MODULE__{
          fixture: String.t(),
          roots: [String.t()],
          payload_ms: non_neg_integer() | float(),
          total_ms: non_neg_integer() | float(),
          final_graph: FinalGraphStats.t(),
          phases: [Phase.t()]
        }
end
