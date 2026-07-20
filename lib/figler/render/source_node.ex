defmodule Figler.Render.SourceNode do
  @moduledoc """
  Render-specific source metadata projected from a Figma `NodeChange`.

  This keeps generated schema structs and their hundreds of unrelated fields
  out of backend compilers.
  """

  alias Figler.Render.Effect
  alias Figler.Render.GeometryRef
  alias Figler.Render.Paint
  alias Figler.Render.Projection
  alias Figler.Render.Text.Measurement
  alias Figler.Render.Text.Source, as: TextSource
  alias Figler.Render.VectorNetwork.Ref, as: VectorNetworkRef
  alias Figler.Scene.Graph.GUID

  @field_names Projection.field_names()

  @enforce_keys [:guid]
  defstruct Projection.struct_fields()

  @type t :: %__MODULE__{
          guid: GUID.figma_guid(),
          node_type: String.t() | nil,
          name: String.t() | nil,
          text_data: map() | nil,
          blend_mode: atom() | nil,
          mask: boolean() | nil,
          mask_type: atom() | nil,
          effects: [Figler.Render.Effect.t()],
          fill_paints: [Figler.Render.Paint.t()],
          stroke_paints: [Figler.Render.Paint.t()],
          fill_geometry: [Figler.Render.GeometryRef.t()],
          stroke_geometry: [Figler.Render.GeometryRef.t()],
          vector_data: VectorNetworkRef.t() | nil,
          boolean_operation: atom() | nil,
          corner_radius: float() | nil,
          stroke_weight: float() | nil,
          frame_mask_disabled: boolean() | nil
        }

  @doc false
  def from_native(record) when is_tuple(record) and tuple_size(record) == length(@field_names) do
    attrs = @field_names |> Enum.zip(Tuple.to_list(record)) |> Map.new() |> normalize_attrs()
    struct!(__MODULE__, attrs)
  end

  @doc false
  def apply_overrides(%__MODULE__{} = source, effective_node) when is_map(effective_node) do
    Projection.override_field_names()
    |> Enum.reduce(source, fn field, effective ->
      case Map.fetch(effective_node, field) do
        {:ok, value} -> Map.put(effective, field, normalize_field(field, value))
        :error -> effective
      end
    end)
  end

  defp normalize_attrs(attrs) do
    Enum.reduce(@field_names, attrs, fn field, normalized ->
      Map.update!(normalized, field, &normalize_field(field, &1))
    end)
  end

  defp normalize_field(:text_data, value), do: TextSource.from_sparse(value)
  defp normalize_field(:vector_data, value), do: VectorNetworkRef.from_sparse(value)

  defp normalize_field(field, value)
       when field in [
              :line_height,
              :letter_spacing,
              :text_decoration_thickness,
              :text_underline_offset
            ],
       do: Measurement.from_sparse(value)

  defp normalize_field(:effects, values),
    do: Enum.map(values || [], &Effect.from_sparse/1)

  defp normalize_field(field, values)
       when field in [:fill_paints, :stroke_paints, :text_decoration_fill_paints],
       do: Enum.map(values || [], &Paint.from_sparse/1)

  defp normalize_field(field, values) when field in [:fill_geometry, :stroke_geometry],
    do: Enum.map(values || [], &GeometryRef.from_sparse/1)

  defp normalize_field(_field, value), do: value
end
