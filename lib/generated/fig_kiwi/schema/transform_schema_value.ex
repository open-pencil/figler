defmodule FigKiwi.Schema.TransformSchemaValue do
  @moduledoc "Generated Kiwi message module for `TransformSchemaValue`."
  use KiwiCodec, kind: :message

  field(:fixed_order_transform3d, 1,
    type: FigKiwi.Schema.FixedOrderTransform3d,
    source_name: "fixedOrderTransform3d"
  )

  field(:transform_functions, 2,
    repeated: true,
    type: FigKiwi.Schema.TransformFn,
    source_name: "transformFunctions"
  )
end
