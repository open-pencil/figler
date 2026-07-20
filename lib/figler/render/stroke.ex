defmodule Figler.Render.Stroke do
  @moduledoc "Rendering-neutral stroke geometry and styling metadata."

  alias Figler.Render.Text.Measurement

  @source_fields [
    :stroke_weight,
    :stroke_align,
    :stroke_cap,
    :stroke_cap_size,
    :stroke_join,
    :miter_limit,
    :dash_pattern
  ]

  defstruct [
    :weight,
    :align,
    :cap,
    :cap_size,
    :join,
    :miter_limit,
    dash_pattern: []
  ]

  @type t :: %__MODULE__{
          weight: float() | nil,
          align: atom() | nil,
          cap: atom() | nil,
          cap_size: Measurement.t() | nil,
          join: atom() | nil,
          miter_limit: float() | nil,
          dash_pattern: [float()]
        }

  @doc false
  @spec source_fields() :: [atom()]
  def source_fields, do: @source_fields

  @doc false
  @spec from_effective(map()) :: t()
  def from_effective(attrs) do
    %__MODULE__{
      weight: Map.get(attrs, :stroke_weight),
      align: Map.get(attrs, :stroke_align),
      cap: Map.get(attrs, :stroke_cap),
      cap_size: Map.get(attrs, :stroke_cap_size),
      join: Map.get(attrs, :stroke_join),
      miter_limit: Map.get(attrs, :miter_limit),
      dash_pattern: Map.get(attrs, :dash_pattern) || []
    }
  end

  @doc false
  @spec skia_cap(t()) :: :butt | :round | :square
  def skia_cap(%__MODULE__{cap: :round}), do: :round
  def skia_cap(%__MODULE__{cap: :square}), do: :square
  def skia_cap(_stroke), do: :butt

  @doc false
  @spec supported_cap?(t()) :: boolean()
  def supported_cap?(%__MODULE__{cap: cap}), do: cap in [nil, :none, :round, :square]

  @doc false
  @spec valid_dash_pattern?(t()) :: boolean()
  def valid_dash_pattern?(%__MODULE__{dash_pattern: []}), do: true

  def valid_dash_pattern?(%__MODULE__{dash_pattern: pattern}) do
    rem(length(pattern), 2) == 0 and Enum.all?(pattern, &(is_number(&1) and &1 > 0))
  end
end
