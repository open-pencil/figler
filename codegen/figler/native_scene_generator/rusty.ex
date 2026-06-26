defmodule Figler.NativeSceneGenerator.Rusty do
  use RustQ.Meta

  @moduledoc """
  Small RustQ-backed helpers for Figler's schema-driven Rust fragments.

  Figler still keeps large native runtimes in Rust templates, but schema-shaped
  snippets should be composed through named helpers rather than open-coded Rust
  strings in every generator module.
  """

  alias RustQ.Meta.AST, as: MetaAST
  alias RustQ.Rust
  alias RustQ.Type, as: R

  @type decoder :: term()
  @type graph_focus_guid :: term()

  @doc """
  Returns Rust helper items authored with `defrust`.
  """
  @spec helper_items() :: [RustQ.Rust.Fragment.t()]
  def helper_items do
    MetaAST.items(__MODULE__, [
      :graph_focus_push_guid_ref,
      :graph_focus_extend_symbol_refs,
      :graph_focus_extend_component_prop_assignments,
      :graph_focus_extend_component_prop_assignments_remaining,
      :graph_focus_extend_component_prop_value
    ])
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

  @doc """
  Renders a Rust block from statement fragments.
  """
  @spec block([term()]) :: String.t()
  def block(lines), do: lines |> Rust.block() |> Rust.to_fragment()

  @doc """
  Builds a `match` arm with a RustQ-rendered block body.
  """
  @spec arm(integer() | String.t(), [term()] | term()) :: RustQ.Rust.Fragment.t()
  def arm(id, lines), do: Rust.arm(to_string(id), lines |> List.wrap() |> block())

  @doc """
  Declares a `OnceLock<Atom>` used for cached Rustler atoms.
  """
  @spec cached_atom_static(String.t()) :: String.t()
  def cached_atom_static(name), do: "static #{name}: OnceLock<Atom> = OnceLock::new();"

  @doc """
  Assigns a cached atom to a Rust local.
  """
  @spec cached_atom(String.t(), String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def cached_atom(local, static_name, atom_name) do
    Rust.let_(local, "cached_atom(env, &#{static_name}, #{Rust.literal(atom_name)})")
  end

  @doc """
  Declares a mutable `Option` local initialized to `None`.
  """
  @spec let_none(atom() | String.t()) :: RustQ.Rust.Fragment.t()
  def let_none(name), do: Rust.let_mut(to_string(name), "None")

  @doc """
  Assigns a decoded term expression to `value`.
  """
  @spec value(String.t()) :: RustQ.Rust.Fragment.t()
  def value(expression), do: Rust.let_("value", expression)

  @doc """
  Assigns an expression to a local.
  """
  @spec assign(atom() | String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def assign(name, expression), do: Rust.assign(to_string(name), expression)

  @doc """
  Assigns `Some(expression)` to an optional local.
  """
  @spec assign_some(atom() | String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def assign_some(name, expression), do: Rust.assign(to_string(name), "Some(#{expression})")

  @doc """
  Emits a schema field block that caches a field atom and appends its value.
  """
  @spec field_value_block(integer(), String.t(), term()) :: String.t()
  def field_value_block(field_id, field_name, value_lines) do
    block([
      cached_atom_static("FIELD_ATOM_#{field_id}"),
      cached_atom("field_atom", "FIELD_ATOM_#{field_id}", field_name),
      value_lines,
      Rust.call_stmt("keys", :push, ["field_atom.encode(env)"]),
      Rust.call_stmt("values", :push, ["value"])
    ])
  end

  @doc """
  Emits a fixed-count decoder loop for array values.
  """
  @spec array_value(String.t()) :: String.t()
  def array_value(item_expression) do
    statements([
      Rust.let_("len", "decoder.read_var_uint()? as usize"),
      Rust.let_mut("items", "Vec::with_capacity(len)"),
      counted_for([
        Rust.let_("item", item_expression),
        Rust.call_stmt("items", :push, ["item"])
      ]),
      Rust.let_("value", "items.encode(env)")
    ])
  end

  @doc """
  Emits a fixed-count skip loop for array values.
  """
  @spec skip_array(String.t()) :: String.t()
  def skip_array(statement),
    do: block([Rust.let_("len", "decoder.read_var_uint()? as usize"), counted_for(statement)])

  @doc """
  Emits a `for _ in 0..len` loop with a RustQ-rendered body.
  """
  @spec counted_for([term()] | term()) :: RustQ.Rust.Fragment.t()
  def counted_for(lines), do: Rust.stmt(["for _ in 0..len ", block(List.wrap(lines))])

  @doc """
  Emits a counted loop that reads `len` from the decoder before looping.
  """
  @spec decoder_counted_loop([term()] | term()) :: String.t()
  def decoder_counted_loop(lines) do
    statements([Rust.let_("len", "decoder.read_var_uint()? as usize"), counted_for(lines)])
  end

  @doc """
  Encodes a static enum atom as a NIF result.
  """
  @spec enum_atom_result(integer(), String.t()) :: String.t()
  def enum_atom_result(value, atom_name) do
    static_name = "ATOM_#{value}"

    block([
      cached_atom_static(static_name),
      "Ok(cached_atom(env, &#{static_name}, #{Rust.literal(atom_name)}).encode(env))"
    ])
  end

  @doc """
  Declares a static scene query field atom.
  """
  @spec query_field_atom(atom() | String.t()) :: String.t()
  def query_field_atom(field), do: field |> query_field_atom_name() |> cached_atom_static()

  @doc """
  Returns the generated static atom name for a scene query field.
  """
  @spec query_field_atom_name(atom() | String.t()) :: String.t()
  def query_field_atom_name(field),
    do: field |> to_string() |> String.upcase() |> Kernel.<>("_ATOM")

  @doc """
  Emits a scene query field encoder guarded by `wants_field/2`.
  """
  @spec query_field_encoder(String.t(), String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def query_field_encoder(name, static_name, value) do
    literal_name = Rust.literal(name)

    Rust.if_("wants_field(fields, #{literal_name})", [
      Rust.call_stmt("keys", :push, [
        "cached_atom(env, &#{static_name}, #{literal_name}).encode(env)"
      ]),
      Rust.call_stmt("values", :push, [value])
    ])
  end

  @doc """
  Emits an indexed XPath attribute return statement.
  """
  @spec return_attr_if_cursor(String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def return_attr_if_cursor(attr, value_expr) do
    Rust.return_if("index == cursor", "Some((#{Rust.literal(attr)}, #{value_expr}))")
  end

  @doc """
  Emits an XPath attribute lookup block for an optional field accessor.
  """
  @spec attr_lookup(String.t(), String.t(), String.t(), keyword()) :: String.t()
  def attr_lookup(accessor, attr, value_expr, opts) do
    lines = [return_attr_if_cursor(attr, value_expr)]

    lines =
      if Keyword.get(opts, :last?, false), do: lines, else: lines ++ [Rust.stmt("cursor += 1")]

    Rust.to_fragment(Rust.if_let("Some(value)", accessor, lines))
  end

  @doc """
  Emits an optional-field contribution to scene XPath attribute count.
  """
  @spec attr_count(atom(), pos_integer()) :: RustQ.Rust.Fragment.t()
  def attr_count(field, count) do
    Rust.if_("self.#{field}.is_some()", [Rust.stmt("count += #{count}")])
  end

  @doc """
  Renders a statement sequence without introducing an extra Rust scope.
  """
  @spec statements([term()]) :: String.t()
  def statements(lines), do: Enum.map_join(lines, "\n", &Rust.to_fragment/1)
end
