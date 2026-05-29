defmodule FigKiwi.Schema.AnimationTimelineAction do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:play, 0)
  enum_value(:pause, 1)
  enum_value(:toggle_play_pause, 2)
  enum_value(:set_playhead, 3)
end
