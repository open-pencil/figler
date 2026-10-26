defmodule Figler.Codegen.Native.Scene.Record do
  @moduledoc """
  Builds complete scene record/query-node structs from projection metadata.

  Struct declarations and literal fields live at the template boundary because
  their shape depends on the projection schema rather than handwritten Rust.
  """

  alias Figler.Scene.Projection
  alias Figler.Scene.Projection.Native, as: ProjectionNative
  alias RustQ.Rust.AST
  alias RustQ.Rust.AST.TypeBuilder, as: T
  alias RustQ.Rustler.Schema

  @spec optional_fields() :: [map()]
  def optional_fields do
    Enum.reject(Projection.fields(), &Map.get(&1, :required?, false))
  end

  @spec query_node_struct() :: AST.Struct.t()
  def query_node_struct do
    %AST.Struct{
      name: :SceneQueryNode,
      vis: :pub,
      derive: ["rustler::NifMap"],
      fields:
        Schema.struct_fields(guid: T.path(:String), node_type: T.path(:String)) ++
          query_node_fields()
    }
  end

  @spec scene_node_record_struct() :: AST.Struct.t()
  def scene_node_record_struct do
    %AST.Struct{
      name: :SceneNodeRecord,
      derive: [:Clone, :Debug],
      fields:
        Schema.struct_fields(guid: T.path(:SceneGuid), node_type: T.ref(:str, lifetime: :static)) ++
          record_fields() ++
          Schema.struct_fields(
            parent: T.path(:Option, generics: [T.path(:usize)]),
            children: T.vec(:usize)
          )
    }
  end

  @spec record_build_fields([map()]) :: [RustQ.Rust.Fragment.t()]
  def record_build_fields(fields \\ optional_fields()) do
    fields |> Enum.map(& &1.name) |> Schema.shorthand_fields()
  end

  defp query_node_fields do
    optional_fields()
    |> Enum.map(&{&1.name, ProjectionNative.rust_type(&1)})
    |> Schema.struct_fields()
  end

  @doc """
  The map type of a scene record's projected fields, which `defrust` code reading a record
  names, so RustQ knows their types.
  """
  @spec record_type() :: Macro.t()
  def record_type do
    fields =
      [guid: quote(do: RustQ.Type.path(:SceneGuid))] ++
        Enum.map(optional_fields(), &{&1.name, record_spec(&1)})

    {:%{}, [], Enum.map(fields, fn {name, spec} -> {{:required, [], [name]}, spec} end)}
  end

  defp record_fields do
    optional_fields()
    |> Enum.map(&{&1.name, RustQ.Spec.type(record_spec(&1)).ast})
    |> Schema.struct_fields()
  end

  # A record keeps its parent's GUID, which the query node writes as text.
  defp record_spec(%{source: {:parent_index, :guid}}),
    do: quote(do: RustQ.Type.option(RustQ.Type.path(:SceneGuid)))

  defp record_spec(field), do: ProjectionNative.rust_spec(field)
end
