defmodule FigKiwi.Scene.Graph.Oracle.Diff do
  @moduledoc false

  use JSONCodec, fast_path: :json

  defstruct [:path, :field, :figma, :figkiwi]

  @type t :: %__MODULE__{path: String.t(), field: String.t(), figma: term(), figkiwi: term()}
end
