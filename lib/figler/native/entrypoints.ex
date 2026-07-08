defmodule Figler.Native.Entrypoints do
  @moduledoc """
  Declares native entrypoints exposed by Figler.

  The Rustler module uses this list to define Elixir fallback stubs, and RustQ
  generation uses the same metadata to select schema decoder entrypoints without
  loading the Rustler module during code generation.
  """

  @stubs [
    {:decode_sparse_message, 1},
    {:decode_graph_seed_records, 1},
    {:decode_graph_focused_sparse_message, 2},
    {:decode_scene_summary, 1},
    {:build_scene_index, 1},
    {:build_scene_index_with_summary, 1},
    {:query_scene_xpath, 2},
    {:query_scene_xpath_fields, 3},
    {:query_scene_index, 2},
    {:query_scene_index_fields, 3},
    {:scene_index_node, 2},
    {:scene_index_parent, 2},
    {:scene_index_roots, 1},
    {:scene_index_children, 2},
    {:scene_index_siblings, 2},
    {:scene_index_by_type, 2},
    {:scene_index_by_type_fields, 3},
    {:scene_index_named, 2},
    {:scene_index_name_contains, 2},
    {:scene_index_name_contains_fields, 3},
    {:scene_index_text_contains, 2},
    {:scene_index_text_contains_fields, 3},
    {:scene_index_components, 1},
    {:scene_index_with_fills, 1},
    {:scene_index_with_strokes, 1},
    {:scene_index_ancestors, 2},
    {:scene_index_descendants, 2}
  ]

  @spec stubs() :: [{atom(), pos_integer()}]
  def stubs, do: @stubs
end
