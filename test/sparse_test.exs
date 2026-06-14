defmodule FigKiwi.SparseTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Sparse

  test "introspects sparse schema-backed maps" do
    sparse = %{__kiwi_module__: FigKiwi.Schema.NodeChange, name: "Rect 1"}

    assert Sparse.module(sparse) == FigKiwi.Schema.NodeChange
    assert Sparse.fields(sparse) == [:name]
    assert Sparse.present?(sparse, :name)
    refute Sparse.present?(sparse, :size)
    assert Sparse.fetch(sparse, :name) == {:ok, "Rect 1"}
    assert Sparse.get(sparse, :size, :missing) == :missing
  end
end
