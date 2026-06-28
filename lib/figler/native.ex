defmodule Figler.Native do
  @moduledoc """
  Convenience facade for generated native codec and scene projection NIFs.

  This module keeps the low-level native entrypoint names available from one
  namespace while the public APIs in `Figler`, `Figler.Sparse`, and
  `Figler.Scene` expose higher-level Elixir shapes.
  """

  alias Figler.Native.{CodecNifs, SceneNifs}

  @codec_delegates [
    {:decode_guid, [:binary], :decode_guid},
    {:decode_vector, [:binary], :decode_vector},
    {:decode_matrix, [:binary], :decode_matrix},
    {:decode_parent_index, [:binary], :decode_parent_index},
    {:decode_image, [:binary], :decode_image},
    {:decode_node_change, [:binary], :decode_node_change},
    {:decode_message, [:binary], :decode_message},
    {:decode_sparse_message, [:binary], :decode_sparse_message}
  ]

  @scene_delegates [
    {:decode_scene_summary, [:binary], :decode_summary},
    {:build_scene_index, [:binary], :build_index},
    {:query_scene_xpath, [:binary, :xpath], :query_xpath},
    {:query_scene_xpath_fields, [:binary, :xpath, :fields], :query_xpath_fields},
    {:query_scene_index, [:index, :xpath], :query_index},
    {:query_scene_index_fields, [:index, :xpath, :fields], :query_index_fields},
    {:scene_index_node, [:index, :guid], :index_node},
    {:scene_index_parent, [:index, :guid], :index_parent},
    {:scene_index_roots, [:index], :index_roots},
    {:scene_index_children, [:index, :guid], :index_children},
    {:scene_index_siblings, [:index, :guid], :index_siblings},
    {:scene_index_by_type, [:index, :node_type], :index_by_type},
    {:scene_index_by_type_fields, [:index, :node_type, :fields], :index_by_type_fields},
    {:scene_index_named, [:index, :name], :index_named},
    {:scene_index_name_contains, [:index, :needle], :index_name_contains},
    {:scene_index_name_contains_fields, [:index, :needle, :fields], :index_name_contains_fields},
    {:scene_index_text_contains, [:index, :needle], :index_text_contains},
    {:scene_index_text_contains_fields, [:index, :needle, :fields], :index_text_contains_fields},
    {:scene_index_components, [:index], :index_components},
    {:scene_index_with_fills, [:index], :index_with_fills},
    {:scene_index_with_strokes, [:index], :index_with_strokes},
    {:scene_index_ancestors, [:index, :guid], :index_ancestors},
    {:scene_index_descendants, [:index, :guid], :index_descendants}
  ]

  for {name, arg_names, target} <- @codec_delegates do
    args = Enum.map(arg_names, &Macro.var(&1, nil))

    def unquote(name)(unquote_splicing(args)) do
      CodecNifs.unquote(target)(unquote_splicing(args))
    end
  end

  for {name, arg_names, target} <- @scene_delegates do
    args = Enum.map(arg_names, &Macro.var(&1, nil))

    def unquote(name)(unquote_splicing(args)) do
      SceneNifs.unquote(target)(unquote_splicing(args))
    end
  end
end
