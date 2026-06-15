defmodule FigKiwi.Scene.Graph.Oracle.Node do
  @moduledoc false

  use JSONCodec, case: :camel, fast_path: :json

  defstruct [
    :guid,
    :type,
    :name,
    :visible,
    :locked,
    :x,
    :y,
    :width,
    :height,
    :characters,
    :parent,
    child_count: 0,
    children: []
  ]

  @type number_or_nil :: number() | nil

  @type t :: %__MODULE__{
          guid: String.t() | nil,
          type: String.t() | nil,
          name: String.t() | nil,
          visible: boolean() | nil,
          locked: boolean() | nil,
          x: number_or_nil(),
          y: number_or_nil(),
          width: number_or_nil(),
          height: number_or_nil(),
          characters: String.t() | nil,
          parent: String.t() | nil,
          child_count: non_neg_integer(),
          children: [map()]
        }

  codec(:children, transform: :children_from_maps)

  def children_from_maps(children) when is_list(children), do: Enum.map(children, &from_map!/1)
end
