defmodule Figler.Native.Module do
  @moduledoc """
  Rustler module for Figler native decoders and scene queries.
  """

  alias Figler.Native.Entrypoints

  use Rustler,
    otp_app: :figler,
    crate: :figler_native,
    path: "native"

  for {name, arity} <- Entrypoints.stubs() do
    args = for index <- 1..arity, do: Macro.var(:"_arg#{index}", nil)

    def unquote(name)(unquote_splicing(args)) do
      :erlang.nif_error(:nif_not_loaded)
    end
  end
end
