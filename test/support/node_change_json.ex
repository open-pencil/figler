defmodule Figler.Test.NodeChangeJSON do
  @moduledoc """
  Converts OpenPencil's decoded `NodeChange` JSON fixtures into Figler's sparse
  record shape: snake_case field atoms, lowercase enum atoms, and GUID maps.

  Field and enum types come from the generated schema modules, so plain strings
  such as names are never mistaken for enum values.
  """

  @spec read!(Path.t()) :: [map()]
  def read!(path), do: path |> File.read!() |> JSON.decode!() |> Enum.map(&record/1)

  @spec record(map()) :: map()
  def record(json), do: convert(json, Figler.Schema.NodeChange)

  defp convert(json, module) when is_map(json) do
    fields = Map.new(module.__kiwi_metadata__().ordered_fields, &{&1.source_name, &1})

    Map.new(json, fn {key, value} ->
      case Map.fetch(fields, key) do
        {:ok, field} -> {field.name, value(value, field.type)}
        :error -> {String.to_existing_atom(Macro.underscore(key)), value}
      end
    end)
  end

  defp value(values, type) when is_list(values), do: Enum.map(values, &value(&1, type))

  defp value(value, {:enum, module}) when is_binary(value) do
    name = String.downcase(value)
    Enum.find(Map.keys(module.__kiwi_metadata__().enum_by_name), &(Atom.to_string(&1) == name))
  end

  defp value(value, module) when is_map(value) and is_atom(module) do
    if KiwiCodec.PrimitiveType.atom?(module), do: value, else: convert(value, module)
  end

  defp value(value, _type), do: value
end
