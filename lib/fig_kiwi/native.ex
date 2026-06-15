defmodule FigKiwi.Native do
  @moduledoc false

  alias FigKiwi.Native.{Codec, Scene}

  defdelegate decode_guid(binary), to: Codec
  defdelegate decode_vector(binary), to: Codec
  defdelegate decode_matrix(binary), to: Codec
  defdelegate decode_parent_index(binary), to: Codec
  defdelegate decode_image(binary), to: Codec
  defdelegate decode_node_change(binary), to: Codec
  defdelegate decode_message(binary), to: Codec
  defdelegate decode_sparse_message(binary), to: Codec

  defdelegate decode_scene_summary(binary), to: Scene, as: :decode_summary
  defdelegate build_scene_index(binary), to: Scene, as: :build_index
  defdelegate query_scene_xpath(binary, xpath), to: Scene, as: :query_xpath
  defdelegate query_scene_xpath_fields(binary, xpath, fields), to: Scene, as: :query_xpath_fields
  defdelegate query_scene_index(index, xpath), to: Scene, as: :query_index
  defdelegate query_scene_index_fields(index, xpath, fields), to: Scene, as: :query_index_fields
end
