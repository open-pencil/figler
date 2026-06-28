use RustQ.Config

unless Code.ensure_loaded?(Figler.Scene.Projection) do
  Code.require_file("lib/figler/scene/projection.ex")
end

unless Code.ensure_loaded?(Figler.Scene.Projection.Native) do
  Code.require_file("lib/figler/scene/projection/native.ex")
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

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus.Decode) do
  Code.require_file("codegen/figler/codegen/native/focus/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Focus) do
  Code.require_file("codegen/figler/codegen/native/focus.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.FieldSkip) do
  Code.require_file("codegen/figler/codegen/native/scene/field_skip.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Decode) do
  Code.require_file("codegen/figler/codegen/native/scene/decode.ex")
end

unless Code.ensure_loaded?(Figler.Codegen.Native.Scene.Attrs) do
  Code.require_file("codegen/figler/codegen/native/scene/attrs.ex")
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

generate "native", "native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content([
    KiwiCodec.RustlerGenerator.source(schema,
      entrypoints: {:nif_stubs, Figler.Native.Entrypoints},
      features: [:full, :sparse, :skip],
      module_prefix: "Figler.Schema"
    ),
    Figler.Codegen.Native.source(schema)
  ])
end
