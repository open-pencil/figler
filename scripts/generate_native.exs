schema = FigKiwi.schema()

KiwiCodec.RustlerGenerator.render!(schema,
  definitions: ["GUID", "Vector", "Matrix"],
  entrypoints: [decode_guid: "GUID", decode_vector: "Vector", decode_matrix: "Matrix"],
  module_prefix: "FigKiwi.Schema",
  template: "native/fig_kiwi_native/src/generated.template.rs",
  out: "native/fig_kiwi_native/src/generated.rs"
)
