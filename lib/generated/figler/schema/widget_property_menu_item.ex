defmodule Figler.Schema.WidgetPropertyMenuItem do
  @moduledoc "Generated Kiwi message module for `WidgetPropertyMenuItem`."
  use KiwiCodec, kind: :message
  field(:property_name, 1, type: :string, source_name: "propertyName")
  field(:tooltip, 2, type: :string, source_name: "tooltip")

  field(:item_type, 3,
    type: {:enum, Figler.Schema.WidgetPropertyMenuItemType},
    source_name: "itemType"
  )

  field(:icon, 4, type: :string, source_name: "icon")

  field(:options, 5,
    repeated: true,
    type: Figler.Schema.WidgetPropertyMenuSelectorOption,
    source_name: "options"
  )

  field(:selected_option, 6, type: :string, source_name: "selectedOption")
  field(:is_toggled, 7, type: :bool, source_name: "isToggled")
  field(:href, 8, type: :string, source_name: "href")
  field(:allow_custom_color, 9, type: :bool, source_name: "allowCustomColor")
end
