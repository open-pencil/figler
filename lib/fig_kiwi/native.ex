defmodule FigKiwi.Native do
  @moduledoc false

  use Rustler,
    otp_app: :fig_kiwi,
    crate: :fig_kiwi_native

  def decode_guid(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_vector(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_matrix(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_parent_index(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_image(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_node_change(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_message(_binary), do: :erlang.nif_error(:nif_not_loaded)
  def decode_scene_summary(_binary), do: :erlang.nif_error(:nif_not_loaded)
end
