defmodule Mix.Tasks.FigKiwi.Bench.Fixtures do
  @moduledoc """
  Benchmarks projected scene operations against external `.fig` fixtures.

  Set `FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR` to a directory containing `.fig` files:

      FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
        mix fig_kiwi.bench.fixtures

  By default, all `*.fig` files in the directory are benchmarked. Pass file names
  to restrict the run:

      mix fig_kiwi.bench.fixtures gold-preview.fig material3.fig
  """

  use Mix.Task

  @shortdoc "Benchmarks projected scene operations against .fig fixtures"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    fixture_dir =
      System.get_env("FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR") ||
        Mix.raise("set FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR to a directory containing .fig files")

    fixtures = fixtures!(fixture_dir, args)

    Mix.shell().info("Fixture\tSize\tPayload\tSummary\tCanvas XPath\tNodes\tCanvases")

    Enum.each(fixtures, fn path ->
      {read_us, fig_binary} = timed(fn -> File.read!(path) end)
      {payload_us, payload} = timed(fn -> FigKiwi.Scene.payload!(fig_binary) end)
      {summary_us, summary} = timed(fn -> FigKiwi.Native.decode_scene_summary(payload) end)

      {query_us, canvases} =
        timed(fn -> FigKiwi.Native.query_scene_xpath(payload, "//canvas") end)

      Mix.shell().info(
        Enum.join(
          [
            Path.basename(path),
            format_bytes(byte_size(fig_binary)),
            format_us(read_us + payload_us),
            format_us(summary_us),
            format_us(query_us),
            summary.node_count,
            length(canvases)
          ],
          "\t"
        )
      )
    end)
  end

  defp fixtures!(fixture_dir, []) do
    fixture_dir
    |> Path.join("*.fig")
    |> Path.wildcard()
    |> Enum.sort()
    |> case do
      [] -> Mix.raise("no .fig files found in #{fixture_dir}")
      fixtures -> fixtures
    end
  end

  defp fixtures!(fixture_dir, files) do
    Enum.map(files, fn file ->
      path = Path.expand(file, fixture_dir)

      if File.regular?(path) do
        path
      else
        Mix.raise("fixture not found: #{path}")
      end
    end)
  end

  defp timed(fun) do
    :timer.tc(fun)
  end

  defp format_us(us) when us >= 1_000_000,
    do: :io_lib.format("~.3fs", [us / 1_000_000]) |> IO.iodata_to_binary()

  defp format_us(us) when us >= 1_000,
    do: :io_lib.format("~.3fms", [us / 1_000]) |> IO.iodata_to_binary()

  defp format_us(us), do: "#{us}µs"

  defp format_bytes(bytes) when bytes >= 1_048_576,
    do: :io_lib.format("~.1f MiB", [bytes / 1_048_576]) |> IO.iodata_to_binary()

  defp format_bytes(bytes) when bytes >= 1024,
    do: :io_lib.format("~.1f KiB", [bytes / 1024]) |> IO.iodata_to_binary()

  defp format_bytes(bytes), do: "#{bytes} B"
end
