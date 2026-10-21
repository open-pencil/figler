defmodule Figler.Native.RecordsTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Scene.Input

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  test "native records encode to the maps the sparse decoder returns" do
    source = @fixture |> File.read!() |> Input.source!()

    assert CodecNifs.decode_record_message(source) == CodecNifs.decode_sparse_message(source)
  end
end
