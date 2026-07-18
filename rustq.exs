use RustQ.Config

alias RustQ.Rustler.Nif

unless Code.ensure_loaded?(Figler.Scene.Projection) do
  Code.require_file("lib/figler/scene/projection.ex")
end

unless Code.ensure_loaded?(Figler.Scene.Projection.Native) do
  Code.require_file("lib/figler/scene/projection/native.ex")
end

unless Code.ensure_loaded?(Figler.Scene.Graph.Seed.Projection) do
  Code.require_file("lib/figler/scene/graph/seed/projection.ex")
end

unless Code.ensure_loaded?(Figler.Native.Entrypoints) do
  Code.require_file("lib/figler/native/entrypoints.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.AtomCache) do
  Code.require_file("codegen/figler/codegen/native/atom_cache.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.SupportFunction) do
  Code.require_file("codegen/figler/codegen/native/support_function.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.RenderProjection) do
  Code.require_file("codegen/figler/codegen/native/render_projection.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus.Decode) do
  Code.require_file("codegen/figler/codegen/native/focus/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus) do
  Code.require_file("codegen/figler/codegen/native/focus.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.FieldSkip) do
  Code.require_file("codegen/figler/codegen/native/scene/field_skip.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.SkipFieldHelpers) do
  Code.require_file("codegen/figler/codegen/native/scene/skip_field_helpers.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Decode) do
  Code.require_file("codegen/figler/codegen/native/scene/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Record) do
  Code.require_file("codegen/figler/codegen/native/scene/record.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene) do
  Code.require_file("codegen/figler/codegen/native/scene.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native) do
  Code.require_file("codegen/figler/codegen/native.ex")
end

template_nif_functions =
  Nif.functions_from_source(
    "native/src/templates/scene_nifs.rs",
    Figler.Native.Entrypoints.template_nifs()
  )

navigation_nif_functions = Figler.Codegen.Native.SupportFunction.scene_navigation_nif_items()

generate "native", "native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content([
    KiwiCodec.RustlerGenerator.source(schema,
      entrypoints: [],
      definitions: ["Message"],
      features: [:sparse, :skip],
      sparse_messages: :descriptor,
      decoder_sources: ["native/src/runtime.rs"],
      module_prefix: "Figler.Schema"
    ),
    Figler.Codegen.Native.source(schema)
  ])
end

generate "native_stubs", "lib/figler/native/generated_stubs.ex" do
  content(
    Nif.stubs_from_functions(
      template_nif_functions ++ navigation_nif_functions,
      Figler.Native.GeneratedStubs
    )
  )
end
