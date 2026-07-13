defmodule Figler.Native.GeneratedStubs do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      def decode_sparse_message(_bytes) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_graph_seed_records(_bytes) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_graph_focused_sparse_message(_bytes, _focus) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def decode_scene_summary(_bytes) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def build_scene_index(_bytes) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def build_scene_index_with_summary(_bytes) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_xpath(_bytes, _xpath) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def query_scene_xpath_fields(_bytes, _xpath, _fields) do
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

      def scene_index_by_type_fields(_resource, _node_type, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_named(_resource, _name) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_name_contains(_resource, _needle) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_name_contains_fields(_resource, _needle, _fields) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_text_contains(_resource, _needle) do
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

      def scene_index_ancestors(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end

      def scene_index_descendants(_resource, _guid) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end
end
