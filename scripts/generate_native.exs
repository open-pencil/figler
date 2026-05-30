schema = FigKiwi.schema()

KiwiCodec.RustlerGenerator.render!(schema,
  definitions: ["GUID", "Vector", "Matrix", "ParentIndex", "Image", "NodeChange"],
  entrypoints: [
    decode_guid: "GUID",
    decode_vector: "Vector",
    decode_matrix: "Matrix",
    decode_parent_index: "ParentIndex",
    decode_image: "Image",
    decode_node_change: "NodeChange"
  ],
  module_prefix: "FigKiwi.Schema",
  template: "native/fig_kiwi_native/src/generated.template.rs",
  out: "native/fig_kiwi_native/src/generated.rs"
)
