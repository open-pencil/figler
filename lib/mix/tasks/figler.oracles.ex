defmodule Mix.Tasks.Figler.Oracles do
  @moduledoc """
  Runs committed or external graph oracle manifests.

      mix figler.oracles
      mix figler.oracles --dir /path/to/external/oracles

  Each oracle fixture directory must contain one `.fig` file, a `manifest.json`,
  and JSON captures referenced by that manifest. Large real `.fig` files should
  stay outside this repository and be passed with `--dir` or
  `FIGLER_EXTERNAL_ORACLE_DIR`.
  """

  use Mix.Task

  alias Figler.Scene
  alias Figler.Scene.Graph.Oracle

  @shortdoc "Runs Figler graph oracle manifests"
  @default_dir "test/fixtures/oracles"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [dir: :keep, committed: :boolean],
        aliases: [d: :dir]
      )

    if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")

    dirs = oracle_dirs(opts)
    results = Enum.flat_map(dirs, &run_dir/1)
    failed = Enum.filter(results, &(&1.failed_count > 0))

    summary = %{
      directory_count: length(dirs),
      manifest_count: length(results),
      failed_count: length(failed),
      results: results
    }

    IO.puts(Jason.encode!(summary, pretty: true))

    if failed != [] do
      Mix.raise("#{length(failed)} oracle manifest(s) failed")
    end
  end

  defp oracle_dirs(opts) do
    cli_dirs = Keyword.get_values(opts, :dir)
    env_dir = System.get_env("FIGLER_EXTERNAL_ORACLE_DIR")

    cond do
      cli_dirs != [] -> cli_dirs
      is_binary(env_dir) and env_dir != "" -> [env_dir]
      Keyword.get(opts, :committed, true) -> [@default_dir]
      true -> []
    end
  end

  defp run_dir(dir) do
    manifests = Path.wildcard(Path.join(dir, "**/manifest.json"))

    if manifests == [] do
      Mix.raise("no oracle manifests found under #{dir}")
    end

    Enum.map(manifests, &run_manifest/1)
  end

  defp run_manifest(manifest) do
    base_dir = Path.dirname(manifest)
    fixture = fixture_for!(base_dir)
    payload = fixture |> File.read!() |> Scene.payload!()

    results = Enum.map(Oracle.entries!(manifest), &Oracle.run(payload, base_dir, &1))

    %{
      manifest: manifest,
      fixture: fixture,
      comparison_count: length(results),
      failed_count: Enum.count(results, &(&1.diff_count > 0)),
      results: Enum.map(results, &Map.delete(&1, :diffs))
    }
  end

  defp fixture_for!(base_dir) do
    case Path.wildcard(Path.join(base_dir, "*.fig")) do
      [fixture] -> fixture
      [] -> Mix.raise("no .fig fixture found next to #{Path.join(base_dir, "manifest.json")}")
      fixtures -> Mix.raise("multiple .fig fixtures found in #{base_dir}: #{inspect(fixtures)}")
    end
  end
end
