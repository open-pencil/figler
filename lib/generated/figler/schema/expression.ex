defmodule Figler.Schema.Expression do
  @moduledoc "Generated Kiwi message module for `Expression`."
  use KiwiCodec, kind: :message

  field(:expression_function, 1,
    type: {:enum, Figler.Schema.ExpressionFunction},
    source_name: "expressionFunction"
  )

  field(:expression_arguments, 2,
    repeated: true,
    type: Figler.Schema.VariableData,
    source_name: "expressionArguments"
  )
end
