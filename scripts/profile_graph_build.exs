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

until =
  System.get_env("FIG_KIWI_PROFILE_UNTIL", "variables")
  |> String.to_existing_atom()

{payload_us, payload} =
  :timer.tc(fn -> fixture |> File.read!() |> FigKiwi.Scene.payload!() end)

profile = FigKiwi.Scene.Graph.profile(payload, root: roots, until: until)

graph = profile.graph

summary = %{
  fixture: fixture,
  roots: roots,
  until: until,
  payload_ms: System.convert_time_unit(payload_us, :microsecond, :millisecond),
  initial_ms: profile.initial_ms,
  total_ms: profile.total_ms,
  final_graph:
    graph
    |> FigKiwi.Scene.Graph.stats()
    |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count]),
  stages: profile.stages
}

IO.puts(Jason.encode!(summary, pretty: true))
