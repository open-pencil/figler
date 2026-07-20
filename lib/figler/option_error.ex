defmodule Figler.OptionError do
  @moduledoc """
  A structured error for one invalid public option.

  Option validators return these values inside their operation-specific error
  contract. Match on `:option` and `:code`; `:value` preserves the rejected
  input for diagnostics.
  """

  @derive Jason.Encoder
  @enforce_keys [:option, :code, :value]
  defstruct [:option, :code, :value]

  @type t :: %__MODULE__{option: atom(), code: atom(), value: term()}

  @doc false
  @spec new(atom(), atom(), term()) :: t()
  def new(option, code, value) when is_atom(option) and is_atom(code),
    do: %__MODULE__{option: option, code: code, value: value}
end
