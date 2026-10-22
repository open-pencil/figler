defmodule Figler.Codegen.Native.Graph.Prepare do
  @moduledoc """
  Normalizes source records before interpretation, as OpenPencil's reader does:

    * `parameterConsumptionMap` entries of type PROP_REF become `componentPropRefs`, and
      property defaults kept in `varValue` become `initialValue`;
    * a property definition naming `parentPropDefId` is completed from the nearest ancestor
      that defines it;
    * a record, and each of its override records, takes the paints, effects, layout grids, or
      text fields of the shared styles it references.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [Figler.Codegen.Native.Graph.Records]

  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod SymbolData, as: [:kiwi_records, :symbol_data]
  defrustmod TextData, as: [:kiwi_records, :text_data]
  defrustmod ParentIndex, as: [:kiwi_records, :parent_index]
  defrustmod ComponentPropDef, as: [:kiwi_records, :component_prop_def]
  defrustmod ComponentPropRef, as: [:kiwi_records, :component_prop_ref]
  defrustmod ComponentPropValue, as: [:kiwi_records, :component_prop_value]
  defrustmod ComponentPropNodeField, as: [:kiwi_records, :component_prop_node_field]
  defrustmod VariableDataMap, as: [:kiwi_records, :variable_data_map]
  defrustmod VariableDataMapEntry, as: [:kiwi_records, :variable_data_map_entry]
  defrustmod VariableData, as: [:kiwi_records, :variable_data]
  defrustmod VariableDataType, as: [:kiwi_records, :variable_data_type]
  defrustmod VariableAnyValue, as: [:kiwi_records, :variable_any_value]
  defrustmod VariableField, as: [:kiwi_records, :variable_field]
  defrustmod PropRefValue, as: [:kiwi_records, :prop_ref_value]
  defrustmod SymbolId, as: [:kiwi_records, :symbol_id]
  defrustmod StyleId, as: [:kiwi_records, :style_id]
  defrustmod AssetRef, as: [:kiwi_records, :asset_ref]
  defrustmod StyleType, as: [:kiwi_records, :style_type]
  defrustmod NodeType, as: [:kiwi_records, :node_type]
  defrustmod Definitions, as: [:kiwi_record_definitions]

  @typep resolved :: HashMap.t(GuidKey.t(), KiwiRecord.t())
  @typep styles :: HashMap.t(GuidKey.t(), KiwiRecord.t())
  @typep style_keys :: HashMap.t(String.t(), GuidKey.t())

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :prepare,
        :normalize,
        :normalize_default,
        :default_value,
        :put_prop_refs,
        :prop_ref,
        :node_field,
        :upsert_ref,
        :inherit_property_definitions,
        :linked_definitions,
        :resolve,
        :resolved_ancestors,
        :inherit_from,
        :inherit_definition,
        :parent_definition,
        :apply_styles,
        :style_records,
        :style_keys,
        :apply_style_refs,
        :style_field,
        :text_style,
        :referenced_style,
        :asset_style,
        :records_by_id,
        :inherit_definitions,
        :definitions_named,
        :with_text_style,
        :cached,
        :unversioned_style,
        :style_by_id,
        :style_names
      ])
  end

  @spec prepare(R.vec(KiwiRecord.t()), R.bool()) :: R.nif_result(R.vec(KiwiRecord.t()))
  defrust prepare(records, styles) do
    normalized = records |> iter() |> map(fn record -> normalize(record) end) |> collect()
    inherited = inherit_property_definitions(normalized)
    if styles, do: ok(apply_styles(inherited)), else: ok(inherited)
  end

  # Applies to a record, its override and derived records, and its text ranges.
  @spec normalize(R.ref(KiwiRecord.t())) :: KiwiRecord.t()
  defrust normalize(record) do
    record.map_records(NodeChange.COMPONENT_PROP_DEFS, fn definition ->
      normalize_default(definition)
    end)
    |> put_prop_refs()
    |> map_record(NodeChange.SYMBOL_DATA, fn data ->
      data.map_records(SymbolData.SYMBOL_OVERRIDES, fn layer -> normalize(layer) end)
    end)
    |> map_records(NodeChange.DERIVED_SYMBOL_DATA, fn derived -> normalize(derived) end)
    |> map_record(NodeChange.TEXT_DATA, fn text ->
      text.map_records(TextData.STYLE_OVERRIDE_TABLE, fn style -> normalize(style) end)
    end)
  end

  # Current files keep a property's default in `varValue`; an instance-swap default names
  # its component by GUID.
  @spec normalize_default(R.ref(KiwiRecord.t())) :: KiwiRecord.t()
  defrust normalize_default(definition) do
    if definition.has(ComponentPropDef.INITIAL_VALUE) do
      definition.clone()
    else
      case default_value(definition) do
        {:some, value} -> definition.put_record(ComponentPropDef.INITIAL_VALUE, value)
        :none -> definition.clone()
      end
    end
  end

  @spec default_value(R.ref(KiwiRecord.t())) :: R.option(KiwiRecord.t())
  defrust default_value(definition) do
    with {:some, variable} <- definition.record(ComponentPropDef.VAR_VALUE),
         {:some, value} <- variable.record(VariableData.VALUE) do
      case value.record(VariableAnyValue.SYMBOL_ID_VALUE).and_then(fn symbol ->
             symbol.record(SymbolId.GUID)
           end) do
        {:some, guid} ->
          some(
            KiwiRecord.new(Definitions.COMPONENT_PROP_VALUE)
            |> put_record(ComponentPropValue.GUID_VALUE, guid.clone())
          )

        :none ->
          some(value.clone())
      end
    else
      _ -> nil
    end
  end

  # A PROP_REF entry replaces the saved ref for the same field, keeping its position; new
  # fields follow the saved refs.
  @spec put_prop_refs(KiwiRecord.t()) :: KiwiRecord.t()
  defrust put_prop_refs(record) do
    entries =
      case record.record(NodeChange.PARAMETER_CONSUMPTION_MAP) do
        {:some, map} -> map.records(VariableDataMap.ENTRIES)
        :none -> Vec.new()
      end

    saved = record.records(NodeChange.COMPONENT_PROP_REFS) |> into_iter() |> cloned() |> collect()

    refs =
      entries
      |> iter()
      |> filter_map(fn entry -> prop_ref(entry) end)
      |> fold(saved, fn refs, prop_ref -> upsert_ref(refs, prop_ref) end)

    if refs.is_empty(), do: record, else: record.put_records(NodeChange.COMPONENT_PROP_REFS, refs)
  end

  @spec prop_ref(R.ref(R.ref(KiwiRecord.t()))) :: R.option(KiwiRecord.t())
  defrust prop_ref(entry) do
    with {:some, variable_field} <- entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD),
         {:some, field} <- node_field(variable_field),
         {:some, variable} <- entry.record(VariableDataMapEntry.VARIABLE_DATA),
         {:some, value} <- variable.record(VariableData.VALUE),
         {:some, reference} <- value.record(VariableAnyValue.PROP_REF_VALUE),
         {:some, def_id} <- reference.record(PropRefValue.DEF_ID),
         true <- variable.enum_value(VariableData.DATA_TYPE) == some(VariableDataType.PROP_REF) do
      some(
        KiwiRecord.new(Definitions.COMPONENT_PROP_REF)
        |> put_record(ComponentPropRef.DEF_ID, def_id.clone())
        |> put_enum(
          ComponentPropRef.COMPONENT_PROP_NODE_FIELD,
          field,
          Definitions.COMPONENT_PROP_NODE_FIELD
        )
      )
    else
      _ -> nil
    end
  end

  # The fields a property binds, from the variable field naming them to the property field.
  @spec node_field(R.u32()) :: R.option(R.u32())
  defrust node_field(field) do
    case field do
      VariableField.VISIBLE -> some(ComponentPropNodeField.VISIBLE)
      VariableField.TEXT_DATA -> some(ComponentPropNodeField.TEXT_DATA)
      VariableField.OVERRIDDEN_SYMBOL_ID -> some(ComponentPropNodeField.OVERRIDDEN_SYMBOL_ID)
      VariableField.SLOT_CONTENT_ID -> some(ComponentPropNodeField.SLOT_CONTENT_ID)
      _ -> nil
    end
  end

  # Replaces the last saved ref for the same field, or adds the ref after the others.
  @spec upsert_ref(R.vec(KiwiRecord.t()), KiwiRecord.t()) :: R.vec(KiwiRecord.t())
  defrust upsert_ref(refs, prop_ref) do
    field = prop_ref.enum_value(ComponentPropRef.COMPONENT_PROP_NODE_FIELD)

    case refs
         |> iter()
         |> rposition(fn saved ->
           saved.enum_value(ComponentPropRef.COMPONENT_PROP_NODE_FIELD) == field
         end) do
      {:some, index} ->
        refs.remove(index)
        refs.insert(index, prop_ref)
        refs

      :none ->
        refs.push(prop_ref)
        refs
    end
  end

  # Completes definitions that name a parent from the nearest ancestor holding it.
  @spec inherit_property_definitions(R.vec(KiwiRecord.t())) :: R.nif_result(R.vec(KiwiRecord.t()))
  defrust inherit_property_definitions(records) do
    if records.iter().any(fn record -> linked_definitions(record) end) do
      by_id = records_by_id(ref(records))
      resolved = HashMap.new()

      records
      |> iter()
      |> map(fn record -> resolve(record, ref(by_id), mut_ref(resolved), ref(HashSet.new())) end)
      |> collect()
    else
      ok(records)
    end
  end

  @spec records_by_id(R.slice(KiwiRecord.t())) :: HashMap.t(GuidKey.t(), R.ref(KiwiRecord.t()))
  defrust records_by_id(records) do
    records
    |> iter()
    |> filter_map(fn record -> record_id(record).map(fn id -> {id, record} end) end)
    |> collect()
  end

  @spec linked_definitions(R.ref(KiwiRecord.t())) :: R.bool()
  defrust linked_definitions(record) do
    record
    |> records(NodeChange.COMPONENT_PROP_DEFS)
    |> iter()
    |> any(fn definition -> definition.has(ComponentPropDef.PARENT_PROP_DEF_ID) end)
  end

  @spec resolve(
          R.ref(KiwiRecord.t()),
          R.ref(HashMap.t(GuidKey.t(), R.ref(KiwiRecord.t()))),
          R.mut_ref(resolved()),
          R.ref(HashSet.t(GuidKey.t()))
        ) :: R.nif_result(KiwiRecord.t())
  defrust resolve(record, by_id, resolved, visiting) do
    case record_id(record) do
      :none ->
        ok(record.clone())

      {:some, id} ->
        cond do
          resolved.contains_key(ref(id)) ->
            cached(resolved, id)

          # Only definitions that name a parent take anything from ancestors.
          not linked_definitions(record) ->
            resolved.insert(id, record.clone())
            ok(record.clone())

          visiting.contains(ref(id)) ->
            err(badarg())

          true ->
            visiting = visiting.clone()
            visiting.insert(id)
            ancestors = resolved_ancestors(record, by_id, resolved, ref(visiting))
            definitions = inherit_from(record, ref(ancestors))
            resolved.insert(id, definitions.clone())
            ok(definitions)
        end
    end
  end

  @spec cached(R.ref(resolved()), GuidKey.t()) :: R.nif_result(KiwiRecord.t())
  defrust cached(resolved, id) do
    case resolved.get(ref(id)) do
      {:some, record} -> ok(record.clone())
      :none -> err(badarg())
    end
  end

  @spec resolved_ancestors(
          R.ref(KiwiRecord.t()),
          R.ref(HashMap.t(GuidKey.t(), R.ref(KiwiRecord.t()))),
          R.mut_ref(resolved()),
          R.ref(HashSet.t(GuidKey.t()))
        ) :: R.nif_result(R.vec(KiwiRecord.t()))
  defrust resolved_ancestors(record, by_id, resolved, visiting) do
    case parent_id(record).and_then(fn id -> by_id.get(ref(id)) end) do
      :none ->
        ok(Vec.new())

      {:some, parent} ->
        parent = resolve(parent, by_id, resolved, visiting)
        ancestors = resolved_ancestors(ref(parent), by_id, resolved, visiting)
        ancestors.insert(0, parent)
        ok(ancestors)
    end
  end

  @spec inherit_from(R.ref(KiwiRecord.t()), R.slice(KiwiRecord.t())) ::
          R.nif_result(KiwiRecord.t())
  defrust inherit_from(record, ancestors) do
    definitions = inherit_definitions(record, ancestors)

    if record.has(NodeChange.COMPONENT_PROP_DEFS),
      do: ok(record.put_records(NodeChange.COMPONENT_PROP_DEFS, definitions)),
      else: ok(record.clone())
  end

  @spec inherit_definitions(R.ref(KiwiRecord.t()), R.slice(KiwiRecord.t())) ::
          R.nif_result(R.vec(KiwiRecord.t()))
  defrust inherit_definitions(record, ancestors) do
    record
    |> records(NodeChange.COMPONENT_PROP_DEFS)
    |> into_iter()
    |> map(fn definition -> inherit_definition(definition, ancestors) end)
    |> collect()
  end

  # A definition whose parent is not among its ancestors, as in a partial set of records,
  # keeps its own fields.
  @spec inherit_definition(R.ref(KiwiRecord.t()), R.slice(KiwiRecord.t())) ::
          R.nif_result(KiwiRecord.t())
  defrust inherit_definition(definition, ancestors) do
    case guid_key(definition.record(ComponentPropDef.PARENT_PROP_DEF_ID)) do
      :none ->
        ok(definition.clone())

      {:some, parent_id} ->
        parent = parent_definition(ancestors, parent_id)
        ok(parent.merge(definition))
    end
  end

  @spec parent_definition(R.slice(KiwiRecord.t()), GuidKey.t()) :: R.nif_result(KiwiRecord.t())
  defrust parent_definition(ancestors, parent_id) do
    found =
      ancestors
      |> iter()
      |> map(fn ancestor -> definitions_named(ancestor, parent_id) end)
      |> find(fn definitions -> not definitions.is_empty() end)

    case found do
      :none ->
        ok(KiwiRecord.new(Definitions.COMPONENT_PROP_DEF))

      {:some, definitions} ->
        if definitions.len() == 1, do: ok(definitions[0].clone()), else: err(badarg())
    end
  end

  @spec definitions_named(R.ref(KiwiRecord.t()), GuidKey.t()) :: R.vec(R.ref(KiwiRecord.t()))
  defrust definitions_named(ancestor, id) do
    ancestor
    |> records(NodeChange.COMPONENT_PROP_DEFS)
    |> into_iter()
    |> filter(fn definition -> guid_key(definition.record(ComponentPropDef.ID)) == some(id) end)
    |> collect()
  end

  @spec apply_styles(R.vec(KiwiRecord.t())) :: R.vec(KiwiRecord.t())
  defrust apply_styles(records) do
    styles = style_records(ref(records))

    if styles.is_empty() do
      records
    else
      keys = style_keys(ref(records))

      records
      |> iter()
      |> map(fn record -> apply_style_refs(record, ref(styles), ref(keys)) end)
      |> collect()
    end
  end

  @spec style_records(R.slice(KiwiRecord.t())) :: styles()
  defrust style_records(records) do
    records
    |> iter()
    |> filter(fn record -> record.has(NodeChange.STYLE_TYPE) end)
    |> filter_map(fn record -> record_id(record).map(fn id -> {id, record.clone()} end) end)
    |> collect()
  end

  # Library styles are named by key, and by key and version.
  @spec style_keys(R.slice(KiwiRecord.t())) :: style_keys()
  defrust style_keys(records) do
    records |> iter() |> flat_map(fn record -> style_names(record) end) |> collect()
  end

  @spec style_names(R.ref(KiwiRecord.t())) :: R.vec({String.t(), GuidKey.t()})
  defrust style_names(record) do
    with {:some, key} <- record.str(NodeChange.KEY),
         {:some, id} <- record_id(record) do
      case record.str(NodeChange.VERSION) do
        {:some, version} -> [{key.to_string(), id}, {format!("{key}@{version}"), id}]
        :none -> [{key.to_string(), id}]
      end
    else
      _ -> []
    end
  end

  @spec apply_style_refs(R.ref(KiwiRecord.t()), R.ref(styles()), R.ref(style_keys())) ::
          KiwiRecord.t()
  defrust apply_style_refs(record, styles, keys) do
    fill =
      style_field(
        record.clone(),
        NodeChange.STYLE_ID_FOR_FILL,
        StyleType.FILL,
        NodeChange.FILL_PAINTS,
        NodeChange.FILL_PAINTS,
        styles,
        keys
      )

    stroke =
      style_field(
        fill,
        NodeChange.STYLE_ID_FOR_STROKE_FILL,
        StyleType.FILL,
        NodeChange.FILL_PAINTS,
        NodeChange.STROKE_PAINTS,
        styles,
        keys
      )

    effect =
      style_field(
        stroke,
        NodeChange.STYLE_ID_FOR_EFFECT,
        StyleType.EFFECT,
        NodeChange.EFFECTS,
        NodeChange.EFFECTS,
        styles,
        keys
      )

    grid =
      style_field(
        effect,
        NodeChange.STYLE_ID_FOR_GRID,
        StyleType.GRID,
        NodeChange.LAYOUT_GRIDS,
        NodeChange.LAYOUT_GRIDS,
        styles,
        keys
      )

    text_style(grid, styles, keys).map_record(NodeChange.SYMBOL_DATA, fn data ->
      data.map_records(SymbolData.SYMBOL_OVERRIDES, fn layer ->
        apply_style_refs(layer, styles, keys)
      end)
    end)
  end

  # A style of `style_type` that sets `source` gives the record its `target`.
  @spec style_field(
          KiwiRecord.t(),
          R.u32(),
          R.u32(),
          R.u32(),
          R.u32(),
          R.ref(styles()),
          R.ref(style_keys())
        ) :: KiwiRecord.t()
  defrust style_field(record, field, style_type, source, target, styles, keys) do
    with {:some, style} <- referenced_style(ref(record), field, styles, keys),
         {:some, value} <- style.get(source) do
      if style.enum_value(NodeChange.STYLE_TYPE) == some(style_type),
        do: record.put(target, value.clone()),
        else: record
    else
      _ -> record
    end
  end

  # A text style sets the fields it defines, and its decoration even when unset.
  @spec text_style(KiwiRecord.t(), R.ref(styles()), R.ref(style_keys())) :: KiwiRecord.t()
  defrust text_style(record, styles, keys) do
    case referenced_style(ref(record), NodeChange.STYLE_ID_FOR_TEXT, styles, keys) do
      {:some, style} ->
        if style.enum_value(NodeChange.TYPE) == some(NodeType.TEXT) and
             style.enum_value(NodeChange.STYLE_TYPE) == some(StyleType.TEXT) do
          with_text_style(record, ref(style))
        else
          record
        end

      :none ->
        record
    end
  end

  @spec with_text_style(KiwiRecord.t(), R.ref(KiwiRecord.t())) :: KiwiRecord.t()
  defrust with_text_style(record, style) do
    text =
      style.take(
        ref([
          NodeChange.FONT_SIZE,
          NodeChange.FONT_NAME,
          NodeChange.LINE_HEIGHT,
          NodeChange.LETTER_SPACING,
          NodeChange.TEXT_CASE
        ])
      )

    merged = record.merge(ref(text))

    case style.get(NodeChange.TEXT_DECORATION) do
      {:some, decoration} -> merged.put(NodeChange.TEXT_DECORATION, decoration.clone())
      :none -> merged.delete(NodeChange.TEXT_DECORATION)
    end
  end

  @spec referenced_style(R.ref(KiwiRecord.t()), R.u32(), R.ref(styles()), R.ref(style_keys())) ::
          R.option(KiwiRecord.t())
  defrust referenced_style(record, field, styles, keys) do
    case record.record(field) do
      :none ->
        nil

      {:some, reference} ->
        case guid_key(reference.record(StyleId.GUID)) do
          {:some, id} ->
            style_by_id(styles, id)

          :none ->
            case reference.record(StyleId.ASSET_REF) do
              {:some, asset} -> asset_style(asset, styles, keys)
              :none -> nil
            end
        end
    end
  end

  @spec asset_style(R.ref(KiwiRecord.t()), R.ref(styles()), R.ref(style_keys())) ::
          R.option(KiwiRecord.t())
  defrust asset_style(asset, styles, keys) do
    case asset.str(AssetRef.KEY) do
      :none ->
        nil

      {:some, key} ->
        case asset.str(AssetRef.VERSION) do
          {:some, version} ->
            case keys.get(ref(format!("{key}@{version}"))) do
              {:some, id} -> style_by_id(styles, deref(id))
              :none -> unversioned_style(styles, keys, key)
            end

          :none ->
            unversioned_style(styles, keys, key)
        end
    end
  end

  @spec unversioned_style(R.ref(styles()), R.ref(style_keys()), R.str()) ::
          R.option(KiwiRecord.t())
  defrust unversioned_style(styles, keys, key) do
    case keys.get(key) do
      {:some, id} -> style_by_id(styles, deref(id))
      :none -> nil
    end
  end

  @spec style_by_id(R.ref(styles()), GuidKey.t()) :: R.option(KiwiRecord.t())
  defrust style_by_id(styles, id) do
    case styles.get(ref(id)) do
      {:some, style} -> some(style.clone())
      :none -> nil
    end
  end
end
