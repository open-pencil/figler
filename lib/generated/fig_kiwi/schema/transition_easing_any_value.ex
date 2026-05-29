defmodule FigKiwi.Schema.TransitionEasingAnyValue do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:spring_easing, 1, type: FigKiwi.Schema.SpringParams, source_name: "springEasing")
  field(:bezier_easing, 2, type: FigKiwi.Schema.BezierHandles, source_name: "bezierEasing")
end
