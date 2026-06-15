defmodule FigKiwi.Scene.Graph.Profile.Stage do
  @moduledoc false

  use JSONCodec, fast_path: :json

  alias FigKiwi.Scene.Graph.Profile.GraphStats

  defstruct [:stage, :ms, :graph]

  @type t :: %__MODULE__{stage: atom(), ms: non_neg_integer(), graph: GraphStats.t()}

  codec(:stage, atom: :existing)
end
