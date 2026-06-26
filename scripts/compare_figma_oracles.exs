#!/usr/bin/env elixir

Mix.Task.run("app.start")

fixture =
  System.get_env("FIGLER_ORACLE_FIXTURE") ||
    raise "set FIGLER_ORACLE_FIXTURE to an exported .fig fixture path"

manifest_path =
  System.get_env("FIGLER_ORACLE_MANIFEST") ||
    List.first(System.argv()) ||
    raise "set FIGLER_ORACLE_MANIFEST or pass a manifest JSON path"

base_dir = Path.dirname(Path.expand(manifest_path))
entries = Figler.Scene.Graph.Oracle.entries!(manifest_path)
fixture_payload = fixture |> File.read!() |> Figler.Scene.payload!()
shared_graph? = System.get_env("FIGLER_ORACLE_SHARED_GRAPH") in ["1", "true", "TRUE"]

{build_us, compare_us, results} =
  if shared_graph? do
    node_guids = Enum.map(entries, & &1.node)

    {build_us, graph} =
      :timer.tc(fn ->
        Figler.Scene.graph(fixture_payload, root: node_guids, until: :stack_layout)
      end)

    {compare_us, results} =
      :timer.tc(fn -> Enum.map(entries, &Figler.Scene.Graph.Oracle.run(graph, base_dir, &1)) end)

    {build_us, compare_us, results}
  else
    {total_us, results} =
      :timer.tc(fn ->
        Enum.map(entries, &Figler.Scene.Graph.Oracle.run(fixture_payload, base_dir, &1))
      end)

    build_us =
      results
      |> Enum.map(&Map.get(&1, :graph_build_ms, 0))
      |> Enum.sum()
      |> System.convert_time_unit(:millisecond, :microsecond)

    compare_us = max(total_us - build_us, 0)
    {build_us, compare_us, results}
  end

summary = %{
  fixture: fixture,
  comparison_count: length(results),
  shared_graph: shared_graph?,
  graph_build_ms: System.convert_time_unit(build_us, :microsecond, :millisecond),
  compare_ms: System.convert_time_unit(compare_us, :microsecond, :millisecond),
  failed_count: Enum.count(results, &(&1.diff_count > 0)),
  results: Enum.map(results, &Map.delete(&1, :diffs))
}

IO.puts(Jason.encode!(summary, pretty: true))

failures = Enum.filter(results, &(&1.diff_count > 0))

if failures == [] do
  IO.puts("Figma oracle comparisons passed")
else
  IO.puts("Figma oracle comparisons failed")

  failures
  |> Enum.map(&Map.take(&1, [:node, :depth, :oracle_json, :diff_count, :diffs]))
  |> JSONCodec.dump()
  |> Jason.encode!(pretty: true)
  |> IO.puts()

  System.halt(1)
end
