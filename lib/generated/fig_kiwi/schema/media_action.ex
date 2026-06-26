defmodule FigKiwi.Schema.MediaAction do
  @moduledoc "Generated Kiwi enum module for `MediaAction`."
  use KiwiCodec, kind: :enum
  enum_value(:play, 0)
  enum_value(:pause, 1)
  enum_value(:toggle_play_pause, 2)
  enum_value(:mute, 3)
  enum_value(:unmute, 4)
  enum_value(:toggle_mute_unmute, 5)
  enum_value(:skip_forward, 6)
  enum_value(:skip_backward, 7)
  enum_value(:skip_to, 8)
  enum_value(:set_playback_rate, 9)
end
