defmodule Figler.Scene.Graph.Profile.Phase do
  @moduledoc """
  JSON-serializable timing for one graph construction phase: `:decode`,
  `:index`, or `:interpret`.
  """

  use JSONCodec, fast_path: :json

  defstruct [:phase, :ms]

  @type t :: %__MODULE__{phase: atom(), ms: non_neg_integer() | float()}

  codec(:phase, atom: :existing)
end
