defmodule Figler.Scene.Graph.Occurrence.Claims do
  @moduledoc false

  # Applies property values onto an occurrence's effective record.

  alias Figler.Scene.Graph.Occurrence
  alias Figler.Scene.Graph.Occurrence.Fields

  @doc """
  The fields of a claim its owner keeps on `target`: an outer owner's
  assignment, recorded with a strictly smaller rank, supersedes the claim.
  """
  @spec retained(map(), Occurrence.t(), non_neg_integer()) :: map()
  def retained(props, %Occurrence{bound_fields: bound}, owner_rank) do
    Map.filter(props, fn {field, _value} -> Map.get(bound, field, owner_rank) >= owner_rank end)
  end

  @doc "Merges claimed fields into an occurrence's effective record."
  @spec apply(Occurrence.t(), map()) :: Occurrence.t()
  def apply(%Occurrence{} = target, props) do
    properties =
      target.properties
      |> invalidate_inherited_text(props)
      |> Map.merge(props)
      |> Map.merge(merge_variable_consumption(target.properties, props))

    %{
      target
      | properties: properties,
        has_own_name: target.has_own_name or Map.has_key?(props, :name)
    }
  end

  # Drops saved glyphs when a claim changes text or shaping and supplies none.
  defp invalidate_inherited_text(properties, %{derived_text_data: _glyphs}), do: properties

  defp invalidate_inherited_text(properties, patch) do
    if changed_text?(properties, patch) or changed_shaping?(properties, patch),
      do: Map.delete(properties, :derived_text_data),
      else: properties
  end

  defp changed_text?(properties, %{text_data: text}) when is_map(text) do
    source = Map.get(properties, :text_data) || %{}
    Enum.any?(text, fn {field, value} -> value != Map.get(source, field) end)
  end

  defp changed_text?(_properties, _patch), do: false

  defp changed_shaping?(properties, patch) do
    Enum.any?(Fields.text_shaping(), fn field ->
      Map.has_key?(patch, field) and Map.get(properties, field) != Map.get(patch, field)
    end)
  end

  @doc """
  Merges variable consumption entries, later entries replacing earlier ones for
  the same field. The result is written as the parameter map, which readers
  consult after the legacy map.
  """
  @spec merge_variable_consumption(map(), map()) :: map()
  def merge_variable_consumption(base, patch) do
    case consumption_entries(patch) do
      [] ->
        %{}

      incoming ->
        %{
          parameter_consumption_map: %{
            entries: dedupe_by_field(consumption_entries(base) ++ incoming)
          }
        }
    end
  end

  # Entries keep the position of a field's first entry and the value of its last.
  defp dedupe_by_field(entries) do
    last = Map.new(entries, &{Map.get(&1, :variable_field), &1})

    {kept, _seen} =
      Enum.reduce(entries, {[], MapSet.new()}, fn entry, {kept, seen} ->
        case Map.get(entry, :variable_field) do
          nil -> {[entry | kept], seen}
          field -> keep_field(field, last, kept, seen)
        end
      end)

    Enum.reverse(kept)
  end

  defp keep_field(field, last, kept, seen) do
    if MapSet.member?(seen, field),
      do: {kept, seen},
      else: {[Map.fetch!(last, field) | kept], MapSet.put(seen, field)}
  end

  # Legacy entries precede parameter entries, which may replace them per field.
  # Unkeyed entries come first, then one entry per field in first-seen order.
  defp consumption_entries(record) do
    legacy = get_in(record, [:variable_consumption_map, :entries]) || []
    parameters = get_in(record, [:parameter_consumption_map, :entries]) || []

    {unkeyed, keyed} =
      Enum.split_with(legacy ++ parameters, &is_nil(Map.get(&1, :variable_field)))

    unkeyed ++ dedupe_by_field(keyed)
  end
end
