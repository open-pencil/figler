defmodule Figler.Codegen.Native.AtomCache do
  @moduledoc """
  Renders Rust fragments for native Rustler atom caches.

  The generated Rust stores frequently-used atoms in `OnceLock<Atom>` statics
  and resolves them with the runtime `cached_atom/3` helper. This module keeps
  that template-boundary spelling in one place so scene/query generators can
  talk in terms of atom cache declarations and encoded atom values.
  """

  alias RustQ.Rust

  @doc """
  Declares a `OnceLock<Atom>` used for cached Rustler atoms.
  """
  @spec static(String.t()) :: String.t()
  def static(name), do: "static #{name}: OnceLock<Atom> = OnceLock::new();"

  @doc """
  Builds a Rust expression that resolves a cached atom.
  """
  @spec expr(String.t(), String.t()) :: iodata()
  def expr(static_name, atom_name) do
    ["cached_atom(env, &", static_name, ", ", Rust.literal(atom_name), ")"]
  end

  @doc """
  Builds a Rust expression that resolves and encodes a cached atom.
  """
  @spec encoded(String.t(), String.t()) :: iodata()
  def encoded(static_name, atom_name), do: [expr(static_name, atom_name), ".encode(env)"]

  @doc """
  Assigns a cached atom to a Rust local.
  """
  @spec bind(String.t(), String.t(), String.t()) :: RustQ.Rust.Fragment.t()
  def bind(local, static_name, atom_name), do: Rust.let_(local, expr(static_name, atom_name))

  @doc """
  Encodes a static enum atom as a NIF result.
  """
  @spec enum_result(integer(), String.t()) :: String.t()
  def enum_result(value, atom_name) do
    static_name = "ATOM_#{value}"

    block([
      static(static_name),
      ["Ok(", encoded(static_name, atom_name), ")"]
    ])
  end

  @doc """
  Emits a schema field block that caches a field atom and appends its value.
  """
  @spec field_value_block(integer(), String.t(), term()) :: String.t()
  def field_value_block(field_id, field_name, value_lines) do
    static_name = "FIELD_ATOM_#{field_id}"

    block([
      static(static_name),
      bind("field_atom", static_name, field_name),
      value_lines,
      Rust.call_stmt("keys", :push, ["field_atom.encode(env)"]),
      Rust.call_stmt("values", :push, ["value"])
    ])
  end

  defp block(lines), do: lines |> Rust.block() |> Rust.to_fragment()
end
