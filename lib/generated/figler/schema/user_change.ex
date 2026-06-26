defmodule Figler.Schema.UserChange do
  @moduledoc "Generated Kiwi message module for `UserChange`."
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:stable_session_id, 44, type: :string, source_name: "stableSessionID")
  field(:connected, 2, type: :bool, source_name: "connected")
  field(:name, 3, type: :string, source_name: "name")
  field(:color, 4, type: Figler.Schema.Color, source_name: "color")
  field(:image_url, 5, type: :string, source_name: "imageURL")
  field(:viewport, 6, type: Figler.Schema.Viewport, source_name: "viewport")
  field(:mouse, 7, type: Figler.Schema.Mouse, source_name: "mouse")
  field(:selection, 8, repeated: true, type: Figler.Schema.GUID, source_name: "selection")
  field(:observing, 9, repeated: true, type: :uint, source_name: "observing")
  field(:device_name, 10, type: :string, source_name: "deviceName")

  field(:recent_clicks, 11,
    repeated: true,
    type: Figler.Schema.Click,
    source_name: "recentClicks"
  )

  field(:scroll_positions, 12,
    repeated: true,
    type: Figler.Schema.ScrollPosition,
    source_name: "scrollPositions"
  )

  field(:triggered_overlays, 13,
    repeated: true,
    type: Figler.Schema.TriggeredOverlay,
    source_name: "triggeredOverlays"
  )

  field(:user_id, 14, type: :string, source_name: "userID")

  field(:last_triggered_hotspot, 15,
    type: Figler.Schema.GUID,
    source_name: "lastTriggeredHotspot"
  )

  field(:last_triggered_prototype_interaction_id, 16,
    type: Figler.Schema.GUID,
    source_name: "lastTriggeredPrototypeInteractionID"
  )

  field(:last_triggered_object_animation_index, 38,
    type: :uint,
    source_name: "lastTriggeredObjectAnimationIndex"
  )

  field(:triggered_overlays_data, 17,
    repeated: true,
    type: Figler.Schema.TriggeredOverlayData,
    source_name: "triggeredOverlaysData"
  )

  field(:playback_updates, 18,
    repeated: true,
    type: Figler.Schema.PlaybackUpdate,
    source_name: "playbackUpdates"
  )

  field(:chat_message, 19, type: Figler.Schema.ChatMessage, source_name: "chatMessage")
  field(:voice_metadata, 20, type: Figler.Schema.VoiceMetadata, source_name: "voiceMetadata")
  field(:can_write, 21, type: :bool, source_name: "canWrite")
  field(:high_five_status, 22, type: :bool, source_name: "highFiveStatus")

  field(:instance_state_changes, 23,
    repeated: true,
    type: Figler.Schema.InstanceStateChange,
    source_name: "instanceStateChanges"
  )

  field(:text_cursor, 24, type: Figler.Schema.TextCursor, source_name: "textCursor")
  field(:text_selection, 25, type: Figler.Schema.TextSelection, source_name: "textSelection")
  field(:connected_at_time_s, 26, type: :uint, source_name: "connectedAtTimeS")
  field(:focus_on_text_cursor, 27, type: :bool, source_name: "focusOnTextCursor")
  field(:heartbeat, 28, type: {:enum, Figler.Schema.Heartbeat}, source_name: "heartbeat")

  field(:triggered_set_variable_action_data, 29,
    repeated: true,
    type: Figler.Schema.TriggeredSetVariableActionData,
    source_name: "triggeredSetVariableActionData"
  )

  field(:video_state_change_data, 30,
    repeated: true,
    type: Figler.Schema.VideoStateChangeData,
    source_name: "videoStateChangeData"
  )

  field(:client_id, 31, type: :string, source_name: "clientID")
  field(:focused_slide_id, 32, type: Figler.Schema.GUID, source_name: "focusedSlideId")

  field(:triggered_set_variable_mode_action_data, 33,
    repeated: true,
    type: Figler.Schema.TriggeredSetVariableModeActionData,
    source_name: "triggeredSetVariableModeActionData"
  )

  field(:april_fun_cursor, 34, type: Figler.Schema.AprilFunCursor, source_name: "aprilFunCursor")

  field(:embedded_prototype_data, 35,
    repeated: true,
    type: Figler.Schema.EmbeddedPrototypeData,
    source_name: "embeddedPrototypeData"
  )

  field(:active_slides_embeddable_prototype, 36,
    type: Figler.Schema.GUID,
    source_name: "activeSlidesEmbeddablePrototype"
  )

  field(:active_embedded_prototypes, 43,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "activeEmbeddedPrototypes"
  )

  field(:active_code_component_id, 37,
    type: Figler.Schema.GUID,
    source_name: "activeCodeComponentId"
  )

  field(:april_fun_fig_pal, 39, type: Figler.Schema.AprilFunFigPal, source_name: "aprilFunFigPal")

  field(:collaborative_text_selection, 40,
    type: Figler.Schema.CollaborativeTextSelection,
    source_name: "collaborativeTextSelection"
  )

  field(:sites_view_state, 41,
    type: {:enum, Figler.Schema.SitesViewState},
    source_name: "sitesViewState"
  )

  field(:node_chat_exchanges, 42,
    repeated: true,
    type: Figler.Schema.NodeChatExchange,
    source_name: "nodeChatExchanges"
  )

  field(:design_full_page_view_state, 45,
    type: {:enum, Figler.Schema.DesignFullPageViewState},
    source_name: "designFullPageViewState"
  )

  field(:agent_info, 46, type: Figler.Schema.AgentInfo, source_name: "agentInfo")
end
