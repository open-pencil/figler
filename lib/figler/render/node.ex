defmodule Figler.Render.Node do
  @moduledoc """
  Rendering-neutral effective node consumed by backend compilers.

  Graph hierarchy, transforms, text, and visibility are joined with normalized
  source paints, geometry, effects, masks, and rich instance overrides before a
  backend sees the scene.
  """

  alias Figler.Render.SourceNode
  alias Figler.Render.Text
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node, as: SceneNode
  alias Figler.Schema.NodeType

  @node_types NodeType.__kiwi_metadata__().enum_by_name |> Map.keys() |> MapSet.new()
  @node_types_by_name Map.new(@node_types, &{Atom.to_string(&1), &1})

  @graph_fields [
    :node_type,
    :name,
    :size,
    :transform,
    :visible,
    :opacity
  ]

  @source_fields [
                   :text_data,
                   :blend_mode,
                   :mask,
                   :mask_type,
                   :effects,
                   :fill_paints,
                   :stroke_paints,
                   :fill_geometry,
                   :stroke_geometry,
                   :vector_data,
                   :boolean_operation,
                   :corner_radius,
                   :stroke_weight,
                   :frame_mask_disabled
                 ] ++ Text.source_fields()

  @enforce_keys [:guid, :source_guid, :node_type]
  defstruct [
    :guid,
    :source_guid,
    :node_type,
    :name,
    :size,
    :transform,
    :visible,
    :opacity,
    :text,
    :vector_network,
    :blend_mode,
    :mask,
    :mask_type,
    :boolean_operation,
    :corner_radius,
    :stroke_weight,
    :frame_mask_disabled,
    effects: [],
    fill_paints: [],
    stroke_paints: [],
    fill_geometry: [],
    stroke_geometry: []
  ]

  @type t :: %__MODULE__{
          guid: GUID.graph_guid(),
          source_guid: GUID.figma_guid(),
          node_type: NodeType.t() | :unknown,
          name: String.t() | nil,
          size: map() | nil,
          transform: map() | nil,
          visible: boolean() | nil,
          opacity: float() | nil,
          text: Text.t() | nil,
          vector_network: Figler.Render.VectorNetwork.Ref.t() | nil,
          blend_mode: atom() | nil,
          mask: boolean() | nil,
          mask_type: atom() | nil,
          effects: [Figler.Render.Effect.t()],
          fill_paints: [Figler.Render.Paint.t()],
          stroke_paints: [Figler.Render.Paint.t()],
          fill_geometry: [Figler.Render.GeometryRef.t()],
          stroke_geometry: [Figler.Render.GeometryRef.t()],
          boolean_operation: atom() | nil,
          corner_radius: float() | nil,
          stroke_weight: float() | nil,
          frame_mask_disabled: boolean() | nil
        }

  @doc false
  @spec from_effective(SceneNode.t(), GUID.figma_guid(), SourceNode.t() | nil) :: t()
  def from_effective(%SceneNode{} = graph_node, source_guid, source) do
    node_type = normalize_node_type(graph_node.node_type)
    {text_source, source_attrs} = source |> source_attrs(graph_node) |> Map.pop(:text_data)
    {vector_network, source_attrs} = Map.pop(source_attrs, :vector_data)
    {text_attrs, source_attrs} = Map.split(source_attrs, Text.source_fields())
    text_node = graph_node |> Map.from_struct() |> Map.merge(text_attrs)

    attrs =
      graph_node
      |> Map.take(@graph_fields)
      |> Map.merge(source_attrs)
      |> Map.merge(%{
        guid: graph_node.guid,
        source_guid: source_guid,
        node_type: node_type,
        vector_network: vector_network,
        text:
          Text.from_effective(
            text_node,
            node_type,
            text_source,
            Map.get(source_attrs, :fill_paints, [])
          )
      })

    struct!(__MODULE__, attrs)
  end

  defp normalize_node_type(type) when is_atom(type) do
    if MapSet.member?(@node_types, type), do: type, else: :unknown
  end

  defp normalize_node_type(type) when is_binary(type),
    do: Map.get(@node_types_by_name, type, :unknown)

  defp normalize_node_type(_type), do: :unknown

  defp source_attrs(nil, _graph_node), do: %{}

  defp source_attrs(%SourceNode{} = source, graph_node) do
    source
    |> SourceNode.apply_overrides(graph_node)
    |> Map.take(@source_fields)
  end
end
