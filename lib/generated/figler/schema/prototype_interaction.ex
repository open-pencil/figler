defmodule Figler.Schema.PrototypeInteraction do
  @moduledoc "Generated Kiwi message module for `PrototypeInteraction`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:event, 2, type: Figler.Schema.PrototypeEvent, source_name: "event")
  field(:actions, 3, repeated: true, type: Figler.Schema.PrototypeAction, source_name: "actions")
  field(:is_deleted, 4, type: :bool, source_name: "isDeleted")
  field(:state_management_version, 5, type: :int, source_name: "stateManagementVersion")
end
