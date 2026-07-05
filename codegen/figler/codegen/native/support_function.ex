defmodule Figler.Codegen.Native.SupportFunction.OptionalRecordAttrs do
  @moduledoc false

  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias Figler.Scene.Projection.Native.XPathAttr
  alias Figler.Scene.Projection.Native.XPathValue

  defmacro defrust_functions do
    attrs =
      Projection.field_names()
      |> Kernel.--(Projection.required_field_names())
      |> Enum.flat_map(&ProjectionNative.xpath_attr_entries/1)

    names = optional_attr_function_names(length(attrs))

    functions =
      attrs
      |> Enum.with_index()
      |> Enum.map(fn {%XPathAttr{} = attr, index} ->
        optional_attr_function(attr, Enum.at(names, index), Enum.at(names, index + 1))
      end)

    {:__block__, [], functions ++ [optional_attr_base_function(List.last(names))]}
  end

  defp optional_attr_function_names(count) do
    for index <- 0..count do
      String.to_atom("scene_node_record_optional_attr_#{index}")
    end
  end

  defp optional_attr_function(%XPathAttr{} = attr, name, next_name) do
    accessor = xpath_accessor(attr)
    value = xpath_value(attr.value)

    quote do
      @spec unquote(name)(RustQ.Type.ref(RustQ.Type.raw(:SceneNodeRecord)), RustQ.Type.usize()) ::
              RustQ.Type.raw(:"Option<(&'static str, String)>")
      defrust unquote(name)(record, index) do
        case unquote(accessor) do
          {:some, value} ->
            if index == 0 do
              some({unquote(attr.attr), unquote(value)})
            else
              unquote(next_name)(record, index - 1)
            end

          :none ->
            unquote(next_name)(record, index)
        end
      end
    end
  end

  defp optional_attr_base_function(name) do
    quote do
      @spec unquote(name)(RustQ.Type.ref(RustQ.Type.raw(:SceneNodeRecord)), RustQ.Type.usize()) ::
              RustQ.Type.raw(:"Option<(&'static str, String)>")
      defrust unquote(name)(_record, _index) do
        nil
      end
    end
  end

  defp xpath_accessor(%XPathAttr{by_ref?: true, field: field}) do
    quote do
      record.unquote(field).as_ref()
    end
  end

  defp xpath_accessor(%XPathAttr{by_ref?: false, field: field}) do
    quote do
      record.unquote(field)
    end
  end

  defp xpath_value(%XPathValue{kind: :field_to_string, field: field}) do
    quote do
      value.unquote(field).to_string()
    end
  end

  defp xpath_value(%XPathValue{kind: :value_to_string}) do
    quote do
      value.to_string()
    end
  end

  defp xpath_value(%XPathValue{kind: :value_clone}) do
    quote do
      value.clone()
    end
  end

  defp xpath_value(%XPathValue{kind: :transform_string}) do
    quote do
      format!(
        "{},{},{},{},{},{}",
        value.m00,
        value.m01,
        value.m02,
        value.m10,
        value.m11,
        value.m12
      )
    end
  end
end

defmodule Figler.Codegen.Native.SupportFunction do
  use RustQ.Meta,
    rust_sources: [
      "native/src/runtime.rs",
      "native/src/templates/graph_focus_decoders.rs"
    ]

  @moduledoc """
  Generated Rust support functions for Figler native codegen.

  These helpers become ordinary Rust functions in the generated native module.
  They are authored with semantic Rusty-Elixir/`defrust`; schema/template splice
  rendering belongs in the neighboring codegen modules.
  """

  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias Figler.Codegen.Native.SupportFunction.OptionalRecordAttrs
  alias RustQ.Meta.AST, as: MetaAST
  alias RustQ.Type, as: R

  require OptionalRecordAttrs

  defrustmod(SceneXpathRuntime, as: :scene_xpath_runtime)

  @type decoder :: R.mut_ref(R.path(:Decoder, R.lifetime(:_)))
  @type graph_focus_guid :: term()
  @type scene_query_node :: R.path(:SceneQueryNode)
  @type scene_size :: %{
          required(:x) => R.f64(),
          required(:y) => R.f64()
        }

  @type scene_transform :: %{
          required(:m00) => R.f64(),
          required(:m01) => R.f64(),
          required(:m02) => R.f64(),
          required(:m10) => R.f64(),
          required(:m11) => R.f64(),
          required(:m12) => R.f64()
        }

  @scene_query_atom_vars %{
    name: :NAME_ATOM,
    parent_guid: :PARENT_GUID_ATOM,
    position: :POSITION_ATOM,
    size: :SIZE_ATOM,
    transform: :TRANSFORM_ATOM,
    visible: :VISIBLE_ATOM,
    locked: :LOCKED_ATOM,
    opacity: :OPACITY_ATOM,
    text: :TEXT_ATOM,
    font_family: :FONT_FAMILY_ATOM,
    font_style: :FONT_STYLE_ATOM,
    font_postscript: :FONT_POSTSCRIPT_ATOM,
    font_size: :FONT_SIZE_ATOM,
    text_style_guid: :TEXT_STYLE_GUID_ATOM,
    component_key: :COMPONENT_KEY_ATOM,
    origin_component_key: :ORIGIN_COMPONENT_KEY_ATOM,
    fill_style_guid: :FILL_STYLE_GUID_ATOM,
    stroke_style_guid: :STROKE_STYLE_GUID_ATOM,
    effect_style_guid: :EFFECT_STYLE_GUID_ATOM,
    grid_style_guid: :GRID_STYLE_GUID_ATOM,
    fill_count: :FILL_COUNT_ATOM,
    stroke_count: :STROKE_COUNT_ATOM
  }

  @optional_field_names Projection.field_names() -- Projection.required_field_names()
  @optional_xpath_attrs Enum.flat_map(
                          @optional_field_names,
                          &ProjectionNative.xpath_attr_entries/1
                        )

  @doc """
  Returns graph-focus helper items authored with `defrust`.
  """
  @spec focus_helper_items() :: [RustQ.Rust.Fragment.t()]
  def focus_helper_items do
    MetaAST.items(__MODULE__, [
      :graph_focus_push_guid_ref,
      :graph_focus_extend_symbol_refs,
      :graph_focus_extend_component_prop_assignments,
      :graph_focus_extend_component_prop_assignments_remaining,
      :graph_focus_extend_component_prop_value
    ])
  end

  @doc """
  Returns scene value reader helpers authored with `defrust`.
  """
  @spec scene_reader_items() :: [RustQ.Rust.Fragment.t()]
  def scene_reader_items do
    optional_scene_node_record_attr_items() ++
      MetaAST.items(__MODULE__, [
        :read_scene_float64_value,
        :read_scene_size_value,
        :read_scene_transform_value,
        :read_scene_font_name_value,
        :scene_node_record_base_attr_count,
        :scene_node_record_attr,
        :scene_node_record_attr_count,
        :scene_query_node,
        :scene_query_node_term
      ])
  end

  @doc """
  Returns root-level scene navigation NIF wrappers authored with `defrust`.
  """
  @spec scene_navigation_nif_items() :: [RustQ.Rust.Fragment.t()]
  def scene_navigation_nif_items do
    MetaAST.items(__MODULE__, [
      :scene_index_node,
      :scene_index_parent,
      :scene_index_roots,
      :scene_index_children,
      :scene_index_siblings,
      :scene_index_by_type,
      :scene_index_named,
      :scene_index_name_contains,
      :scene_index_text_contains,
      :scene_index_ancestors,
      :scene_index_descendants,
      :scene_index_by_type_fields,
      :scene_index_name_contains_fields,
      :scene_index_text_contains_fields,
      :scene_index_components,
      :scene_index_with_fills,
      :scene_index_with_strokes
    ])
  end

  @spec read_scene_float64_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(R.f64())
  defrust read_scene_float64_value(decoder) do
    {:ok, cast(decoder.read_var_float_value(), R.f64())}
  end

  @allow Clippy.redundant_field_names()
  @spec read_scene_size_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(scene_size())
  defrust read_scene_size_value(decoder) do
    {:ok,
     struct_literal(SceneSize,
       x: read_scene_float64_value(decoder),
       y: read_scene_float64_value(decoder)
     )}
  end

  @allow Clippy.redundant_field_names()
  @spec read_scene_transform_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(scene_transform())
  defrust read_scene_transform_value(decoder) do
    {:ok,
     struct_literal(SceneTransform,
       m00: read_scene_float64_value(decoder),
       m01: read_scene_float64_value(decoder),
       m02: read_scene_float64_value(decoder),
       m10: read_scene_float64_value(decoder),
       m11: read_scene_float64_value(decoder),
       m12: read_scene_float64_value(decoder)
     )}
  end

  @spec read_scene_font_name_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(
            {R.option(R.path(:String)), R.option(R.path(:String)), R.option(R.path(:String))}
          )
  defrust read_scene_font_name_value(decoder) do
    family = decoder.read_string_value()
    style = decoder.read_string_value()
    postscript = decoder.read_string_value()
    {:ok, {some(family), some(style), some(postscript)}}
  end

  defmacro push_optional_scene_query_fields do
    fields = Projection.field_names() -- Projection.required_field_names()

    {:__block__, [], Enum.map(fields, &push_optional_scene_query_field/1)}
  end

  defmacro scene_query_node_struct_literal do
    fields =
      [
        guid: quote(do: node.guid.to_string()),
        node_type: quote(do: node.node_type.to_string())
      ] ++ Enum.map(optional_field_names(), &scene_query_node_struct_field/1)

    quote do
      struct_literal(SceneQueryNode, unquote(fields))
    end
  end

  defmacro count_optional_scene_node_record_attrs do
    case Enum.map(optional_field_names(), &count_optional_scene_node_record_attr/1) do
      [] ->
        quote(do: 0)

      [first | rest] ->
        Enum.reduce(rest, first, fn count_expr, acc ->
          quote do
            unquote(acc) + unquote(count_expr)
          end
        end)
    end
  end

  OptionalRecordAttrs.defrust_functions()

  @spec scene_node_record_base_attr_count() :: R.usize()
  defrust scene_node_record_base_attr_count() do
    2
  end

  @spec scene_node_record_attr(R.ref(R.raw(:SceneNodeRecord)), R.usize()) ::
          R.raw(:"Option<(&'static str, String)>")
  defrust scene_node_record_attr(record, index) do
    if index == 0 do
      some({"guid", record.guid.to_string()})
    else
      if index == 1 do
        some({"type", record.node_type.to_string()})
      else
        scene_node_record_optional_attr_0(record, index - 2)
      end
    end
  end

  @spec scene_node_record_attr_count(R.ref(R.raw(:SceneNodeRecord))) :: R.usize()
  defrust scene_node_record_attr_count(record) do
    scene_node_record_base_attr_count() + count_optional_scene_node_record_attrs()
  end

  @spec scene_query_node(R.ref(R.raw(:SceneIndex)), R.usize()) :: scene_query_node()
  defrust scene_query_node(scene, node_index) do
    node = ref(index(scene.nodes, node_index))
    scene_query_node_struct_literal()
  end

  @spec scene_query_node_term(
          R.path(:Env, R.lifetime(:a)),
          R.ref(R.raw(:SceneIndex)),
          R.usize(),
          R.slice(R.path(:String))
        ) :: R.nif_result(term())
  defrust scene_query_node_term(env, scene, node_index, fields) do
    node = ref(index(scene.nodes, node_index))
    keys = Vec.with_capacity(fields.len().max(2))
    values = Vec.with_capacity(fields.len().max(2))

    keys.push(cached_atom(env, ref(GUID_ATOM), "guid").encode(env))
    values.push(node.guid.to_string().encode(env))
    keys.push(cached_atom(env, ref(NODE_TYPE_ATOM), "node_type").encode(env))
    values.push(node.node_type.encode(env))

    push_optional_scene_query_fields()

    Term.map_from_term_arrays(env, ref(keys), ref(values))
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_node(
          R.path(:Env, R.lifetime(:a)),
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.nif_result(term())
  defrust scene_index_node(env, resource, guid) do
    SceneXpathRuntime.scene_index_node_value(env, resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_parent(
          R.path(:Env, R.lifetime(:a)),
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.nif_result(term())
  defrust scene_index_parent(env, resource, guid) do
    SceneXpathRuntime.scene_index_parent_value(env, resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_roots(Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t())) ::
          R.vec(scene_query_node())
  defrust scene_index_roots(resource) do
    SceneXpathRuntime.scene_index_roots_value(resource)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_children(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_children(resource, guid) do
    SceneXpathRuntime.scene_index_children_value(resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_siblings(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_siblings(resource, guid) do
    SceneXpathRuntime.scene_index_siblings_value(resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_by_type(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_by_type(resource, node_type) do
    SceneXpathRuntime.scene_index_by_type_value(resource, node_type)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_named(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_named(resource, name) do
    SceneXpathRuntime.scene_index_named_value(resource, name)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_name_contains(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_name_contains(resource, needle) do
    SceneXpathRuntime.scene_index_name_contains_value(resource, needle)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_text_contains(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_text_contains(resource, needle) do
    SceneXpathRuntime.scene_index_text_contains_value(resource, needle)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_ancestors(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_ancestors(resource, guid) do
    SceneXpathRuntime.scene_index_ancestors_value(resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_descendants(
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String)
        ) :: R.vec(scene_query_node())
  defrust scene_index_descendants(resource, guid) do
    SceneXpathRuntime.scene_index_descendants_value(resource, guid)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_by_type_fields(
          R.path(:Env, R.lifetime(:a)),
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String),
          R.vec(R.path(:String))
        ) :: R.nif_result(term())
  defrust scene_index_by_type_fields(env, resource, node_type, fields) do
    SceneXpathRuntime.scene_index_by_type_fields_value(env, resource, node_type, fields)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_name_contains_fields(
          R.path(:Env, R.lifetime(:a)),
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String),
          R.vec(R.path(:String))
        ) :: R.nif_result(term())
  defrust scene_index_name_contains_fields(env, resource, needle, fields) do
    SceneXpathRuntime.scene_index_name_contains_fields_value(env, resource, needle, fields)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_text_contains_fields(
          R.path(:Env, R.lifetime(:a)),
          Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t()),
          R.path(:String),
          R.vec(R.path(:String))
        ) :: R.nif_result(term())
  defrust scene_index_text_contains_fields(env, resource, needle, fields) do
    SceneXpathRuntime.scene_index_text_contains_fields_value(env, resource, needle, fields)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_components(Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t())) ::
          R.vec(scene_query_node())
  defrust scene_index_components(resource) do
    SceneXpathRuntime.scene_index_components_value(resource)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_with_fills(Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t())) ::
          R.vec(scene_query_node())
  defrust scene_index_with_fills(resource) do
    SceneXpathRuntime.scene_index_with_fills_value(resource)
  end

  @nif schedule: "DirtyCpu"
  @spec scene_index_with_strokes(Rustler.ResourceArc.t(SceneXpathRuntime.SceneIndexResource.t())) ::
          R.vec(scene_query_node())
  defrust scene_index_with_strokes(resource) do
    SceneXpathRuntime.scene_index_with_strokes_value(resource)
  end

  defp optional_field_names, do: @optional_field_names
  defp optional_xpath_attrs, do: @optional_xpath_attrs

  defp optional_scene_node_record_attr_items do
    MetaAST.items(__MODULE__, optional_attr_function_names())
  end

  defp optional_attr_function_names do
    for index <- 0..length(optional_xpath_attrs()) do
      String.to_atom("scene_node_record_optional_attr_#{index}")
    end
  end

  defp count_optional_scene_node_record_attr(:size),
    do: count_optional_scene_node_record_attr(:size, 4)

  defp count_optional_scene_node_record_attr(field),
    do: count_optional_scene_node_record_attr(field, 1)

  defp count_optional_scene_node_record_attr(field, count) do
    quote do
      if record.unquote(field).is_some() do
        unquote(count)
      else
        0
      end
    end
  end

  defp scene_query_node_struct_field(:parent_guid) do
    {:parent_guid, quote(do: node.parent_guid.map(fn guid -> guid.to_string() end))}
  end

  defp scene_query_node_struct_field(field) do
    value =
      if ProjectionNative.rust_copy?(field),
        do: quote(do: node.unquote(field)),
        else: quote(do: node.unquote(field).clone())

    {field, value}
  end

  defp push_optional_scene_query_field(:parent_guid) do
    quote do
      if wants_field(fields, "parent_guid") do
        keys.push(cached_atom(env, ref(PARENT_GUID_ATOM), "parent_guid").encode(env))
        values.push(node.parent_guid.map(fn guid -> guid.to_string() end).encode(env))
      end
    end
  end

  defp push_optional_scene_query_field(field) do
    field_name = Atom.to_string(field)
    atom_name = Map.fetch!(@scene_query_atom_vars, field)

    quote do
      if wants_field(fields, unquote(field_name)) do
        keys.push(
          cached_atom(env, ref(unquote(Macro.var(atom_name, nil))), unquote(field_name)).encode(
            env
          )
        )

        values.push(node.unquote(field).encode(env))
      end
    end
  end

  @spec graph_focus_push_guid_ref(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.unit())
  defrust graph_focus_push_guid_ref(decoder, refs) do
    graph_focus_push_ref(refs, graph_focus_read_guid(decoder))
    :ok
  end

  @spec graph_focus_extend_symbol_refs(
          R.raw(:GraphFocusSymbolData),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.option(R.raw(:GraphFocusGuid)))
  defrust graph_focus_extend_symbol_refs(data, refs) do
    symbol_id = data.symbol_id
    graph_focus_extend_refs(refs, data.refs)
    {:ok, symbol_id}
  end

  @spec graph_focus_extend_component_prop_assignments(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.unit())
  defrust graph_focus_extend_component_prop_assignments(decoder, refs) do
    remaining = decoder.read_var_uint()
    graph_focus_extend_component_prop_assignments_remaining(decoder, refs, remaining)
  end

  @spec graph_focus_extend_component_prop_assignments_remaining(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid)))),
          R.u32()
        ) :: R.nif_result(R.unit())
  defrust graph_focus_extend_component_prop_assignments_remaining(decoder, refs, remaining) do
    if remaining == 0 do
      :ok
    else
      next = graph_focus_read_component_prop_assignment(decoder)
      graph_focus_extend_refs(refs, next)
      graph_focus_extend_component_prop_assignments_remaining(decoder, refs, remaining - 1)
    end
  end

  @spec graph_focus_extend_component_prop_value(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.unit())
  defrust graph_focus_extend_component_prop_value(decoder, refs) do
    next = graph_focus_read_component_prop_value(decoder)
    graph_focus_extend_refs(refs, next)
    :ok
  end
end
