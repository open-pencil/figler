defmodule Mix.Tasks.Figler.Profile.Graph do
  @moduledoc """
  Profiles effective graph construction.

      mix figler.profile.graph --fixture path/to/file.fig --root 3740:112537

  Environment fallbacks:

    * `FIGLER_PROFILE_FIXTURE`
    * `FIGLER_PROFILE_ROOTS` - comma-separated roots
  """

  use Mix.Task

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Profile.FinalGraphStats
  alias Figler.Scene.Graph.Profile.Phase
  alias Figler.Scene.Graph.Profile.Summary

  @shortdoc "Profiles Figler effective graph construction"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [fixture: :string, root: :keep, roots: :string, output: :string],
        aliases: [f: :fixture, r: :root, o: :output]
      )

    fixture = option(opts, :fixture, "FIGLER_PROFILE_FIXTURE") || raise_fixture!()
    roots = roots(opts)

    {payload_us, payload} =
      :timer.tc(fn -> fixture |> File.read!() |> Scene.source!() end)

    profile_opts = if roots == [], do: [], else: [root: roots]
    profile = Graph.profile(payload, profile_opts)

    summary = %Summary{
      fixture: fixture,
      roots: roots,
      payload_ms: ms(payload_us),
      total_ms: profile.total_ms,
      final_graph: final_graph_stats(profile.graph),
      phases: Enum.map(profile.phases, &struct!(Phase, &1))
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
      roots = System.get_env("FIGLER_PROFILE_ROOTS") -> split_roots(roots)
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
    raise "pass --fixture or set FIGLER_PROFILE_FIXTURE"
  end

  defp final_graph_stats(graph) do
    graph
    |> Graph.stats()
    |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count])
    |> FinalGraphStats.from_map!()
  end

  defp ms(us), do: us / 1_000
end
