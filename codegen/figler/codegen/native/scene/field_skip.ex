defmodule Figler.Codegen.Native.Scene.FieldSkip do
  @moduledoc """
  Builds compact Figler scene skip-field decoder invocations.

  Scene summary and scene index decoding need to skip arbitrary Kiwi message
  fields after their field id has already been read. This module keeps that
  schema-shaped skip metadata in one place and emits compact macro invocations
  consumed by `scene_summary_decoders.rs`.
  """

  alias KiwiCodec.Schema.Enum, as: SchemaEnum
  alias RustQ.Rust
  alias RustQ.Rust.AST.Builder, as: A

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

  defmodule Field do
    @moduledoc """
    One schema field skip operation rendered as a macro arm.
    """

    @enforce_keys [:id, :repeated, :bytes, :function]
    defstruct [:id, :repeated, :bytes, :function]

    @type t :: %__MODULE__{
            id: non_neg_integer(),
            repeated: boolean(),
            bytes: boolean(),
            function: String.t()
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
      |> Enum.map(&field(&1, definition_map))
      |> Enum.sort_by(& &1.id)

    Rust.ast_item(
      A.macro_item_token_call(
        :fig_scene_skip_field_decoder,
        skip_decoder_tokens(function, error, fields)
      )
    )
  end

  defp field(%{id: id, array?: true, type: "byte"}, _definition_map) do
    %Field{id: id, repeated: false, bytes: true, function: "kiwi_skip_bytes_value"}
  end

  defp field(%{id: id, array?: true, type: type}, definition_map) do
    %Field{id: id, repeated: true, bytes: false, function: skip_function(type, definition_map)}
  end

  defp field(%{id: id, type: type}, definition_map) do
    %Field{id: id, repeated: false, bytes: false, function: skip_function(type, definition_map)}
  end

  defp skip_decoder_tokens(function, error, fields) do
    [
      "fn ",
      A.path(function),
      "; decoder ",
      A.path(:decoder),
      "; field ",
      A.path(:field),
      "; definition ",
      A.lit(error),
      "; skip_fields [",
      Enum.map(fields, &field_tokens/1),
      "]"
    ]
  end

  defp field_tokens(%Field{} = field) do
    [
      A.lit(field.id),
      " => ",
      A.lit(field.repeated),
      " ",
      A.lit(field.bytes),
      " ",
      A.path(field.function),
      "; "
    ]
  end

  defp skip_function(type, definition_map) do
    cond do
      KiwiCodec.PrimitiveType.name?(type) ->
        "kiwi_skip_#{Macro.underscore(type)}_value"

      match?(%SchemaEnum{}, Map.get(definition_map, type)) ->
        "kiwi_skip_uint_value"

      Map.has_key?(definition_map, type) ->
        "skip_#{Macro.underscore(type)}_from_decoder"
    end
  end
end
