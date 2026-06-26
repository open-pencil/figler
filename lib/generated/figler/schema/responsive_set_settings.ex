defmodule Figler.Schema.ResponsiveSetSettings do
  @moduledoc "Generated Kiwi message module for `ResponsiveSetSettings`."
  use KiwiCodec, kind: :message
  field(:title, 1, type: :string, source_name: "title")
  field(:description, 2, type: :string, source_name: "description")

  field(:scaling_mode, 3,
    type: {:enum, Figler.Schema.ResponsiveScalingMode},
    source_name: "scalingMode"
  )

  field(:scaling_min_font_size, 4, type: :float, source_name: "scalingMinFontSize")
  field(:scaling_max_font_size, 5, type: :float, source_name: "scalingMaxFontSize")
  field(:scaling_min_layout_width, 6, type: :float, source_name: "scalingMinLayoutWidth")
  field(:scaling_max_layout_width, 7, type: :float, source_name: "scalingMaxLayoutWidth")
  field(:lang, 8, type: :string, source_name: "lang")
  field(:favicon_hash, 9, type: :string, source_name: "faviconHash")
  field(:social_image_hash, 10, type: :string, source_name: "socialImageHash")
  field(:google_analytics_id, 11, type: :string, source_name: "googleAnalyticsID")
  field(:block_search_indexing, 12, type: :bool, source_name: "blockSearchIndexing")
  field(:custom_code_head_start, 13, type: :string, source_name: "customCodeHeadStart")
  field(:custom_code_head_end, 14, type: :string, source_name: "customCodeHeadEnd")
  field(:custom_code_body_start, 15, type: :string, source_name: "customCodeBodyStart")
  field(:custom_code_body_end, 16, type: :string, source_name: "customCodeBodyEnd")
  field(:favicon_id, 17, type: Figler.Schema.GUID, source_name: "faviconID")
  field(:social_image_id, 18, type: Figler.Schema.GUID, source_name: "socialImageID")
  field(:add_bypass_links, 19, type: :bool, source_name: "addBypassLinks")
  field(:ignore_reduced_motion, 20, type: :bool, source_name: "ignoreReducedMotion")
  field(:cookie_banner, 21, type: Figler.Schema.CookieBannerSettings, source_name: "cookieBanner")
end
