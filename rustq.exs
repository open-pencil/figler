unless Code.ensure_loaded?(Figler.Mix.KiwiCodegen),
  do: Code.require_file("lib/mix/figler/kiwi_codegen.ex")

Figler.Mix.KiwiCodegen.load!()

use RustQ.Config

alias RustQ.Rustler.Nif

# The generators and the projections they read, in dependency order. `rustq.gen` does not
# compile the project first, since this file regenerates some of its sources.
for {module, file} <- [
      {Figler.Render.Projection, "lib/figler/render/projection.ex"},
      {Figler.Scene.Projection, "lib/figler/scene/projection.ex"},
      {Figler.Scene.Projection.Native, "codegen/figler/scene/projection/native.ex"},
      {Figler.Codegen.Native.AtomCache, "codegen/figler/codegen/native/atom_cache.ex"},
      {Figler.Codegen.Native.SupportFunction,
       "codegen/figler/codegen/native/support_function.ex"},
      {Figler.Codegen.Native.RenderProjection,
       "codegen/figler/codegen/native/render_projection.ex"},
      {Figler.Codegen.Native.Focus.Decode, "codegen/figler/codegen/native/focus/decode.ex"},
      {Figler.Codegen.Native.Focus, "codegen/figler/codegen/native/focus.ex"},
      {Figler.Codegen.Native.Scene.FieldSkip,
       "codegen/figler/codegen/native/scene/field_skip.ex"},
      {Figler.Codegen.Native.Scene.SkipFieldHelpers,
       "codegen/figler/codegen/native/scene/skip_field_helpers.ex"},
      {Figler.Codegen.Native.Scene.Decode, "codegen/figler/codegen/native/scene/decode.ex"},
      {Figler.Codegen.Native.Scene.Record, "codegen/figler/codegen/native/scene/record.ex"},
      {Figler.Codegen.Native.Scene, "codegen/figler/codegen/native/scene.ex"},
      {Figler.Codegen.Native.Graph.Records, "codegen/figler/codegen/native/graph/records.ex"},
      {Figler.Codegen.Native.Graph.Prepare, "codegen/figler/codegen/native/graph/prepare.ex"},
      {Figler.Codegen.Native.Graph.SourceIndex,
       "codegen/figler/codegen/native/graph/source_index.ex"},
      {Figler.Codegen.Native.Graph.Occurrence,
       "codegen/figler/codegen/native/graph/occurrence.ex"},
      {Figler.Codegen.Native.Graph.Claims, "codegen/figler/codegen/native/graph/claims.ex"},
      {Figler.Codegen.Native.Graph.Bindings, "codegen/figler/codegen/native/graph/bindings.ex"},
      {Figler.Codegen.Native.Graph.Layer, "codegen/figler/codegen/native/graph/layer.ex"},
      {Figler.Codegen.Native.Graph.Geometry, "codegen/figler/codegen/native/graph/geometry.ex"},
      {Figler.Codegen.Native.Graph.Variables, "codegen/figler/codegen/native/graph/variables.ex"},
      {Figler.Codegen.Native.Graph.VariableBindings,
       "codegen/figler/codegen/native/graph/variable_bindings.ex"},
      {Figler.Codegen.Native.Graph.Interpreter,
       "codegen/figler/codegen/native/graph/interpreter.ex"},
      {Figler.Codegen.Native.Graph.Materialize,
       "codegen/figler/codegen/native/graph/materialize.ex"},
      {Figler.Codegen.Native, "codegen/figler/codegen/native.ex"}
    ],
    not Code.ensure_loaded?(module),
    do: Code.require_file(file)

template_nif_functions = Figler.Codegen.Native.Scene.template_nif_functions()

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
      features: [:sparse, :skip, :records],
      sparse_messages: :descriptor,
      decoder_sources: ["native/src/runtime.rs"],
      unknown_fields: :runtime_schema,
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
