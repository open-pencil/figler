defmodule Figler.Scene.Projection.Native do
  @moduledoc """
  Rust-side projection metadata for scene fields.

  Native scene code generation uses these helpers to choose Rust field types,
  copy semantics, and XPath attribute encoders for each projected scene field.
  """

  def rust_type(:size), do: "Option<SceneSize>"
  def rust_type(:transform), do: "Option<SceneTransform>"
  def rust_type(field) when field in [:visible, :locked], do: "Option<bool>"
  def rust_type(field) when field in [:opacity, :font_size], do: "Option<f32>"
  def rust_type(field) when field in [:fill_count, :stroke_count], do: "Option<usize>"
  def rust_type(_field), do: "Option<String>"

  def rust_copy?(field),
    do: field in [:visible, :locked, :opacity, :font_size, :fill_count, :stroke_count]

  def xpath_attr_entries(:size) do
    [
      {:size, "x", "value.x.to_string()", []},
      {:size, "y", "value.y.to_string()", []},
      {:size, "width", "value.x.to_string()", []},
      {:size, "height", "value.y.to_string()", []}
    ]
  end

  def xpath_attr_entries(:transform) do
    [
      {:transform, "transform",
       "format!(\"{},{},{},{},{},{}\", value.m00, value.m01, value.m02, value.m10, value.m11, value.m12)",
       []}
    ]
  end

  def xpath_attr_entries(:parent_guid),
    do: [{:parent_guid, "parent_guid", "value.to_string()", []}]

  def xpath_attr_entries(field) do
    value_expr = if rust_copy?(field), do: "value.to_string()", else: "value.clone()"
    opts = if rust_copy?(field), do: [by_ref?: false], else: []
    [{field, Atom.to_string(field), value_expr, opts}]
  end
end
