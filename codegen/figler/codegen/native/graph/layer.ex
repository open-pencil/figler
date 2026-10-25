defmodule Figler.Codegen.Native.Graph.Layer do
  @moduledoc """
  Swaps and assignments addressed relative to the expansion that receives them, for the native
  interpreter.

  `boundary` is set when an outer decision replaced a component the layer was written against.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep layer_owner :: %{required(:id) => GuidKey.t(), required(:rank) => R.u32()}

  @typep boundary :: %{
           required(:replaced) => R.vec(GuidKey.t()),
           required(:path) => R.vec(GuidKey.t())
         }

  @typep layer :: %{
           required(:owner) => layer_owner(),
           required(:declared_path) => R.vec(GuidKey.t()),
           required(:path) => R.vec(GuidKey.t()),
           required(:swap) => R.option(GuidKey.t()),
           required(:boundary) => R.option(boundary()),
           required(:assignments) => R.vec(Kiwi.kiwi_record())
         }

  # Fields an owner sets at a path in its expansion.
  @typep claim :: %{required(:path) => R.vec(GuidKey.t()), required(:props) => Kiwi.kiwi_record()}

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :own,
        :mode_claims,
        :override_path,
        :structural_layer,
        :descend
      ])
  end

  # Splits an owner's saved overrides into structural layers and property claims. A mode
  # placed on an instance record belongs to the instance even when `symbolOverrides` does not
  # repeat it, so it becomes a root claim.
  @spec own(R.ref(Kiwi.kiwi_record()), layer_owner()) :: {R.vec(layer()), R.vec(claim())}
  defrust own(source, owner) do
    overrides =
      case source.record(Kiwi.NodeChange.SYMBOL_DATA) do
        {:some, data} -> data.records(Kiwi.SymbolData.SYMBOL_OVERRIDES)
        :none -> Vec.new()
      end

    layers =
      for override <- overrides.iter(),
          {:some, layer} <- [structural_layer(override, owner)],
          do: layer

    claims = mode_claims(source)

    for override <- overrides do
      path = override_path(override)

      props =
        override.drop(
          ref([
            Kiwi.NodeChange.GUID_PATH,
            Kiwi.NodeChange.OVERRIDDEN_SYMBOL_ID,
            Kiwi.NodeChange.COMPONENT_PROP_ASSIGNMENTS
          ])
        )

      if not path.is_empty() and not props.is_empty() do
        claims.push(struct_literal(Claim, path: path, props: props))
      end
    end

    {layers, claims}
  end

  @spec mode_claims(R.ref(Kiwi.kiwi_record())) :: R.vec(claim())
  defrust mode_claims(source) do
    with true <- source.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.INSTANCE),
         true <- source.has(Kiwi.NodeChange.VARIABLE_MODE_BY_SET_MAP),
         {:some, symbol_id} <- symbol_id(source) do
      [
        struct_literal(Claim,
          path: [symbol_id],
          props: source.take(ref([Kiwi.NodeChange.VARIABLE_MODE_BY_SET_MAP]))
        )
      ]
    else
      _ -> Vec.new()
    end
  end

  @spec override_path(R.ref(Kiwi.kiwi_record())) :: R.vec(GuidKey.t())
  defrust override_path(override) do
    case override.record(Kiwi.NodeChange.GUID_PATH) do
      {:some, path} ->
        for guid <- path.records(Kiwi.GuidPath.GUIDS),
            {:some, key} <- [guid_key(some(guid))],
            do: key

      :none ->
        Vec.new()
    end
  end

  @spec structural_layer(R.ref(Kiwi.kiwi_record()), R.ref(layer_owner())) :: R.option(layer())
  defrust structural_layer(override, owner) do
    path = override_path(override)
    swap = guid_key(override.record(Kiwi.NodeChange.OVERRIDDEN_SYMBOL_ID))

    assignments =
      override.records(Kiwi.NodeChange.COMPONENT_PROP_ASSIGNMENTS)
      |> into_iter()
      |> cloned()
      |> collect()

    if not path.is_empty() and (swap.is_some() or not assignments.is_empty()) do
      some(
        struct_literal(Layer,
          owner: owner.clone(),
          declared_path: path.clone(),
          path: path,
          swap: swap,
          boundary: nil,
          assignments: assignments
        )
      )
    else
      nil
    end
  end

  # The layer one level further down its path.
  @spec descend(R.ref(layer())) :: layer()
  defrust descend(layer) do
    %{layer.clone() | path: layer.path.iter().skip(1).copied().collect()}
  end
end
