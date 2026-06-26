Mix.install(
  [
    {:kiwi_codec, path: Path.expand("../../kiwi_codec", __DIR__)},
    {:fig_kiwi, path: Path.expand("..", __DIR__)}
  ],
  consolidate_protocols: false
)

guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)
size = struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0)
node_change = struct(FigKiwi.Schema.NodeChange, guid: guid, type: :rectangle, name: "Rect 1", size: size)
message = struct(FigKiwi.Schema.Message, type: :node_changes, session_id: 12, node_changes: [node_change])

schema = FigKiwi.schema()
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

static_binary = FigKiwi.encode_message(message)
runtime_binary = KiwiCodec.SchemaInterpreter.encode(schema, "Message", runtime_message)

jobs = %{
  "static encode" => fn -> FigKiwi.encode_message(message) end,
  "static decode" => fn -> FigKiwi.decode_message(static_binary) end,
  "native decode" => fn -> FigKiwi.Native.decode_message(static_binary) end,
  "runtime encode" => fn -> KiwiCodec.SchemaInterpreter.encode(schema, "Message", runtime_message) end,
  "runtime decode" => fn -> KiwiCodec.SchemaInterpreter.decode(schema, "Message", runtime_binary) end
}

if Code.ensure_loaded?(Benchee) do
  Benchee.run(jobs)
else
  Enum.each(jobs, fn {name, fun} ->
    {microseconds, _result} = :timer.tc(fn -> for _ <- 1..10_000, do: fun.() end)
    IO.puts("#{name}: #{microseconds / 10_000} µs/op")
  end)
end
