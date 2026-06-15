defmodule FigKiwi.Scene.Graph.Profile.Summary do
  @moduledoc false

  use JSONCodec, fast_path: :json

  alias FigKiwi.Scene.Graph.Profile.FinalGraphStats
  alias FigKiwi.Scene.Graph.Profile.Stage

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
          payload_ms: non_neg_integer(),
          initial_ms: non_neg_integer(),
          total_ms: non_neg_integer(),
          final_graph: FinalGraphStats.t(),
          stages: [Stage.t()]
        }
end
