defmodule Figler.Render.CornerRadii do
  @moduledoc """
  Rendering-neutral rectangular corner radii.

  Figma stores one uniform radius plus optional independent corner values. The
  independent values only take effect when the source flag is enabled.
  """

  alias Figler.Render.Shape

  @enforce_keys [:top_left, :top_right, :bottom_right, :bottom_left, :independent?, :smoothing]
  defstruct [:top_left, :top_right, :bottom_right, :bottom_left, :independent?, :smoothing]

  @type t :: %__MODULE__{
          top_left: number(),
          top_right: number(),
          bottom_right: number(),
          bottom_left: number(),
          independent?: boolean(),
          smoothing: number()
        }

  @source_fields [
    :corner_radius,
    :rectangle_top_left_corner_radius,
    :rectangle_top_right_corner_radius,
    :rectangle_bottom_right_corner_radius,
    :rectangle_bottom_left_corner_radius,
    :rectangle_corner_radii_independent,
    :corner_smoothing
  ]

  @doc false
  @spec source_fields() :: [atom()]
  def source_fields, do: @source_fields

  @doc false
  @spec from_source(map()) :: t()
  def from_source(source) when is_map(source) do
    uniform = Map.get(source, :corner_radius) || 0.0
    independent? = Map.get(source, :rectangle_corner_radii_independent) == true

    %__MODULE__{
      top_left: radius(source, :rectangle_top_left_corner_radius, uniform, independent?),
      top_right: radius(source, :rectangle_top_right_corner_radius, uniform, independent?),
      bottom_right: radius(source, :rectangle_bottom_right_corner_radius, uniform, independent?),
      bottom_left: radius(source, :rectangle_bottom_left_corner_radius, uniform, independent?),
      independent?: independent?,
      smoothing: Map.get(source, :corner_smoothing) || 0.0
    }
  end

  @doc false
  @spec warnings(t()) :: [map()]
  def warnings(%__MODULE__{} = corners) do
    radius_warnings =
      corners
      |> validation_radius_values()
      |> Enum.reject(fn {_corner, value} -> Shape.finite_number?(value) and value >= 0 end)
      |> Enum.map(fn {corner, value} ->
        %{code: :corner_radius_invalid, corner: corner, radius: value}
      end)

    smoothing_warnings =
      cond do
        not Shape.finite_number?(corners.smoothing) or corners.smoothing < 0 or
            corners.smoothing > 1 ->
          [%{code: :corner_smoothing_invalid, smoothing: corners.smoothing}]

        corners.smoothing > 0 and any_radius?(corners) ->
          [%{code: :corner_smoothing_approximated, smoothing: corners.smoothing}]

        true ->
          []
      end

    radius_warnings ++ smoothing_warnings
  end

  @doc false
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = corners) do
    Enum.all?(radius_values(corners), fn {_corner, value} ->
      Shape.finite_number?(value) and value >= 0
    end) and
      Shape.finite_number?(corners.smoothing) and corners.smoothing >= 0 and
      corners.smoothing <= 1
  end

  @doc false
  @spec any_radius?(t()) :: boolean()
  def any_radius?(%__MODULE__{} = corners) do
    Enum.any?(radius_values(corners), fn {_corner, value} -> is_number(value) and value > 0 end)
  end

  @doc false
  @spec inset(t(), number()) :: t()
  def inset(%__MODULE__{} = corners, amount) when is_number(amount) do
    %{
      corners
      | top_left: max(corners.top_left - amount, 0.0),
        top_right: max(corners.top_right - amount, 0.0),
        bottom_right: max(corners.bottom_right - amount, 0.0),
        bottom_left: max(corners.bottom_left - amount, 0.0)
    }
  end

  defp radius(source, key, uniform, true), do: Map.get(source, key) || uniform
  defp radius(_source, _key, uniform, false), do: uniform

  defp validation_radius_values(%__MODULE__{independent?: false, top_left: radius}),
    do: [uniform: radius]

  defp validation_radius_values(%__MODULE__{} = corners), do: radius_values(corners)

  defp radius_values(corners) do
    [
      top_left: corners.top_left,
      top_right: corners.top_right,
      bottom_right: corners.bottom_right,
      bottom_left: corners.bottom_left
    ]
  end
end
