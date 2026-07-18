defmodule Figler.Render.Oracle.Runner do
  @moduledoc """
  Runs same-scene visual comparisons from JSON manifests.

  A manifest selects the same `.fig` page or root, scale, and background used
  to produce each OpenPencil reference PNG:

      {
        "fig": "fixture.fig",
        "cases": [
          {
            "name": "button",
            "reference": "button.png",
            "root": "1:23",
            "scale": 2.0,
            "background": "transparent",
            "thresholds": {
              "channel": 2,
              "changed_ratio": 0.001,
              "mean_delta": 0.1,
              "max_delta": 16
            }
          }
        ]
      }

  Paths are resolved relative to the manifest. Large fixtures and references
  can remain outside the repository.
  """

  alias Figler.Document
  alias Figler.Render
  alias Figler.Render.Oracle

  @type result :: %{
          manifest: String.t(),
          fixture: String.t(),
          case_count: non_neg_integer(),
          failed_count: non_neg_integer(),
          passed?: boolean(),
          cases: [map()]
        }

  @doc "Runs all visual cases in a render-oracle manifest."
  @spec run(Path.t()) :: {:ok, result()} | {:error, term()}
  def run(manifest_path) do
    manifest_path = Path.expand(manifest_path)
    base_dir = Path.dirname(manifest_path)

    with {:ok, manifest} <- decode_manifest(manifest_path),
         {:ok, fixture} <- fixture_path(manifest, base_dir),
         {:ok, fig} <- File.read(fixture),
         {:ok, document} <- Document.open(fig),
         {:ok, cases} <- cases(manifest),
         results <- Enum.map(cases, &run_case(document, base_dir, &1)) do
      failed_count = Enum.count(results, &(not &1.passed?))

      {:ok,
       %{
         manifest: manifest_path,
         fixture: fixture,
         case_count: length(results),
         failed_count: failed_count,
         passed?: failed_count == 0,
         cases: results
       }}
    end
  end

  defp decode_manifest(path) do
    with {:ok, json} <- File.read(path),
         {:ok, manifest} when is_map(manifest) <- Jason.decode(json) do
      {:ok, manifest}
    else
      {:ok, _value} -> {:error, :invalid_render_oracle_manifest}
      error -> error
    end
  end

  defp fixture_path(%{"fig" => relative}, base_dir) when is_binary(relative),
    do: existing_file(Path.expand(relative, base_dir), :fig_fixture_not_found)

  defp fixture_path(_manifest, base_dir) do
    case Path.wildcard(Path.join(base_dir, "*.fig")) do
      [fixture] -> {:ok, Path.expand(fixture)}
      [] -> {:error, :fig_fixture_not_found}
      _fixtures -> {:error, :multiple_fig_fixtures}
    end
  end

  defp cases(%{"cases" => cases}) when is_list(cases) and cases != [] do
    if Enum.all?(cases, &is_map/1), do: {:ok, cases}, else: {:error, :invalid_render_oracle_cases}
  end

  defp cases(_manifest), do: {:error, :invalid_render_oracle_cases}

  defp run_case(document, base_dir, entry) do
    name = Map.get(entry, "name", Map.get(entry, "reference", "unnamed"))

    with {:ok, reference_path} <- reference_path(entry, base_dir),
         {:ok, reference_png} <- File.read(reference_path),
         {:ok, render_opts} <- render_options(entry),
         {:ok, threshold_opts} <- threshold_options(entry),
         {:ok, actual, metadata} <- Render.render(document, render_opts),
         {:ok, metrics} <- Oracle.compare_png(reference_png, actual, threshold_opts) do
      %{
        name: name,
        reference: reference_path,
        passed?: metrics.passed?,
        metrics: metrics,
        render: %{
          root: metadata.root,
          bounds: Map.from_struct(metadata.bounds),
          warnings: Enum.map(metadata.warnings, &warning_result/1)
        }
      }
    else
      {:error, reason} ->
        %{name: name, passed?: false, error: inspect(reason)}
    end
  end

  defp warning_result(warning) do
    %{
      guid: warning.guid,
      feature: Atom.to_string(warning.feature),
      value: inspect(warning.value)
    }
  end

  defp reference_path(%{"reference" => relative}, base_dir) when is_binary(relative),
    do: existing_file(Path.expand(relative, base_dir), :reference_png_not_found)

  defp reference_path(_entry, _base_dir), do: {:error, :reference_png_required}

  defp existing_file(path, error) do
    if File.regular?(path), do: {:ok, path}, else: {:error, {error, path}}
  end

  defp render_options(entry) do
    with :ok <- valid_selection(entry),
         {:ok, scale} <- positive_number(Map.get(entry, "scale", 1.0), :scale) do
      opts = [format: :raw, scale: scale]
      opts = put_option(opts, :root, Map.get(entry, "root"))
      opts = put_option(opts, :page, Map.get(entry, "page"))
      {:ok, put_option(opts, :background, background(Map.get(entry, "background")))}
    end
  end

  defp valid_selection(%{"root" => _root, "page" => _page}),
    do: {:error, :root_and_page_are_mutually_exclusive}

  defp valid_selection(_entry), do: :ok

  defp positive_number(value, _field) when is_number(value) and value > 0,
    do: {:ok, value * 1.0}

  defp positive_number(_value, field), do: {:error, {:invalid_render_oracle_option, field}}

  defp background(nil), do: nil
  defp background("transparent"), do: :transparent
  defp background(value), do: value

  defp put_option(opts, _key, nil), do: opts
  defp put_option(opts, key, value), do: Keyword.put(opts, key, value)

  defp threshold_options(entry) do
    case Map.get(entry, "thresholds", %{}) do
      thresholds when is_map(thresholds) -> threshold_options_map(thresholds)
      _invalid -> {:error, :invalid_render_oracle_thresholds}
    end
  end

  defp threshold_options_map(thresholds) do
    channel = Map.get(thresholds, "channel", 0)

    with {:ok, channel} <- byte_threshold(channel, :channel),
         {:ok, changed_ratio} <-
           non_negative_number(Map.get(thresholds, "changed_ratio", 0.0), :changed_ratio),
         {:ok, mean_delta} <-
           non_negative_number(Map.get(thresholds, "mean_delta", channel * 1.0), :mean_delta),
         {:ok, max_delta} <- byte_threshold(Map.get(thresholds, "max_delta", 255), :max_delta) do
      {:ok,
       [
         channel_threshold: channel,
         max_changed_ratio: changed_ratio,
         max_mean_delta: mean_delta,
         max_channel_delta: max_delta
       ]}
    end
  end

  defp byte_threshold(value, _field) when is_integer(value) and value in 0..255, do: {:ok, value}
  defp byte_threshold(_value, field), do: {:error, {:invalid_render_oracle_threshold, field}}

  defp non_negative_number(value, _field) when is_number(value) and value >= 0,
    do: {:ok, value * 1.0}

  defp non_negative_number(_value, field),
    do: {:error, {:invalid_render_oracle_threshold, field}}
end
