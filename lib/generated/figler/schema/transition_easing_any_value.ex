defmodule Figler.Schema.TransitionEasingAnyValue do
  @moduledoc "Generated Kiwi message module for `TransitionEasingAnyValue`."
  use KiwiCodec, kind: :message
  field(:spring_easing, 1, type: Figler.Schema.SpringParams, source_name: "springEasing")
  field(:bezier_easing, 2, type: Figler.Schema.BezierHandles, source_name: "bezierEasing")
end
