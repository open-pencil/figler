defmodule Figler.Render.Text.Measurement do
  @moduledoc "A typed Figma text measurement retaining its source units."

  defstruct [:value, :units]

  @type units :: :raw | :pixels | :percent
  @type t :: %__MODULE__{value: float(), units: units()}
  @type kind :: :letter_spacing | :line_height

  @spec from_sparse(map() | nil) :: t() | nil
  def from_sparse(nil), do: nil

  def from_sparse(%{value: value, units: units}) when is_number(value) do
    %__MODULE__{value: value * 1.0, units: units}
  end

  def from_sparse(_value), do: nil

  @spec pixels(t() | nil, number() | nil, kind()) :: float() | nil
  def pixels(nil, _font_size, _kind), do: nil

  def pixels(%__MODULE__{value: value, units: :pixels}, _font_size, _kind), do: value

  def pixels(%__MODULE__{value: value, units: :percent}, font_size, _kind)
      when is_number(font_size),
      do: value / 100.0 * font_size

  def pixels(%__MODULE__{value: value, units: :raw}, font_size, :line_height)
      when is_number(font_size),
      do: value * font_size

  def pixels(%__MODULE__{value: value, units: :raw}, _font_size, :letter_spacing), do: value
  def pixels(_measurement, _font_size, _kind), do: nil
end
