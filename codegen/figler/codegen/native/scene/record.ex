defmodule Figler.Codegen.Native.Scene.Record do
  @moduledoc """
  Builds scene record/query-node field splices from projection metadata.

  These splices are Rust struct field declarations and struct literal entries,
  so they live at the template boundary rather than in `defrust` functions.
  The module keeps the projection-to-Rust mapping explicit and typed instead of
  scattering ad hoc field-line string construction through `Scene`.
  """

  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias RustQ.Rust

  defmodule Field do
    @moduledoc """
    A projected scene field and its Rust storage metadata.
    """

    @enforce_keys [:name, :rust_type, :copy?]
    defstruct [:name, :rust_type, :copy?]

    @type t :: %__MODULE__{name: atom(), rust_type: String.t(), copy?: boolean()}
  end

  defmodule BuildValue do
    @moduledoc """
    Semantic description of a `SceneQueryNode` struct-literal field value.
    """

    @enforce_keys [:kind]
    defstruct [:kind, :field]

    @type kind :: :node_field | :cloned_node_field | :parent_guid_string
    @type t :: %__MODULE__{kind: kind(), field: atom() | nil}
  end

  @spec optional_fields() :: [Field.t()]
  def optional_fields do
    Projection.field_names()
    |> Kernel.--(Projection.required_field_names())
    |> Enum.map(&field/1)
  end

  @spec query_node_fields([Field.t()]) :: [RustQ.Rust.Fragment.t()]
  def query_node_fields(fields \\ optional_fields()) do
    Enum.map(fields, &field_declaration(&1, &1.rust_type))
  end

  @spec record_fields([Field.t()]) :: [RustQ.Rust.Fragment.t()]
  def record_fields(fields \\ optional_fields()) do
    Enum.map(fields, fn
      %Field{name: :parent_guid} = field -> field_declaration(field, "Option<SceneGuid>")
      %Field{} = field -> field_declaration(field, field.rust_type)
    end)
  end

  @spec query_node_build_fields([Field.t()]) :: [RustQ.Rust.Fragment.t()]
  def query_node_build_fields(fields \\ optional_fields()) do
    Enum.map(fields, fn %Field{} = field ->
      field_entry(field.name, build_value_expr(query_node_build_value(field)))
    end)
  end

  @spec record_build_fields([Field.t()]) :: [RustQ.Rust.Fragment.t()]
  def record_build_fields(fields \\ optional_fields()) do
    Enum.map(fields, &field_shorthand(&1.name))
  end

  defp field(name) do
    %Field{
      name: name,
      rust_type: ProjectionNative.rust_type(name),
      copy?: ProjectionNative.rust_copy?(name)
    }
  end

  defp field_declaration(%Field{name: name}, rust_type), do: Rust.field(name, rust_type)

  defp query_node_build_value(%Field{name: :parent_guid}) do
    %BuildValue{kind: :parent_guid_string}
  end

  defp query_node_build_value(%Field{name: name, copy?: true}) do
    %BuildValue{kind: :node_field, field: name}
  end

  defp query_node_build_value(%Field{name: name}) do
    %BuildValue{kind: :cloned_node_field, field: name}
  end

  defp build_value_expr(%BuildValue{kind: :parent_guid_string}) do
    "node.parent_guid.map(|guid| guid.to_string())"
  end

  defp build_value_expr(%BuildValue{kind: :node_field, field: field}) do
    ["node.", Atom.to_string(field)]
  end

  defp build_value_expr(%BuildValue{kind: :cloned_node_field, field: field}) do
    ["node.", Atom.to_string(field), ".clone()"]
  end

  defp field_entry(name, value), do: Rust.stmt([Atom.to_string(name), ": ", value, ","])
  defp field_shorthand(name), do: Rust.stmt([Atom.to_string(name), ","])
end
