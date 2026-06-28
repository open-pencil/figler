defmodule Figler.Scene.Graph.Seed.Value do
  @moduledoc """
  Normalizes generated schema values into graph-friendly Elixir values.

  These helpers convert GUIDs, vectors, and matrices from generated structs or
  maps into compact values stored on seed nodes and resolved scene nodes.
  """

  def guid(nil), do: nil
  def guid(%{session_id: session_id, local_id: local_id}), do: {session_id, local_id}

  def vector(nil), do: nil
  def vector(%{x: x, y: y}), do: %{x: x, y: y}

  def matrix(nil), do: nil

  def matrix(%{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}) do
    %{m00: m00, m01: m01, m02: m02, m10: m10, m11: m11, m12: m12}
  end
end
