defmodule Figler.Native.GeneratedStubs do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def decode_sparse_message(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_record_message(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_interpret(_bytes, _schema, _root) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_resolve_variables(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_new(_bytes, _schema, _styles, _variables, _focus) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_node(_graph, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_nodes(_graph, _guids) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_node_slice(_graph, _offset, _limit) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_record(_graph, _guid, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_records(_graph, _guids, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_children(_graph, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_guids(_graph) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_roots(_graph) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_of_type(_graph, _node_type) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_named(_graph, _name) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_provenance(_graph, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_unresolved(_graph) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_source(_graph, _id) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_source_node(_graph, _id) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_stats(_graph) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def graph_fields(_graph, _only) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_graph_focused_sparse_message(_bytes, _schema, _focus) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_document_metadata(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_render_source_nodes(_bytes, _schema, _focus) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_scene_summary(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def build_scene_index(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def build_scene_index_with_summary(_bytes, _schema) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_xpath(_bytes, _schema, _xpath) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_xpath_fields(_bytes, _schema, _xpath, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_index(_resource, _xpath) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_index_fields(_resource, _xpath, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_node(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_parent(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_roots(_resource) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_children(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_siblings(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_by_type(_resource, _node_type) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_named(_resource, _name) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_name_contains(_resource, _needle) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_text_contains(_resource, _needle) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_ancestors(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_descendants(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_by_type_fields(_resource, _node_type, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_name_contains_fields(_resource, _needle, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_text_contains_fields(_resource, _needle, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_components(_resource) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_with_fills(_resource) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_with_strokes(_resource) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end
end
