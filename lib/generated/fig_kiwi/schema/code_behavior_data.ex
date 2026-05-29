defmodule FigKiwi.Schema.CodeBehaviorData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:icon, 2, type: :string, source_name: "icon")
  field(:node_types, 3, repeated: true, type: :string, source_name: "nodeTypes")
  field(:category, 4, type: :string, source_name: "category")
  field(:api_version, 5, type: :uint, source_name: "apiVersion")
end
