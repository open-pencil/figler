defmodule FigKiwi.Schema.CookieBannerText do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:banner_header, 1, type: :string, source_name: "bannerHeader")
  field(:banner_disclaimer_explicit, 2, type: :string, source_name: "bannerDisclaimerExplicit")
  field(:banner_disclaimer_implicit, 3, type: :string, source_name: "bannerDisclaimerImplicit")
  field(:policy_label, 4, type: :string, source_name: "policyLabel")
  field(:accept_text, 5, type: :string, source_name: "acceptText")
  field(:acknowledge_text, 6, type: :string, source_name: "acknowledgeText")
  field(:manage_text, 7, type: :string, source_name: "manageText")
  field(:reject_text, 8, type: :string, source_name: "rejectText")
  field(:necessary_text, 9, type: :string, source_name: "necessaryText")
  field(:necessary_description, 10, type: :string, source_name: "necessaryDescription")
  field(:analytics_text, 11, type: :string, source_name: "analyticsText")
  field(:analytics_description, 12, type: :string, source_name: "analyticsDescription")
  field(:preferences_text, 13, type: :string, source_name: "preferencesText")
  field(:preferences_description, 14, type: :string, source_name: "preferencesDescription")
  field(:marketing_text, 15, type: :string, source_name: "marketingText")
  field(:marketing_description, 16, type: :string, source_name: "marketingDescription")
  field(:save_label, 17, type: :string, source_name: "saveLabel")
  field(:trigger_label, 18, type: :string, source_name: "triggerLabel")
end
