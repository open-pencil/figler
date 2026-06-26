use RustQ.Config

unless Code.ensure_loaded?(Figler.Scene.Projection) do
  Code.require_file("lib/figler/scene/projection.ex")
end

unless Code.ensure_loaded?(Figler.Scene.Projection.Native) do
  Code.require_file("lib/figler/scene/projection/native.ex")
end

unless Code.ensure_loaded?(Figler.Native.Nifs) do
  Code.require_file("lib/figler/native/nifs.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator.Rusty) do
  Code.require_file("codegen/figler/native_scene_generator/rusty.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator.Focus) do
  Code.require_file("codegen/figler/native_scene_generator/focus.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator.Skip) do
  Code.require_file("codegen/figler/native_scene_generator/skip.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator.Sparse) do
  Code.require_file("codegen/figler/native_scene_generator/sparse.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator.Scene) do
  Code.require_file("codegen/figler/native_scene_generator/scene.ex")
end

unless Code.ensure_loaded?(Figler.NativeSceneGenerator) do
  Code.require_file("codegen/figler/native_scene_generator.ex")
end

generate "native", "native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content([
    KiwiCodec.RustlerGenerator.source(schema,
      entrypoints: {:nif_stubs, Figler.Native.Nifs},
      module_prefix: "Figler.Schema"
    ),
    Figler.NativeSceneGenerator.source(schema)
  ])
end
