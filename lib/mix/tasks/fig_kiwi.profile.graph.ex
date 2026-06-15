defmodule Mix.Tasks.FigKiwi.Profile.Graph do
  @moduledoc """
  Profiles effective graph construction.

      mix fig_kiwi.profile.graph --fixture path/to/file.fig --root 3740:112537 --until stack_layout

  Environment fallbacks:

    * `FIG_KIWI_PROFILE_FIXTURE`
    * `FIG_KIWI_PROFILE_ROOTS` - comma-separated roots
    * `FIG_KIWI_PROFILE_UNTIL`
  """

  use Mix.Task

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.Profile.FinalGraphStats
  alias FigKiwi.Scene.Graph.Profile.GraphStats
  alias FigKiwi.Scene.Graph.Profile.Stage
  alias FigKiwi.Scene.Graph.Profile.Summary

  @shortdoc "Profiles FigKiwi effective graph construction"

  @stage_atoms %{
    "populate_instances" => :populate_instances,
    "symbol_overrides" => :symbol_overrides,
    "sync_overrides" => :sync_overrides,
    "component_props" => :component_props,
    "sync_component_props" => :sync_component_props,
    "derived_symbol_data" => :derived_symbol_data,
    "stack_layout" => :stack_layout,
    "variables" => :variables
  }

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [fixture: :string, root: :keep, roots: :string, until: :string, output: :string],
        aliases: [f: :fixture, r: :root, u: :until, o: :output]
      )

    fixture = option(opts, :fixture, "FIG_KIWI_PROFILE_FIXTURE") || raise_fixture!()
    roots = roots(opts)
    until_stage = option(opts, :until, "FIG_KIWI_PROFILE_UNTIL") || "stack_layout"

    {payload_us, payload} =
      :timer.tc(fn -> fixture |> File.read!() |> Scene.payload!() end)

    profile_opts = [root: roots, until: stage_atom(until_stage)]
    profile = Graph.profile(payload, profile_opts)

    summary = %Summary{
      fixture: fixture,
      roots: roots,
      until: until_stage,
      payload_ms: ms(payload_us),
      initial_ms: profile.initial_ms,
      total_ms: profile.total_ms,
      final_graph: final_graph_stats(profile.graph),
      stages: Enum.map(profile.stages, &stage_summary/1)
    }

    json = summary |> JSONCodec.dump() |> Jason.encode!(pretty: true)

    case option(opts, :output, nil) do
      nil -> IO.puts(json)
      path -> File.write!(path, json <> "\n")
    end
  end

  defp option(opts, key, nil), do: Keyword.get(opts, key)
  defp option(opts, key, env), do: Keyword.get(opts, key) || System.get_env(env)

  defp roots(opts) do
    explicit_roots = Keyword.get_values(opts, :root)

    cond do
      explicit_roots != [] -> explicit_roots
      roots = Keyword.get(opts, :roots) -> split_roots(roots)
      roots = System.get_env("FIG_KIWI_PROFILE_ROOTS") -> split_roots(roots)
      true -> []
    end
  end

  defp split_roots(roots) do
    roots
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp raise_fixture! do
    raise "pass --fixture or set FIG_KIWI_PROFILE_FIXTURE"
  end

  defp final_graph_stats(graph) do
    graph
    |> Graph.stats()
    |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count])
    |> FinalGraphStats.from_map!()
  end

  defp stage_summary(stage) do
    %Stage{
      stage: stage.stage,
      ms: stage.ms,
      graph: GraphStats.from_map!(stage.graph)
    }
  end

  defp stage_atom(stage) do
    stage = String.trim(stage)
    Map.get(@stage_atoms, stage) || raise ArgumentError, "unknown graph stage #{inspect(stage)}"
  end

  defp ms(us), do: System.convert_time_unit(us, :microsecond, :millisecond)
end
