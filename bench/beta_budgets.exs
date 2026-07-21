defmodule Figler.Bench.BetaBudgets do
  @moduledoc false

  alias Figler.Native.CodecNifs
  alias Figler.Render
  alias Figler.Render.Skia, as: SkiaBackend
  alias Figler.Render.Skia.Assets
  alias Figler.Render.Skia.Bounds, as: SkiaBounds
  alias Figler.Scene
  alias Figler.Scene.Graph

  @poll_ms 1

  def run do
    large_path = env_path!("FIGLER_BUDGET_LARGE_FIXTURE")
    large_root = env!("FIGLER_BUDGET_LARGE_ROOT")
    render_path = env_path!("FIGLER_BUDGET_RENDER_FIXTURE")
    render_root = env!("FIGLER_BUDGET_RENDER_ROOT")
    warmup = env_count("FIGLER_BUDGET_WARMUP", 1, 0)
    samples = env_count("FIGLER_BUDGET_SAMPLES", 5, 1)

    large_binary = File.read!(large_path)
    {:ok, large_document} = Figler.Document.open(large_binary)
    large_index = Scene.index(large_document.payload)

    render_binary = File.read!(render_path)
    {:ok, render_document} = Figler.Document.open(render_binary)
    {:ok, render_scene} = Render.prepare(render_document, root: render_root)
    render_guids = SkiaBounds.render_guids(render_scene, render_scene.root)

    stages = [
      stage("query", fn -> Scene.query(large_index, "//canvas") end, &length/1),
      stage("graph", fn -> Scene.graph(large_document.payload) end, &graph_info/1),
      stage(
        "projection",
        fn -> CodecNifs.decode_render_source_nodes(large_document.payload, [large_root]) end,
        &length/1
      ),
      stage(
        "asset_loading",
        fn -> Assets.load(render_scene, render_guids, system_font_fallback: false) end,
        &asset_info/1
      ),
      stage(
        "compilation",
        fn -> SkiaBackend.compile(render_scene, system_font_fallback: false) end,
        &compile_info/1
      )
    ]

    measurements = Map.new(stages, &measure_stage(&1, warmup, samples))
    {:ok, compiled} = SkiaBackend.compile(render_scene, system_font_fallback: false)

    rasterization =
      stage(
        "rasterization",
        fn -> Skia.render(compiled.document, format: :png) end,
        &raster_info/1
      )

    {"rasterization", raster_measurement} =
      measure_stage(rasterization, warmup, samples)

    measurements = Map.put(measurements, "rasterization", raster_measurement)

    {budget_file, budget_checks} = budget_checks(measurements)

    report = %{
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      budget_file: budget_file,
      budget_checks: budget_checks,
      runtime: %{
        elixir: System.version(),
        otp: System.otp_release(),
        schedulers: System.schedulers_online()
      },
      fixtures: %{
        large: fixture_info(large_path, large_binary, large_root),
        render: fixture_info(render_path, render_binary, render_root)
      },
      method: %{
        cold_samples: 1,
        warmup_samples: warmup,
        warm_samples: samples,
        peak_beam_scope: "isolated worker process",
        peak_rss_scope: "whole BEAM OS process delta",
        polling_ms: @poll_ms
      },
      measurements: measurements
    }

    json = Jason.encode!(report, pretty: true) <> "\n"

    case System.get_env("FIGLER_BUDGET_OUTPUT") do
      nil -> IO.write(json)
      path -> File.write!(path, json)
    end

    case budget_checks do
      %{passed: false, failures: failures} ->
        raise "beta performance budgets exceeded: #{inspect(failures)}"

      _not_checked_or_passed ->
        :ok
    end
  end

  defp stage(name, fun, info), do: %{name: name, fun: fun, info: info}

  defp measure_stage(stage, warmup, samples) do
    cold = measured(stage.fun, stage.info)
    repeat(warmup, fn -> measured(stage.fun, stage.info) end)
    warm = repeat(samples, fn -> measured(stage.fun, stage.info) end)
    {stage.name, %{cold: cold, warm: summarize(warm)}}
  end

  defp measured(fun, info_fun) do
    parent = self()
    ref = make_ref()

    {pid, monitor} =
      spawn_monitor(fn ->
        :erlang.garbage_collect()
        send(parent, {ref, :ready})

        receive do
          {^ref, :run} -> :ok
        end

        started = System.monotonic_time()
        result = fun.()
        elapsed = System.monotonic_time() - started
        info = info_fun.(result)
        send(parent, {ref, :done, elapsed, info})

        receive do
          {^ref, :release} -> :ok
        end
      end)

    receive do
      {^ref, :ready} -> :ok
    end

    baseline_beam = process_memory(pid)
    baseline_rss = rss_bytes()
    send(pid, {ref, :run})

    sample =
      monitor_until_done(
        ref,
        pid,
        monitor,
        baseline_beam,
        baseline_rss,
        baseline_beam,
        baseline_rss
      )

    send(pid, {ref, :release})

    receive do
      {:DOWN, ^monitor, :process, ^pid, :normal} ->
        sample

      {:DOWN, ^monitor, :process, ^pid, reason} ->
        raise "benchmark stage failed: #{inspect(reason)}"
    end
  end

  defp monitor_until_done(
         ref,
         pid,
         monitor,
         baseline_beam,
         baseline_rss,
         peak_beam,
         peak_rss
       ) do
    receive do
      {:DOWN, ^monitor, :process, ^pid, reason} ->
        raise "benchmark stage failed: #{inspect(reason)}"

      {^ref, :done, elapsed, info} ->
        final_beam = process_memory(pid)
        final_rss = rss_bytes()

        %{
          elapsed_ms: native_ms(elapsed),
          peak_beam_bytes: max(peak_beam, final_beam),
          peak_beam_delta_bytes: max(max(peak_beam, final_beam) - baseline_beam, 0),
          peak_rss_delta_bytes: max(max(peak_rss, final_rss) - baseline_rss, 0),
          info: info
        }
    after
      @poll_ms ->
        monitor_until_done(
          ref,
          pid,
          monitor,
          baseline_beam,
          baseline_rss,
          max(peak_beam, process_memory(pid)),
          max(peak_rss, rss_bytes())
        )
    end
  end

  defp summarize(samples) do
    by_time = Enum.sort_by(samples, & &1.elapsed_ms)

    %{
      sample_count: length(samples),
      p50_ms: percentile(by_time, 0.50).elapsed_ms,
      p95_ms: percentile(by_time, 0.95).elapsed_ms,
      max_peak_beam_delta_bytes:
        Enum.max_by(samples, & &1.peak_beam_delta_bytes).peak_beam_delta_bytes,
      max_peak_rss_delta_bytes:
        Enum.max_by(samples, & &1.peak_rss_delta_bytes).peak_rss_delta_bytes,
      info: percentile(by_time, 0.50).info
    }
  end

  defp percentile(samples, percentile) do
    index = max(ceil(length(samples) * percentile) - 1, 0)
    Enum.at(samples, index)
  end

  defp repeat(0, _fun), do: []
  defp repeat(count, fun), do: Enum.map(1..count, fn _index -> fun.() end)

  defp budget_checks(measurements) do
    case System.get_env("FIGLER_BUDGET_LIMITS") do
      nil ->
        {nil, nil}

      path ->
        limits = path |> File.read!() |> Jason.decode!() |> Map.fetch!("budgets")

        failures =
          Enum.flat_map(limits, fn {stage, stage_limits} ->
            measurement = Map.fetch!(measurements, stage)
            actual = budget_values(measurement)

            Enum.flat_map(stage_limits, fn {metric, limit} ->
              value = Map.fetch!(actual, metric)

              if value <= limit,
                do: [],
                else: [%{stage: stage, metric: metric, value: value, limit: limit}]
            end)
          end)

        {path, %{passed: failures == [], failures: failures}}
    end
  end

  defp budget_values(measurement) do
    %{
      "cold_ms" => measurement.cold.elapsed_ms,
      "warm_p95_ms" => measurement.warm.p95_ms,
      "peak_beam_delta_bytes" =>
        max(measurement.cold.peak_beam_delta_bytes, measurement.warm.max_peak_beam_delta_bytes),
      "peak_rss_delta_bytes" =>
        max(measurement.cold.peak_rss_delta_bytes, measurement.warm.max_peak_rss_delta_bytes)
    }
  end

  defp graph_info(graph) do
    graph
    |> Graph.stats()
    |> Map.take([:node_count, :clone_count, :unresolved_count, :applied_count, :root_count])
  end

  defp asset_info({:ok, assets}) do
    %{
      images: map_size(assets.images),
      geometries: map_size(assets.geometries),
      vector_networks: map_size(assets.vector_networks),
      fonts: map_size(assets.fonts),
      errors: map_size(assets.errors)
    }
  end

  defp compile_info({:ok, result}) do
    %{commands: length(Skia.commands(result.document)), warnings: length(result.warnings)}
  end

  defp raster_info({:ok, png}), do: %{bytes: byte_size(png)}

  defp fixture_info(path, binary, root) do
    %{
      name: Path.basename(path),
      bytes: byte_size(binary),
      sha256: Base.encode16(:crypto.hash(:sha256, binary), case: :lower),
      root: root
    }
  end

  defp process_memory(pid) do
    case Process.info(pid, :memory) do
      {:memory, bytes} -> bytes
      nil -> 0
    end
  end

  defp rss_bytes do
    with {:ok, status} <- File.read("/proc/#{System.pid()}/status"),
         [kilobytes] <- Regex.run(~r/^VmRSS:\s+(\d+)\s+kB$/m, status, capture: :all_but_first) do
      String.to_integer(kilobytes) * 1_024
    else
      _unavailable -> 0
    end
  end

  defp native_ms(native),
    do: System.convert_time_unit(native, :native, :microsecond) / 1_000

  defp env!(name), do: System.get_env(name) || raise("set #{name}")

  defp env_path!(name) do
    path = env!(name)
    if File.regular?(path), do: path, else: raise("fixture not found: #{path}")
  end

  defp env_count(name, default, minimum) do
    case System.get_env(name) do
      nil ->
        default

      value ->
        case Integer.parse(value) do
          {count, ""} when count >= minimum -> count
          _invalid -> raise "#{name} must be an integer >= #{minimum}"
        end
    end
  end
end

Figler.Bench.BetaBudgets.run()
