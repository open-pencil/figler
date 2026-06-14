defmodule FigKiwi.Sparse do
  @moduledoc """
  Helpers for sparse schema-backed Kiwi maps.

  Sparse maps are produced by `FigKiwi.decode_sparse_message/1`. They contain a
  `:__kiwi_module__` key with the generated schema module and only the fields
  present in the encoded payload.
  """

  @module_key :__kiwi_module__

  @type t :: %{required(:__kiwi_module__) => module(), optional(atom()) => term()}

  @doc """
  Returns the generated schema module for a sparse map.
  """
  @spec module(t()) :: module()
  def module(%{@module_key => module}), do: module

  @doc """
  Returns sparse field keys, excluding metadata.
  """
  @spec fields(t()) :: [atom()]
  def fields(%{} = sparse) do
    sparse
    |> Map.keys()
    |> Enum.reject(&(&1 == @module_key))
  end

  @doc """
  Returns whether a sparse field was present on the wire.
  """
  @spec present?(t(), atom()) :: boolean()
  def present?(%{} = sparse, field), do: Map.has_key?(sparse, field)

  @doc """
  Fetches a sparse field value.
  """
  @spec fetch(t(), atom()) :: {:ok, term()} | :error
  def fetch(%{} = sparse, field), do: Map.fetch(sparse, field)

  @doc """
  Gets a sparse field value.
  """
  @spec get(t(), atom(), term()) :: term()
  def get(%{} = sparse, field, default \\ nil), do: Map.get(sparse, field, default)
end
