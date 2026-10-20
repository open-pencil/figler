defmodule Figler.Scene.Graph.Occurrence.GUID do
  @moduledoc """
  GUIDs as the occurrence interpreter compares and indexes them.

  Sparse records carry GUIDs as `%{session_id: _, local_id: _}` maps; the
  interpreter uses `{session_id, local_id}` tuples.
  """

  @unset {0xFFFFFFFF, 0xFFFFFFFF}

  @type t :: {non_neg_integer(), non_neg_integer()}

  @spec key(map() | t() | nil) :: t() | nil
  def key(nil), do: nil
  def key({_session_id, _local_id} = key), do: key
  def key(%{session_id: session_id, local_id: local_id}), do: {session_id, local_id}
  def key(_value), do: nil

  @spec same?(map() | t() | nil, map() | t() | nil) :: boolean()
  def same?(left, right) do
    case {key(left), key(right)} do
      {nil, _right} -> false
      {key, key} -> true
      _different -> false
    end
  end

  @doc "An override key, unless it is the unset GUID layers without one share."
  @spec override_key(term()) :: t() | nil
  def override_key(value) do
    case key(value) do
      @unset -> nil
      key -> key
    end
  end

  @spec unset?(map() | t() | nil) :: boolean()
  def unset?(value), do: key(value) == @unset

  @spec format(t() | nil) :: String.t() | nil
  def format(nil), do: nil
  def format({session_id, local_id}), do: "#{session_id}:#{local_id}"
end
