defmodule Figler.Scene.Graph.Variables.Formula do
  @moduledoc """
  Evaluates variable expressions as Figma does, following OpenPencil's formula
  signatures (`scene-graph/src/variables/formula/signatures.ts`).

  A formula node is a literal (number, boolean, string, or `%{r, g, b, a}`
  color), `{:alias, id}`, or `{operator, operands}`. Operand types are checked
  against each operator's overloads; a mismatch, a division by zero, or a
  overflowing result raises `ArgumentError`.
  """

  @operators [
    :addition,
    :subtraction,
    :multiply,
    :divide,
    :negate,
    :equals,
    :not_equal,
    :less_than,
    :less_than_or_equal,
    :greater_than,
    :greater_than_or_equal,
    :and,
    :or,
    :not,
    :stringify,
    :is_truthy,
    :ternary
  ]

  @text_types [:float, :boolean, :string]

  @type value_type :: :float | :boolean | :string | :color
  @type literal :: number() | boolean() | String.t() | map()
  @type formula :: literal() | {:alias, term()} | {atom(), [formula()]}

  @doc "The operators a formula may use, named as Kiwi's `ExpressionFunction`."
  @spec operators() :: [atom()]
  def operators, do: @operators

  @doc """
  Evaluates a formula, resolving references with `resolve`, which returns a
  literal or `nil` for a variable that cannot be resolved.
  """
  @spec evaluate(formula(), (term() -> literal() | nil)) :: literal()
  def evaluate({:alias, id}, resolve) do
    case resolve.(id) do
      nil -> raise ArgumentError, "cannot resolve variable #{inspect(id)}"
      value -> checked(value)
    end
  end

  def evaluate({operator, operands}, resolve) when operator in @operators do
    operands = Enum.map(operands, &evaluate(&1, resolve))
    operator |> apply_operator(operands, Enum.map(operands, &type!/1)) |> checked()
  rescue
    ArithmeticError -> reraise ArgumentError, "formula result must be finite", __STACKTRACE__
  end

  def evaluate(literal, _resolve), do: checked(literal)

  @doc "The type of a literal, or `nil` for anything else."
  @spec type(term()) :: value_type() | nil
  def type(value) when is_boolean(value), do: :boolean
  def type(value) when is_number(value), do: :float
  def type(value) when is_binary(value), do: :string
  def type(%{r: _, g: _, b: _}), do: :color
  def type(_value), do: nil

  defp type!(value), do: type(value) || raise(ArgumentError, "not a variable value")

  # BEAM floats are always finite; arithmetic that would overflow raises.
  defp checked(value) do
    type!(value)
    value
  end

  defp apply_operator(:addition, [a, b], [:float, :float]), do: a + b

  defp apply_operator(:addition, [a, b], types)
       when types in [[:string, :string], [:string, :float], [:float, :string]] or
              types in [[:string, :boolean], [:boolean, :string]],
       do: text(a) <> text(b)

  defp apply_operator(:subtraction, [a, b], [:float, :float]), do: a - b
  defp apply_operator(:multiply, [a, b], [:float, :float]), do: a * b

  defp apply_operator(:divide, [_a, zero], [:float, :float]) when zero in [0, +0.0, -0.0],
    do: raise(ArgumentError, "cannot divide by zero")

  defp apply_operator(:divide, [a, b], [:float, :float]), do: a / b
  defp apply_operator(:negate, [a], [:float]), do: -a

  defp apply_operator(:equals, [a, b], [type, type]) when type in @text_types, do: a === b
  defp apply_operator(:not_equal, [a, b], [type, type]) when type in @text_types, do: a !== b
  defp apply_operator(:less_than, [a, b], [:float, :float]), do: a < b
  defp apply_operator(:less_than_or_equal, [a, b], [:float, :float]), do: a <= b
  defp apply_operator(:greater_than, [a, b], [:float, :float]), do: a > b
  defp apply_operator(:greater_than_or_equal, [a, b], [:float, :float]), do: a >= b
  defp apply_operator(:and, [a, b], [:boolean, :boolean]), do: a and b
  defp apply_operator(:or, [a, b], [:boolean, :boolean]), do: a or b
  defp apply_operator(:not, [a], [:boolean]), do: not a
  defp apply_operator(:stringify, [a], [type]) when type in @text_types, do: text(a)
  defp apply_operator(:is_truthy, [a], [type]) when type in @text_types, do: truthy(a)

  defp apply_operator(:ternary, [true, then, _otherwise], [:boolean, type, type])
       when type in [:color | @text_types],
       do: then

  defp apply_operator(:ternary, [false, _then, otherwise], [:boolean, type, type])
       when type in [:color | @text_types],
       do: otherwise

  defp apply_operator(operator, _operands, types),
    do: raise(ArgumentError, "#{operator} does not take #{inspect(types)}")

  @doc """
  The text a variable bound to text content shows: a string as it is, a
  boolean as `"true"` or `"false"`, and a number as Figma writes it, read at
  32-bit precision: within a millionth of zero as `"0"`, a whole number as that
  integer, anything else with two decimals and ties rounded to even.
  """
  @spec text(term()) :: String.t() | nil
  def text(value) when is_binary(value), do: value
  def text(value) when is_boolean(value), do: Atom.to_string(value)
  def text(value) when is_integer(value), do: value |> clamp_int32() |> Integer.to_string()
  def text(value) when is_float(value), do: number_text(value)
  def text(_value), do: nil

  defp number_text(input) do
    <<value::float-32>> = <<input::float-32>>

    cond do
      abs(value) < 1.0e-6 -> "0"
      value == trunc(value) -> value |> trunc() |> clamp_int32() |> Integer.to_string()
      true -> two_decimals(value)
    end
  end

  defp two_decimals(value) do
    scaled = abs(value) * 100
    floor = trunc(Float.floor(scaled))
    cents = if scaled - floor == 0.5, do: floor + rem(floor, 2), else: round(scaled)
    sign = if value < 0, do: "-", else: ""

    "#{sign}#{div(cents, 100)}.#{cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end

  defp clamp_int32(value), do: value |> max(-2_147_483_648) |> min(2_147_483_647)

  @false_words ["false", "no", "off"]

  @doc """
  Whether Figma reads a value as true, as a visibility binding does: a number
  other than 0, and text other than `""`, `"false"`, `"no"`, or `"off"`.
  """
  @spec truthy(term()) :: boolean() | nil
  def truthy(value) when is_boolean(value), do: value
  def truthy(value) when is_number(value), do: value != 0

  def truthy(value) when is_binary(value),
    do: value != "" and String.downcase(String.trim(value)) not in @false_words

  def truthy(_value), do: nil
end
