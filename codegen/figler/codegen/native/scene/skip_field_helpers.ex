defmodule Figler.Codegen.Native.Scene.SkipFieldHelpers do
  use RustQ.Meta,
    rust_sources: ["native/src/templates/kiwi_skip_helpers.rs"],
    callable_modules: [
      KiwiCodec.RustlerGenerator.Skip.ValueHelpers,
      KiwiCodec.RustlerGenerator.UnknownFields
    ]

  @moduledoc """
  RustQ-authored scene skip-field descriptor helpers.

  Scene summary/index decoders sometimes receive a Kiwi field id that has
  already been read. These helpers dispatch that field id through compact
  descriptor metadata without relying on raw Rust macro definitions.
  """

  alias RustQ.Meta.AST, as: MetaAST
  alias RustQ.Type, as: R

  # A function pointer: raw, because RustQ would derive a term decoder for an
  # alias of one (rc.11).
  @type fig_scene_skip_field :: %{
          required(:id) => R.u32(),
          required(:repeated) => R.bool(),
          required(:bytes) => R.bool(),
          required(:skip) => R.raw(:KiwiSkipFn)
        }

  @doc """
  Returns type, macro, and function fragments for scene skip-field dispatch.
  """
  @spec fragments() :: [RustQ.Rust.Fragment.t()]
  def fragments do
    __MODULE__.__rustq_type_items__() ++
      MetaAST.macro_items!(__MODULE__, [:fig_scene_skip_field_decoder]) ++
      MetaAST.functions!(__MODULE__, [:fig_scene_skip_field])
  end

  defrustmacro fig_scene_skip_field_decoder(
                 fn: name(:ident),
                 decoder: decoder(:ident),
                 field: field(:ident),
                 definition: definition_name(:literal),
                 skip_fields:
                   repeat do
                     field_id(:literal)
                     field_repeated(:literal)
                     field_bytes(:literal)
                     field_skip(:ident)
                   end
               ) do
    @spec name(R.mut_ref(R.path(:Decoder, R.lifetime(:_))), R.u32()) :: R.nif_result(R.unit())
    defrust name(decoder, field) do
      fig_scene_skip_field(
        decoder,
        field,
        definition_name,
        ref(
          array([
            repeat skip_fields do
              struct_literal(FigSceneSkipField,
                id: field_id,
                repeated: field_repeated,
                bytes: field_bytes,
                skip: field_skip
              )
            end
          ])
        )
      )
    end
  end

  @spec fig_scene_skip_field(
          R.mut_ref(R.path(:Decoder, R.lifetime(:_))),
          R.u32(),
          R.str(),
          R.slice(R.path(:FigSceneSkipField))
        ) :: R.nif_result(R.unit())
  defrust fig_scene_skip_field(decoder, field_id, definition_name, fields) do
    case fields.binary_search_by_key(field_id, fn field -> field.id end) do
      {:ok, index} ->
        field = fields.get(index).unwrap()
        kind = kiwi_skip_descriptor_kind(field.repeated, field.bytes, field.skip)
        kiwi_skip_kind(decoder, kind)

      {:error, _index} ->
        kiwi_unknown_field(decoder, definition_name, field_id)
    end
  end
end
