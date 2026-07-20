defmodule Figler.Render.Warning do
  @moduledoc """
  A structured rendering diagnostic.

  Warning codes are stable within the beta API. `:severity` classifies why a
  render is not exact; `:context` exposes structured details when available;
  and `:value` preserves the original backend-neutral diagnostic value for
  compatibility and debugging.

  All warnings are returned in non-strict render metadata. `strict: true`
  rejects the same warning list with
  `{:error, {:unsupported_render_features, warnings}}`.
  """

  @derive Jason.Encoder
  @enforce_keys [:code, :feature, :guid, :severity, :context, :value]
  defstruct [:code, :feature, :guid, :severity, :context, :value]

  @type severity :: :approximation | :unsupported | :substitution | :invalid | :missing

  @type t :: %__MODULE__{
          code: atom(),
          feature: atom(),
          guid: String.t(),
          severity: severity(),
          context: map(),
          value: term()
        }

  @doc false
  @spec new(String.t(), atom(), term()) :: t()
  def new(guid, feature, value) when is_binary(guid) and is_atom(feature) do
    code = code(value)

    %__MODULE__{
      code: code,
      feature: feature,
      guid: guid,
      severity: severity(code),
      context: context(value),
      value: value
    }
  end

  @doc "Returns the stable warning code represented by a diagnostic value."
  @spec code(term()) :: atom()
  def code(%{code: code}) when is_atom(code), do: code
  def code(value) when is_atom(value), do: value

  def code(value) when is_tuple(value) do
    case Tuple.to_list(value) do
      [code | _details] when is_atom(code) -> code
      _empty_or_invalid -> :unknown_render_warning
    end
  end

  def code(_value), do: :unknown_render_warning

  @doc "Returns the severity classification for a stable warning code."
  @spec severity(atom()) :: severity()
  def severity(:font_substituted), do: :substitution

  def severity(code) when is_atom(code) do
    name = Atom.to_string(code)

    cond do
      String.ends_with?(name, "_approximated") ->
        :approximation

      String.contains?(name, "invalid") ->
        :invalid

      String.contains?(name, "malformed") ->
        :invalid

      String.ends_with?(name, "_failed") ->
        :invalid

      code in [:text_style_length_mismatch, :text_style_splits_surrogate] ->
        :invalid

      String.contains?(name, "missing") ->
        :missing

      String.contains?(name, "unavailable") ->
        :missing

      true ->
        :unsupported
    end
  end

  defp context(%{code: _code} = value), do: Map.delete(value, :code)
  defp context(value) when is_tuple(value), do: %{details: value |> Tuple.to_list() |> tl()}
  defp context(_value), do: %{}
end
