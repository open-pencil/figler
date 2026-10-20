defmodule Figler.Scene.Graph.Occurrence.Layer do
  @moduledoc false

  # A swap or assignment addressed relative to the expansion that receives it.
  # `boundary` is set when an outer decision replaced a component the layer
  # was written against: `%{replaced: [component], path: path}`.

  alias Figler.Scene.Graph.Occurrence.GUID

  @enforce_keys [:owner, :declared_path, :path]
  defstruct [:owner, :declared_path, :path, :swap, :boundary, assignments: []]

  @type owner :: %{id: GUID.t(), rank: non_neg_integer()}

  @type t :: %__MODULE__{
          owner: owner(),
          declared_path: [GUID.t()],
          path: [GUID.t()],
          swap: GUID.t() | nil,
          boundary: %{replaced: [GUID.t()], path: [GUID.t()]} | nil,
          assignments: [map()]
        }

  @type claim :: %{path: [GUID.t()], props: map()}

  @override_structure [
    :guid_path,
    :overridden_symbol_id,
    :component_prop_assignments,
    :__kiwi_module__
  ]

  @doc """
  Splits an owner's saved overrides into structural layers and property claims.

  A mode placed on an instance record belongs to the instance even when
  `symbolOverrides` does not repeat it, so it becomes a root claim.
  """
  @spec own(map(), owner()) :: {[t()], [claim()]}
  def own(source, owner) do
    {structural, claims} =
      source
      |> get_in([:symbol_data, :symbol_overrides])
      |> List.wrap()
      |> Enum.reduce({[], Enum.reverse(mode_claims(source))}, &split_override(&1, &2, owner))

    {Enum.reverse(structural), Enum.reverse(claims)}
  end

  defp mode_claims(%{type: :instance, variable_mode_by_set_map: modes} = source)
       when modes != nil do
    case get_in(source, [:symbol_data, :symbol_id]) |> GUID.key() do
      nil -> []
      symbol_id -> [%{path: [symbol_id], props: %{variable_mode_by_set_map: modes}}]
    end
  end

  defp mode_claims(_source), do: []

  defp split_override(override, {structural, claims}, owner) do
    case override |> get_in([:guid_path, :guids]) |> List.wrap() |> Enum.map(&GUID.key/1) do
      [] ->
        {structural, claims}

      path ->
        props = Map.drop(override, @override_structure)
        {structural_layer(override, path, owner) ++ structural, claim(path, props) ++ claims}
    end
  end

  defp structural_layer(override, path, owner) do
    swap = GUID.key(Map.get(override, :overridden_symbol_id))
    assignments = Map.get(override, :component_prop_assignments) || []

    if swap || assignments != [],
      do: [
        %__MODULE__{
          owner: owner,
          declared_path: path,
          path: path,
          swap: swap,
          assignments: assignments
        }
      ],
      else: []
  end

  defp claim(_path, props) when map_size(props) == 0, do: []
  defp claim(path, props), do: [%{path: path, props: props}]

  @doc "The layer one level further down its path."
  @spec descend(t()) :: t()
  def descend(%__MODULE__{path: [_segment | rest]} = layer), do: %{layer | path: rest}
end
