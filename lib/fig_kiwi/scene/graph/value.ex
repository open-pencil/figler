defmodule FigKiwi.Scene.Graph.Value do
  @moduledoc false

  def guid(nil), do: nil
  def guid(%{session_id: session_id, local_id: local_id}), do: {session_id, local_id}

  def vector(nil), do: nil
  def vector(%{x: x, y: y}), do: %{x: x, y: y}

  def matrix(nil), do: nil

  def matrix(%{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}) do
    %{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}
  end
end
