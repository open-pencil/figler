defmodule Figler.Schema.PrototypeAction do
  @moduledoc "Generated Kiwi message module for `PrototypeAction`."
  use KiwiCodec, kind: :message
  field(:transition_node_id, 1, type: Figler.Schema.GUID, source_name: "transitionNodeID")

  field(:transition_type, 2,
    type: {:enum, Figler.Schema.TransitionType},
    source_name: "transitionType"
  )

  field(:transition_duration, 3, type: :float, source_name: "transitionDuration")
  field(:easing_type, 4, type: {:enum, Figler.Schema.EasingType}, source_name: "easingType")
  field(:transition_timeout, 5, type: :float, source_name: "transitionTimeout")

  field(:transition_should_smart_animate, 6,
    type: :bool,
    source_name: "transitionShouldSmartAnimate"
  )

  field(:connection_type, 7,
    type: {:enum, Figler.Schema.ConnectionType},
    source_name: "connectionType"
  )

  field(:overlay_relative_position, 9,
    type: Figler.Schema.Vector,
    source_name: "overlayRelativePosition"
  )

  field(:navigation_type, 10,
    type: {:enum, Figler.Schema.NavigationType},
    source_name: "navigationType"
  )

  field(:transition_preserve_scroll, 11, type: :bool, source_name: "transitionPreserveScroll")
  field(:easing_function, 12, repeated: true, type: :float, source_name: "easingFunction")
  field(:extra_scroll_offset, 13, type: Figler.Schema.Vector, source_name: "extraScrollOffset")

  field(:transition_reset_scroll_position, 25,
    type: :bool,
    source_name: "transitionResetScrollPosition"
  )

  field(:transition_reset_interactive_components, 26,
    type: :bool,
    source_name: "transitionResetInteractiveComponents"
  )

  field(:transition_overrides_enabled, 42, type: :bool, source_name: "transitionOverridesEnabled")
  field(:connection_url, 8, type: :string, source_name: "connectionURL")
  field(:open_url_in_new_tab, 18, type: :bool, source_name: "openUrlInNewTab")
  field(:link_param, 34, type: Figler.Schema.VariableData, source_name: "linkParam")
  field(:cms_target, 35, type: Figler.Schema.CMSItemPageTarget, source_name: "cmsTarget")
  field(:target_variable_id, 14, type: Figler.Schema.GUID, source_name: "targetVariableID")

  field(:target_variable_value, 15,
    type: Figler.Schema.VariableAnyValue,
    source_name: "targetVariableValue"
  )

  field(:target_variable, 19,
    type: Figler.Schema.PrototypeVariableTarget,
    source_name: "targetVariable"
  )

  field(:target_variable_data, 20,
    type: Figler.Schema.VariableData,
    source_name: "targetVariableData"
  )

  field(:media_action, 16, type: {:enum, Figler.Schema.MediaAction}, source_name: "mediaAction")

  field(:transition_reset_video_position, 17,
    type: :bool,
    source_name: "transitionResetVideoPosition"
  )

  field(:media_skip_to_time, 21, type: :float, source_name: "mediaSkipToTime")
  field(:media_skip_by_amount, 22, type: :float, source_name: "mediaSkipByAmount")
  field(:media_playback_rate, 36, type: :float, source_name: "mediaPlaybackRate")

  field(:conditions, 23,
    repeated: true,
    type: Figler.Schema.VariableData,
    source_name: "conditions"
  )

  field(:conditional_actions, 24,
    repeated: true,
    type: Figler.Schema.ConditionalActions,
    source_name: "conditionalActions"
  )

  field(:target_variable_set_id, 27,
    type: Figler.Schema.VariableSetID,
    source_name: "targetVariableSetID"
  )

  field(:target_variable_mode_id, 28,
    type: Figler.Schema.GUID,
    source_name: "targetVariableModeID"
  )

  field(:target_variable_set_key, 29, type: :string, source_name: "targetVariableSetKey")

  field(:variable_set_target_extension_id, 38,
    type: Figler.Schema.VariableSetID,
    source_name: "variableSetTargetExtensionId"
  )

  field(:animation_type, 30,
    type: {:enum, Figler.Schema.AnimationType},
    source_name: "animationType"
  )

  field(:animation_target_id, 31, type: Figler.Schema.GUID, source_name: "animationTargetId")

  field(:animation_phase, 32,
    type: {:enum, Figler.Schema.AnimationPhase},
    source_name: "animationPhase"
  )

  field(:animation_state, 33, type: Figler.Schema.AnimationState, source_name: "animationState")
  field(:simple_link, 37, type: :bool, source_name: "simpleLink")

  field(:animation_timeline_action, 39,
    type: {:enum, Figler.Schema.AnimationTimelineAction},
    source_name: "animationTimelineAction"
  )

  field(:animation_timeline_def_id, 41,
    type: Figler.Schema.GUID,
    source_name: "animationTimelineDefId"
  )

  field(:animation_skip_to_time, 40, type: :float, source_name: "animationSkipToTime")
end
