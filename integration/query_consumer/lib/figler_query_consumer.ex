defmodule FiglerQueryConsumer do
  def verify do
    message = struct(Figler.Schema.Message, type: :node_changes, session_id: 0, node_changes: [])
    encoded = Figler.encode_message(message)
    decoded = Figler.decode_message(encoded)
    sparse = Figler.decode_sparse_message(encoded)
    document = Figler.decode!(encoded)
    roundtrip = Figler.encode!(document)

    decoded.type == :node_changes and sparse.type == :node_changes and
      Figler.decode!(roundtrip).message == message and
      :code.is_loaded(Skia) == false and
      :code.is_loaded(Figler.Codegen.Native) == false and
      :code.is_loaded(Figler.Scene.Projection.Native) == false and
      :code.is_loaded(RustQ) == false and
      :code.is_loaded(Reach) == false and
      :code.is_loaded(ExDNA) == false and
      :code.is_loaded(VibeKit) == false
  end
end
