defmodule Figler.Scene.Graph.Oracle.Diff do
  @moduledoc """
  Field-level difference found during an oracle comparison.

  Each diff records the graph path, compared field, expected Figma value, and
  value produced by Figler.
  """

  use JSONCodec, fast_path: :json

  defstruct [:path, :field, :figma, :figkiwi]

  @type t :: %__MODULE__{path: String.t(), field: String.t(), figma: term(), figkiwi: term()}
end
