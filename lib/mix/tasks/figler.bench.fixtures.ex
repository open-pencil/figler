defmodule Mix.Tasks.Figler.Bench.Fixtures do
  @moduledoc """
  Benchmarks projected scene operations against external `.fig` fixtures.

  Set `FIGLER_OPEN_PENCIL_FIXTURE_DIR` to a directory containing `.fig` files:

      FIGLER_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
        mix figler.bench.fixtures

  By default, all `*.fig` files in the directory are benchmarked. Pass file names
  to restrict the run:

      mix figler.bench.fixtures gold-preview.fig material3.fig

  Full, sparse, and graph decode timings can be controlled for large fixtures:

      FIGLER_BENCH_FULL_DECODE=0 mix figler.bench.fixtures nuxtui.fig
      FIGLER_BENCH_SPARSE_DECODE=0 mix figler.bench.fixtures nuxtui.fig
      FIGLER_BENCH_GRAPH=1 mix figler.bench.fixtures gold-preview.fig

  Each measured operation is warmed up twice and sampled seven times by default.
  Override those counts with `FIGLER_BENCH_WARMUP` and `FIGLER_BENCH_SAMPLES`.
  Timing columns report p50/p95. Memory columns report the median change in BEAM
  process memory and intentionally do not claim to include native resource memory.
  """

  use Mix.Task

  alias Figler.Native.CodecNifs, as: Codec
  alias Figler.Native.SceneNifs, as: Scene
  alias Figler.Scene.Graph

  @shortdoc "Benchmarks projected scene operations against .fig fixtures"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    fixture_dir =
      System.get_env("FIGLER_OPEN_PENCIL_FIXTURE_DIR") ||
        Mix.raise("set FIGLER_OPEN_PENCIL_FIXTURE_DIR to a directory containing .fig files")

    fixtures = fixtures!(fixture_dir, args)
    full_decode? = env_enabled?("FIGLER_BENCH_FULL_DECODE", default: true)
    sparse_decode? = env_enabled?("FIGLER_BENCH_SPARSE_DECODE", default: true)
    graph? = env_enabled?("FIGLER_BENCH_GRAPH", default: false)

    bench_opts = [
      warmup: env_count!("FIGLER_BENCH_WARMUP", 2, 0),
      samples: env_count!("FIGLER_BENCH_SAMPLES", 7, 1)
    ]

    Mix.shell().info(
      "Fixture\tSize\tPayload\tFull Decode p50/p95\tFull BEAM Δ\tSparse Decode p50/p95\tSparse BEAM Δ\tGraph p50/p95\tGraph BEAM Δ\tGraph Nodes\tGraph Clones\tGraph Unresolved\tGraph Applied\tSummary p50/p95\tIndex p50/p95\tCanvas XPath p50/p95\tIndexed //canvas p50/p95\tIndexed fields //canvas p50/p95\tIndexed //* p50/p95\tIndexed fields //* p50/p95\tBy type text p50/p95\tText contains p50/p95\tNode lookup p50/p95\tNodes\tCanvases"
    )

    Enum.each(fixtures, fn path ->
      {read_us, fig_binary} = timed(fn -> File.read!(path) end)
      {payload_us, payload} = timed(fn -> Figler.Scene.source!(fig_binary) end)

      full_decode =
        maybe_benchmark(
          full_decode?,
          fn -> Figler.decode_message(payload) end,
          &message_info/1,
          bench_opts
        )

      sparse_decode =
        maybe_benchmark(
          sparse_decode?,
          fn -> Codec.decode_sparse_message(payload) end,
          &sparse_message_info/1,
          bench_opts
        )

      graph =
        maybe_benchmark(
          graph?,
          fn -> Figler.Scene.graph(fig_binary) end,
          &graph_info/1,
          bench_opts
        )

      summary = benchmark(fn -> Scene.decode_summary(payload) end, &summary_info/1, bench_opts)
      summary_value = Scene.decode_summary(payload)
      index_stats = benchmark(fn -> Scene.build_index(payload) end, &empty_info/1, bench_opts)
      index = Scene.build_index(payload)

      query =
        benchmark(fn -> Scene.query_xpath(payload, "//canvas") end, &list_info/1, bench_opts)

      canvases = Scene.query_xpath(payload, "//canvas")

      indexed_query =
        benchmark(fn -> Scene.query_index(index, "//canvas") end, &list_info/1, bench_opts)

      indexed_canvases = Scene.query_index(index, "//canvas")

      indexed_fields_query =
        benchmark(
          fn -> Scene.query_index_fields(index, "//canvas", ["name"]) end,
          &list_info/1,
          bench_opts
        )

      indexed_fields_canvases = Scene.query_index_fields(index, "//canvas", ["name"])

      unless length(canvases) == length(indexed_canvases) do
        Mix.raise("indexed query mismatch for #{path}")
      end

      unless length(canvases) == length(indexed_fields_canvases) do
        Mix.raise("indexed fields query mismatch for #{path}")
      end

      indexed_all_query =
        benchmark(fn -> Scene.query_index(index, "//*") end, &list_info/1, bench_opts)

      all_nodes = Scene.query_index(index, "//*")

      indexed_all_fields_query =
        benchmark(
          fn -> Scene.query_index_fields(index, "//*", ["name"]) end,
          &list_info/1,
          bench_opts
        )

      all_field_nodes = Scene.query_index_fields(index, "//*", ["name"])

      unless length(all_nodes) == length(all_field_nodes) do
        Mix.raise("indexed all fields query mismatch for #{path}")
      end

      by_type_text =
        benchmark(fn -> Scene.index_by_type(index, "text") end, &list_info/1, bench_opts)

      text_nodes = Scene.index_by_type(index, "text")

      text_contains =
        benchmark(
          fn -> Scene.index_text_contains(index, "Label") end,
          &list_info/1,
          bench_opts
        )

      label_nodes = Scene.index_text_contains(index, "Label")
      sample_guid = canvases |> List.first() |> Map.fetch!(:guid)

      node_lookup =
        benchmark(fn -> Scene.index_node(index, sample_guid) end, &empty_info/1, bench_opts)

      if length(label_nodes) > length(text_nodes) do
        Mix.raise("text helper mismatch for #{path}")
      end

      Mix.shell().info(
        Enum.join(
          [
            Path.basename(path),
            format_bytes(byte_size(fig_binary)),
            format_us(read_us + payload_us),
            format_optional_timing(full_decode),
            format_optional_memory(full_decode),
            format_optional_timing(sparse_decode),
            format_optional_memory(sparse_decode),
            format_optional_timing(graph),
            format_optional_memory(graph),
            optional_stat(graph, :node_count),
            optional_stat(graph, :clone_count),
            optional_stat(graph, :unresolved_count),
            optional_stat(graph, :applied_count),
            format_timing(summary),
            format_timing(index_stats),
            format_timing(query),
            format_timing(indexed_query),
            format_timing(indexed_fields_query),
            format_timing(indexed_all_query),
            format_timing(indexed_all_fields_query),
            format_timing(by_type_text),
            format_timing(text_contains),
            format_timing(node_lookup),
            summary_value.node_count,
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

  defp timed(fun), do: :timer.tc(fun)

  defp maybe_benchmark(false, _fun, _info_fun, _opts), do: :skip
  defp maybe_benchmark(true, fun, info_fun, opts), do: benchmark(fun, info_fun, opts)

  defp benchmark(fun, info_fun, opts) do
    warmup(fun, Keyword.fetch!(opts, :warmup))

    samples =
      for _index <- 1..Keyword.fetch!(opts, :samples) do
        measured(fun, info_fun)
      end

    by_time = Enum.sort_by(samples, & &1.elapsed_us)
    by_memory = Enum.sort_by(samples, & &1.memory_bytes)
    median = percentile(by_time, 0.50)

    %{
      p50_us: median.elapsed_us,
      p95_us: percentile(by_time, 0.95).elapsed_us,
      memory_bytes: percentile(by_memory, 0.50).memory_bytes,
      info: median.info
    }
  end

  defp warmup(_fun, 0), do: :ok

  defp warmup(fun, count) do
    _result = fun.()
    warmup(fun, count - 1)
  end

  defp measured(fun, info_fun) do
    parent = self()
    ref = make_ref()

    {pid, monitor_ref} =
      spawn_monitor(fn ->
        :erlang.garbage_collect()
        before_memory = process_memory(self())
        start = System.monotonic_time()
        result = fun.()

        elapsed_us =
          System.convert_time_unit(System.monotonic_time() - start, :native, :microsecond)

        after_memory = process_memory(self())
        info = info_fun.(result)

        send(parent, {
          ref,
          %{
            elapsed_us: elapsed_us,
            memory_bytes: max(after_memory - before_memory, 0),
            info: info
          }
        })
      end)

    receive do
      {^ref, sample} ->
        Process.demonitor(monitor_ref, [:flush])
        sample

      {:DOWN, ^monitor_ref, :process, ^pid, reason} ->
        Mix.raise("benchmark process failed: #{inspect(reason)}")
    end
  end

  defp percentile(samples, percentile) do
    index = ceil(length(samples) * percentile) - 1
    Enum.at(samples, max(index, 0))
  end

  defp process_memory(pid) do
    {:memory, bytes} = Process.info(pid, :memory)
    bytes
  end

  defp message_info(%{node_changes: node_changes}) when is_list(node_changes),
    do: %{node_changes: length(node_changes)}

  defp message_info(_message), do: %{}

  defp sparse_message_info(%{node_changes: node_changes}) when is_list(node_changes),
    do: %{node_changes: length(node_changes)}

  defp sparse_message_info(_message), do: %{}
  defp graph_info(graph), do: Graph.stats(graph)
  defp summary_info(summary), do: %{node_count: summary.node_count}
  defp list_info(values), do: %{count: length(values)}
  defp empty_info(_value), do: %{}

  defp env_enabled?(name, opts) do
    default = Keyword.fetch!(opts, :default)

    case System.get_env(name) do
      nil -> default
      value when value in ["", "0", "false", "FALSE", "no", "NO", "off", "OFF"] -> false
      _value -> true
    end
  end

  defp env_count!(name, default, minimum) do
    case System.get_env(name) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {count, ""} when count >= minimum -> count
          _other -> Mix.raise("#{name} must be an integer >= #{minimum}")
        end
    end
  end

  defp format_optional_timing(:skip), do: "skip"
  defp format_optional_timing(stats), do: format_timing(stats)
  defp format_optional_memory(:skip), do: "skip"
  defp format_optional_memory(stats), do: format_bytes(stats.memory_bytes)
  defp optional_stat(:skip, _key), do: "skip"
  defp optional_stat(stats, key), do: Map.fetch!(stats.info, key)

  defp format_timing(stats), do: "#{format_us(stats.p50_us)}/#{format_us(stats.p95_us)}"

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
