defmodule FigKiwi.Schema.CookieBannerSettings do
  @moduledoc "Generated Kiwi message module for `CookieBannerSettings`."
  use KiwiCodec, kind: :message
  field(:enabled, 1, type: :bool, source_name: "enabled")

  field(:component_type, 2,
    type: {:enum, FigKiwi.Schema.CookieBannerComponentType},
    source_name: "componentType"
  )

  field(:x_alignment, 3,
    type: {:enum, FigKiwi.Schema.CookieXAlignment},
    source_name: "xAlignment"
  )

  field(:y_alignment, 4,
    type: {:enum, FigKiwi.Schema.CookieYAlignment},
    source_name: "yAlignment"
  )

  field(:trigger_x_alignment, 5,
    type: {:enum, FigKiwi.Schema.CookieXAlignment},
    source_name: "triggerXAlignment"
  )

  field(:trigger_y_alignment, 6,
    type: {:enum, FigKiwi.Schema.CookieYAlignment},
    source_name: "triggerYAlignment"
  )

  field(:trigger_component_type, 7,
    type: {:enum, FigKiwi.Schema.TriggerComponentType},
    source_name: "triggerComponentType"
  )

  field(:policy_url, 8, type: :string, source_name: "policyUrl")
  field(:text, 9, type: FigKiwi.Schema.CookieBannerText, source_name: "text")
  field(:policy_link, 10, type: FigKiwi.Schema.GUID, source_name: "policyLink")
  field(:locale, 11, type: :string, source_name: "locale")
end
