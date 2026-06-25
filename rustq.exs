use RustQ.Config

unless Code.ensure_loaded?(FigKiwi.Scene.Projection) do
  Code.require_file("lib/fig_kiwi/scene/projection.ex")
end

unless Code.ensure_loaded?(FigKiwi.Scene.Projection.Native) do
  Code.require_file("lib/fig_kiwi/scene/projection/native.ex")
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

  render(File.read!("native/src/generated.template.rs"),
    filename: "native/src/generated.template.rs",
    include_dir: "native/src",
    rustfmt: true,
    splice:
      KiwiCodec.RustlerGenerator.splices(schema,
        definitions: ["GUID", "Vector", "Matrix", "ParentIndex", "Image", "NodeChange", "Message"],
        entrypoints: [
          decode_guid: "GUID",
          decode_vector: "Vector",
          decode_matrix: "Matrix",
          decode_parent_index: "ParentIndex",
          decode_image: "Image",
          decode_node_change: "NodeChange",
          decode_message: "Message"
        ],
        module_prefix: "FigKiwi.Schema",
        extra_splices: FigKiwi.NativeSceneGenerator.render_splices(schema)
      )
  )
end
