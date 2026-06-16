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
    %{
      name: :size,
      source: {:node_change, :size},
      xpath_attrs: [:x, :y, :width, :height],
      value: :vector
    },
    %{
      name: :transform,
      source: {:node_change, :transform},
      xpath_attrs: [:transform],
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
      function_exported?(module, :__kiwi_props__, 0),
      props = module.__kiwi_props__(),
      field <- fields do
    unless Map.has_key?(props.fields_by_name, field) do
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

  def style_id_field(name), do: Map.fetch!(@style_id_fields, name)

  def rust_type(:size), do: "Option<SceneSize>"
  def rust_type(:transform), do: "Option<SceneTransform>"
  def rust_type(field) when field in [:visible, :locked], do: "Option<bool>"
  def rust_type(field) when field in [:opacity, :font_size], do: "Option<f32>"
  def rust_type(field) when field in [:fill_count, :stroke_count], do: "Option<usize>"
  def rust_type(_field), do: "Option<String>"

  def rust_copy?(field),
    do: field in [:visible, :locked, :opacity, :font_size, :fill_count, :stroke_count]

  def xpath_attr_entries(:size) do
    [
      {:size, "x", "value.x.to_string()", []},
      {:size, "y", "value.y.to_string()", []},
      {:size, "width", "value.x.to_string()", []},
      {:size, "height", "value.y.to_string()", []}
    ]
  end

  def xpath_attr_entries(:transform) do
    [
      {:transform, "transform",
       "format!(\"{},{},{},{},{},{}\", value.m00, value.m01, value.m02, value.m10, value.m11, value.m12)",
       []}
    ]
  end

  def xpath_attr_entries(:parent_guid),
    do: [{:parent_guid, "parent_guid", "value.to_string()", []}]

  def xpath_attr_entries(field) do
    value_expr = if rust_copy?(field), do: "value.to_string()", else: "value.clone()"
    opts = if rust_copy?(field), do: [by_ref?: false], else: []
    [{field, Atom.to_string(field), value_expr, opts}]
  end

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
