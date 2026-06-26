defmodule Figler.Scene.Graph.Profile.Stage do
  @moduledoc """
  JSON-serializable timing result for one graph resolver stage.

  Profile reports use this struct to persist the stage name, elapsed time, and
  graph statistics after the stage ran.
  """

  use JSONCodec, fast_path: :json

  alias Figler.Scene.Graph.Profile.GraphStats

  defstruct [:stage, :ms, :graph]

  @type t :: %__MODULE__{stage: atom(), ms: non_neg_integer(), graph: GraphStats.t()}

  codec(:stage, atom: :existing)
end
