defmodule Figler.Scene.Projection.NativeTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native

  test "derives native storage from projection semantics" do
    assert Native.rust_type(:size) == "Option<SceneSize>"
    assert Native.rust_type(:transform) == "Option<SceneTransform>"
    assert Native.rust_type(:visible) == "Option<bool>"
    assert Native.rust_type(:opacity) == "Option<f32>"
    assert Native.rust_type(:fill_count) == "Option<usize>"
    assert Native.rust_type(:name) == "Option<String>"

    assert Native.rust_copy?(Projection.field!(:visible))
    assert Native.rust_copy?(Projection.field!(:font_size))
    assert Native.rust_copy?(Projection.field!(:stroke_count))
    refute Native.rust_copy?(Projection.field!(:name))
    refute Native.rust_copy?(Projection.field!(:size))
  end

  test "derives XPath attributes from projection descriptors" do
    assert Enum.map(Native.xpath_attr_entries(:size), &{&1.attr, &1.value.kind, &1.value.field}) ==
             [
               {"x", :field_to_string, :x},
               {"y", :field_to_string, :y},
               {"width", :field_to_string, :x},
               {"height", :field_to_string, :y}
             ]

    assert [%{value: %{kind: :transform_string}, by_ref?: true}] =
             Native.xpath_attr_entries(:transform)

    assert [%{value: %{kind: :value_to_string}, by_ref?: true}] =
             Native.xpath_attr_entries(:parent_guid)

    assert [%{value: %{kind: :value_to_string}, by_ref?: false}] =
             Native.xpath_attr_entries(:visible)

    assert [%{value: %{kind: :value_clone}, by_ref?: true}] =
             Native.xpath_attr_entries(:name)
  end

  test "raises for unknown projection fields" do
    assert_raise ArgumentError, "unknown scene projection field: :missing", fn ->
      Projection.field!(:missing)
    end
  end
end
