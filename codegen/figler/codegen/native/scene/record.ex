defmodule Figler.Codegen.Native.Scene.Record do
  @moduledoc """
  Builds scene record/query-node field splices from projection metadata.

  These splices are Rust struct field declarations and struct literal entries,
  so they live at the template boundary rather than in `defrust` functions.
  The module keeps the projection-to-Rust mapping explicit and typed instead of
  scattering ad hoc field-line string construction through `Scene`.
  """

  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rustler.Schema

  defmodule Field do
    @moduledoc """
    A projected scene field and its Rust storage metadata.
    """

    @enforce_keys [:name, :rust_type, :copy?]
    defstruct [:name, :rust_type, :copy?]

    @type t :: %__MODULE__{
            name: atom(),
            rust_type: RustQ.Rust.rust_type(),
            copy?: boolean()
          }
  end

  @spec optional_fields() :: [Field.t()]
  def optional_fields do
    Projection.field_names()
    |> Kernel.--(Projection.required_field_names())
    |> Enum.map(&field/1)
  end

  @spec query_node_fields([Field.t()]) :: [RustQ.Rust.Field.t()]
  def query_node_fields(fields \\ optional_fields()) do
    fields
    |> Enum.map(&{&1.name, &1.rust_type})
    |> Schema.struct_fields()
  end

  @spec record_fields([Field.t()]) :: [RustQ.Rust.Field.t()]
  def record_fields(fields \\ optional_fields()) do
    fields
    |> Enum.map(fn
      %Field{name: :parent_guid} ->
        {:parent_guid, A.type_path(:Option, generics: [A.type_path(:SceneGuid)])}

      %Field{name: name, rust_type: rust_type} ->
        {name, rust_type}
    end)
    |> Schema.struct_fields()
  end

  @spec record_build_fields([Field.t()]) :: [RustQ.Rust.ShorthandField.t()]
  def record_build_fields(fields \\ optional_fields()) do
    fields |> Enum.map(& &1.name) |> Schema.shorthand_fields()
  end

  @spec seed_record_expr() :: RustQ.Rust.AST.VecLiteral.t()
  def seed_record_expr do
    SeedProjection.native_record_fields()
    |> Enum.map(&A.var/1)
    |> A.vec()
  end

  defp field(name) do
    descriptor = Projection.field!(name)

    %Field{
      name: name,
      rust_type: ProjectionNative.rust_type(descriptor),
      copy?: ProjectionNative.rust_copy?(descriptor)
    }
  end
end
