defmodule FiglerRenderConsumer do
  alias Figler.Schema

  def verify do
    document = guid(0, 0)
    canvas = guid(0, 1)
    rectangle = guid(1, 1)

    nodes = [
      struct(Schema.NodeChange, guid: document, type: :document, name: "Document"),
      struct(Schema.NodeChange,
        guid: canvas,
        parent_index: struct(Schema.ParentIndex, guid: document, position: "!"),
        type: :canvas,
        name: "Page"
      ),
      struct(Schema.NodeChange,
        guid: rectangle,
        parent_index: struct(Schema.ParentIndex, guid: canvas, position: "!"),
        type: :rectangle,
        name: "Card",
        size: struct(Schema.Vector, x: 20.0, y: 10.0),
        transform:
          struct(Schema.Matrix,
            m00: 1.0,
            m01: 0.0,
            m02: 0.0,
            m10: 0.0,
            m11: 1.0,
            m12: 0.0
          ),
        visible: true,
        fill_paints: [
          struct(Schema.Paint,
            type: :solid,
            visible: true,
            opacity: 1.0,
            color: struct(Schema.Color, r: 1.0, g: 0.0, b: 0.0, a: 1.0)
          )
        ]
      )
    ]

    message = struct(Schema.Message, type: :node_changes, session_id: 0, node_changes: nodes)

    with {:ok, png, %{warnings: []}} <-
           message
           |> Figler.encode_message()
           |> Figler.Render.render(root: "1:1", strict: true) do
      match?(<<137, 80, 78, 71, _::binary>>, png) and
        :code.is_loaded(Figler.Codegen.Native) == false and
        :code.is_loaded(Figler.Scene.Projection.Native) == false and
        :code.is_loaded(RustQ) == false and
        :code.is_loaded(Reach) == false and
        :code.is_loaded(ExDNA) == false and
        :code.is_loaded(VibeKit) == false
    end
  end

  defp guid(session_id, local_id),
    do: struct(Schema.GUID, session_id: session_id, local_id: local_id)
end
