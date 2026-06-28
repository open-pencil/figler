defmodule Figler.Scene.Projection.Native do
  @moduledoc """
  Rust-side projection metadata for scene fields.

  Native scene code generation uses these helpers to choose Rust field types,
  copy semantics, and XPath attribute encoders for each projected scene field.
  """

  defmodule XPathValue do
    @moduledoc """
    Semantic description of how to render an XPath attribute value in native Rust.
    """

    @enforce_keys [:kind]
    defstruct [:kind, :field]

    @type kind :: :field_to_string | :value_to_string | :value_clone | :transform_string
    @type t :: %__MODULE__{kind: kind(), field: atom() | nil}
  end

  defmodule XPathAttr do
    @moduledoc """
    Native XPath attribute metadata for one projected scene field.
    """

    @enforce_keys [:field, :attr, :value, :by_ref?]
    defstruct [:field, :attr, :value, :by_ref?]

    @type t :: %__MODULE__{
            field: atom(),
            attr: String.t(),
            value: XPathValue.t(),
            by_ref?: boolean()
          }
  end

  def rust_type(:size), do: "Option<SceneSize>"
  def rust_type(:transform), do: "Option<SceneTransform>"
  def rust_type(field) when field in [:visible, :locked], do: "Option<bool>"
  def rust_type(field) when field in [:opacity, :font_size], do: "Option<f32>"
  def rust_type(field) when field in [:fill_count, :stroke_count], do: "Option<usize>"
  def rust_type(_field), do: "Option<String>"

  def rust_copy?(field),
    do: field in [:visible, :locked, :opacity, :font_size, :fill_count, :stroke_count]

  @spec xpath_attr_entries(atom()) :: [XPathAttr.t()]
  def xpath_attr_entries(:size) do
    [
      xpath_attr(:size, "x", field_to_string(:x)),
      xpath_attr(:size, "y", field_to_string(:y)),
      xpath_attr(:size, "width", field_to_string(:x)),
      xpath_attr(:size, "height", field_to_string(:y))
    ]
  end

  def xpath_attr_entries(:transform) do
    [xpath_attr(:transform, "transform", value(:transform_string))]
  end

  def xpath_attr_entries(:parent_guid) do
    [xpath_attr(:parent_guid, "parent_guid", value(:value_to_string))]
  end

  def xpath_attr_entries(field) do
    value = if rust_copy?(field), do: value(:value_to_string), else: value(:value_clone)
    by_ref? = not rust_copy?(field)

    [xpath_attr(field, Atom.to_string(field), value, by_ref?: by_ref?)]
  end

  defp xpath_attr(field, attr, %XPathValue{} = value, opts \\ []) do
    %XPathAttr{
      field: field,
      attr: attr,
      value: value,
      by_ref?: Keyword.get(opts, :by_ref?, true)
    }
  end

  defp field_to_string(field), do: %XPathValue{kind: :field_to_string, field: field}
  defp value(kind), do: %XPathValue{kind: kind}
end
