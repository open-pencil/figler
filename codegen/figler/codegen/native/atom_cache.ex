defmodule Figler.Codegen.Native.AtomCache do
  @moduledoc """
  Renders Rust static declarations for native Rustler atom caches.

  The generated Rust stores frequently-used atoms in `OnceLock<Atom>` statics.
  Runtime lookup and encoding behavior belongs in Rusty-Elixir support
  functions; this module only owns the static declarations needed at template
  splice boundaries.
  """

  @doc """
  Declares a `OnceLock<Atom>` used for cached Rustler atoms.
  """
  @spec static(String.t()) :: String.t()
  def static(name), do: "static #{name}: OnceLock<Atom> = OnceLock::new();"
end
