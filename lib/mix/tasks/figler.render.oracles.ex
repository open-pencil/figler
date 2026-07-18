defmodule Mix.Tasks.Figler.Render.Oracles do
  @moduledoc """
  Runs same-scene OpenPencil/Figler visual oracle manifests.

      mix figler.render.oracles --manifest /path/to/render-manifest.json
      mix figler.render.oracles --dir /path/to/external/render-oracles

  Directories are searched recursively for `render-manifest.json`. If neither
  option is supplied, the task uses `FIGLER_RENDER_ORACLE_DIR`, then
  `test/fixtures/render_oracles` when that committed directory exists.

  Each manifest names one `.fig` fixture and one or more reference PNG cases.
  Every case controls page or root selection, scale, background, and pixel-diff
  thresholds, ensuring both renderers compare the same scene.
  """

  use Mix.Task

  alias Figler.Render.Oracle.Runner

  @shortdoc "Runs same-scene visual rendering oracles"
  @default_dir "test/fixtures/render_oracles"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [manifest: :keep, dir: :keep],
        aliases: [m: :manifest, d: :dir]
      )

    if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")

    manifests = manifests(opts)
    if manifests == [], do: Mix.raise("no render oracle manifests found")

    results = Enum.map(manifests, &run_manifest!/1)
    failed_count = Enum.count(results, &(not &1.passed?))

    IO.puts(
      Jason.encode!(
        %{manifest_count: length(results), failed_count: failed_count, results: results},
        pretty: true
      )
    )

    if failed_count > 0, do: Mix.raise("#{failed_count} render oracle manifest(s) failed")
  end

  defp manifests(opts) do
    explicit = Keyword.get_values(opts, :manifest)

    if explicit == [] do
      opts
      |> oracle_dirs()
      |> Enum.flat_map(&Path.wildcard(Path.join(&1, "**/render-manifest.json")))
      |> Enum.uniq()
      |> Enum.sort()
    else
      Enum.map(explicit, &Path.expand/1)
    end
  end

  defp oracle_dirs(opts) do
    cli_dirs = Keyword.get_values(opts, :dir)
    env_dir = System.get_env("FIGLER_RENDER_ORACLE_DIR")

    cond do
      cli_dirs != [] -> cli_dirs
      is_binary(env_dir) and env_dir != "" -> [env_dir]
      File.dir?(@default_dir) -> [@default_dir]
      true -> []
    end
  end

  defp run_manifest!(manifest) do
    case Runner.run(manifest) do
      {:ok, result} -> result
      {:error, reason} -> Mix.raise("render oracle #{manifest} failed: #{inspect(reason)}")
    end
  end
end
