defmodule Figler.Scene.Summary do
  @moduledoc """
  Lightweight projected scene summary.
  """

  @enforce_keys [:node_count, :parented_count, :root_count, :type_counts]
  defstruct [:node_count, :parented_count, :root_count, :type_counts]

  @type t :: %__MODULE__{
          node_count: non_neg_integer(),
          parented_count: non_neg_integer(),
          root_count: non_neg_integer(),
          type_counts: [{String.t(), non_neg_integer()}]
        }

  @doc false
  @spec from_map(map()) :: t()
  def from_map(map) when is_map(map), do: struct!(__MODULE__, map)
end
