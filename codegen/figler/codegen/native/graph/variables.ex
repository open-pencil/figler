defmodule Figler.Codegen.Native.Graph.Variables do
  @moduledoc """
  Variable collections and values read from a document and resolved in a mode context, for the
  native interpreter.

  Following OpenPencil's reader and scene graph, a collection has modes, the first its default.
  A variable has one value per mode: a literal, an alias of another variable, a formula, or a
  color composed from a color and an opacity. Expressions OpenPencil cannot evaluate are kept
  unresolved and reported.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias Figler.Codegen.Native.Graph.SourceIndex
  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @typep variable_type :: :float | :boolean | :string | :color

  @typep color :: %{
           required(:r) => R.f64(),
           required(:g) => R.f64(),
           required(:b) => R.f64(),
           required(:a) => R.f64()
         }

  @typep variable_value ::
           R.enum(float: [R.f64()], boolean: [R.bool()], string: [String.t()], color: [color()])

  # A formula node: a literal, a reference to another variable, or an operator applied to
  # operands. The operator is a Kiwi `ExpressionFunction`.
  @typep operation :: %{required(:operator) => R.u32(), required(:operands) => R.vec(formula())}
  @typep formula ::
           R.enum(
             literal: [variable_value()],
             alias: [Records.guid_key()],
             operation: [operation()]
           )

  # An operand of a composed color: a literal or a reference; anything else resolves to
  # nothing.
  @typep color_operand ::
           R.enum(literal: [variable_value()], alias: [Records.guid_key()], other: [])
  @typep composed :: %{required(:color) => color_operand(), required(:opacity) => color_operand()}

  @typep stored ::
           R.enum(
             literal: [variable_value()],
             alias: [Records.guid_key()],
             formula: [operation()],
             compose_color: [composed()],
             unsupported: []
           )

  @typep collection :: %{
           required(:default_mode) => Records.guid_key(),
           required(:modes) => R.vec(Records.guid_key())
         }

  @typep variable :: %{
           required(:id) => Records.guid_key(),
           required(:type) => variable_type(),
           required(:collection) => Records.guid_key(),
           required(:values) => BTreeMap.t(Records.guid_key(), stored())
         }

  # An expression OpenPencil cannot evaluate, by variable and mode.
  @typep unsupported_expression :: %{
           required(:variable) => Records.guid_key(),
           required(:mode) => Records.guid_key()
         }

  @typep variables :: %{
           required(:collections) => HashMap.t(Records.guid_key(), collection()),
           required(:variables) => HashMap.t(Records.guid_key(), variable()),
           required(:keys) => HashMap.t(String.t(), HashMap.t(String.t(), Records.guid_key())),
           required(:diagnostics) => R.vec(unsupported_expression())
         }

  @typep modes :: HashMap.t(Records.guid_key(), Records.guid_key())

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  # Reads the collections and variables among `records`.
  @spec new_variables(R.ref(SourceIndex.sources())) :: variables()
  defrust new_variables(records) do
    collections =
      for {id, record} <- records,
          record.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.VARIABLE_SET),
          {:some, collection} <- [collection(record)],
          into: %{},
          do: {id, collection}

    vars =
      struct_literal(Variables,
        collections: collections,
        variables: %{},
        keys: asset_keys(records),
        diagnostics: []
      )

    for(
      {id, record} <- records,
      record.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.VARIABLE),
      do: id
    )
    |> Enum.sort()
    |> Enum.reduce(vars, fn id, vars -> put_variable(vars, records[id]) end)
  end

  # Library resources are named by key, and by key and version.
  @spec asset_keys(R.ref(SourceIndex.sources())) ::
          HashMap.t(String.t(), HashMap.t(String.t(), Records.guid_key()))
  defrust asset_keys(records) do
    for {id, record} <- records, {:some, key} <- [record.str(Kiwi.NodeChange.KEY)], reduce: %{} do
      keys ->
        version = record.str(Kiwi.NodeChange.VERSION).unwrap_or("").to_string()

        Map.update(keys, key.to_string(), %{version => id}, fn versions ->
          Map.put(versions, version, id)
        end)
    end
  end

  # The resource a `VariableID` or `VariableSetID` names: by GUID, or by asset key. An
  # unversioned reference to a key with several versions names nothing.
  @spec reference(R.ref(variables()), R.ref(Kiwi.kiwi_record())) :: R.option(Records.guid_key())
  defrust reference(vars, reference) do
    case guid_key(reference.record(Kiwi.VariableId.GUID)) do
      {:some, id} ->
        some(id)

      :none ->
        reference.record(Kiwi.VariableId.ASSET_REF)
        |> and_then(fn asset -> asset_reference(vars, asset) end)
    end
  end

  @spec asset_reference(R.ref(variables()), R.ref(Kiwi.kiwi_record())) ::
          R.option(Records.guid_key())
  defrust asset_reference(vars, asset) do
    with {:some, key} <- asset.str(Kiwi.AssetRef.KEY),
         {:some, versions} <- vars.keys.get(key) do
      case asset.str(Kiwi.AssetRef.VERSION) do
        {:some, version} when version != "" ->
          Map.get(versions, version)

        _ ->
          case {Map.get(versions, ""), map_size(versions)} do
            {{:some, id}, _count} -> some(id)
            {:none, 1} -> versions |> Map.values() |> List.first()
            _ -> nil
          end
      end
    else
      _ -> nil
    end
  end

  @spec collection(R.ref(Kiwi.kiwi_record())) :: R.option(collection())
  defrust collection(record) do
    modes =
      for mode <- record.records(Kiwi.NodeChange.VARIABLE_SET_MODES),
          {:some, id} <- [guid_key(mode.record(Kiwi.VariableSetMode.ID))],
          do: id

    case modes do
      [default | _rest] -> some(struct_literal(Collection, default_mode: default, modes: modes))
      [] -> nil
    end
  end

  @spec variable_type(R.ref(Kiwi.kiwi_record())) :: R.option(variable_type())
  defrust variable_type(record) do
    case record.enum_value(Kiwi.NodeChange.VARIABLE_RESOLVED_TYPE) do
      {:some, Kiwi.VariableResolvedDataType.FLOAT} -> some(:float)
      {:some, Kiwi.VariableResolvedDataType.BOOLEAN} -> some(:boolean)
      {:some, Kiwi.VariableResolvedDataType.STRING} -> some(:string)
      {:some, Kiwi.VariableResolvedDataType.COLOR} -> some(:color)
      _ -> nil
    end
  end

  @spec put_variable(variables(), R.ref(Kiwi.kiwi_record())) :: variables()
  defrust put_variable(vars, record) do
    collection =
      record.record(Kiwi.NodeChange.VARIABLE_SET_ID)
      |> and_then(fn set -> reference(vars, set) end)
      |> or_else(fn -> parent_id(record) end)

    with {:some, id} <- record_id(record),
         {:some, type} <- variable_type(record),
         {:some, collection} <- collection,
         {:some, found} <- vars.collections.get(ref(collection)) do
      {values, diagnostics} = mode_values(vars, record, id, ref(found.modes))
      vars = %{vars | diagnostics: vars.diagnostics ++ diagnostics}

      if values == %{} do
        vars
      else
        variable =
          struct_literal(Variable, id: id, type: type, collection: collection, values: values)

        %{vars | variables: Map.put(vars.variables, id, variable)}
      end
    else
      _ -> vars
    end
  end

  # The value in each of `modes` the variable has, and the expressions among them OpenPencil
  # cannot evaluate.
  @spec mode_values(
          R.ref(variables()),
          R.ref(Kiwi.kiwi_record()),
          Records.guid_key(),
          R.slice(Records.guid_key())
        ) ::
          {BTreeMap.t(Records.guid_key(), stored()), R.vec(unsupported_expression())}
  defrust mode_values(vars, record, id, modes) do
    entries =
      case record.record(Kiwi.NodeChange.VARIABLE_DATA_VALUES) do
        {:some, data_values} -> data_values.records(Kiwi.VariableDataValues.ENTRIES)
        :none -> []
      end

    stored =
      for entry <- entries,
          {:some, mode} <- [guid_key(entry.record(Kiwi.VariableDataValuesEntry.MODE_ID))],
          mode in modes,
          do:
            {mode,
             stored_value(vars, entry.record(Kiwi.VariableDataValuesEntry.VARIABLE_DATA), 0)}

    diagnostics =
      for {mode, :unsupported} <- stored,
          do: struct_literal(UnsupportedExpression, variable: id, mode: mode)

    {Map.new(stored), diagnostics}
  end

  # A stored value: a literal, an alias, a formula, a composed color, or unsupported.
  @spec stored_value(R.ref(variables()), R.option(R.ref(Kiwi.kiwi_record())), R.u32()) :: stored()
  defrust stored_value(vars, data, depth) do
    case data do
      {:some, data} when depth <= 64 ->
        value = data.record(Kiwi.VariableData.VALUE)

        data_type =
          data.enum_value(Kiwi.VariableData.DATA_TYPE)
          |> or_else(fn -> data.enum_value(Kiwi.VariableData.RESOLVED_DATA_TYPE) end)

        case {data_type, value} do
          {{:some, Kiwi.VariableDataType.ALIAS}, {:some, value}} ->
            alias_value(vars, value)

          {{:some, Kiwi.VariableDataType.EXPRESSION}, _value} ->
            expression(vars, data, depth)

          {{:some, data_type}, {:some, value}} ->
            case literal(data_type, value) do
              {:some, literal} -> {:literal, literal}
              :none -> :unsupported
            end

          _ ->
            :unsupported
        end

      _ ->
        :unsupported
    end
  end

  @spec literal(R.u32(), R.ref(Kiwi.kiwi_record())) :: R.option(variable_value())
  defrust literal(data_type, value) do
    case {data_type, value.record(Kiwi.VariableAnyValue.COLOR_VALUE),
          value.bool(Kiwi.VariableAnyValue.BOOL_VALUE),
          value.str(Kiwi.VariableAnyValue.TEXT_VALUE),
          value.float(Kiwi.VariableAnyValue.FLOAT_VALUE)} do
      {Kiwi.VariableDataType.COLOR, {:some, color}, _flag, _text, _number} ->
        some({:color, literal_color(color)})

      {Kiwi.VariableDataType.BOOLEAN, _color, {:some, flag}, _text, _number} ->
        some({:boolean, flag})

      {Kiwi.VariableDataType.STRING, _color, _flag, {:some, text}, _number} ->
        some({:string, text.to_string()})

      {Kiwi.VariableDataType.FLOAT, _color, _flag, _text, {:some, number}} ->
        some({:float, cast(number, R.f64())})

      _ ->
        nil
    end
  end

  @spec literal_color(R.ref(Kiwi.kiwi_record())) :: color()
  defrust literal_color(color) do
    struct_literal(Color,
      r: cast(color.float(Kiwi.Color.R).unwrap_or(0.0), R.f64()),
      g: cast(color.float(Kiwi.Color.G).unwrap_or(0.0), R.f64()),
      b: cast(color.float(Kiwi.Color.B).unwrap_or(0.0), R.f64()),
      a: cast(color.float(Kiwi.Color.A).unwrap_or(1.0), R.f64())
    )
  end

  @spec alias_value(R.ref(variables()), R.ref(Kiwi.kiwi_record())) :: stored()
  defrust alias_value(vars, value) do
    case value.record(Kiwi.VariableAnyValue.ALIAS).and_then(fn variable ->
           reference(vars, variable)
         end) do
      {:some, id} -> {:alias, id}
      :none -> :unsupported
    end
  end

  @spec expression(R.ref(variables()), R.ref(Kiwi.kiwi_record()), R.u32()) :: stored()
  defrust expression(vars, data, depth) do
    case data.record(Kiwi.VariableData.VALUE).and_then(fn value ->
           value.record(Kiwi.VariableAnyValue.EXPRESSION_VALUE)
         end) do
      {:some, expression} ->
        arguments = expression.records(Kiwi.Expression.EXPRESSION_ARGUMENTS)

        case expression.enum_value(Kiwi.Expression.EXPRESSION_FUNCTION) do
          {:some, Kiwi.ExpressionFunction.COMPOSE_COLOR} ->
            compose_color(vars, arguments, depth)

          {:some, function} ->
            formula(vars, function, arguments, depth)

          :none ->
            :unsupported
        end

      :none ->
        :unsupported
    end
  end

  @spec compose_color(R.ref(variables()), R.slice(R.ref(Kiwi.kiwi_record())), R.u32()) :: stored()
  defrust compose_color(vars, arguments, depth) do
    case arguments do
      [color, opacity] ->
        case {color_operand(stored_value(vars, some(color), depth + 1)),
              color_operand(stored_value(vars, some(opacity), depth + 1))} do
          {{:some, color}, {:some, opacity}} ->
            {:compose_color, struct_literal(Composed, color: color, opacity: opacity)}

          _ ->
            :unsupported
        end

      _ ->
        :unsupported
    end
  end

  # A formula or unsupported value cannot compose a color; a nested composition resolves to
  # nothing.
  @spec color_operand(stored()) :: R.option(color_operand())
  defrust color_operand(stored) do
    case stored do
      {:literal, literal} -> some({:literal, literal})
      {:alias, id} -> some({:alias, id})
      {:compose_color, _composed} -> some(:other)
      _ -> nil
    end
  end

  @spec formula(R.ref(variables()), R.u32(), R.slice(R.ref(Kiwi.kiwi_record())), R.u32()) ::
          stored()
  defrust formula(vars, function, arguments, depth) do
    if function in [
         Kiwi.ExpressionFunction.ADDITION,
         Kiwi.ExpressionFunction.SUBTRACTION,
         Kiwi.ExpressionFunction.MULTIPLY,
         Kiwi.ExpressionFunction.DIVIDE,
         Kiwi.ExpressionFunction.NEGATE,
         Kiwi.ExpressionFunction.EQUALS,
         Kiwi.ExpressionFunction.NOT_EQUAL,
         Kiwi.ExpressionFunction.LESS_THAN,
         Kiwi.ExpressionFunction.LESS_THAN_OR_EQUAL,
         Kiwi.ExpressionFunction.GREATER_THAN,
         Kiwi.ExpressionFunction.GREATER_THAN_OR_EQUAL,
         Kiwi.ExpressionFunction.AND,
         Kiwi.ExpressionFunction.OR,
         Kiwi.ExpressionFunction.NOT,
         Kiwi.ExpressionFunction.STRINGIFY,
         Kiwi.ExpressionFunction.IS_TRUTHY,
         Kiwi.ExpressionFunction.TERNARY
       ] do
      case formula_operands(vars, arguments, depth) do
        {:some, operands} ->
          {:formula, struct_literal(Operation, operator: function, operands: operands)}

        :none ->
          :unsupported
      end
    else
      :unsupported
    end
  end

  # Every argument as a formula operand, or nothing when one cannot be.
  @spec formula_operands(R.ref(variables()), R.slice(R.ref(Kiwi.kiwi_record())), R.u32()) ::
          R.option(R.vec(formula()))
  defrust formula_operands(vars, arguments, depth) do
    arguments
    |> iter()
    |> map(fn argument -> formula_operand(stored_value(vars, some(argument), depth + 1)) end)
    |> collect()
  end

  @spec formula_operand(stored()) :: R.option(formula())
  defrust formula_operand(stored) do
    case stored do
      {:literal, literal} -> some({:literal, literal})
      {:alias, id} -> some({:alias, id})
      {:formula, operation} -> some({:operation, operation})
      _ -> nil
    end
  end

  # Resolves a variable in a mode context, following aliases and evaluating formulas. `modes`
  # maps collections to the mode a layer uses; collections it leaves out use their default
  # mode. A variable that cannot resolve to a value of its own type resolves to nothing.
  @spec resolve_variable(R.ref(variables()), Records.guid_key(), R.ref(modes())) ::
          R.option(variable_value())
  defrust resolve_variable(vars, id, modes) do
    vars.variables.get(ref(id))
    |> and_then(fn variable -> resolve_chain(vars, variable, modes, MapSet.new(), 0) end)
  end

  @spec resolve_chain(
          R.ref(variables()),
          R.ref(variable()),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key())),
          R.u32()
        ) :: R.option(variable_value())
  defrust resolve_chain(vars, variable, modes, visiting, depth) do
    if depth >= 64 do
      nil
    else
      visited = MapSet.put(visiting, variable.id)

      case value_in_mode(vars, variable, modes) do
        {:some, {:alias, next}} ->
          if MapSet.member?(visiting, next) do
            nil
          else
            vars.variables.get(next)
            |> and_then(fn target ->
              resolve_chain(vars, target, modes, visited, depth + 1)
            end)
            |> and_then(fn value -> drawable(value, variable.type) end)
          end

        {:some, stored} ->
          evaluate(vars, stored, modes, visited)
          |> and_then(fn value -> drawable(value, variable.type) end)

        :none ->
          nil
      end
    end
  end

  @spec value_in_mode(R.ref(variables()), R.ref(variable(), R.lifetime(:a)), R.ref(modes())) ::
          R.option(R.ref(stored(), R.lifetime(:a)))
  defrust value_in_mode(vars, variable, modes) do
    with {:some, collection} <- vars.collections.get(ref(variable.collection)) do
      mode = Map.get(modes, variable.collection, collection.default_mode)

      variable.values.get(ref(mode))
      |> or_else(fn -> variable.values.get(ref(collection.default_mode)) end)
      |> or_else(fn -> variable.values.values().next() end)
    else
      _ -> nil
    end
  end

  @spec evaluate(
          R.ref(variables()),
          R.ref(stored()),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key()))
        ) ::
          R.option(variable_value())
  defrust evaluate(vars, stored, modes, visiting) do
    case stored do
      {:literal, literal} ->
        some(literal.clone())

      {:formula, operation} ->
        evaluate_formula(vars, ref({:operation, operation.clone()}), modes, visiting)

      {:compose_color, composed} ->
        with {:some, {:color, color}} <-
               evaluate_operand(vars, composed.color, modes, visiting),
             {:some, {:float, opacity}} <-
               evaluate_operand(vars, composed.opacity, modes, visiting) do
          some({:color, %{color | a: (opacity / 100.0).clamp(0.0, 1.0)}})
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  @spec evaluate_operand(
          R.ref(variables()),
          R.ref(color_operand()),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key()))
        ) :: R.option(variable_value())
  defrust evaluate_operand(vars, operand, modes, visiting) do
    case operand do
      {:literal, literal} -> some(literal.clone())
      {:alias, id} -> resolve_reference(vars, id, modes, visiting)
      :other -> nil
    end
  end

  @spec resolve_reference(
          R.ref(variables()),
          Records.guid_key(),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key()))
        ) ::
          R.option(variable_value())
  defrust resolve_reference(vars, id, modes, visiting) do
    if MapSet.member?(visiting, id) do
      nil
    else
      vars.variables.get(ref(id))
      |> and_then(fn variable ->
        resolve_chain(vars, variable, modes, visiting, MapSet.size(visiting))
      end)
    end
  end

  @spec drawable(variable_value(), variable_type()) :: R.option(variable_value())
  defrust drawable(value, type) do
    if value_type(value) == type, do: some(value), else: nil
  end

  @spec value_type(R.ref(variable_value())) :: variable_type()
  defrust value_type(value) do
    case value do
      {:float, _value} -> :float
      {:boolean, _value} -> :boolean
      {:string, _value} -> :string
      {:color, _value} -> :color
    end
  end

  # Evaluates a formula; an operand type an operator does not take, a division by zero, or a
  # result that is not finite evaluates to nothing.
  @spec evaluate_formula(
          R.ref(variables()),
          R.ref(formula()),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key()))
        ) ::
          R.option(variable_value())
  defrust evaluate_formula(vars, formula, modes, visiting) do
    case formula do
      {:literal, literal} ->
        finite(literal.clone())

      {:alias, id} ->
        resolve_reference(vars, id, modes, visiting)
        |> and_then(fn value -> finite(value) end)

      {:operation, operation} ->
        evaluated_operands(vars, operation.operands, modes, visiting)
        |> and_then(fn operands -> apply_operator(operation.operator, operands) end)
        |> and_then(fn value -> finite(value) end)
    end
  end

  @spec evaluated_operands(
          R.ref(variables()),
          R.slice(formula()),
          R.ref(modes()),
          R.ref(HashSet.t(Records.guid_key()))
        ) :: R.option(R.vec(variable_value()))
  defrust evaluated_operands(vars, operands, modes, visiting) do
    operands
    |> iter()
    |> map(fn operand -> evaluate_formula(vars, operand, modes, visiting) end)
    |> collect()
  end

  @spec finite(variable_value()) :: R.option(variable_value())
  defrust finite(value) do
    case value do
      {:float, number} when not number.is_finite() -> nil
      _ -> some(value)
    end
  end

  @spec apply_operator(R.u32(), R.vec(variable_value())) :: R.option(variable_value())
  defrust apply_operator(operator, operands) do
    case operands do
      [operand] -> unary(operator, operand)
      [left, right] -> binary(operator, left, right)
      [condition, then, otherwise] -> ternary(operator, condition, then, otherwise)
      _ -> nil
    end
  end

  @spec unary(R.u32(), R.ref(variable_value())) :: R.option(variable_value())
  defrust unary(operator, operand) do
    case {operator, operand} do
      {Kiwi.ExpressionFunction.NEGATE, {:float, number}} ->
        some({:float, -number})

      {Kiwi.ExpressionFunction.NOT, {:boolean, flag}} ->
        some({:boolean, not flag})

      {Kiwi.ExpressionFunction.STRINGIFY, _operand} ->
        text(operand).map(fn text -> {:string, text} end)

      {Kiwi.ExpressionFunction.IS_TRUTHY, _operand} ->
        truthy(operand).map(fn truthy -> {:boolean, truthy} end)

      _ ->
        nil
    end
  end

  @spec binary(R.u32(), R.ref(variable_value()), R.ref(variable_value())) ::
          R.option(variable_value())
  defrust binary(operator, left, right) do
    case {operator, left, right} do
      {Kiwi.ExpressionFunction.ADDITION, {:float, a}, {:float, b}} ->
        some({:float, a + b})

      {Kiwi.ExpressionFunction.ADDITION, _left, _right} ->
        concatenated(left, right)

      {Kiwi.ExpressionFunction.SUBTRACTION, {:float, a}, {:float, b}} ->
        some({:float, a - b})

      {Kiwi.ExpressionFunction.MULTIPLY, {:float, a}, {:float, b}} ->
        some({:float, a * b})

      {Kiwi.ExpressionFunction.DIVIDE, {:float, _a}, {:float, b}} when b == 0.0 ->
        nil

      {Kiwi.ExpressionFunction.DIVIDE, {:float, a}, {:float, b}} ->
        some({:float, a / b})

      {Kiwi.ExpressionFunction.EQUALS, _left, _right} ->
        equal(left, right).map(fn same -> {:boolean, same} end)

      {Kiwi.ExpressionFunction.NOT_EQUAL, _left, _right} ->
        equal(left, right).map(fn same -> {:boolean, not same} end)

      {Kiwi.ExpressionFunction.LESS_THAN, {:float, a}, {:float, b}} ->
        some({:boolean, a < b})

      {Kiwi.ExpressionFunction.LESS_THAN_OR_EQUAL, {:float, a}, {:float, b}} ->
        some({:boolean, a <= b})

      {Kiwi.ExpressionFunction.GREATER_THAN, {:float, a}, {:float, b}} ->
        some({:boolean, a > b})

      {Kiwi.ExpressionFunction.GREATER_THAN_OR_EQUAL, {:float, a}, {:float, b}} ->
        some({:boolean, a >= b})

      {Kiwi.ExpressionFunction.AND, {:boolean, a}, {:boolean, b}} ->
        some({:boolean, a and b})

      {Kiwi.ExpressionFunction.OR, {:boolean, a}, {:boolean, b}} ->
        some({:boolean, a or b})

      _ ->
        nil
    end
  end

  @spec ternary(
          R.u32(),
          R.ref(variable_value()),
          R.ref(variable_value()),
          R.ref(variable_value())
        ) :: R.option(variable_value())
  defrust ternary(operator, condition, then, otherwise) do
    case {operator, condition} do
      {Kiwi.ExpressionFunction.TERNARY, {:boolean, chosen}}
      when value_type(then) == value_type(otherwise) ->
        if chosen, do: some(then.clone()), else: some(otherwise.clone())

      _ ->
        nil
    end
  end

  # Whether two values of one text type are equal; colors and mixed types do not compare.
  @spec equal(R.ref(variable_value()), R.ref(variable_value())) :: R.option(R.bool())
  defrust equal(left, right) do
    case {left, right} do
      {{:float, a}, {:float, b}} -> some(a == b)
      {{:boolean, a}, {:boolean, b}} -> some(a == b)
      {{:string, a}, {:string, b}} -> some(a == b)
      _ -> nil
    end
  end

  # Text joins with text, a number, or a boolean, in either order.
  @spec concatenated(R.ref(variable_value()), R.ref(variable_value())) ::
          R.option(variable_value())
  defrust concatenated(a, b) do
    case {text(a), text(b), value_type(a) == :string or value_type(b) == :string} do
      {{:some, a}, {:some, b}, true} -> some({:string, "#{a}#{b}"})
      _ -> nil
    end
  end

  # The text a value shows: a string as it is, a boolean as `true` or `false`, and a number as
  # Figma writes it, read at 32-bit precision.
  @spec text(R.ref(variable_value())) :: R.option(String.t())
  defrust text(value) do
    case value do
      {:string, text} -> some(text.clone())
      {:boolean, flag} -> some("#{flag}")
      {:float, number} -> some(number_text(number))
      {:color, _color} -> nil
    end
  end

  # Within a millionth of zero as `0`, a whole number as that integer, anything else with two
  # decimals and ties rounded to even.
  @spec number_text(R.f64()) :: String.t()
  defrust number_text(input) do
    value = cast(cast(input, R.f32()), R.f64())

    cond do
      value.abs() < 1.0e-6 ->
        "0"

      value == value.trunc() ->
        cast(value.trunc().clamp(-2_147_483_648.0, 2_147_483_647.0), R.i64()).to_string()

      true ->
        two_decimals(value)
    end
  end

  @spec two_decimals(R.f64()) :: String.t()
  defrust two_decimals(value) do
    scaled = value.abs() * 100.0
    floor = scaled.floor()

    cents =
      if scaled - floor == 0.5,
        do: cast(floor, R.i64()) + rem(cast(floor, R.i64()), 2),
        else: cast(scaled.round(), R.i64())

    sign = if value < 0.0, do: "-", else: ""
    format!("{sign}{}.{:02}", div(cents, 100), rem(cents, 100))
  end

  # Whether Figma reads a value as true: a number other than 0, and text other than "",
  # "false", "no", or "off".
  @spec truthy(R.ref(variable_value())) :: R.option(R.bool())
  defrust truthy(value) do
    case value do
      {:boolean, flag} ->
        some(flag)

      {:float, number} ->
        some(number != 0.0)

      {:string, text} ->
        word = text |> String.trim() |> String.downcase()
        some(text != "" and word not in ["false", "no", "off"])

      {:color, _color} ->
        nil
    end
  end
end
