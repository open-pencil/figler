defmodule FigKiwi.Native.Scene do
  @moduledoc false

  alias FigKiwi.Native.Nif

  @delegates [
    {:decode_summary, [:binary], :decode_scene_summary},
    {:build_index, [:binary], :build_scene_index},
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
    {:index_named, [:index, :name], :scene_index_named},
    {:index_name_contains, [:index, :needle], :scene_index_name_contains},
    {:index_text_contains, [:index, :needle], :scene_index_text_contains},
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
