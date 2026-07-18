defmodule Figler.Render.Text.Source do
  @moduledoc false

  alias Figler.Render.Font
  alias Figler.Render.Text.StyleOverride

  defstruct [:characters, character_style_ids: [], style_overrides: %{}, fallback_fonts: []]

  @type t :: %__MODULE__{
          characters: String.t() | nil,
          character_style_ids: [non_neg_integer()],
          style_overrides: %{optional(non_neg_integer()) => StyleOverride.t()},
          fallback_fonts: [Font.t()]
        }

  @spec from_sparse(map() | nil) :: t() | nil
  def from_sparse(nil), do: nil

  def from_sparse(sparse) when is_map(sparse) do
    %__MODULE__{
      characters: Map.get(sparse, :characters),
      character_style_ids: Map.get(sparse, :character_style_i_ds) || [],
      style_overrides: style_overrides(Map.get(sparse, :style_override_table) || []),
      fallback_fonts: Enum.map(Map.get(sparse, :fallback_fonts) || [], &fallback_font/1)
    }
  end

  defp style_overrides(values) do
    values
    |> Enum.map(&StyleOverride.from_sparse/1)
    |> Enum.reject(&is_nil(&1.style_id))
    |> Map.new(&{&1.style_id, &1})
  end

  defp fallback_font(font_name) do
    Font.from_values(
      Map.get(font_name, :family),
      Map.get(font_name, :style),
      Map.get(font_name, :postscript),
      nil
    )
  end
end
