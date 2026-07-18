defmodule Figler.Render do
  @compile {:no_warn_undefined, [Skia]}

  @moduledoc """
  Prepares effective `.fig` scenes and renders them through optional backends.

  Rendering uses `Figler.Scene.Graph` for resolved hierarchy and instance
  semantics, then joins effective nodes with generated source `NodeChange`
  values for paint and shape metadata.
  """

  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Render.Skia, as: SkiaBackend
  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID

  @doc """
  Decodes an input and prepares a rendering-neutral effective scene.
  """
  @spec prepare(binary(), keyword()) :: {:ok, RenderScene.t()}
  def prepare(input, opts \\ []) when is_binary(input) and is_list(opts) do
    payload = Scene.payload!(input)
    message = Figler.decode_message(payload)
    graph_opts = Keyword.get(opts, :graph, [])
    graph = Graph.build(payload, graph_opts)

    source_nodes =
      Map.new(message.node_changes, fn node ->
        {GUID.from_schema(node.guid), node}
      end)

    {:ok,
     %RenderScene{
       payload: payload,
       message: message,
       graph: graph,
       source_nodes: source_nodes
     }}
  end

  @doc """
  Renders a `.fig` input with the Skia backend.

  Phase-one rendering supports effective hierarchy, affine transforms, opacity,
  rectangular clipping, solid fills and strokes, rectangles, ellipses, lines,
  and basic text. Unsupported visible paints are returned as warnings, or as an
  error with `strict: true`.
  """
  @spec render(binary() | RenderScene.t(), keyword()) ::
          {:ok, binary() | map(), map()} | {:error, term()}
  def render(input, opts \\ [])

  def render(input, opts) when is_binary(input) and is_list(opts) do
    with {:ok, scene} <- prepare(input, opts) do
      render(scene, opts)
    end
  end

  def render(%RenderScene{} = scene, opts) when is_list(opts) do
    if Code.ensure_loaded?(Skia),
      do: render_with_skia(scene, opts),
      else: {:error, :skia_not_available}
  end

  defp render_with_skia(scene, opts) do
    with {:ok, result} <- SkiaBackend.compile(scene, opts),
         {:ok, rendered} <- Skia.render(result.document, render_options(opts)) do
      {:ok, rendered, Map.delete(result, :document)}
    end
  end

  defp render_options(opts) do
    [
      format: Keyword.get(opts, :format, :png),
      quality: Keyword.get(opts, :quality)
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end
end
