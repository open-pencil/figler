defmodule Figler.Schema.NodeBehaviors do
  @moduledoc "Generated Kiwi message module for `NodeBehaviors`."
  use KiwiCodec, kind: :message
  field(:link, 1, type: Figler.Schema.LinkBehavior, source_name: "link")
  field(:appear, 2, type: Figler.Schema.AppearBehavior, source_name: "appear")
  field(:hover, 3, type: Figler.Schema.HoverBehavior, source_name: "hover")
  field(:press, 4, type: Figler.Schema.PressBehavior, source_name: "press")
  field(:focus, 5, type: Figler.Schema.FocusBehavior, source_name: "focus")

  field(:scroll_parallax, 6,
    type: Figler.Schema.ScrollParallaxBehavior,
    source_name: "scrollParallax"
  )

  field(:scroll_transform, 7,
    type: Figler.Schema.ScrollTransformBehavior,
    source_name: "scrollTransform"
  )

  field(:cursor, 8, type: Figler.Schema.CursorBehavior, source_name: "cursor")
  field(:marquee, 9, type: Figler.Schema.MarqueeBehavior, source_name: "marquee")
  field(:code, 10, repeated: true, type: Figler.Schema.CodeBehavior, source_name: "code")
end
