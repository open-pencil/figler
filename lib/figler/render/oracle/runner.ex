defmodule Figler.Render.Oracle.Runner do
  @moduledoc """
  Runs same-scene visual comparisons from JSON manifests.

  A manifest selects the same `.fig` page or root, scale, and background used
  to produce each OpenPencil reference PNG:

      {
        "fig": "fixture.fig",
        "oracle": {"renderer": "open-pencil", "source_root": "1:23"},
        "cases": [
          {
            "name": "button",
            "reference": "button.png",
            "root": "1:23",
            "scale": 2.0,
            "background": "transparent",
            "fallback_fonts": ["../fonts/NotoSansSC-Regular.otf"],
            "font_languages": ["zh-Hans"],
            "expected_warning_codes": ["font_substituted"],
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
  can remain outside the repository. Optional `oracle` metadata is copied into
  reports so source-renderer IDs can be recorded when importers remap nodes.
  """

  alias Figler.Document
  alias Figler.Render
  alias Figler.Render.Oracle

  @type result :: %{
          manifest: String.t(),
          fixture: String.t(),
          oracle: map(),
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
         oracle: Map.get(manifest, "oracle", %{}),
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
         {:ok, render_opts} <- render_options(entry, base_dir),
         {:ok, threshold_opts} <- threshold_options(entry),
         {:ok, expected_warning_codes} <- expected_warning_codes(entry),
         {:ok, actual, metadata} <- Render.render(document, render_opts),
         {:ok, metrics} <- Oracle.compare_png(reference_png, actual, threshold_opts) do
      warning_check = warning_check(expected_warning_codes, metadata.warnings)

      %{
        name: name,
        reference: reference_path,
        passed?: metrics.passed? and warning_check.passed?,
        metrics: metrics,
        warning_check: warning_check,
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
      value: json_value(warning.value)
    }
  end

  defp expected_warning_codes(entry) do
    case Map.fetch(entry, "expected_warning_codes") do
      :error -> {:ok, nil}
      {:ok, codes} when is_list(codes) -> validate_warning_codes(codes)
      {:ok, _invalid} -> {:error, :invalid_expected_warning_codes}
    end
  end

  defp validate_warning_codes(codes) do
    if Enum.all?(codes, &is_binary/1),
      do: {:ok, Enum.sort(Enum.uniq(codes))},
      else: {:error, :invalid_expected_warning_codes}
  end

  defp warning_check(nil, warnings) do
    %{checked?: false, passed?: true, expected: nil, actual: warning_codes(warnings)}
  end

  defp warning_check(expected, warnings) do
    actual = warning_codes(warnings)
    %{checked?: true, passed?: actual == expected, expected: expected, actual: actual}
  end

  defp warning_codes(warnings) do
    warnings
    |> Enum.map(&warning_code/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp warning_code(%{value: %{code: code}}) when is_atom(code), do: Atom.to_string(code)

  defp warning_code(%{feature: feature, value: value}),
    do: "#{feature}:#{inspect(value)}"

  defp warning_code(_warning), do: nil

  defp json_value(nil), do: nil
  defp json_value(value) when is_boolean(value), do: value
  defp json_value(value) when is_atom(value), do: Atom.to_string(value)

  defp json_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.map(&json_value/1)

  defp json_value(value) when is_list(value), do: Enum.map(value, &json_value/1)

  defp json_value(value) when is_map(value) do
    Map.new(value, fn {key, nested} -> {to_string(key), json_value(nested)} end)
  end

  defp json_value(value), do: value

  defp reference_path(%{"reference" => relative}, base_dir) when is_binary(relative),
    do: existing_file(Path.expand(relative, base_dir), :reference_png_not_found)

  defp reference_path(_entry, _base_dir), do: {:error, :reference_png_required}

  defp existing_file(path, error) do
    if File.regular?(path), do: {:ok, path}, else: {:error, {error, path}}
  end

  defp render_options(entry, base_dir) do
    with :ok <- valid_selection(entry),
         {:ok, scale} <- positive_number(Map.get(entry, "scale", 1.0), :scale),
         {:ok, fallback_font_paths} <- fallback_font_paths(entry, base_dir),
         {:ok, font_languages} <- font_languages(entry) do
      opts = [format: :raw, scale: scale]
      opts = put_option(opts, :root, Map.get(entry, "root"))
      opts = put_option(opts, :page, Map.get(entry, "page"))
      opts = put_option(opts, :background, background(Map.get(entry, "background")))
      opts = put_option(opts, :fallback_font_paths, fallback_font_paths)
      {:ok, put_option(opts, :font_languages, font_languages)}
    end
  end

  defp fallback_font_paths(entry, base_dir) do
    case Map.get(entry, "fallback_fonts", []) do
      paths when is_list(paths) ->
        paths
        |> Enum.reduce_while({:ok, []}, &collect_fallback_font(&1, &2, base_dir))
        |> then(fn
          {:ok, resolved} -> {:ok, Enum.reverse(resolved)}
          error -> error
        end)

      _invalid ->
        {:error, :invalid_fallback_fonts}
    end
  end

  defp collect_fallback_font(path, {:ok, resolved}, base_dir) when is_binary(path) do
    case existing_file(Path.expand(path, base_dir), :fallback_font_not_found) do
      {:ok, absolute} -> {:cont, {:ok, [absolute | resolved]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp collect_fallback_font(_invalid, _resolved, _base_dir),
    do: {:halt, {:error, :invalid_fallback_fonts}}

  defp font_languages(entry) do
    case Map.get(entry, "font_languages", []) do
      languages when is_list(languages) ->
        if Enum.all?(languages, &is_binary/1),
          do: {:ok, languages},
          else: {:error, :invalid_font_languages}

      _invalid ->
        {:error, :invalid_font_languages}
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
