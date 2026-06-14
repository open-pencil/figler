use RustQ.Config

require_file "lib/fig_kiwi/native_scene_generator.ex"

generate "native", "native/fig_kiwi_native/src/generated.rs" do
  schema =
    "priv/schema/fig.kiwi"
    |> File.read!()
    |> KiwiCodec.parse_schema!()

  content(
    KiwiCodec.RustlerGenerator.render_source!(schema,
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
      template: "native/fig_kiwi_native/src/generated.template.rs",
      extra_splices: [scene_index: FigKiwi.NativeSceneGenerator.render(schema)]
    )
  )
end
