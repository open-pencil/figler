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

  alias Figler.Scene.Projection
  alias RustQ.Rust.AST.Builder, as: A

  def rust_type(field) when is_atom(field), do: field |> Projection.field!() |> rust_type()
  def rust_type(%{value: :vector}), do: option_type(:SceneSize)
  def rust_type(%{value: :matrix}), do: option_type(:SceneTransform)
  def rust_type(%{decode: :bool}), do: option_type(:bool)
  def rust_type(%{decode: :float}), do: option_type(:f32)
  def rust_type(%{value: :count}), do: option_type(:usize)
  def rust_type(%{name: _name}), do: option_type(:String)

  def rust_copy?(field) when is_atom(field), do: field |> Projection.field!() |> rust_copy?()
  def rust_copy?(%{decode: kind}) when kind in [:bool, :float], do: true
  def rust_copy?(%{value: :count}), do: true
  def rust_copy?(%{name: _name}), do: false

  @spec xpath_attr_entries(atom() | map()) :: [XPathAttr.t()]
  def xpath_attr_entries(field) when is_atom(field),
    do: field |> Projection.field!() |> xpath_attr_entries()

  def xpath_attr_entries(%{name: name, xpath_values: values}) do
    Enum.map(values, fn {attr, value} ->
      xpath_attr(name, Atom.to_string(attr), xpath_value(value))
    end)
  end

  def xpath_attr_entries(%{name: name, xpath_attrs: attrs} = field) do
    value = field |> Map.get(:xpath_value, default_xpath_value(field)) |> xpath_value()
    by_ref? = not rust_copy?(field)

    Enum.map(attrs, &xpath_attr(name, Atom.to_string(&1), value, by_ref?: by_ref?))
  end

  defp xpath_attr(field, attr, %XPathValue{} = value, opts \\ []) do
    %XPathAttr{
      field: field,
      attr: attr,
      value: value,
      by_ref?: Keyword.get(opts, :by_ref?, true)
    }
  end

  defp option_type(type), do: A.type_path(:Option, generics: [A.type_path(type)])

  defp default_xpath_value(field) do
    if rust_copy?(field), do: :value_to_string, else: :value_clone
  end

  defp xpath_value({:field_to_string, field}),
    do: %XPathValue{kind: :field_to_string, field: field}

  defp xpath_value(kind), do: %XPathValue{kind: kind}
end
