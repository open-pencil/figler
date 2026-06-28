defmodule Figler.Codegen.Native.Scene.FieldSkip do
  @moduledoc """
  Builds compact Figler scene skip-field decoder invocations.

  Scene summary and scene index decoding need to skip arbitrary Kiwi message
  fields after their field id has already been read. This module keeps that
  schema-shaped skip metadata in one place and emits compact macro invocations
  consumed by `scene_summary_decoders.rs`.
  """

  alias KiwiCodec.RustlerGenerator.RustExpr
  alias RustQ.Rust

  defmodule Decoder do
    @moduledoc """
    Request for one compact scene skip-field decoder invocation.
    """

    @enforce_keys [:definition, :function, :error_name]
    defstruct [:definition, :function, :error_name]

    @type t :: %__MODULE__{
            definition: String.t(),
            function: atom(),
            error_name: String.t()
          }
  end

  @spec decoder(map(), Decoder.t()) :: RustQ.Rust.Fragment.t()
  def decoder(definition_map, %Decoder{
        definition: definition,
        function: function,
        error_name: error
      }) do
    fields =
      definition_map
      |> Map.fetch!(definition)
      |> then(& &1.fields)
      |> Enum.map(&field_entry(&1, definition_map))
      |> Enum.intersperse("\n")

    Rust.item([
      "fig_scene_skip_field_decoder! {\n",
      "    fn ",
      Atom.to_string(function),
      ";\n",
      "    decoder decoder;\n",
      "    definition ",
      inspect(error),
      ";\n",
      "    fields [\n",
      RustExpr.indent(fields, 8),
      "\n    ]\n",
      "}"
    ])
  end

  defp field_entry(field, definition_map) do
    [Integer.to_string(field.id), " => ", field_kind(field, definition_map), ";"]
  end

  defp field_kind(%{array?: true, type: "byte"}, _definition_map),
    do: "bytes kiwi_skip_bytes_value"

  defp field_kind(%{array?: true, type: type}, definition_map),
    do: ["repeated ", skip_function(type, definition_map)]

  defp field_kind(%{type: type}, definition_map),
    do: ["one ", skip_function(type, definition_map)]

  defp skip_function(type, definition_map) do
    cond do
      KiwiCodec.PrimitiveType.name?(type) ->
        "kiwi_skip_#{Macro.underscore(type)}_value"

      Map.has_key?(definition_map, type) ->
        "skip_#{Macro.underscore(type)}_from_decoder"
    end
  end
end
