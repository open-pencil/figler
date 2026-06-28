defmodule Figler.Codegen.Native.Defrust do
  use RustQ.Meta,
    rust_sources: ["native/src/runtime.rs"]

  @moduledoc """
  Rust helper items authored with RustQ `defrust` for Figler native codegen.

  These helpers become ordinary Rust functions in the generated native module.
  Keep semantic Rusty-Elixir here; schema/template splice rendering belongs in
  the neighboring codegen modules.
  """

  alias RustQ.Meta.AST, as: MetaAST
  alias RustQ.Type, as: R

  @type decoder :: R.mut_ref(R.path(:Decoder, R.lifetime(:_)))
  @type graph_focus_guid :: term()
  @type scene_size :: R.path(:SceneSize)
  @type scene_transform :: R.path(:SceneTransform)

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
    MetaAST.items(__MODULE__, [
      :read_scene_float64_value,
      :read_scene_size_value,
      :read_scene_transform_value,
      :read_scene_font_name_value
    ])
  end

  @spec read_scene_float64_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(R.f64())
  # TODO: remove the explicit propagation once RustQ can infer through cast/2.
  defrust read_scene_float64_value(decoder) do
    value = unwrap!(decoder.read_var_float_value())
    {:ok, cast(value, R.f64())}
  end

  @allow Clippy.redundant_field_names()
  @spec read_scene_size_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(scene_size())
  # TODO: remove the explicit propagation once RustQ can infer struct literal field types.
  defrust read_scene_size_value(decoder) do
    x = unwrap!(read_scene_float64_value(decoder))
    y = unwrap!(read_scene_float64_value(decoder))
    {:ok, struct_literal(SceneSize, x: x, y: y)}
  end

  @allow Clippy.redundant_field_names()
  @spec read_scene_transform_value(R.mut_ref(R.path(:Decoder, R.lifetime(:_)))) ::
          R.nif_result(scene_transform())
  # TODO: remove the explicit propagation once RustQ can infer struct literal field types.
  defrust read_scene_transform_value(decoder) do
    m00 = unwrap!(read_scene_float64_value(decoder))
    m01 = unwrap!(read_scene_float64_value(decoder))
    m02 = unwrap!(read_scene_float64_value(decoder))
    m10 = unwrap!(read_scene_float64_value(decoder))
    m11 = unwrap!(read_scene_float64_value(decoder))
    m12 = unwrap!(read_scene_float64_value(decoder))

    {:ok,
     struct_literal(SceneTransform,
       m00: m00,
       m01: m01,
       m02: m02,
       m10: m10,
       m11: m11,
       m12: m12
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

  @spec graph_focus_push_guid_ref(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.unit())
  defrust graph_focus_push_guid_ref(decoder, refs) do
    graph_focus_push_ref(refs, unwrap!(graph_focus_read_guid(decoder)))
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
    remaining = unwrap!(decoder.read_var_uint())
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
      next = unwrap!(graph_focus_read_component_prop_assignment(decoder))
      graph_focus_extend_refs(refs, next)
      graph_focus_extend_component_prop_assignments_remaining(decoder, refs, remaining - 1)
    end
  end

  @spec graph_focus_extend_component_prop_value(
          R.mut_ref(R.raw(:"Decoder<'_>")),
          R.mut_ref(R.option(R.vec(R.raw(:GraphFocusGuid))))
        ) :: R.nif_result(R.unit())
  defrust graph_focus_extend_component_prop_value(decoder, refs) do
    next = unwrap!(graph_focus_read_component_prop_value(decoder))
    graph_focus_extend_refs(refs, next)
    :ok
  end
end
