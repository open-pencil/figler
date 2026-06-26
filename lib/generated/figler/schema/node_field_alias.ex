defmodule Figler.Schema.NodeFieldAlias do
  @moduledoc "Generated Kiwi message module for `NodeFieldAlias`."
  use KiwiCodec, kind: :message
  field(:stable_path_to_node, 1, type: Figler.Schema.GUIDPath, source_name: "stablePathToNode")
  field(:node_field, 2, type: {:enum, Figler.Schema.NodeFieldAliasType}, source_name: "nodeField")
  field(:index_or_key, 3, type: :string, source_name: "indexOrKey")
end
