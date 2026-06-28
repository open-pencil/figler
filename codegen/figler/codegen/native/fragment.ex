defmodule Figler.Codegen.Native.Fragment do
  @moduledoc """
  Small RustQ fragment helpers shared by Figler native codegen modules.

  These helpers are for template splice boundaries: they assemble statements,
  arms, and counted decoder loops without pretending the fragments are stable
  Rust functions.
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
  Renders a statement sequence without introducing an extra Rust scope.
  """
  @spec statements([term()]) :: String.t()
  def statements(lines), do: Enum.map_join(lines, "\n", &Rust.to_fragment/1)
end
