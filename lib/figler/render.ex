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
  alias Figler.Render.Options
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
    with :ok <- Options.validate(opts),
         {:ok, document} <- Document.open(input) do
      prepare_document(document, opts)
    end
  end

  @spec prepare(Document.t(), keyword()) :: {:ok, RenderScene.t()} | {:error, term()}
  def prepare(%Document{} = document, opts) when is_list(opts) do
    with :ok <- Options.validate(opts), do: prepare_document(document, opts)
  end

  @doc """
  Renders a `.fig` input with the Skia backend.

  Rendering uses effective normalized metadata for hierarchy, instance
  overrides, paints, geometry, effects, masks, text, fonts, and compositing.
  Unsupported or approximate features—including unavailable fonts, missing
  glyph coverage, and substitutions—are returned as warnings, or as an error
  with `strict: true`. Deterministic caller-provided fallback fonts can be passed
  with `:fallback_font_paths` or `:fallback_typefaces`.

  Public options are documented by `Figler.Render.Options`. Unknown or malformed
  options return `{:error, {:invalid_render_options, errors}}`. Non-finite or
  oversized output bounds return `{:error, {:invalid_render_bounds, context}}`
  before a canvas is allocated. Rendering without the optional Skia dependency
  returns `{:error, :skia_not_available}`.
  """
  @spec render(binary() | Document.t() | RenderScene.t(), keyword()) ::
          {:ok, binary() | map(), map()} | {:error, term()}
  def render(input, opts \\ [])

  def render(input, opts)
      when (is_binary(input) or is_struct(input, Document)) and is_list(opts) do
    with {:ok, scene} <- prepare(input, opts), do: render_selected(scene, opts)
  end

  def render(%RenderScene{} = scene, opts) when is_list(opts) do
    with :ok <- Options.validate(opts) do
      if Code.ensure_loaded?(Skia),
        do: render_prepared(scene, opts),
        else: {:error, :skia_not_available}
    end
  end

  defp prepare_document(document, opts) do
    graph_opts = Keyword.get(opts, :graph, [])
    graph = Graph.build({document.payload, document.schema}, graph_opts)

    with {:ok, root} <- Selection.root(graph, document.pages, opts) do
      source_nodes =
        {document.payload, document.schema}
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

  # Render fields come from the source record, with the occurrence's effective
  # record applied over them.
  defp effective_render_nodes(graph, source_nodes) do
    Map.new(graph.nodes, fn {guid, node} ->
      source_guid = Graph.provenance(graph, guid).source_guid

      source =
        case Map.get(source_nodes, source_guid) do
          nil -> nil
          source -> SourceNode.apply_overrides(source, Map.get(graph.records, guid, %{}))
        end

      {guid, RenderNode.from_effective(node, source_guid, source)}
    end)
  end

  defp projection_root(graph, root), do: Graph.provenance(graph, root).source_guid

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
