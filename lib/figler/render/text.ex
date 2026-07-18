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
    style = present(Map.get(node, :font_style))

    %__MODULE__{
      family: present(Map.get(node, :font_family)),
      style: style,
      postscript: present(Map.get(node, :font_postscript)),
      size: float(Map.get(node, :font_size)),
      weight: weight(style),
      slant: slant(style)
    }
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

defmodule Figler.Render.Text do
  @moduledoc "Rendering-neutral text content and requested font."

  alias Figler.Render.Font

  @enforce_keys [:content, :font]
  defstruct [:content, :font]

  @type t :: %__MODULE__{content: String.t(), font: Font.t()}

  @doc false
  @spec from_effective(map(), Figler.Schema.NodeType.t() | :unknown) :: t() | nil
  def from_effective(node, :text) when is_map(node) do
    %__MODULE__{content: content(Map.get(node, :text)), font: Font.from_effective(node)}
  end

  def from_effective(_node, _node_type), do: nil

  defp content(value) when is_binary(value), do: value
  defp content(_value), do: ""
end
