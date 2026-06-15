defmodule FigKiwi.Native.Codec do
  @moduledoc false

  alias FigKiwi.Native.Nif

  defdelegate decode_guid(binary), to: Nif
  defdelegate decode_vector(binary), to: Nif
  defdelegate decode_matrix(binary), to: Nif
  defdelegate decode_parent_index(binary), to: Nif
  defdelegate decode_image(binary), to: Nif
  defdelegate decode_node_change(binary), to: Nif
  defdelegate decode_message(binary), to: Nif
  defdelegate decode_sparse_message(binary), to: Nif
end
