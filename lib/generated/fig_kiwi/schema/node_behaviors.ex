defmodule FigKiwi.Schema.NodeBehaviors do
  @moduledoc "Generated Kiwi message module for `NodeBehaviors`."
  use KiwiCodec, kind: :message
  field(:link, 1, type: FigKiwi.Schema.LinkBehavior, source_name: "link")
  field(:appear, 2, type: FigKiwi.Schema.AppearBehavior, source_name: "appear")
  field(:hover, 3, type: FigKiwi.Schema.HoverBehavior, source_name: "hover")
  field(:press, 4, type: FigKiwi.Schema.PressBehavior, source_name: "press")
  field(:focus, 5, type: FigKiwi.Schema.FocusBehavior, source_name: "focus")

  field(:scroll_parallax, 6,
    type: FigKiwi.Schema.ScrollParallaxBehavior,
    source_name: "scrollParallax"
  )

  field(:scroll_transform, 7,
    type: FigKiwi.Schema.ScrollTransformBehavior,
    source_name: "scrollTransform"
  )

  field(:cursor, 8, type: FigKiwi.Schema.CursorBehavior, source_name: "cursor")
  field(:marquee, 9, type: FigKiwi.Schema.MarqueeBehavior, source_name: "marquee")
  field(:code, 10, repeated: true, type: FigKiwi.Schema.CodeBehavior, source_name: "code")
end
