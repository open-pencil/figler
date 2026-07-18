defmodule Figler.Render.Font do
  @moduledoc """
  Rendering-neutral font request projected from Figma text metadata.

  Family, style, and PostScript names retain source intent. Weight and slant
  are normalized for backend typeface matching.
  """

  @weight_markers [
    {100, ["thin", "hairline"]},
    {200, ["extra light", "extralight", "ultra light", "ultralight"]},
    {300, ["light"]},
    {600, ["semi bold", "semibold", "demi bold", "demibold"]},
    {800, ["extra bold", "extrabold", "ultra bold", "ultrabold"]},
    {900, ["black", "heavy"]},
    {700, ["bold"]},
    {500, ["medium"]}
  ]

  @enforce_keys []
  defstruct [:family, :style, :postscript, :size, weight: 400, slant: :upright]

  @type t :: %__MODULE__{
          family: String.t() | nil,
          style: String.t() | nil,
          postscript: String.t() | nil,
          size: float() | nil,
          weight: 100..900,
          slant: :upright | :italic | :oblique
        }

  @doc false
  @spec from_effective(map()) :: t()
  def from_effective(node) when is_map(node) do
    from_values(
      Map.get(node, :font_family),
      Map.get(node, :font_style),
      Map.get(node, :font_postscript),
      Map.get(node, :font_size)
    )
  end

  @doc false
  @spec from_values(term(), term(), term(), term()) :: t()
  def from_values(family, style, postscript, size) do
    style = present(style)

    %__MODULE__{
      family: present(family),
      style: style,
      postscript: present(postscript),
      size: float(size),
      weight: weight(style),
      slant: slant(style)
    }
  end

  @doc false
  @spec with_overrides(t(), map()) :: t()
  def with_overrides(%__MODULE__{} = base, overrides) when is_map(overrides) do
    from_values(
      override(overrides, :font_family, base.family),
      override(overrides, :font_style, base.style),
      override(overrides, :font_postscript, base.postscript),
      override(overrides, :font_size, base.size)
    )
  end

  defp override(overrides, key, default) do
    case Map.fetch(overrides, key) do
      {:ok, nil} -> default
      {:ok, value} -> value
      :error -> default
    end
  end

  defp present(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      present -> present
    end
  end

  defp present(_value), do: nil

  defp float(value) when is_number(value), do: value * 1.0
  defp float(_value), do: nil

  defp weight(nil), do: 400

  defp weight(style) do
    normalized = String.downcase(style)

    Enum.find_value(@weight_markers, 400, fn {weight, markers} ->
      if String.contains?(normalized, markers), do: weight
    end)
  end

  defp slant(nil), do: :upright

  defp slant(style) do
    normalized = String.downcase(style)

    cond do
      String.contains?(normalized, "italic") -> :italic
      String.contains?(normalized, "oblique") -> :oblique
      true -> :upright
    end
  end
end
