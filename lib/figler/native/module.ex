defmodule Figler.Native.Module do
  @moduledoc """
  Rustler module for Figler native decoders and scene queries.
  """

  use Rustler,
    otp_app: :figler,
    crate: :figler_native,
    path: "native"

  use Figler.Native.GeneratedStubs
end
