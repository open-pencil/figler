defmodule Figler.Codegen.Native.AtomCache do
  @moduledoc """
  Builds cached Rustler atom metadata from scene projection fields.

  Static names, RustQ type metadata, and Rust declarations all share the same
  projection-derived naming rule.
  """

  alias Figler.Scene.Projection
  alias RustQ.Rust
  alias RustQ.Rust.AST.Builder, as: A

  @static_names Map.new(Projection.field_names(), fn field ->
                  name = field |> Atom.to_string() |> String.upcase()
                  {field, :"#{name}_ATOM"}
                end)

  @doc false
  defmacro use_rustq_meta(opts) do
    {fields_ast, opts} = Keyword.pop!(opts, :atom_fields)
    {fields, _binding} = Code.eval_quoted(fields_ast, [], __CALLER__)

    static_types =
      Enum.map(fields, fn field ->
        {static_name(field), quote(do: RustQ.Type.raw(:"OnceLock<Atom>"))}
      end)

    opts = Keyword.put(opts, :static_types, static_types)

    quote do
      use RustQ.Meta, unquote(opts)
    end
  end

  @spec static_name(atom()) :: atom()
  def static_name(field), do: Map.fetch!(@static_names, field)

  @spec static_var_map([atom()]) :: %{atom() => atom()}
  def static_var_map(fields), do: Map.new(fields, &{&1, static_name(&1)})

  @doc "Builds a structural `OnceLock<Atom>` static declaration."
  @spec static(atom()) :: Rust.Fragment.t()
  def static(field) do
    field
    |> static_name()
    |> A.static(
      A.type_path(:OnceLock, generics: [A.type_path(:Atom)]),
      A.path_call([:OnceLock, :new])
    )
    |> Rust.ast_item()
  end
end
