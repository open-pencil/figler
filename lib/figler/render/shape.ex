defmodule Figler.Render.Shape.Polygon do
  @moduledoc "Typed rendering parameters for a regular polygon."

  @enforce_keys [:point_count]
  defstruct [:point_count]

  @type t :: %__MODULE__{point_count: integer()}
end

defmodule Figler.Render.Shape.Star do
  @moduledoc "Typed rendering parameters for a regular star."

  @enforce_keys [:point_count, :inner_scale]
  defstruct [:point_count, :inner_scale]

  @type t :: %__MODULE__{point_count: integer(), inner_scale: float()}
end

defmodule Figler.Render.Shape.Arc do
  @moduledoc "Typed rendering parameters for a partial ellipse or ellipse ring."

  @enforce_keys [:start_angle, :end_angle, :inner_radius]
  defstruct [:start_angle, :end_angle, :inner_radius]

  @type t :: %__MODULE__{
          start_angle: float(),
          end_angle: float(),
          inner_radius: float()
        }
end

defmodule Figler.Render.Shape do
  @moduledoc """
  Rendering-neutral typed parameters for Figma primitive geometry.

  The backend receives these values instead of raw `NodeChange` fields.
  """

  alias Figler.Render.Shape.Arc
  alias Figler.Render.Shape.Polygon
  alias Figler.Render.Shape.Star

  @type t :: Polygon.t() | Star.t() | Arc.t() | nil

  @doc false
  @spec source_fields() :: [atom()]
  def source_fields, do: [:count, :star_inner_scale, :arc_data]

  @doc false
  @spec from_source(atom(), map()) :: t()
  def from_source(:regular_polygon, source) do
    %Polygon{point_count: Map.get(source, :count) || 5}
  end

  def from_source(:star, source) do
    %Star{
      point_count: Map.get(source, :count) || 5,
      inner_scale: Map.get(source, :star_inner_scale) || 0.38
    }
  end

  def from_source(:ellipse, %{arc_data: %Arc{} = arc}), do: arc
  def from_source(_node_type, _source), do: nil

  @doc false
  @spec issues(t()) :: [map()]
  def issues(%Polygon{point_count: count})
      when not is_integer(count) or count < 3 or count > 10_000,
      do: [%{code: :polygon_point_count_invalid, point_count: count}]

  def issues(%Star{point_count: count})
      when not is_integer(count) or count < 3 or count > 10_000,
      do: [%{code: :star_point_count_invalid, point_count: count}]

  def issues(%Star{inner_scale: scale}) when not is_number(scale) or scale <= 0 or scale >= 1,
    do: [%{code: :star_inner_scale_invalid, inner_scale: scale}]

  def issues(%Arc{} = arc) do
    cond do
      not finite_number?(arc.start_angle) or not finite_number?(arc.end_angle) ->
        [%{code: :arc_angles_invalid, start_angle: arc.start_angle, end_angle: arc.end_angle}]

      not finite_number?(arc.inner_radius) or arc.inner_radius < 0 or arc.inner_radius >= 1 ->
        [%{code: :arc_inner_radius_invalid, inner_radius: arc.inner_radius}]

      true ->
        []
    end
  end

  def issues(_shape), do: []

  @doc false
  @spec valid?(t()) :: boolean()
  def valid?(shape), do: issues(shape) == []

  @doc false
  @spec arc_from_sparse(map() | tuple() | nil) :: Arc.t() | nil
  def arc_from_sparse(nil), do: nil

  def arc_from_sparse(%{} = value) do
    %Arc{
      start_angle: Map.get(value, :starting_angle) || Map.get(value, "startingAngle") || 0.0,
      end_angle: Map.get(value, :ending_angle) || Map.get(value, "endingAngle") || 0.0,
      inner_radius: Map.get(value, :inner_radius) || Map.get(value, "innerRadius") || 0.0
    }
  end

  def arc_from_sparse({start_angle, end_angle, inner_radius}) do
    %Arc{start_angle: start_angle, end_angle: end_angle, inner_radius: inner_radius}
  end

  @doc false
  @spec finite_number?(term()) :: boolean()
  def finite_number?(value) when is_integer(value), do: true

  def finite_number?(value) when is_float(value) do
    :erlang.float_to_binary(value, [:compact]) not in ["inf", "-inf", "nan"]
  end

  def finite_number?(_value), do: false
end
