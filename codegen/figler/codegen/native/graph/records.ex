defmodule Figler.Codegen.Native.Graph.Records do
  @moduledoc """
  Reading GUIDs and tree placement from native Kiwi records, for the native interpreter.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ]

  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod Guid, as: [:kiwi_records, :guid]
  defrustmod ParentIndex, as: [:kiwi_records, :parent_index]

  @type guid_key :: {R.u32(), R.u32()}

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :guid_key,
        :record_id,
        :parent_id,
        :position,
        :enum_is,
        :has_guid
      ])
  end

  @spec guid_key(R.option(R.ref(R.path(:KiwiRecord)))) :: R.option(guid_key())
  defrust guid_key(guid) do
    with {:some, guid} <- guid,
         {:some, session} <- guid.uint(Guid.SESSION_ID),
         {:some, local} <- guid.uint(Guid.LOCAL_ID) do
      some({session, local})
    else
      _ -> nil
    end
  end

  @spec record_id(R.ref(R.path(:KiwiRecord))) :: R.option(guid_key())
  defrust record_id(record), do: guid_key(record.record(NodeChange.GUID))

  @spec parent_id(R.ref(R.path(:KiwiRecord))) :: R.option(guid_key())
  defrust parent_id(record) do
    case record.record(NodeChange.PARENT_INDEX) do
      {:some, parent} -> guid_key(parent.record(ParentIndex.GUID))
      :none -> nil
    end
  end

  # Saved sibling order: the fractional position string, compared as text.
  @spec position(R.ref(R.path(:KiwiRecord))) :: R.str()
  defrust position(record) do
    case record.record(NodeChange.PARENT_INDEX) do
      {:some, parent} -> parent.str(ParentIndex.POSITION).unwrap_or("")
      :none -> ""
    end
  end

  @spec enum_is(R.ref(KiwiRecord.t()), R.u32(), R.u32()) :: R.bool()
  defrust enum_is(record, field, value), do: record.enum_value(field) == some(value)

  @spec has_guid(R.ref(KiwiRecord.t()), R.u32(), guid_key()) :: R.bool()
  defrust has_guid(record, field, id), do: guid_key(record.record(field)) == some(id)
end
