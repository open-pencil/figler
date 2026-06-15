defmodule FigKiwi.Native.Nif do
  @moduledoc false

  use Rustler,
    otp_app: :fig_kiwi,
    crate: :fig_kiwi_native,
    path: "native"

  @stubs [
    {:decode_guid, 1},
    {:decode_vector, 1},
    {:decode_matrix, 1},
    {:decode_parent_index, 1},
    {:decode_image, 1},
    {:decode_node_change, 1},
    {:decode_message, 1},
    {:decode_sparse_message, 1},
    {:decode_scene_summary, 1},
    {:build_scene_index, 1},
    {:query_scene_xpath, 2},
    {:query_scene_xpath_fields, 3},
    {:query_scene_index, 2},
    {:query_scene_index_fields, 3},
    {:scene_index_node, 2},
    {:scene_index_parent, 2},
    {:scene_index_roots, 1},
    {:scene_index_children, 2},
    {:scene_index_siblings, 2},
    {:scene_index_ancestors, 2},
    {:scene_index_descendants, 2}
  ]

  for {name, arity} <- @stubs do
    args = for index <- 1..arity, do: Macro.var(:"_arg#{index}", nil)

    def unquote(name)(unquote_splicing(args)) do
      :erlang.nif_error(:nif_not_loaded)
    end
  end
end
