defmodule Figler.Scene.Projection do
  @moduledoc """
  Field projection table for native scene records.

  The projection describes which generated `Figler.Schema.NodeChange` fields
  are decoded into lightweight scene nodes, how each value is represented, and
  which names are exposed to XPath attribute filters.
  """

  @source_module Figler.Schema.NodeChange
  @parent_index_source_module Figler.Schema.ParentIndex
  @text_data_source_module Figler.Schema.TextData
  @font_name_source_module Figler.Schema.FontName
  @style_id_source_module Figler.Schema.StyleId

  @fields [
    %{name: :guid, source: {:node_change, :guid}, required?: true, xpath_attrs: [:guid]},
    %{name: :node_type, source: {:node_change, :type}, required?: true, xpath_attrs: [:type]},
    %{name: :name, source: {:node_change, :name}, xpath_attrs: [:name]},
    %{
      name: :parent_guid,
      source: {:parent_index, :guid},
      xpath_attrs: [:parent_guid],
      xpath_value: :value_to_string
    },
    %{name: :position, source: {:parent_index, :position}, xpath_attrs: [:position]},
    %{
      name: :size,
      source: {:node_change, :size},
      xpath_attrs: [:x, :y, :width, :height],
      xpath_values: [
        x: {:field_to_string, :x},
        y: {:field_to_string, :y},
        width: {:field_to_string, :x},
        height: {:field_to_string, :y}
      ],
      value: :vector
    },
    %{
      name: :transform,
      source: {:node_change, :transform},
      xpath_attrs: [:transform],
      xpath_value: :transform_string,
      value: :matrix
    },
    %{name: :visible, source: {:node_change, :visible}, xpath_attrs: [:visible], decode: :bool},
    %{name: :locked, source: {:node_change, :locked}, xpath_attrs: [:locked], decode: :bool},
    %{name: :opacity, source: {:node_change, :opacity}, xpath_attrs: [:opacity], decode: :float},
    %{name: :text, source: {:text_data, :characters}, xpath_attrs: [:text], decode: :text_data},
    %{
      name: :font_family,
      source: {:font_name, :family},
      xpath_attrs: [:font_family],
      decode: :font_name
    },
    %{
      name: :font_style,
      source: {:font_name, :style},
      xpath_attrs: [:font_style],
      decode: :font_name
    },
    %{
      name: :font_postscript,
      source: {:font_name, :postscript},
      xpath_attrs: [:font_postscript],
      decode: :font_name
    },
    %{
      name: :font_size,
      source: {:node_change, :font_size},
      xpath_attrs: [:font_size],
      decode: :float
    },
    %{
      name: :text_style_guid,
      source: {:style_id, :guid},
      xpath_attrs: [:text_style_guid],
      value: :style_guid
    },
    %{
      name: :component_key,
      source: {:node_change, :component_key},
      xpath_attrs: [:component_key]
    },
    %{
      name: :origin_component_key,
      source: {:node_change, :origin_component_key},
      xpath_attrs: [:origin_component_key]
    },
    %{
      name: :fill_style_guid,
      source: {:style_id, :guid},
      xpath_attrs: [:fill_style_guid],
      value: :style_guid
    },
    %{
      name: :stroke_style_guid,
      source: {:style_id, :guid},
      xpath_attrs: [:stroke_style_guid],
      value: :style_guid
    },
    %{
      name: :effect_style_guid,
      source: {:style_id, :guid},
      xpath_attrs: [:effect_style_guid],
      value: :style_guid
    },
    %{
      name: :grid_style_guid,
      source: {:style_id, :guid},
      xpath_attrs: [:grid_style_guid],
      value: :style_guid
    },
    %{
      name: :fill_count,
      source: {:node_change, :fill_paints},
      xpath_attrs: [:fill_count],
      value: :count,
      decode: :counted_paints
    },
    %{
      name: :stroke_count,
      source: {:node_change, :stroke_paints},
      xpath_attrs: [:stroke_count],
      value: :count,
      decode: :counted_paints
    }
  ]

  @node_change_source_fields @fields
                             |> Enum.flat_map(fn
                               %{source: {:node_change, field}} -> [field]
                               %{source: {:parent_index, _}} -> [:parent_index]
                               %{source: {:text_data, _}} -> [:text_data]
                               %{source: {:font_name, _}} -> [:font_name]
                               %{name: :fill_style_guid} -> [:style_id_for_fill]
                               %{name: :stroke_style_guid} -> [:style_id_for_stroke_fill]
                               %{name: :effect_style_guid} -> [:style_id_for_effect]
                               %{name: :grid_style_guid} -> [:style_id_for_grid]
                               %{source: {:style_id, _}} -> [:style_id_for_text]
                             end)
                             |> Enum.uniq()

  @parent_index_source_fields [:guid, :position]
  @text_data_source_fields [:characters]
  @font_name_source_fields [:family, :style, :postscript]
  @style_id_source_fields [:guid]

  @schema_checks [
    {@source_module, @node_change_source_fields},
    {@parent_index_source_module, @parent_index_source_fields},
    {@text_data_source_module, @text_data_source_fields},
    {@font_name_source_module, @font_name_source_fields},
    {@style_id_source_module, @style_id_source_fields}
  ]

  for {module, fields} <- @schema_checks,
      Code.ensure_loaded?(module),
      function_exported?(module, :__kiwi_metadata__, 0),
      metadata = module.__kiwi_metadata__(),
      field <- fields do
    unless Map.has_key?(metadata.fields_by_name, field) do
      raise CompileError,
        description:
          "#{inspect(module)} is missing required scene projection field #{inspect(field)}"
    end
  end

  @style_id_fields %{
    text_style_guid: :style_id_for_text,
    fill_style_guid: :style_id_for_fill,
    stroke_style_guid: :style_id_for_stroke_fill,
    effect_style_guid: :style_id_for_effect,
    grid_style_guid: :style_id_for_grid
  }

  def source_module, do: @source_module
  def source_fields, do: @node_change_source_fields
  def parent_index_source_fields, do: @parent_index_source_fields
  def fields, do: @fields
  def field_names, do: Enum.map(@fields, & &1.name)

  def field!(name) do
    Enum.find(@fields, &(&1.name == name)) ||
      raise ArgumentError, "unknown scene projection field: #{inspect(name)}"
  end

  def style_id_field(name), do: Map.fetch!(@style_id_fields, name)

  def source_name(field) when is_atom(field) do
    field
    |> Atom.to_string()
    |> Macro.camelize()
    |> then(fn <<first::binary-size(1), rest::binary>> -> String.downcase(first) <> rest end)
  end

  def source_name(%{name: name, source: {:style_id, :guid}}),
    do: name |> style_id_field() |> source_name()

  def source_name(%{source: {:node_change, field}}), do: source_name(field)
  def source_name(%{source: {:parent_index, _field}}), do: source_name(:parent_index)
  def source_name(%{source: {:text_data, _field}}), do: source_name(:text_data)
  def source_name(%{source: {:font_name, _field}}), do: source_name(:font_name)

  def required_field_names,
    do: @fields |> Enum.filter(&Map.get(&1, :required?, false)) |> Enum.map(& &1.name)

  def xpath_attrs, do: @fields |> Enum.flat_map(&Map.get(&1, :xpath_attrs, [])) |> Enum.uniq()
end
