#!/usr/bin/env elixir

Mix.Task.run("app.start")

fixture =
  System.get_env("FIG_KIWI_PROFILE_FIXTURE") ||
    System.get_env("FIG_KIWI_ORACLE_FIXTURE") ||
    raise "set FIG_KIWI_PROFILE_FIXTURE or FIG_KIWI_ORACLE_FIXTURE"

roots =
  System.get_env("FIG_KIWI_PROFILE_ROOTS") ||
    System.get_env("FIG_KIWI_ORACLE_NODE") ||
    raise "set FIG_KIWI_PROFILE_ROOTS to one or more comma-separated node GUIDs"

roots =
  roots
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)

stages = [
  :populate_instances,
  :symbol_overrides,
  :sync_overrides,
  :component_props,
  :sync_component_props,
  :derived_symbol_data,
  :stack_layout,
  :variables
]

measure = fn label, fun ->
  {us, result} = :timer.tc(fun)
  {label, System.convert_time_unit(us, :microsecond, :millisecond), result}
end

{payload_label, payload_ms, payload} =
  measure.("payload", fn -> fixture |> File.read!() |> FigKiwi.Scene.payload!() end)

stage_results =
  Enum.map(stages, fn stage ->
    {_label, ms, graph} =
      measure.(Atom.to_string(stage), fn ->
        FigKiwi.Scene.graph(payload, root: roots, until: stage)
      end)

    stats =
      graph
      |> FigKiwi.Scene.Graph.stats()
      |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count])

    %{stage: stage, cumulative_ms: ms, graph: stats}
  end)

summary = %{
  fixture: fixture,
  roots: roots,
  payload_ms: payload_ms,
  payload_label: payload_label,
  note: "stage timings are independent cumulative graph builds through each stage",
  stages: stage_results
}

IO.puts(Jason.encode!(summary, pretty: true))
