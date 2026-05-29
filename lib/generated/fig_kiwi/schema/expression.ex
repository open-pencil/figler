defmodule FigKiwi.Schema.Expression do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:expression_function, 1,
    type: {:enum, FigKiwi.Schema.ExpressionFunction},
    source_name: "expressionFunction"
  )

  field(:expression_arguments, 2,
    repeated: true,
    type: FigKiwi.Schema.VariableData,
    source_name: "expressionArguments"
  )
end
