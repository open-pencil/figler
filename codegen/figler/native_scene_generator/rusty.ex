defmodule Figler.NativeSceneGenerator.Rusty do
  @moduledoc """
  Small RustQ-backed helpers for Figler's schema-driven Rust fragments.

  Figler still keeps large native runtimes in Rust templates, but schema-shaped
  snippets should be composed through named helpers rather than open-coded Rust
  strings in every generator module.
  """

  alias RustQ.Rust

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
  Assigns a decoded term expression to `value`.
  """
  @spec value(String.t()) :: RustQ.Rust.Fragment.t()
  def value(expression), do: Rust.let_("value", expression)

  @doc """
  Emits a fixed-count decoder loop for array values.
  """
  @spec array_value(String.t()) :: String.t()
  def array_value(item_expression) do
    statements([
      Rust.let_("len", "decoder.read_var_uint()? as usize"),
      Rust.let_mut("items", "Vec::with_capacity(len)"),
      Rust.stmt("for _ in 0..len { let item = #{item_expression}; items.push(item); }"),
      Rust.let_("value", "items.encode(env)")
    ])
  end

  @doc """
  Emits a fixed-count skip loop for array values.
  """
  @spec skip_array(String.t()) :: String.t()
  def skip_array(statement) do
    block([
      Rust.let_("len", "decoder.read_var_uint()? as usize"),
      Rust.stmt("for _ in 0..len { #{statement} }")
    ])
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

  defp statements(lines), do: Enum.map_join(lines, "\n", &Rust.to_fragment/1)
end
