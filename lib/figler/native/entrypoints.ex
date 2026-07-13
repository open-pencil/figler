defmodule Figler.Native.Entrypoints do
  @moduledoc """
  Groups native entrypoint names by their structural signature source.

  Template entrypoints are read from `scene_nifs.rs`; navigation entrypoints are
  read from Rusty-Elixir AST metadata. Argument lists and Elixir arities are not
  duplicated here.
  """

  @template_names [
    :decode_sparse_message,
    :decode_graph_seed_records,
    :decode_graph_focused_sparse_message,
    :decode_scene_summary,
    :build_scene_index,
    :build_scene_index_with_summary,
    :query_scene_xpath,
    :query_scene_xpath_fields,
    :query_scene_index,
    :query_scene_index_fields
  ]

  @navigation_names [
    :scene_index_node,
    :scene_index_parent,
    :scene_index_roots,
    :scene_index_children,
    :scene_index_siblings,
    :scene_index_by_type,
    :scene_index_by_type_fields,
    :scene_index_named,
    :scene_index_name_contains,
    :scene_index_name_contains_fields,
    :scene_index_text_contains,
    :scene_index_text_contains_fields,
    :scene_index_components,
    :scene_index_with_fills,
    :scene_index_with_strokes,
    :scene_index_ancestors,
    :scene_index_descendants
  ]

  @spec template_names() :: [atom()]
  def template_names, do: @template_names

  @spec navigation_names() :: [atom()]
  def navigation_names, do: @navigation_names
end
