defmodule Figler.Schema.TRSSTransform2D do
  @moduledoc "Generated Kiwi message module for `TRSSTransform2D`."
  use KiwiCodec, kind: :message
  field(:translation, 1, type: Figler.Schema.Vector, source_name: "translation")
  field(:rotation, 2, type: :float, source_name: "rotation")
  field(:scale, 3, type: Figler.Schema.Vector, source_name: "scale")
  field(:shear_x, 4, type: :float, source_name: "shearX")
end
