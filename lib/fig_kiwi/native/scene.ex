defmodule FigKiwi.Native.Scene do
  @moduledoc false

  alias FigKiwi.Native.Nif

  defdelegate decode_summary(binary), to: Nif, as: :decode_scene_summary
  defdelegate build_index(binary), to: Nif, as: :build_scene_index
  defdelegate query_xpath(binary, xpath), to: Nif, as: :query_scene_xpath
  defdelegate query_xpath_fields(binary, xpath, fields), to: Nif, as: :query_scene_xpath_fields
  defdelegate query_index(index, xpath), to: Nif, as: :query_scene_index
  defdelegate query_index_fields(index, xpath, fields), to: Nif, as: :query_scene_index_fields
end
