defmodule Figler.Native.SceneNifs do
  @moduledoc """
  Thin Elixir wrapper around native scene index and query entrypoints.

  Entrypoints that decode take a payload binary or a `t:Figler.Scene.source/0`.

  `Figler.Scene` builds on these delegates to normalize inputs and project
  native maps into documented scene structs.
  """

  alias Figler.Error
  alias Figler.Native.Module
  alias Figler.Scene.Input

  @operations %{
    decode_summary: :summary,
    build_index: :index,
    build_index_with_summary: :index,
    query_xpath: :query,
    query_xpath_fields: :query,
    query_index: :query,
    query_index_fields: :query,
    index_node: :node,
    index_parent: :parent,
    index_roots: :roots,
    index_children: :children,
    index_siblings: :siblings,
    index_by_type: :by_type,
    index_by_type_fields: :by_type,
    index_named: :named,
    index_name_contains: :name_contains,
    index_name_contains_fields: :name_contains,
    index_text_contains: :text_contains,
    index_text_contains_fields: :text_contains,
    index_components: :components,
    index_with_fills: :with_fills,
    index_with_strokes: :with_strokes,
    index_ancestors: :ancestors,
    index_descendants: :descendants
  }

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
    operation = Map.fetch!(@operations, name)

    nif_args =
      Enum.flat_map(arg_names, fn
        :binary -> [Macro.var(:payload, nil), Macro.var(:schema, nil)]
        arg -> [Macro.var(arg, nil)]
      end)

    source =
      if :binary in arg_names do
        quote do
          {unquote(Macro.var(:payload, nil)), unquote(Macro.var(:schema, nil))} =
            Input.to_source(unquote(Macro.var(:binary, nil)))
        end
      end

    def unquote(name)(unquote_splicing(args)) do
      unquote(source)

      Error.protect(unquote(operation), fn ->
        Module.unquote(nif_name)(unquote_splicing(nif_args))
      end)
    end
  end
end
