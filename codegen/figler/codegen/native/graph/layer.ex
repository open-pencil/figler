defmodule Figler.Codegen.Native.Graph.Layer do
  @moduledoc """
  Swaps and assignments addressed relative to the expansion that receives them, for the native
  interpreter.

  Mirrors `Figler.Scene.Graph.Occurrence.Layer`. `boundary` is set when an outer decision
  replaced a component the layer was written against.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodeType, as: [:kiwi_records, :node_type]
  defrustmod SymbolData, as: [:kiwi_records, :symbol_data]
  defrustmod GuidPath, as: [:kiwi_records, :guid_path]

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
           required(:assignments) => R.vec(KiwiRecord.t())
         }

  # Fields an owner sets at a path in its expansion.
  @typep claim :: %{required(:path) => R.vec(GuidKey.t()), required(:props) => KiwiRecord.t()}

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
  @spec own(R.ref(KiwiRecord.t()), layer_owner()) :: {R.vec(layer()), R.vec(claim())}
  defrust own(source, owner) do
    overrides =
      case source.record(NodeChange.SYMBOL_DATA) do
        {:some, data} -> data.records(SymbolData.SYMBOL_OVERRIDES)
        :none -> Vec.new()
      end

    layers =
      overrides
      |> iter()
      |> filter_map(fn override -> structural_layer(override, ref(owner)) end)
      |> collect()

    claims = mode_claims(source)

    for override <- overrides do
      path = override_path(override)

      props =
        override.drop(
          ref([
            NodeChange.GUID_PATH,
            NodeChange.OVERRIDDEN_SYMBOL_ID,
            NodeChange.COMPONENT_PROP_ASSIGNMENTS
          ])
        )

      if not path.is_empty() and not props.is_empty() do
        claims.push(struct_literal(Claim, path: path, props: props))
      end
    end

    {layers, claims}
  end

  @spec mode_claims(R.ref(KiwiRecord.t())) :: R.vec(claim())
  defrust mode_claims(source) do
    with true <- source.enum_value(NodeChange.TYPE) == some(NodeType.INSTANCE),
         true <- source.has(NodeChange.VARIABLE_MODE_BY_SET_MAP),
         {:some, symbol_id} <- symbol_id(source) do
      [
        struct_literal(Claim,
          path: [symbol_id],
          props: source.take(ref([NodeChange.VARIABLE_MODE_BY_SET_MAP]))
        )
      ]
    else
      _ -> Vec.new()
    end
  end

  @spec override_path(R.ref(KiwiRecord.t())) :: R.vec(GuidKey.t())
  defrust override_path(override) do
    case override.record(NodeChange.GUID_PATH) do
      {:some, path} ->
        path.records(GuidPath.GUIDS)
        |> into_iter()
        |> filter_map(fn guid -> guid_key(some(guid)) end)
        |> collect()

      :none ->
        Vec.new()
    end
  end

  @spec structural_layer(R.ref(KiwiRecord.t()), R.ref(layer_owner())) :: R.option(layer())
  defrust structural_layer(override, owner) do
    path = override_path(override)
    swap = guid_key(override.record(NodeChange.OVERRIDDEN_SYMBOL_ID))

    assignments =
      override.records(NodeChange.COMPONENT_PROP_ASSIGNMENTS)
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
