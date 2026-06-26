use RustQ.Config

unless Code.ensure_loaded?(FigKiwi.Scene.Projection) do
  Code.require_file("lib/fig_kiwi/scene/projection.ex")
end

unless Code.ensure_loaded?(FigKiwi.Scene.Projection.Native) do
  Code.require_file("lib/fig_kiwi/scene/projection/native.ex")
end

unless Code.ensure_loaded?(FigKiwi.Native.Nifs) do
  Code.require_file("lib/fig_kiwi/native/nifs.ex")
end

unless Code.ensure_loaded?(FigKiwi.NativeSceneGenerator.Focus) do
  Code.require_file("lib/fig_kiwi/native_scene_generator/focus.ex")
end

unless Code.ensure_loaded?(FigKiwi.NativeSceneGenerator.Skip) do
  Code.require_file("lib/fig_kiwi/native_scene_generator/skip.ex")
end

unless Code.ensure_loaded?(FigKiwi.NativeSceneGenerator.Sparse) do
  Code.require_file("lib/fig_kiwi/native_scene_generator/sparse.ex")
end

unless Code.ensure_loaded?(FigKiwi.NativeSceneGenerator.Scene) do
  Code.require_file("lib/fig_kiwi/native_scene_generator/scene.ex")
end

unless Code.ensure_loaded?(FigKiwi.NativeSceneGenerator) do
  Code.require_file("lib/fig_kiwi/native_scene_generator.ex")
end

generate "native", "native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content [
    KiwiCodec.RustlerGenerator.source(schema,
      entrypoints: {:nif_stubs, FigKiwi.Native.Nifs},
      module_prefix: "FigKiwi.Schema"
    ),
    FigKiwi.NativeSceneGenerator.source(schema)
  ]
end
