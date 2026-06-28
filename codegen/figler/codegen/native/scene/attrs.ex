defmodule Figler.Codegen.Native.Scene.Attrs do
  @moduledoc """
  Builds scene XPath and query-field attribute splices.

  XPath attributes and query-field encoders are template-boundary fragments:
  they are not stable Rust functions, but schema/projection-shaped snippets that
  attach projected fields to Rustler terms and XPath attributes. This module
  keeps their metadata explicit instead of spreading string decisions through
  `Figler.Codegen.Native.Scene`.
  """

  alias Figler.Codegen.Native.AtomCache
  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias Figler.Scene.Projection.Native.XPathAttr
  alias Figler.Scene.Projection.Native.XPathValue
  alias RustQ.Rust

  defmodule XPathEntry do
    @moduledoc """
    One XPath attribute exposed for a projected scene field.
    """

    @enforce_keys [:field, :attr, :value, :by_ref?, :last?]
    defstruct [:field, :attr, :value, :by_ref?, :last?]

    @type t :: %__MODULE__{
            field: atom(),
            attr: String.t(),
            value: XPathValue.t(),
            by_ref?: boolean(),
            last?: boolean()
          }
  end

  defmodule QueryValue do
    @moduledoc """
    Semantic description of how to encode a scene query result field value.
    """

    @enforce_keys [:kind]
    defstruct [:kind, :field]

    @type kind :: :encoded_node_field | :encoded_parent_guid_string
    @type t :: %__MODULE__{kind: kind(), field: atom() | nil}
  end

  defmodule QueryField do
    @moduledoc """
    One optional field that can be encoded for scene query results.
    """

    @enforce_keys [:field, :atom_static, :value]
    defstruct [:field, :atom_static, :value]

    @type t :: %__MODULE__{field: atom(), atom_static: String.t(), value: QueryValue.t()}
  end

  @spec xpath_lookup([atom()]) :: [RustQ.Rust.Fragment.t()]
  def xpath_lookup(fields \\ optional_field_names()) do
    fields
    |> xpath_entries()
    |> Enum.map(&xpath_entry/1)
  end

  @spec xpath_count([atom()]) :: [RustQ.Rust.Fragment.t()]
  def xpath_count(fields \\ optional_field_names()) do
    Enum.map(fields, fn
      :size -> attr_count(:size, 4)
      field -> attr_count(field, 1)
    end)
  end

  @spec query_field_atoms([atom()]) :: [RustQ.Rust.Fragment.t()]
  def query_field_atoms(fields \\ query_field_names()) do
    fields
    |> Enum.map(&query_field/1)
    |> Enum.map(&query_field_atom/1)
  end

  @spec query_field_encoders([atom()]) :: [RustQ.Rust.Fragment.t()]
  def query_field_encoders(fields \\ query_field_names()) do
    fields
    |> Enum.map(&query_field/1)
    |> Enum.map(&query_field_encoder/1)
  end

  defp optional_field_names do
    Projection.field_names() -- Projection.required_field_names()
  end

  defp query_field_names, do: optional_field_names()

  defp xpath_entries(fields) do
    entries = Enum.flat_map(fields, &ProjectionNative.xpath_attr_entries/1)

    entries
    |> Enum.with_index()
    |> Enum.map(fn {%XPathAttr{} = attr, index} ->
      %XPathEntry{
        field: attr.field,
        attr: attr.attr,
        value: attr.value,
        by_ref?: attr.by_ref?,
        last?: index == length(entries) - 1
      }
    end)
  end

  defp xpath_entry(%XPathEntry{} = entry) do
    attr_lookup(accessor(entry), entry.attr, value_expr(entry.value), last?: entry.last?)
  end

  defp accessor(%XPathEntry{by_ref?: true, field: field}), do: "self.#{field}.as_ref()"
  defp accessor(%XPathEntry{by_ref?: false, field: field}), do: "self.#{field}"

  defp value_expr(%XPathValue{kind: :field_to_string, field: field}) do
    ["value.", Atom.to_string(field), ".to_string()"]
  end

  defp value_expr(%XPathValue{kind: :value_to_string}), do: "value.to_string()"
  defp value_expr(%XPathValue{kind: :value_clone}), do: "value.clone()"

  defp value_expr(%XPathValue{kind: :transform_string}) do
    "format!(\"{},{},{},{},{},{}\", value.m00, value.m01, value.m02, value.m10, value.m11, value.m12)"
  end

  defp query_field(:parent_guid) do
    %QueryField{
      field: :parent_guid,
      atom_static: query_field_atom_name(:parent_guid),
      value: %QueryValue{kind: :encoded_parent_guid_string}
    }
  end

  defp query_field(field) do
    name = field_name(field)

    %QueryField{
      field: field,
      atom_static: query_field_atom_name(name),
      value: %QueryValue{kind: :encoded_node_field, field: field}
    }
  end

  defp query_field_atom(%QueryField{} = field), do: AtomCache.static(field.atom_static)

  defp query_field_atom_name(field),
    do: field |> to_string() |> String.upcase() |> Kernel.<>("_ATOM")

  defp query_field_encoder(%QueryField{} = field) do
    name = field_name(field.field)
    literal_name = Rust.literal(name)

    Rust.if_("wants_field(fields, #{literal_name})", [
      Rust.call_stmt("keys", :push, [AtomCache.encoded(field.atom_static, name)]),
      Rust.call_stmt("values", :push, [query_value_expr(field.value)])
    ])
  end

  defp query_value_expr(%QueryValue{kind: :encoded_parent_guid_string}) do
    "node.parent_guid.map(|guid| guid.to_string()).encode(env)"
  end

  defp query_value_expr(%QueryValue{kind: :encoded_node_field, field: field}) do
    ["node.", Atom.to_string(field), ".encode(env)"]
  end

  defp attr_lookup(accessor, attr, value_expr, opts) do
    lines = [return_attr_if_cursor(attr, value_expr)]

    lines =
      if Keyword.get(opts, :last?, false), do: lines, else: lines ++ [Rust.stmt("cursor += 1")]

    Rust.to_fragment(Rust.if_let("Some(value)", accessor, lines))
  end

  defp return_attr_if_cursor(attr, value_expr) do
    Rust.return_if("index == cursor", "Some((#{Rust.literal(attr)}, #{value_expr}))")
  end

  defp attr_count(field, count) do
    Rust.if_("self.#{field}.is_some()", [Rust.stmt("count += #{count}")])
  end

  defp field_name(field), do: Atom.to_string(field)
end
