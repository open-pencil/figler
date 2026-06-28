defmodule Figler.SparseTest do
  use ExUnit.Case, async: true

  alias Figler.Sparse

  test "introspects sparse schema-backed maps" do
    sparse = %{__kiwi_module__: Figler.Schema.NodeChange, name: "Rect 1"}

    assert Sparse.module(sparse) == Figler.Schema.NodeChange
    assert Sparse.fields(sparse) == [:name]
    assert Sparse.present?(sparse, :name)
    refute Sparse.present?(sparse, :size)
    assert Sparse.fetch(sparse, :name) == {:ok, "Rect 1"}
    assert Sparse.get(sparse, :size, :missing) == :missing
  end
end
