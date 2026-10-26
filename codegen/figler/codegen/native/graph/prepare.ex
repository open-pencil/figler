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
    callable_modules: [Figler.Codegen.Native.Graph.Records]

  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep resolved :: HashMap.t(Records.guid_key(), Kiwi.kiwi_record())
  @typep styles :: HashMap.t(Records.guid_key(), Kiwi.kiwi_record())
  @typep style_keys :: HashMap.t(String.t(), Records.guid_key())

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  @spec prepare(R.vec(Kiwi.kiwi_record()), R.bool()) :: R.nif_result(R.vec(Kiwi.kiwi_record()))
  defrust prepare(records, styles) do
    normalized = Enum.map(records, fn record -> normalize(record) end)
    inherited = inherit_property_definitions(normalized)
    if styles, do: ok(apply_styles(inherited)), else: ok(inherited)
  end

  # Applies to a record, its override and derived records, and its text ranges.
  @spec normalize(R.ref(Kiwi.kiwi_record())) :: Kiwi.kiwi_record()
  defrust normalize(record) do
    record.map_records(Kiwi.NodeChange.COMPONENT_PROP_DEFS, fn definition ->
      normalize_default(definition)
    end)
    |> put_prop_refs()
    |> map_record(Kiwi.NodeChange.SYMBOL_DATA, fn data ->
      data.map_records(Kiwi.SymbolData.SYMBOL_OVERRIDES, fn layer -> normalize(layer) end)
    end)
    |> map_records(Kiwi.NodeChange.DERIVED_SYMBOL_DATA, fn derived -> normalize(derived) end)
    |> map_record(Kiwi.NodeChange.TEXT_DATA, fn text ->
      text.map_records(Kiwi.TextData.STYLE_OVERRIDE_TABLE, fn style -> normalize(style) end)
    end)
  end

  # Current files keep a property's default in `varValue`; an instance-swap default names
  # its component by GUID.
  @spec normalize_default(R.ref(Kiwi.kiwi_record())) :: Kiwi.kiwi_record()
  defrust normalize_default(definition) do
    if definition.has(Kiwi.ComponentPropDef.INITIAL_VALUE) do
      definition.clone()
    else
      case default_value(definition) do
        {:some, value} -> definition.put_record(Kiwi.ComponentPropDef.INITIAL_VALUE, value)
        :none -> definition.clone()
      end
    end
  end

  @spec default_value(R.ref(Kiwi.kiwi_record())) :: R.option(Kiwi.kiwi_record())
  defrust default_value(definition) do
    with {:some, variable} <- definition.record(Kiwi.ComponentPropDef.VAR_VALUE),
         {:some, value} <- variable.record(Kiwi.VariableData.VALUE) do
      case value.record(Kiwi.VariableAnyValue.SYMBOL_ID_VALUE).and_then(fn symbol ->
             symbol.record(Kiwi.SymbolId.GUID)
           end) do
        {:some, guid} ->
          some(
            KiwiRecord.new(Kiwi.Definitions.COMPONENT_PROP_VALUE)
            |> put_record(Kiwi.ComponentPropValue.GUID_VALUE, guid.clone())
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
  @spec put_prop_refs(Kiwi.kiwi_record()) :: Kiwi.kiwi_record()
  defrust put_prop_refs(record) do
    entries =
      case record.record(Kiwi.NodeChange.PARAMETER_CONSUMPTION_MAP) do
        {:some, map} -> map.records(Kiwi.VariableDataMap.ENTRIES)
        :none -> []
      end

    saved =
      Enum.map(record.records(Kiwi.NodeChange.COMPONENT_PROP_REFS), fn saved -> saved.clone() end)

    refs =
      for entry <- entries, {:some, prop_ref} <- [prop_ref(entry)], reduce: saved do
        refs -> upsert_ref(refs, prop_ref)
      end

    if refs == [],
      do: record,
      else: record.put_records(Kiwi.NodeChange.COMPONENT_PROP_REFS, refs)
  end

  @spec prop_ref(R.ref(Kiwi.kiwi_record())) :: R.option(Kiwi.kiwi_record())
  defrust prop_ref(entry) do
    with {:some, variable_field} <- entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD),
         {:some, field} <- node_field(variable_field),
         {:some, variable} <- entry.record(Kiwi.VariableDataMapEntry.VARIABLE_DATA),
         {:some, value} <- variable.record(Kiwi.VariableData.VALUE),
         {:some, reference} <- value.record(Kiwi.VariableAnyValue.PROP_REF_VALUE),
         {:some, def_id} <- reference.record(Kiwi.PropRefValue.DEF_ID),
         true <-
           variable.enum_value(Kiwi.VariableData.DATA_TYPE) ==
             some(Kiwi.VariableDataType.PROP_REF) do
      some(
        KiwiRecord.new(Kiwi.Definitions.COMPONENT_PROP_REF)
        |> put_record(Kiwi.ComponentPropRef.DEF_ID, def_id.clone())
        |> put_enum(
          Kiwi.ComponentPropRef.COMPONENT_PROP_NODE_FIELD,
          field,
          Kiwi.Definitions.COMPONENT_PROP_NODE_FIELD
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
      Kiwi.VariableField.VISIBLE ->
        some(Kiwi.ComponentPropNodeField.VISIBLE)

      Kiwi.VariableField.TEXT_DATA ->
        some(Kiwi.ComponentPropNodeField.TEXT_DATA)

      Kiwi.VariableField.OVERRIDDEN_SYMBOL_ID ->
        some(Kiwi.ComponentPropNodeField.OVERRIDDEN_SYMBOL_ID)

      Kiwi.VariableField.SLOT_CONTENT_ID ->
        some(Kiwi.ComponentPropNodeField.SLOT_CONTENT_ID)

      _ ->
        nil
    end
  end

  # Replaces the last saved ref for the same field, or adds the ref after the others.
  @spec upsert_ref(R.vec(Kiwi.kiwi_record()), Kiwi.kiwi_record()) :: R.vec(Kiwi.kiwi_record())
  defrust upsert_ref(refs, prop_ref) do
    field = prop_ref.enum_value(Kiwi.ComponentPropRef.COMPONENT_PROP_NODE_FIELD)

    last =
      refs
      |> Enum.map(fn saved ->
        saved.enum_value(Kiwi.ComponentPropRef.COMPONENT_PROP_NODE_FIELD)
      end)
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.find_value(fn {saved, index} -> if saved == field, do: some(index) end)

    case last do
      {:some, index} -> List.replace_at(refs, index, prop_ref)
      :none -> refs ++ [prop_ref]
    end
  end

  # Completes definitions that name a parent from the nearest ancestor holding it.
  @spec inherit_property_definitions(R.vec(Kiwi.kiwi_record())) ::
          R.nif_result(R.vec(Kiwi.kiwi_record()))
  defrust inherit_property_definitions(records) do
    if Enum.any?(records, &linked_definitions/1) do
      by_id = records_by_id(records)
      resolved = %{}
      Enum.map(records, fn record -> resolve(record, by_id, resolved, MapSet.new()) end)
    else
      {:ok, records}
    end
  end

  @spec records_by_id(R.slice(Kiwi.kiwi_record())) ::
          HashMap.t(Records.guid_key(), R.ref(Kiwi.kiwi_record()))
  defrust records_by_id(records) do
    for record <- records,
        {:some, id} <- [record_id(record)],
        into: %{},
        do: {id, record}
  end

  @spec linked_definitions(R.ref(Kiwi.kiwi_record())) :: R.bool()
  defrust linked_definitions(record) do
    record.records(Kiwi.NodeChange.COMPONENT_PROP_DEFS)
    |> Enum.any?(fn definition -> definition.has(Kiwi.ComponentPropDef.PARENT_PROP_DEF_ID) end)
  end

  @spec resolve(
          R.ref(Kiwi.kiwi_record()),
          R.ref(HashMap.t(Records.guid_key(), R.ref(Kiwi.kiwi_record()))),
          R.mut_ref(resolved()),
          R.ref(HashSet.t(Records.guid_key()))
        ) :: R.nif_result(Kiwi.kiwi_record())
  defrust resolve(record, by_id, resolved, visiting) do
    case record_id(record) do
      :none ->
        {:ok, record.clone()}

      {:some, id} ->
        cond do
          Map.has_key?(resolved, id) ->
            cached(resolved, id)

          # Only definitions that name a parent take anything from ancestors.
          not linked_definitions(record) ->
            resolved.insert(id, record.clone())
            {:ok, record.clone()}

          MapSet.member?(visiting, id) ->
            {:error, badarg()}

          true ->
            visiting = MapSet.put(visiting, id)
            ancestors = resolved_ancestors(record, by_id, resolved, visiting)
            definitions = inherit_from(record, ancestors)
            resolved.insert(id, definitions.clone())
            {:ok, definitions}
        end
    end
  end

  @spec cached(R.ref(resolved()), Records.guid_key()) :: R.nif_result(Kiwi.kiwi_record())
  defrust cached(resolved, id) do
    case Map.get(resolved, id) do
      {:some, record} -> {:ok, record}
      :none -> {:error, badarg()}
    end
  end

  @spec resolved_ancestors(
          R.ref(Kiwi.kiwi_record()),
          R.ref(HashMap.t(Records.guid_key(), R.ref(Kiwi.kiwi_record()))),
          R.mut_ref(resolved()),
          R.ref(HashSet.t(Records.guid_key()))
        ) :: R.nif_result(R.vec(Kiwi.kiwi_record()))
  defrust resolved_ancestors(record, by_id, resolved, visiting) do
    case parent_id(record).and_then(fn id -> Map.get(by_id, id) end) do
      :none ->
        {:ok, []}

      {:some, parent} ->
        parent = resolve(parent, by_id, resolved, visiting)
        ancestors = resolved_ancestors(parent, by_id, resolved, visiting)
        {:ok, [parent] ++ ancestors}
    end
  end

  @spec inherit_from(R.ref(Kiwi.kiwi_record()), R.slice(Kiwi.kiwi_record())) ::
          R.nif_result(Kiwi.kiwi_record())
  defrust inherit_from(record, ancestors) do
    definitions = inherit_definitions(record, ancestors)

    if record.has(Kiwi.NodeChange.COMPONENT_PROP_DEFS),
      do: {:ok, record.put_records(Kiwi.NodeChange.COMPONENT_PROP_DEFS, definitions)},
      else: {:ok, record.clone()}
  end

  @spec inherit_definitions(R.ref(Kiwi.kiwi_record()), R.slice(Kiwi.kiwi_record())) ::
          R.nif_result(R.vec(Kiwi.kiwi_record()))
  defrust inherit_definitions(record, ancestors) do
    record.records(Kiwi.NodeChange.COMPONENT_PROP_DEFS)
    |> Enum.map(fn definition -> inherit_definition(definition, ancestors) end)
  end

  # A definition whose parent is not among its ancestors, as in a partial set of records,
  # keeps its own fields.
  @spec inherit_definition(R.ref(Kiwi.kiwi_record()), R.slice(Kiwi.kiwi_record())) ::
          R.nif_result(Kiwi.kiwi_record())
  defrust inherit_definition(definition, ancestors) do
    case guid_key(definition.record(Kiwi.ComponentPropDef.PARENT_PROP_DEF_ID)) do
      :none ->
        {:ok, definition.clone()}

      {:some, parent_id} ->
        parent = parent_definition(ancestors, parent_id)
        {:ok, parent.merge(definition)}
    end
  end

  @spec parent_definition(R.slice(Kiwi.kiwi_record()), Records.guid_key()) ::
          R.nif_result(Kiwi.kiwi_record())
  defrust parent_definition(ancestors, parent_id) do
    found =
      ancestors
      |> Enum.map(fn ancestor -> definitions_named(ancestor, parent_id) end)
      |> Enum.find(fn definitions -> definitions != [] end)

    case found do
      :none ->
        {:ok, KiwiRecord.new(Kiwi.Definitions.COMPONENT_PROP_DEF)}

      {:some, definitions} ->
        case definitions do
          [definition] -> {:ok, definition.clone()}
          _definitions -> {:error, badarg()}
        end
    end
  end

  @spec definitions_named(R.ref(Kiwi.kiwi_record()), Records.guid_key()) ::
          R.vec(R.ref(Kiwi.kiwi_record()))
  defrust definitions_named(ancestor, id) do
    ancestor.records(Kiwi.NodeChange.COMPONENT_PROP_DEFS)
    |> Enum.filter(fn definition ->
      guid_key(definition.record(Kiwi.ComponentPropDef.ID)) == some(id)
    end)
  end

  @spec apply_styles(R.vec(Kiwi.kiwi_record())) :: R.vec(Kiwi.kiwi_record())
  defrust apply_styles(records) do
    styles = style_records(records)

    if styles == %{} do
      records
    else
      keys = style_keys(records)

      Enum.map(records, fn record -> apply_style_refs(record, styles, keys) end)
    end
  end

  @spec style_records(R.slice(Kiwi.kiwi_record())) :: styles()
  defrust style_records(records) do
    for record <- records,
        record.has(Kiwi.NodeChange.STYLE_TYPE),
        {:some, id} <- [record_id(record)],
        into: %{},
        do: {id, record.clone()}
  end

  # Library styles are named by key, and by key and version.
  @spec style_keys(R.slice(Kiwi.kiwi_record())) :: style_keys()
  defrust style_keys(records) do
    Enum.flat_map(records, &style_names/1)
  end

  @spec style_names(R.ref(Kiwi.kiwi_record())) :: R.vec({String.t(), Records.guid_key()})
  defrust style_names(record) do
    with {:some, key} <- record.str(Kiwi.NodeChange.KEY),
         {:some, id} <- record_id(record) do
      case record.str(Kiwi.NodeChange.VERSION) do
        {:some, version} -> [{key.to_string(), id}, {format!("{key}@{version}"), id}]
        :none -> [{key.to_string(), id}]
      end
    else
      _ -> []
    end
  end

  @spec apply_style_refs(R.ref(Kiwi.kiwi_record()), R.ref(styles()), R.ref(style_keys())) ::
          Kiwi.kiwi_record()
  defrust apply_style_refs(record, styles, keys) do
    fill =
      style_field(
        record.clone(),
        Kiwi.NodeChange.STYLE_ID_FOR_FILL,
        Kiwi.StyleType.FILL,
        Kiwi.NodeChange.FILL_PAINTS,
        Kiwi.NodeChange.FILL_PAINTS,
        styles,
        keys
      )

    stroke =
      style_field(
        fill,
        Kiwi.NodeChange.STYLE_ID_FOR_STROKE_FILL,
        Kiwi.StyleType.FILL,
        Kiwi.NodeChange.FILL_PAINTS,
        Kiwi.NodeChange.STROKE_PAINTS,
        styles,
        keys
      )

    effect =
      style_field(
        stroke,
        Kiwi.NodeChange.STYLE_ID_FOR_EFFECT,
        Kiwi.StyleType.EFFECT,
        Kiwi.NodeChange.EFFECTS,
        Kiwi.NodeChange.EFFECTS,
        styles,
        keys
      )

    grid =
      style_field(
        effect,
        Kiwi.NodeChange.STYLE_ID_FOR_GRID,
        Kiwi.StyleType.GRID,
        Kiwi.NodeChange.LAYOUT_GRIDS,
        Kiwi.NodeChange.LAYOUT_GRIDS,
        styles,
        keys
      )

    text_style(grid, styles, keys).map_record(Kiwi.NodeChange.SYMBOL_DATA, fn data ->
      data.map_records(Kiwi.SymbolData.SYMBOL_OVERRIDES, fn layer ->
        apply_style_refs(layer, styles, keys)
      end)
    end)
  end

  # A style of `style_type` that sets `source` gives the record its `target`.
  @spec style_field(
          Kiwi.kiwi_record(),
          R.u32(),
          R.u32(),
          R.u32(),
          R.u32(),
          R.ref(styles()),
          R.ref(style_keys())
        ) :: Kiwi.kiwi_record()
  defrust style_field(record, field, style_type, source, target, styles, keys) do
    with {:some, style} <- referenced_style(ref(record), field, styles, keys),
         {:some, value} <- style.get(source) do
      if style.enum_value(Kiwi.NodeChange.STYLE_TYPE) == some(style_type),
        do: record.put(target, value.clone()),
        else: record
    else
      _ -> record
    end
  end

  # A text style sets the fields it defines, and its decoration even when unset.
  @spec text_style(Kiwi.kiwi_record(), R.ref(styles()), R.ref(style_keys())) :: Kiwi.kiwi_record()
  defrust text_style(record, styles, keys) do
    case referenced_style(ref(record), Kiwi.NodeChange.STYLE_ID_FOR_TEXT, styles, keys) do
      {:some, style} ->
        if style.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.TEXT) and
             style.enum_value(Kiwi.NodeChange.STYLE_TYPE) == some(Kiwi.StyleType.TEXT) do
          with_text_style(record, ref(style))
        else
          record
        end

      :none ->
        record
    end
  end

  @spec with_text_style(Kiwi.kiwi_record(), R.ref(Kiwi.kiwi_record())) :: Kiwi.kiwi_record()
  defrust with_text_style(record, style) do
    text =
      style.take(
        ref([
          Kiwi.NodeChange.FONT_SIZE,
          Kiwi.NodeChange.FONT_NAME,
          Kiwi.NodeChange.LINE_HEIGHT,
          Kiwi.NodeChange.LETTER_SPACING,
          Kiwi.NodeChange.TEXT_CASE
        ])
      )

    merged = record.merge(ref(text))

    case style.get(Kiwi.NodeChange.TEXT_DECORATION) do
      {:some, decoration} -> merged.put(Kiwi.NodeChange.TEXT_DECORATION, decoration.clone())
      :none -> merged.delete(Kiwi.NodeChange.TEXT_DECORATION)
    end
  end

  @spec referenced_style(R.ref(Kiwi.kiwi_record()), R.u32(), R.ref(styles()), R.ref(style_keys())) ::
          R.option(Kiwi.kiwi_record())
  defrust referenced_style(record, field, styles, keys) do
    case record.record(field) do
      :none ->
        nil

      {:some, reference} ->
        case guid_key(reference.record(Kiwi.StyleId.GUID)) do
          {:some, id} ->
            style_by_id(styles, id)

          :none ->
            case reference.record(Kiwi.StyleId.ASSET_REF) do
              {:some, asset} -> asset_style(asset, styles, keys)
              :none -> nil
            end
        end
    end
  end

  @spec asset_style(R.ref(Kiwi.kiwi_record()), R.ref(styles()), R.ref(style_keys())) ::
          R.option(Kiwi.kiwi_record())
  defrust asset_style(asset, styles, keys) do
    case asset.str(Kiwi.AssetRef.KEY) do
      :none ->
        nil

      {:some, key} ->
        case asset.str(Kiwi.AssetRef.VERSION) do
          {:some, version} ->
            case Map.get(keys, "#{key}@#{version}") do
              {:some, id} -> style_by_id(styles, id)
              :none -> unversioned_style(styles, keys, key)
            end

          :none ->
            unversioned_style(styles, keys, key)
        end
    end
  end

  @spec unversioned_style(R.ref(styles()), R.ref(style_keys()), R.str()) ::
          R.option(Kiwi.kiwi_record())
  defrust unversioned_style(styles, keys, key) do
    Map.get(keys, key) |> and_then(fn id -> style_by_id(styles, id) end)
  end

  @spec style_by_id(R.ref(styles()), Records.guid_key()) :: R.option(Kiwi.kiwi_record())
  defrust style_by_id(styles, id) do
    Map.get(styles, id)
  end
end
