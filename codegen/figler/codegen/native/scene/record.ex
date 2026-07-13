defmodule Figler.Codegen.Native.Scene.Record do
  @moduledoc """
  Builds complete scene record/query-node structs from projection metadata.

  Struct declarations and literal fields live at the template boundary because
  their shape depends on the projection schema rather than handwritten Rust.
  """

  alias Figler.Scene.Graph.Seed.Projection, as: SeedProjection
  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias RustQ.Rust
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rust.AST.TypeBuilder, as: T
  alias RustQ.Rustler.Schema

  @spec optional_fields() :: [map()]
  def optional_fields do
    Enum.reject(Projection.fields(), &Map.get(&1, :required?, false))
  end

  @spec query_node_struct() :: Rust.Struct.t()
  def query_node_struct do
    Rust.struct(:SceneQueryNode,
      vis: :pub,
      derive: ["rustler::NifMap"],
      fields:
        Schema.struct_fields(guid: T.path(:String), node_type: T.path(:String)) ++
          query_node_fields()
    )
  end

  @spec scene_node_record_struct() :: Rust.Struct.t()
  def scene_node_record_struct do
    Rust.struct(:SceneNodeRecord,
      derive: [:Clone, :Debug],
      fields:
        Schema.struct_fields(guid: T.path(:SceneGuid), node_type: T.ref(:str, lifetime: :static)) ++
          record_fields() ++
          Schema.struct_fields(parent: option_type(:usize), children: T.vec(:usize))
    )
  end

  @spec record_build_fields([map()]) :: [RustQ.Rust.ShorthandField.t()]
  def record_build_fields(fields \\ optional_fields()) do
    fields |> Enum.map(& &1.name) |> Schema.shorthand_fields()
  end

  @spec seed_record_expr() :: RustQ.Rust.AST.VecLiteral.t()
  def seed_record_expr do
    SeedProjection.native_record_fields()
    |> Enum.map(&A.var/1)
    |> A.vec()
  end

  defp query_node_fields do
    optional_fields()
    |> Enum.map(&{&1.name, ProjectionNative.rust_type(&1)})
    |> Schema.struct_fields()
  end

  defp record_fields do
    optional_fields()
    |> Enum.map(&{&1.name, record_rust_type(&1)})
    |> Schema.struct_fields()
  end

  defp record_rust_type(%{source: {:parent_index, :guid}}), do: option_type(:SceneGuid)
  defp record_rust_type(field), do: ProjectionNative.rust_type(field)

  defp option_type(type), do: T.path(:Option, generics: [T.path(type)])
end
