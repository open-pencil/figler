defmodule Figler.Native.Scene do
  @moduledoc """
  Thin Elixir wrapper around native scene index and query NIFs.

  `Figler.Scene` builds on these delegates to normalize inputs and project
  native maps into documented scene structs.
  """

  alias Figler.Native.Nif

  @delegates [
    {:decode_summary, [:binary], :decode_scene_summary},
    {:build_index, [:binary], :build_scene_index},
    {:build_index_with_summary, [:binary], :build_scene_index_with_summary},
    {:query_xpath, [:binary, :xpath], :query_scene_xpath},
    {:query_xpath_fields, [:binary, :xpath, :fields], :query_scene_xpath_fields},
    {:query_index, [:index, :xpath], :query_scene_index},
    {:query_index_fields, [:index, :xpath, :fields], :query_scene_index_fields},
    {:index_node, [:index, :guid], :scene_index_node},
    {:index_parent, [:index, :guid], :scene_index_parent},
    {:index_roots, [:index], :scene_index_roots},
    {:index_children, [:index, :guid], :scene_index_children},
    {:index_siblings, [:index, :guid], :scene_index_siblings},
    {:index_by_type, [:index, :node_type], :scene_index_by_type},
    {:index_by_type_fields, [:index, :node_type, :fields], :scene_index_by_type_fields},
    {:index_named, [:index, :name], :scene_index_named},
    {:index_name_contains, [:index, :needle], :scene_index_name_contains},
    {:index_name_contains_fields, [:index, :needle, :fields], :scene_index_name_contains_fields},
    {:index_text_contains, [:index, :needle], :scene_index_text_contains},
    {:index_text_contains_fields, [:index, :needle, :fields], :scene_index_text_contains_fields},
    {:index_components, [:index], :scene_index_components},
    {:index_with_fills, [:index], :scene_index_with_fills},
    {:index_with_strokes, [:index], :scene_index_with_strokes},
    {:index_ancestors, [:index, :guid], :scene_index_ancestors},
    {:index_descendants, [:index, :guid], :scene_index_descendants}
  ]

  for {name, arg_names, nif_name} <- @delegates do
    args = Enum.map(arg_names, &Macro.var(&1, nil))

    def unquote(name)(unquote_splicing(args)) do
      Nif.unquote(nif_name)(unquote_splicing(args))
    end
  end
end
