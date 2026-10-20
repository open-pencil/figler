defmodule Mix.Tasks.Figler.Openpencil do
  @moduledoc """
  Compares effective graphs against OpenPencil's occurrence interpreter.

      mix figler.openpencil file.fig [file.fig ...]
      mix figler.openpencil file.fig --page 0:1 --show 40
      mix figler.openpencil file.fig --openpencil ../open-pencil-app --json
      mix figler.openpencil file.fig --scene

  Runs `scripts/openpencil_oracle.ts` with `bun` against an OpenPencil checkout
  (`--openpencil`, `FIGLER_OPENPENCIL_DIR`, or `../open-pencil-app`) that has its
  dependencies installed, then diffs each page's interpreted tree against
  `Figler.Scene.graph/2`. Prints diff counts by field and the first `--show`
  differences (default 20), or the full result with `--json`.

  `--scene` compares resolved values (paints, text, layout) against OpenPencil's
  materialized scene graph instead of its interpreted occurrence trees.
  """

  use Mix.Task

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.OpenPencilOracle

  @shortdoc "Diffs Figler graphs against OpenPencil's reader"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, files, invalid} =
      OptionParser.parse(args,
        strict: [
          openpencil: :string,
          page: :keep,
          show: :integer,
          json: :boolean,
          scene: :boolean
        ]
      )

    if invalid != [] or files == [] do
      Mix.raise("usage: mix figler.openpencil FILE.fig [--page ID] [--show N] [--json]")
    end

    oracle_opts =
      [pages: Keyword.get_values(opts, :page), scene: Keyword.get(opts, :scene, false)]
      |> put_present(:openpencil, opts[:openpencil])

    results = Enum.map(files, &compare(&1, oracle_opts))

    if opts[:json] do
      IO.puts(Jason.encode!(results, pretty: true))
    else
      Enum.each(results, &print(&1, Keyword.get(opts, :show, 20)))
    end
  end

  defp compare(file, oracle_opts) do
    expected = OpenPencilOracle.expected!(file, oracle_opts)
    # Interpreted trees precede variable resolution, which only the scene resolves.
    graph_opts = if oracle_opts[:scene], do: [], else: [resolve_variables: false]
    graph = file |> File.read!() |> Figler.Scene.graph(graph_opts)

    result =
      if oracle_opts[:scene],
        do: OpenPencilOracle.compare_scene(graph, expected),
        else: OpenPencilOracle.compare(graph, expected)

    %{
      file: file,
      diff_count: length(result.diffs),
      by_field: result.by_field,
      figler_unresolved: length(Graph.unresolved(graph)),
      openpencil_diagnostics: expected["diagnostics"],
      diffs: result.diffs
    }
  end

  defp print(result, show) do
    Mix.shell().info(
      "#{result.file}: #{result.diff_count} differences " <>
        "(Figler unresolved: #{result.figler_unresolved}, " <>
        "OpenPencil diagnostics: #{length(result.openpencil_diagnostics)})"
    )

    result.by_field
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.each(fn {field, count} -> Mix.shell().info("  #{field}: #{count}") end)

    result.diffs
    |> Enum.take(show)
    |> Enum.each(fn diff ->
      Mix.shell().info(
        "  #{diff.path} #{diff.field}: openpencil=#{inspect(diff.openpencil, charlists: :as_lists)} " <>
          "figler=#{inspect(diff.figler, charlists: :as_lists)}"
      )
    end)
  end

  defp put_present(opts, _key, nil), do: opts
  defp put_present(opts, key, value), do: Keyword.put(opts, key, value)
end
