defmodule Figler.Native.Nif do
  @moduledoc """
  Rustler NIF module for Figler native decoders and scene queries.
  """

  alias Figler.Native.Nifs

  use Rustler,
    otp_app: :figler,
    crate: :figler_native,
    path: "native"

  for {name, arity} <- Nifs.stubs() do
    args = for index <- 1..arity, do: Macro.var(:"_arg#{index}", nil)

    def unquote(name)(unquote_splicing(args)) do
      :erlang.nif_error(:nif_not_loaded)
    end
  end
end
