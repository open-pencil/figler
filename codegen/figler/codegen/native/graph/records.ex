defmodule Figler.Codegen.Native.Graph.Records do
  @moduledoc """
  Reading GUIDs and tree placement from native Kiwi records, for the native interpreter.
  """

  use RustQ.Meta

  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @type guid_key :: {R.u32(), R.u32()}

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  @spec guid_key(R.option(R.ref(Kiwi.kiwi_record()))) :: R.option(guid_key())
  defrust guid_key(guid) do
    with {:some, guid} <- guid,
         {:some, session} <- guid.uint(Kiwi.Guid.SESSION_ID),
         {:some, local} <- guid.uint(Kiwi.Guid.LOCAL_ID) do
      some({session, local})
    else
      _ -> nil
    end
  end

  @spec record_id(R.ref(Kiwi.kiwi_record())) :: R.option(guid_key())
  defrust record_id(record), do: guid_key(record.record(Kiwi.NodeChange.GUID))

  @spec parent_id(R.ref(Kiwi.kiwi_record())) :: R.option(guid_key())
  defrust parent_id(record) do
    case record.record(Kiwi.NodeChange.PARENT_INDEX) do
      {:some, parent} -> guid_key(parent.record(Kiwi.ParentIndex.GUID))
      :none -> nil
    end
  end

  # Saved sibling order: the fractional position string, compared as text.
  @spec position(R.ref(Kiwi.kiwi_record())) :: R.str()
  defrust position(record) do
    case record.record(Kiwi.NodeChange.PARENT_INDEX) do
      {:some, parent} -> parent.str(Kiwi.ParentIndex.POSITION).unwrap_or("")
      :none -> ""
    end
  end
end
