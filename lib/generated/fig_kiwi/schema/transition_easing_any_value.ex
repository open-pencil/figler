defmodule FigKiwi.Schema.TransitionEasingAnyValue do
  @moduledoc "Generated Kiwi message module for `TransitionEasingAnyValue`."
  use KiwiCodec, kind: :message
  field(:spring_easing, 1, type: FigKiwi.Schema.SpringParams, source_name: "springEasing")
  field(:bezier_easing, 2, type: FigKiwi.Schema.BezierHandles, source_name: "bezierEasing")
end
