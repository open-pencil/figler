defmodule FigKiwi.Native.Codec do
  @moduledoc false

  alias FigKiwi.Native.Nif

  @delegates [
    :decode_guid,
    :decode_vector,
    :decode_matrix,
    :decode_parent_index,
    :decode_image,
    :decode_node_change,
    :decode_message,
    :decode_sparse_message
  ]

  for name <- @delegates do
    defdelegate unquote(name)(binary), to: Nif
  end

  defdelegate decode_graph_focused_sparse_message(binary, focus), to: Nif
end
