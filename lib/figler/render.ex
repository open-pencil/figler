defmodule Figler.Render do
  @compile {:no_warn_undefined, [Skia]}

  @moduledoc """
  Prepares effective `.fig` scenes and renders them through optional backends.

  Rendering uses `Figler.Scene.Graph` for resolved hierarchy and instance
  semantics, then joins effective nodes with a root-focused native projection
  of paint and shape metadata.
  """

  alias Figler.Document
  alias Figler.Native.CodecNifs
  alias Figler.Render.Node, as: RenderNode
  alias Figler.Render.Scene, as: RenderScene
  alias Figler.Render.Selection
  alias Figler.Render.Skia, as: SkiaBackend
  alias Figler.Render.SourceNode
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID

  @doc """
  Decodes an input and prepares a rendering-neutral effective scene.

  An already-opened `Figler.Document` can be reused to avoid decoding the
  archive and message again.
  """
  @spec prepare(binary() | Document.t(), keyword()) :: {:ok, RenderScene.t()} | {:error, term()}
  def prepare(input, opts \\ [])

  def prepare(input, opts) when is_binary(input) and is_list(opts) do
    with {:ok, document} <- Document.open(input) do
      prepare_document(document, opts)
    end
  end

  @spec prepare(Document.t(), keyword()) :: {:ok, RenderScene.t()}
  def prepare(%Document{} = document, opts) when is_list(opts) do
    prepare_document(document, opts)
  end

  @doc """
  Renders a `.fig` input with the Skia backend.

  Rendering uses effective normalized metadata for hierarchy, instance
  overrides, paints, geometry, effects, masks, text, fonts, and compositing.
  Unsupported or approximate features—including unavailable fonts and missing
  glyph coverage—are returned as warnings, or as an error with `strict: true`.
  """
  @spec render(binary() | Document.t() | RenderScene.t(), keyword()) ::
          {:ok, binary() | map(), map()} | {:error, term()}
  def render(input, opts \\ [])

  def render(input, opts)
      when (is_binary(input) or is_struct(input, Document)) and is_list(opts) do
    with {:ok, scene} <- prepare(input, opts), do: render_selected(scene, opts)
  end

  def render(%RenderScene{} = scene, opts) when is_list(opts) do
    if Code.ensure_loaded?(Skia),
      do: render_prepared(scene, opts),
      else: {:error, :skia_not_available}
  end

  defp prepare_document(document, opts) do
    graph_opts = Keyword.get(opts, :graph, [])
    graph = Graph.build(document.payload, graph_opts)

    with {:ok, root} <- Selection.root(graph, document.pages, opts) do
      source_nodes =
        document.payload
        |> CodecNifs.decode_render_source_nodes([projection_root(graph, root) |> GUID.format()])
        |> Map.new(fn record ->
          source = SourceNode.from_native(record)
          {source.guid, source}
        end)

      render_nodes = effective_render_nodes(graph, source_nodes)

      {:ok,
       %RenderScene{
         document: document,
         payload: document.payload,
         graph: graph,
         root: root,
         children: graph.children,
         source_nodes: source_nodes,
         render_nodes: render_nodes
       }}
    end
  end

  defp effective_render_nodes(graph, source_nodes) do
    Map.new(graph.nodes, fn {guid, node} ->
      source_guid =
        graph.provenance
        |> Map.get(guid, %{})
        |> Map.get(:source_guid, guid)

      source = Map.get(source_nodes, source_guid)
      {guid, RenderNode.from_effective(node, source_guid, source)}
    end)
  end

  defp projection_root(graph, root) do
    graph.provenance
    |> Map.get(root, %{})
    |> Map.get(:source_guid, root)
  end

  defp render_selected(scene, opts) do
    if Code.ensure_loaded?(Skia),
      do: render_with_skia(scene, opts),
      else: {:error, :skia_not_available}
  end

  defp render_prepared(scene, opts) do
    if Keyword.has_key?(opts, :root) or Keyword.has_key?(opts, :page) do
      with {:ok, selected} <- prepare(scene.document, opts), do: render_with_skia(selected, opts)
    else
      render_with_skia(scene, opts)
    end
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
