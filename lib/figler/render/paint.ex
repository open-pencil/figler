defmodule Figler.Render.Paint.Image do
  @moduledoc "Normalized image reference used by an image paint."

  defstruct [:hash, :data_blob, :name]

  @type t :: %__MODULE__{
          hash: binary() | [byte()] | nil,
          data_blob: non_neg_integer() | nil,
          name: String.t() | nil
        }

  @doc false
  def from_sparse(nil), do: nil

  def from_sparse(value) when is_map(value) do
    struct(__MODULE__, Map.take(value, [:hash, :data_blob, :name]))
  end
end

defmodule Figler.Render.Paint.Stop do
  @moduledoc "Normalized positioned gradient stop."

  alias Figler.Render.Color

  defstruct [:color, :position]

  @type t :: %__MODULE__{color: Figler.Render.Color.t() | nil, position: float() | nil}

  @doc false
  def from_sparse(value) when is_map(value) do
    %__MODULE__{
      color: Color.from_sparse(Map.get(value, :color)),
      position: Map.get(value, :position)
    }
  end
end

defmodule Figler.Render.Paint do
  @moduledoc "Rendering-neutral normalized Figma paint."

  alias Figler.Render.Color
  alias Figler.Render.Matrix
  alias Figler.Render.Paint.Image
  alias Figler.Render.Paint.Stop

  defstruct [
    :type,
    :color,
    :opacity,
    :visible,
    :blend_mode,
    :transform,
    :image,
    :image_scale_mode,
    :filter_color_adjust,
    :paint_filter,
    :rotation,
    :scale,
    stops: []
  ]

  @type t :: %__MODULE__{
          type: atom() | integer() | nil,
          color: Figler.Render.Color.t() | nil,
          opacity: float() | nil,
          visible: boolean() | nil,
          blend_mode: atom() | nil,
          stops: [Stop.t()],
          transform: Matrix.t() | nil,
          image: Image.t() | nil,
          image_scale_mode: atom() | nil,
          filter_color_adjust: map() | nil,
          paint_filter: map() | nil,
          rotation: float() | nil,
          scale: float() | nil
        }

  @doc false
  def from_sparse(value) when is_map(value) do
    %__MODULE__{
      type: Map.get(value, :type),
      color: Color.from_sparse(Map.get(value, :color)),
      opacity: Map.get(value, :opacity),
      visible: Map.get(value, :visible),
      blend_mode: Map.get(value, :blend_mode),
      stops: Enum.map(Map.get(value, :stops) || [], &Stop.from_sparse/1),
      transform: Matrix.from_sparse(Map.get(value, :transform)),
      image: Image.from_sparse(Map.get(value, :image)),
      image_scale_mode: Map.get(value, :image_scale_mode),
      filter_color_adjust: plain_map(Map.get(value, :filter_color_adjust)),
      paint_filter: plain_map(Map.get(value, :paint_filter)),
      rotation: Map.get(value, :rotation),
      scale: Map.get(value, :scale)
    }
  end

  defp plain_map(nil), do: nil
  defp plain_map(value), do: Map.delete(value, :__kiwi_module__)
end
