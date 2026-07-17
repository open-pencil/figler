Mix.install(
  [
    {:benchee, "~> 1.4"},
    {:kiwi_codec, path: Path.expand("../../kiwi_codec", __DIR__)},
    {:figler, path: Path.expand("..", __DIR__)}
  ],
  consolidate_protocols: false
)

alias Figler.Native.{CodecNifs, SceneNifs}
alias Figler.Scene.Graph

guid = struct(Figler.Schema.GUID, session_id: 12, local_id: 34)
size = struct(Figler.Schema.Vector, x: 100.0, y: 50.0)

node_change =
  struct(Figler.Schema.NodeChange,
    guid: guid,
    type: :rectangle,
    name: "Rect 1",
    size: size
  )

message =
  struct(Figler.Schema.Message,
    type: :node_changes,
    session_id: 12,
    node_changes: [node_change]
  )

schema = Figler.schema()

runtime_message = %{
  "type" => "NODE_CHANGES",
  "sessionID" => 12,
  "nodeChanges" => [
    %{
      "guid" => %{"sessionID" => 12, "localID" => 34},
      "type" => "RECTANGLE",
      "name" => "Rect 1",
      "size" => %{"x" => 100.0, "y" => 50.0}
    }
  ]
}

static_binary = Figler.encode_message(message)
runtime_binary = KiwiCodec.SchemaInterpreter.encode(schema, "Message", runtime_message)

Benchee.run(
  %{
    "static encode" => fn -> Figler.encode_message(message) end,
    "static decode" => fn -> Figler.decode_message(static_binary) end,
    "native sparse decode" => fn -> CodecNifs.decode_sparse_message(static_binary) end,
    "native graph seed projection" => fn ->
      CodecNifs.decode_graph_seed_records(static_binary)
    end,
    "native scene index" => fn -> SceneNifs.build_index(static_binary) end,
    "graph materialization" => fn -> Graph.build(static_binary) end,
    "prepared runtime encode" => fn -> Figler.encode_message_runtime(runtime_message) end,
    "prepared runtime decode" => fn -> Figler.decode_message_runtime(runtime_binary) end,
    "unprepared runtime encode" => fn ->
      KiwiCodec.SchemaInterpreter.encode(schema, "Message", runtime_message)
    end,
    "unprepared runtime decode" => fn ->
      KiwiCodec.SchemaInterpreter.decode(schema, "Message", runtime_binary)
    end
  },
  warmup: 1,
  time: 3,
  memory_time: 1
)
