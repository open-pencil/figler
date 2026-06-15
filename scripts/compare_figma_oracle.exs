#!/usr/bin/env elixir

Mix.Task.run("app.start")

fixture =
  System.get_env("FIG_KIWI_ORACLE_FIXTURE") ||
    raise "set FIG_KIWI_ORACLE_FIXTURE to a .fig fixture path"

node_guid =
  System.get_env("FIG_KIWI_ORACLE_NODE") ||
    raise "set FIG_KIWI_ORACLE_NODE to the Figma node GUID/id to compare"

oracle_json =
  System.get_env("FIG_KIWI_ORACLE_JSON") ||
    raise "set FIG_KIWI_ORACLE_JSON to browser oracle JSON output"

depth =
  System.get_env("FIG_KIWI_ORACLE_DEPTH", "2")
  |> String.to_integer()

epsilon =
  System.get_env("FIG_KIWI_ORACLE_EPSILON", "0.0001")
  |> String.to_float()

ignore_null_size? = System.get_env("FIG_KIWI_ORACLE_IGNORE_NULL_SIZE", "1") != "0"

entry = %FigKiwi.Scene.Graph.Oracle.Entry{
  node: node_guid,
  json: oracle_json,
  depth: depth,
  epsilon: epsilon,
  ignore_null_size: ignore_null_size?
}

fixture_payload = fixture |> File.read!() |> FigKiwi.Scene.payload!()
result = FigKiwi.Scene.Graph.Oracle.run(fixture_payload, File.cwd!(), entry)

summary = %{
  node: result.node,
  depth: result.depth,
  graph_build_ms: result.graph_build_ms,
  graph: result.graph,
  diff_count: result.diff_count
}

IO.puts(Jason.encode!(summary, pretty: true))

if result.diffs == [] do
  IO.puts("Figma oracle comparison passed")
else
  IO.puts("Figma oracle comparison failed")

  result.diffs
  |> JSONCodec.dump()
  |> Jason.encode!(pretty: true)
  |> IO.puts()

  System.halt(1)
end
