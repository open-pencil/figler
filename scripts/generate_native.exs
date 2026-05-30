schema = FigKiwi.schema()

KiwiCodec.RustlerGenerator.render!(schema,
  definitions: ["GUID", "Vector", "Matrix", "ParentIndex", "Image"],
  entrypoints: [
    decode_guid: "GUID",
    decode_vector: "Vector",
    decode_matrix: "Matrix",
    decode_parent_index: "ParentIndex",
    decode_image: "Image"
  ],
  module_prefix: "FigKiwi.Schema",
  template: "native/fig_kiwi_native/src/generated.template.rs",
  out: "native/fig_kiwi_native/src/generated.rs"
)
