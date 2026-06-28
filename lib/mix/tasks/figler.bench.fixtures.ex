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

    Mix.shell().info(
      "Fixture\tSize\tPayload\tFull Decode\tFull Mem\tSparse Decode\tSparse Mem\tGraph\tGraph Mem\tGraph Nodes\tGraph Clones\tGraph Unresolved\tGraph Applied\tSummary\tIndex\tCanvas XPath\tIndexed //canvas\tIndexed fields //canvas\tIndexed //*\tIndexed fields //*\tBy type text\tText contains\tNode lookup\tNodes\tCanvases"
    )

    Enum.each(fixtures, fn path ->
      {read_us, fig_binary} = timed(fn -> File.read!(path) end)
      {payload_us, payload} = timed(fn -> Figler.Scene.payload!(fig_binary) end)

      {full_decode_us, full_decode_mem} =
        maybe_measured(
          full_decode?,
          fn -> Codec.decode_message(payload) end,
          &message_info/1
        )

      {sparse_decode_us, sparse_decode_mem} =
        maybe_measured(
          sparse_decode?,
          fn -> Codec.decode_sparse_message(payload) end,
          &sparse_message_info/1
        )

      {graph_us, graph_mem, graph_stats} =
        maybe_measured_with_info(
          graph?,
          fn -> Figler.Scene.graph(fig_binary) end,
          &graph_info/1
        )

      {summary_us, summary} = timed(fn -> Scene.decode_summary(payload) end)
      {index_us, index} = timed(fn -> Scene.build_index(payload) end)

      {query_us, canvases} =
        timed(fn -> Scene.query_xpath(payload, "//canvas") end)

      {indexed_query_us, indexed_canvases} =
        timed(fn -> Scene.query_index(index, "//canvas") end)

      {indexed_fields_query_us, indexed_fields_canvases} =
        timed(fn -> Scene.query_index_fields(index, "//canvas", ["name"]) end)

      unless length(canvases) == length(indexed_canvases) do
        Mix.raise("indexed query mismatch for #{path}")
      end

      unless length(canvases) == length(indexed_fields_canvases) do
        Mix.raise("indexed fields query mismatch for #{path}")
      end

      {indexed_all_query_us, all_nodes} =
        timed(fn -> Scene.query_index(index, "//*") end)

      {indexed_all_fields_query_us, all_field_nodes} =
        timed(fn -> Scene.query_index_fields(index, "//*", ["name"]) end)

      unless length(all_nodes) == length(all_field_nodes) do
        Mix.raise("indexed all fields query mismatch for #{path}")
      end

      {by_type_text_us, text_nodes} =
        timed(fn -> Scene.index_by_type(index, "text") end)

      {text_contains_us, label_nodes} =
        timed(fn -> Scene.index_text_contains(index, "Label") end)

      sample_guid = canvases |> List.first() |> Map.fetch!(:guid)
      {node_lookup_us, _node} = timed(fn -> Scene.index_node(index, sample_guid) end)

      if length(label_nodes) > length(text_nodes) do
        Mix.raise("text helper mismatch for #{path}")
      end

      Mix.shell().info(
        Enum.join(
          [
            Path.basename(path),
            format_bytes(byte_size(fig_binary)),
            format_us(read_us + payload_us),
            format_optional_us(full_decode_us),
            format_optional_bytes(full_decode_mem),
            format_optional_us(sparse_decode_us),
            format_optional_bytes(sparse_decode_mem),
            format_optional_us(graph_us),
            format_optional_bytes(graph_mem),
            optional_stat(graph_stats, :node_count),
            optional_stat(graph_stats, :clone_count),
            optional_stat(graph_stats, :unresolved_count),
            optional_stat(graph_stats, :applied_count),
            format_us(summary_us),
            format_us(index_us),
            format_us(query_us),
            format_us(indexed_query_us),
            format_us(indexed_fields_query_us),
            format_us(indexed_all_query_us),
            format_us(indexed_all_fields_query_us),
            format_us(by_type_text_us),
            format_us(text_contains_us),
            format_us(node_lookup_us),
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

  defp maybe_measured(false, _fun, _info_fun), do: {:skip, :skip}

  defp maybe_measured(true, fun, info_fun) do
    {elapsed_us, memory_bytes, _info} = measured(fun, info_fun)
    {elapsed_us, memory_bytes}
  end

  defp maybe_measured_with_info(false, _fun, _info_fun), do: {:skip, :skip, :skip}

  defp maybe_measured_with_info(true, fun, info_fun) do
    measured(fun, info_fun)
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
        send(parent, {ref, elapsed_us, max(after_memory - before_memory, 0), info})
      end)

    receive do
      {^ref, elapsed_us, memory_bytes, info} ->
        Process.demonitor(monitor_ref, [:flush])
        {elapsed_us, memory_bytes, info}

      {:DOWN, ^monitor_ref, :process, ^pid, reason} ->
        Mix.raise("benchmark process failed: #{inspect(reason)}")
    end
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

  defp env_enabled?(name, opts) do
    default = Keyword.fetch!(opts, :default)

    case System.get_env(name) do
      nil -> default
      value when value in ["", "0", "false", "FALSE", "no", "NO", "off", "OFF"] -> false
      _value -> true
    end
  end

  defp format_optional_us(:skip), do: "skip"
  defp format_optional_us(us), do: format_us(us)

  defp format_optional_bytes(:skip), do: "skip"
  defp format_optional_bytes(bytes), do: format_bytes(bytes)

  defp optional_stat(:skip, _key), do: "skip"
  defp optional_stat(stats, key), do: Map.fetch!(stats, key)

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
