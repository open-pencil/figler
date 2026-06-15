defmodule FigKiwi.Scene.Projection do
  @moduledoc false

  @source_module FigKiwi.Schema.NodeChange
  @parent_index_source_module FigKiwi.Schema.ParentIndex
  @text_data_source_module FigKiwi.Schema.TextData
  @font_name_source_module FigKiwi.Schema.FontName
  @style_id_source_module FigKiwi.Schema.StyleId

  @fields [
    %{name: :guid, source: {:node_change, :guid}, required?: true, xpath_attrs: [:guid]},
    %{name: :node_type, source: {:node_change, :type}, required?: true, xpath_attrs: [:type]},
    %{name: :name, source: {:node_change, :name}, xpath_attrs: [:name]},
    %{name: :parent_guid, source: {:parent_index, :guid}, xpath_attrs: [:parent_guid]},
    %{name: :position, source: {:parent_index, :position}, xpath_attrs: [:position]},
    %{name: :size, source: {:node_change, :size}, xpath_attrs: [:x, :y, :width, :height]},
    %{name: :transform, source: {:node_change, :transform}, xpath_attrs: [:transform]},
    %{name: :visible, source: {:node_change, :visible}, xpath_attrs: [:visible]},
    %{name: :locked, source: {:node_change, :locked}, xpath_attrs: [:locked]},
    %{name: :text, source: {:text_data, :characters}, xpath_attrs: [:text]},
    %{name: :font_family, source: {:font_name, :family}, xpath_attrs: [:font_family]},
    %{name: :font_style, source: {:font_name, :style}, xpath_attrs: [:font_style]},
    %{name: :font_postscript, source: {:font_name, :postscript}, xpath_attrs: [:font_postscript]},
    %{name: :text_style_guid, source: {:style_id, :guid}, xpath_attrs: [:text_style_guid]},
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
    %{name: :fill_style_guid, source: {:style_id, :guid}, xpath_attrs: [:fill_style_guid]},
    %{name: :stroke_style_guid, source: {:style_id, :guid}, xpath_attrs: [:stroke_style_guid]},
    %{name: :effect_style_guid, source: {:style_id, :guid}, xpath_attrs: [:effect_style_guid]},
    %{name: :grid_style_guid, source: {:style_id, :guid}, xpath_attrs: [:grid_style_guid]},
    %{name: :fill_count, source: {:node_change, :fill_paints}, xpath_attrs: [:fill_count]},
    %{name: :stroke_count, source: {:node_change, :stroke_paints}, xpath_attrs: [:stroke_count]}
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
      function_exported?(module, :__kiwi_props__, 0),
      props = module.__kiwi_props__(),
      field <- fields do
    unless Map.has_key?(props.fields_by_name, field) do
      raise CompileError,
        description:
          "#{inspect(module)} is missing required scene projection field #{inspect(field)}"
    end
  end

  def source_module, do: @source_module
  def source_fields, do: @node_change_source_fields
  def parent_index_source_fields, do: @parent_index_source_fields
  def fields, do: @fields
  def field_names, do: Enum.map(@fields, & &1.name)

  def required_field_names,
    do: @fields |> Enum.filter(&Map.get(&1, :required?, false)) |> Enum.map(& &1.name)

  def xpath_attrs, do: @fields |> Enum.flat_map(&Map.get(&1, :xpath_attrs, [])) |> Enum.uniq()
end
