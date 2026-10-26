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
  def rust_type(field), do: RustQ.Spec.type(rust_spec(field)).ast

  @doc "The spec of a projected field's native value, which its Rust type is."
  @spec rust_spec(atom() | map()) :: Macro.t()
  def rust_spec(field) when is_atom(field), do: field |> Projection.field!() |> rust_spec()
  def rust_spec(%{value: :vector}), do: quote(do: RustQ.Type.option(RustQ.Type.path(:SceneSize)))

  def rust_spec(%{value: :matrix}),
    do: quote(do: RustQ.Type.option(RustQ.Type.path(:SceneTransform)))

  def rust_spec(%{decode: :bool}), do: quote(do: RustQ.Type.option(RustQ.Type.bool()))
  def rust_spec(%{decode: :float}), do: quote(do: RustQ.Type.option(RustQ.Type.f32()))
  def rust_spec(%{value: :count}), do: quote(do: RustQ.Type.option(RustQ.Type.usize()))
  def rust_spec(%{name: _name}), do: quote(do: RustQ.Type.option(String.t()))

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

  defp default_xpath_value(field) do
    if rust_copy?(field), do: :value_to_string, else: :value_clone
  end

  defp xpath_value({:field_to_string, field}),
    do: %XPathValue{kind: :field_to_string, field: field}

  defp xpath_value(kind), do: %XPathValue{kind: kind}
end
