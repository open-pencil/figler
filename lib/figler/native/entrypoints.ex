defmodule Figler.Native.Entrypoints do
  @moduledoc """
  Lists template-backed native entrypoints whose signatures are read directly
  from `scene_nifs.rs`. Rusty-Elixir navigation entrypoints are discovered from
  their generated AST instead of being duplicated here.
  """

  @template_names [
    :decode_sparse_message,
    :decode_graph_focused_sparse_message,
    :decode_document_metadata,
    :decode_render_source_nodes,
    :decode_scene_summary,
    :build_scene_index,
    :build_scene_index_with_summary,
    :query_scene_xpath,
    :query_scene_xpath_fields,
    :query_scene_index,
    :query_scene_index_fields
  ]

  @spec template_names() :: [atom()]
  def template_names, do: @template_names

  @spec template_nifs() :: [{atom(), keyword()}]
  def template_nifs, do: Enum.map(@template_names, &{&1, []})
end
