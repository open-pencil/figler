defmodule Figler.Render.Options do
  @moduledoc """
  Validation and types for the public rendering option contract.

  Unknown options and malformed values return
  `{:error, {:invalid_render_options, errors}}`, where each error contains the
  option name, a stable code, and the rejected value.
  """

  alias Figler.OptionError

  @type option ::
          {:root, String.t() | non_neg_integer()}
          | {:page, String.t() | non_neg_integer()}
          | {:graph, keyword()}
          | {:scale, number()}
          | {:background, term()}
          | {:format, :png | :jpeg | :webp | :raw}
          | {:quality, 0..100}
          | {:strict, boolean()}
          | {:fallback_font_paths, [String.t()]}
          | {:fallback_typefaces, [term()]}
          | {:font_languages, [String.t()]}
          | {:system_font_fallback, boolean()}

  @type error :: OptionError.t()

  @keys [
    :root,
    :page,
    :graph,
    :scale,
    :background,
    :format,
    :quality,
    :strict,
    :fallback_font_paths,
    :fallback_typefaces,
    :font_languages,
    :system_font_fallback
  ]

  @doc "Validates public rendering options."
  @spec validate(keyword()) :: :ok | {:error, {:invalid_render_options, [error()]}}
  def validate(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      errors =
        opts
        |> Enum.flat_map(&validate_option/1)
        |> add_selection_error(opts)

      if errors == [], do: :ok, else: {:error, {:invalid_render_options, errors}}
    else
      {:error, {:invalid_render_options, [error(:options, :invalid_keyword_list, opts)]}}
    end
  end

  defp validate_option({key, value}) when key not in @keys,
    do: [error(key, :unknown_option, value)]

  defp validate_option({key, value}) when key in [:root, :page] do
    if is_binary(value) or (is_integer(value) and value >= 0),
      do: [],
      else: [error(key, :invalid_selection, value)]
  end

  defp validate_option({:graph, value}), do: list_error(:graph, value)

  defp validate_option({:scale, value}) do
    if is_number(value) and value > 0,
      do: [],
      else: [error(:scale, :invalid_scale, value)]
  end

  defp validate_option({:format, value}) do
    if value in [:png, :jpeg, :webp, :raw],
      do: [],
      else: [error(:format, :invalid_format, value)]
  end

  defp validate_option({:quality, value}) do
    if is_integer(value) and value in 0..100,
      do: [],
      else: [error(:quality, :invalid_quality, value)]
  end

  defp validate_option({key, value}) when key in [:strict, :system_font_fallback] do
    if is_boolean(value), do: [], else: [error(key, :invalid_boolean, value)]
  end

  defp validate_option({key, value}) when key in [:fallback_font_paths, :font_languages] do
    if is_list(value) and Enum.all?(value, &is_binary/1),
      do: [],
      else: [error(key, :invalid_string_list, value)]
  end

  defp validate_option({:fallback_typefaces, value}), do: list_error(:fallback_typefaces, value)
  defp validate_option({:background, _value}), do: []

  defp validate_option(value), do: [error(:options, :invalid_option_entry, value)]

  defp add_selection_error(errors, opts) do
    if Keyword.has_key?(opts, :root) and Keyword.has_key?(opts, :page) do
      [error(:selection, :conflicting_root_and_page, Keyword.take(opts, [:root, :page])) | errors]
    else
      errors
    end
  end

  defp list_error(key, value) do
    if is_list(value), do: [], else: [error(key, :invalid_list, value)]
  end

  defp error(option, code, value), do: OptionError.new(option, code, value)
end
