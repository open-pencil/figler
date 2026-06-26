defmodule Figler.Scene.Graph.Profile.GraphStats do
  @moduledoc """
  JSON-serializable graph statistics captured during profiling.

  The stats track graph size, clone/source counts, resolver state, and stage
  progress after individual graph build steps.
  """

  use JSONCodec, fast_path: :json

  defstruct [
    :node_count,
    :clone_count,
    :unresolved_count,
    :applied_count,
    :seed_count,
    :clone_instance_count,
    :clone_seed_count,
    :source_instance_count,
    :source_seed_count,
    :parented_count,
    :root_count,
    :resolver,
    resolved_stages: []
  ]

  @type t :: %__MODULE__{
          node_count: non_neg_integer() | nil,
          clone_count: non_neg_integer() | nil,
          unresolved_count: non_neg_integer() | nil,
          applied_count: non_neg_integer() | nil,
          seed_count: non_neg_integer() | nil,
          clone_instance_count: non_neg_integer() | nil,
          clone_seed_count: non_neg_integer() | nil,
          source_instance_count: non_neg_integer() | nil,
          source_seed_count: non_neg_integer() | nil,
          parented_count: non_neg_integer() | nil,
          root_count: non_neg_integer() | nil,
          resolver: atom() | nil,
          resolved_stages: [atom()]
        }

  codec(:resolver, atom: :existing)
  codec(:resolved_stages, atom: :existing)
end
