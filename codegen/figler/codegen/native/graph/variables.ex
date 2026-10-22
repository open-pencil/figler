defmodule Figler.Codegen.Native.Graph.Variables do
  @moduledoc """
  Variable collections and values read from a document and resolved in a mode context, for
  the native interpreter.

  Mirrors `Figler.Scene.Graph.Variables` and `Figler.Scene.Graph.Variables.Formula`. A
  collection has modes, the first its default. A variable has one value per mode: a literal,
  an alias of another variable, a formula, or a color composed from a color and an opacity.
  Expressions OpenPencil cannot evaluate are kept unresolved and reported.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [
      Figler.Codegen.Native.Graph.Records,
      Figler.Codegen.Native.Graph.SourceIndex
    ]

  alias Figler.Codegen.Native.Graph.SourceIndex
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodeType, as: [:kiwi_records, :node_type]
  defrustmod VariableSetMode, as: [:kiwi_records, :variable_set_mode]
  defrustmod VariableDataValues, as: [:kiwi_records, :variable_data_values]
  defrustmod VariableDataValuesEntry, as: [:kiwi_records, :variable_data_values_entry]
  defrustmod VariableData, as: [:kiwi_records, :variable_data]
  defrustmod VariableDataType, as: [:kiwi_records, :variable_data_type]
  defrustmod VariableResolvedDataType, as: [:kiwi_records, :variable_resolved_data_type]
  defrustmod VariableAnyValue, as: [:kiwi_records, :variable_any_value]
  defrustmod VariableId, as: [:kiwi_records, :variable_id]
  defrustmod Expression, as: [:kiwi_records, :expression]
  defrustmod ExpressionFunction, as: [:kiwi_records, :expression_function]
  defrustmod ColorField, as: [:kiwi_records, :color]
  defrustmod AssetRef, as: [:kiwi_records, :asset_ref]
  defrustmod Definitions, as: [:kiwi_record_definitions]

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
           R.enum(literal: [variable_value()], alias: [GuidKey.t()], operation: [operation()])

  # An operand of a composed color: a literal or a reference; anything else resolves to
  # nothing.
  @typep color_operand :: R.enum(literal: [variable_value()], alias: [GuidKey.t()], other: [])
  @typep composed :: %{required(:color) => color_operand(), required(:opacity) => color_operand()}

  @typep stored ::
           R.enum(
             literal: [variable_value()],
             alias: [GuidKey.t()],
             formula: [operation()],
             compose_color: [composed()],
             unsupported: []
           )

  @typep collection :: %{
           required(:default_mode) => GuidKey.t(),
           required(:modes) => R.vec(GuidKey.t())
         }

  @typep variable :: %{
           required(:id) => GuidKey.t(),
           required(:type) => variable_type(),
           required(:collection) => GuidKey.t(),
           required(:values) => BTreeMap.t(GuidKey.t(), stored())
         }

  # An expression OpenPencil cannot evaluate, by variable and mode.
  @typep unsupported_expression :: %{
           required(:variable) => GuidKey.t(),
           required(:mode) => GuidKey.t()
         }

  @typep variables :: %{
           required(:collections) => HashMap.t(GuidKey.t(), collection()),
           required(:variables) => HashMap.t(GuidKey.t(), variable()),
           required(:keys) => HashMap.t(String.t(), HashMap.t(String.t(), GuidKey.t())),
           required(:diagnostics) => R.vec(unsupported_expression())
         }

  @typep modes :: HashMap.t(GuidKey.t(), GuidKey.t())

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :new_variables,
        :asset_keys,
        :reference,
        :asset_reference,
        :collection,
        :variable_type,
        :put_variable,
        :mode_values,
        :stored_value,
        :literal,
        :literal_color,
        :alias_value,
        :expression,
        :compose_color,
        :color_operand,
        :formula,
        :formula_operands,
        :formula_operand,
        :resolve_variable,
        :resolve_chain,
        :value_in_mode,
        :evaluate,
        :evaluate_operand,
        :resolve_reference,
        :drawable,
        :value_type,
        :evaluate_formula,
        :evaluated_operands,
        :apply_operator,
        :unary,
        :binary,
        :ternary,
        :equal,
        :finite,
        :concatenated,
        :text,
        :number_text,
        :two_decimals,
        :truthy
      ])
  end

  # Reads the collections and variables among `records`.
  @spec new_variables(R.ref(SourceIndex.sources())) :: variables()
  defrust new_variables(records) do
    collections =
      records
      |> iter()
      |> filter(fn {_id, record} ->
        record.enum_value(NodeChange.TYPE) == some(NodeType.VARIABLE_SET)
      end)
      |> filter_map(fn {id, record} ->
        collection(record).map(fn collection -> {deref(id), collection} end)
      end)
      |> collect()

    vars =
      struct_literal(Variables,
        collections: collections,
        variables: HashMap.new(),
        keys: asset_keys(records),
        diagnostics: Vec.new()
      )

    ids =
      for {id, record} <- records.iter(),
          record.enum_value(NodeChange.TYPE) == some(NodeType.VARIABLE),
          do: deref(id)

    ids.sort()

    for id <- ids do
      put_variable(mut_ref(vars), ref(records[ref(id)]))
    end

    vars
  end

  # Library resources are named by key, and by key and version.
  @spec asset_keys(R.ref(SourceIndex.sources())) ::
          HashMap.t(String.t(), HashMap.t(String.t(), GuidKey.t()))
  defrust asset_keys(records) do
    keys = HashMap.new()

    for {id, record} <- records.iter() do
      case record.str(NodeChange.KEY) do
        {:some, key} ->
          version = record.str(NodeChange.VERSION).unwrap_or("")
          keys.entry(key.to_string()).or_default().insert(version.to_string(), deref(id))

        :none ->
          :ok
      end
    end

    keys
  end

  # The resource a `VariableID` or `VariableSetID` names: by GUID, or by asset key. An
  # unversioned reference to a key with several versions names nothing.
  @spec reference(R.ref(variables()), R.ref(KiwiRecord.t())) :: R.option(GuidKey.t())
  defrust reference(vars, reference) do
    case guid_key(reference.record(VariableId.GUID)) do
      {:some, id} ->
        some(id)

      :none ->
        reference.record(VariableId.ASSET_REF)
        |> and_then(fn asset -> asset_reference(vars, asset) end)
    end
  end

  @spec asset_reference(R.ref(variables()), R.ref(KiwiRecord.t())) :: R.option(GuidKey.t())
  defrust asset_reference(vars, asset) do
    with {:some, key} <- asset.str(AssetRef.KEY),
         {:some, versions} <- vars.keys.get(key) do
      case asset.str(AssetRef.VERSION) do
        {:some, version} when not version.is_empty() ->
          versions.get(version).copied()

        _ ->
          case {versions.get(""), versions.len()} do
            {{:some, id}, _count} -> some(deref(id))
            {:none, 1} -> versions.values().copied().next()
            _ -> nil
          end
      end
    else
      _ -> nil
    end
  end

  @spec collection(R.ref(KiwiRecord.t())) :: R.option(collection())
  defrust collection(record) do
    modes =
      record
      |> records(NodeChange.VARIABLE_SET_MODES)
      |> iter()
      |> filter_map(fn mode -> guid_key(mode.record(VariableSetMode.ID)) end)
      |> collect()

    case modes.first() do
      {:some, default} ->
        some(struct_literal(Collection, default_mode: deref(default), modes: modes.clone()))

      :none ->
        nil
    end
  end

  @spec variable_type(R.ref(KiwiRecord.t())) :: R.option(variable_type())
  defrust variable_type(record) do
    case record.enum_value(NodeChange.VARIABLE_RESOLVED_TYPE) do
      {:some, VariableResolvedDataType.FLOAT} -> some(:float)
      {:some, VariableResolvedDataType.BOOLEAN} -> some(:boolean)
      {:some, VariableResolvedDataType.STRING} -> some(:string)
      {:some, VariableResolvedDataType.COLOR} -> some(:color)
      _ -> nil
    end
  end

  @spec put_variable(R.mut_ref(variables()), R.ref(KiwiRecord.t())) :: R.unit()
  defrust put_variable(vars, record) do
    collection =
      record.record(NodeChange.VARIABLE_SET_ID)
      |> and_then(fn set -> reference(vars, set) end)
      |> or_else(fn -> parent_id(record) end)

    with {:some, id} <- record_id(record),
         {:some, type} <- variable_type(record),
         {:some, collection} <- collection,
         {:some, modes} <-
           vars.collections.get(ref(collection)).map(fn found -> found.modes.clone() end) do
      values = mode_values(vars, record, id, ref(modes))

      if not values.is_empty() do
        vars.variables.insert(
          id,
          struct_literal(Variable, id: id, type: type, collection: collection, values: values)
        )
      end
    else
      _ -> :ok
    end
  end

  @spec mode_values(
          R.mut_ref(variables()),
          R.ref(KiwiRecord.t()),
          GuidKey.t(),
          R.slice(GuidKey.t())
        ) ::
          BTreeMap.t(GuidKey.t(), stored())
  defrust mode_values(vars, record, id, modes) do
    values = BTreeMap.new()

    entries =
      case record.record(NodeChange.VARIABLE_DATA_VALUES) do
        {:some, data_values} -> data_values.records(VariableDataValues.ENTRIES)
        :none -> Vec.new()
      end

    for entry <- entries do
      case guid_key(entry.record(VariableDataValuesEntry.MODE_ID)) do
        {:some, mode} when modes.contains(ref(mode)) ->
          stored = stored_value(vars, entry.record(VariableDataValuesEntry.VARIABLE_DATA), 0)

          case stored do
            :unsupported ->
              vars.diagnostics.push(
                struct_literal(UnsupportedExpression, variable: id, mode: mode)
              )

            _ ->
              :ok
          end

          values.insert(mode, stored)

        _ ->
          :ok
      end
    end

    values
  end

  # A stored value: a literal, an alias, a formula, a composed color, or unsupported.
  @spec stored_value(R.ref(variables()), R.option(R.ref(KiwiRecord.t())), R.u32()) :: stored()
  defrust stored_value(vars, data, depth) do
    case data do
      {:some, data} when depth <= 64 ->
        value = data.record(VariableData.VALUE)

        data_type =
          data.enum_value(VariableData.DATA_TYPE)
          |> or_else(fn -> data.enum_value(VariableData.RESOLVED_DATA_TYPE) end)

        case {data_type, value} do
          {{:some, VariableDataType.ALIAS}, {:some, value}} ->
            alias_value(vars, value)

          {{:some, VariableDataType.EXPRESSION}, _value} ->
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

  @spec literal(R.u32(), R.ref(KiwiRecord.t())) :: R.option(variable_value())
  defrust literal(data_type, value) do
    case {data_type, value.record(VariableAnyValue.COLOR_VALUE),
          value.bool(VariableAnyValue.BOOL_VALUE), value.str(VariableAnyValue.TEXT_VALUE),
          value.float(VariableAnyValue.FLOAT_VALUE)} do
      {VariableDataType.COLOR, {:some, color}, _flag, _text, _number} ->
        some({:color, literal_color(color)})

      {VariableDataType.BOOLEAN, _color, {:some, flag}, _text, _number} ->
        some({:boolean, flag})

      {VariableDataType.STRING, _color, _flag, {:some, text}, _number} ->
        some({:string, text.to_string()})

      {VariableDataType.FLOAT, _color, _flag, _text, {:some, number}} ->
        some({:float, cast(number, R.f64())})

      _ ->
        nil
    end
  end

  @spec literal_color(R.ref(KiwiRecord.t())) :: color()
  defrust literal_color(color) do
    struct_literal(Color,
      r: cast(color.float(ColorField.R).unwrap_or(0.0), R.f64()),
      g: cast(color.float(ColorField.G).unwrap_or(0.0), R.f64()),
      b: cast(color.float(ColorField.B).unwrap_or(0.0), R.f64()),
      a: cast(color.float(ColorField.A).unwrap_or(1.0), R.f64())
    )
  end

  @spec alias_value(R.ref(variables()), R.ref(KiwiRecord.t())) :: stored()
  defrust alias_value(vars, value) do
    case value.record(VariableAnyValue.ALIAS).and_then(fn variable ->
           reference(vars, variable)
         end) do
      {:some, id} -> {:alias, id}
      :none -> :unsupported
    end
  end

  @spec expression(R.ref(variables()), R.ref(KiwiRecord.t()), R.u32()) :: stored()
  defrust expression(vars, data, depth) do
    case data.record(VariableData.VALUE).and_then(fn value ->
           value.record(VariableAnyValue.EXPRESSION_VALUE)
         end) do
      {:some, expression} ->
        arguments = expression.records(Expression.EXPRESSION_ARGUMENTS)

        case expression.enum_value(Expression.EXPRESSION_FUNCTION) do
          {:some, ExpressionFunction.COMPOSE_COLOR} -> compose_color(vars, ref(arguments), depth)
          {:some, function} -> formula(vars, function, ref(arguments), depth)
          :none -> :unsupported
        end

      :none ->
        :unsupported
    end
  end

  @spec compose_color(R.ref(variables()), R.slice(R.ref(KiwiRecord.t())), R.u32()) :: stored()
  defrust compose_color(vars, arguments, depth) do
    case arguments do
      [color, opacity] ->
        case {color_operand(stored_value(vars, some(deref(color)), depth + 1)),
              color_operand(stored_value(vars, some(deref(opacity)), depth + 1))} do
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

  @spec formula(R.ref(variables()), R.u32(), R.slice(R.ref(KiwiRecord.t())), R.u32()) :: stored()
  defrust formula(vars, function, arguments, depth) do
    supported =
      ref([
        ExpressionFunction.ADDITION,
        ExpressionFunction.SUBTRACTION,
        ExpressionFunction.MULTIPLY,
        ExpressionFunction.DIVIDE,
        ExpressionFunction.NEGATE,
        ExpressionFunction.EQUALS,
        ExpressionFunction.NOT_EQUAL,
        ExpressionFunction.LESS_THAN,
        ExpressionFunction.LESS_THAN_OR_EQUAL,
        ExpressionFunction.GREATER_THAN,
        ExpressionFunction.GREATER_THAN_OR_EQUAL,
        ExpressionFunction.AND,
        ExpressionFunction.OR,
        ExpressionFunction.NOT,
        ExpressionFunction.STRINGIFY,
        ExpressionFunction.IS_TRUTHY,
        ExpressionFunction.TERNARY
      ])

    if supported.contains(ref(function)) do
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
  @spec formula_operands(R.ref(variables()), R.slice(R.ref(KiwiRecord.t())), R.u32()) ::
          R.option(R.vec(formula()))
  defrust formula_operands(vars, arguments, depth) do
    arguments
    |> iter()
    |> map(fn argument ->
      formula_operand(stored_value(vars, some(deref(argument)), depth + 1))
    end)
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
  @spec resolve_variable(R.ref(variables()), GuidKey.t(), R.ref(modes())) ::
          R.option(variable_value())
  defrust resolve_variable(vars, id, modes) do
    vars.variables.get(ref(id))
    |> and_then(fn variable -> resolve_chain(vars, variable, modes, ref(HashSet.new()), 0) end)
  end

  @spec resolve_chain(
          R.ref(variables()),
          R.ref(variable()),
          R.ref(modes()),
          R.ref(HashSet.t(GuidKey.t())),
          R.u32()
        ) :: R.option(variable_value())
  defrust resolve_chain(vars, variable, modes, visiting, depth) do
    if depth >= 64 do
      nil
    else
      visited = visiting.clone()
      visited.insert(variable.id)

      case value_in_mode(vars, variable, modes) do
        {:some, {:alias, next}} ->
          if visiting.contains(next) do
            nil
          else
            vars.variables.get(next)
            |> and_then(fn target ->
              resolve_chain(vars, target, modes, ref(visited), depth + 1)
            end)
            |> and_then(fn value -> drawable(value, variable.type) end)
          end

        {:some, stored} ->
          evaluate(vars, stored, modes, ref(visited))
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
      mode = modes.get(ref(variable.collection)).copied().unwrap_or(collection.default_mode)

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
          R.ref(HashSet.t(GuidKey.t()))
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
               evaluate_operand(vars, ref(composed.color), modes, visiting),
             {:some, {:float, opacity}} <-
               evaluate_operand(vars, ref(composed.opacity), modes, visiting) do
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
          R.ref(HashSet.t(GuidKey.t()))
        ) :: R.option(variable_value())
  defrust evaluate_operand(vars, operand, modes, visiting) do
    case operand do
      {:literal, literal} -> some(literal.clone())
      {:alias, id} -> resolve_reference(vars, deref(id), modes, visiting)
      :other -> nil
    end
  end

  @spec resolve_reference(
          R.ref(variables()),
          GuidKey.t(),
          R.ref(modes()),
          R.ref(HashSet.t(GuidKey.t()))
        ) ::
          R.option(variable_value())
  defrust resolve_reference(vars, id, modes, visiting) do
    if visiting.contains(ref(id)) do
      nil
    else
      vars.variables.get(ref(id))
      |> and_then(fn variable ->
        resolve_chain(vars, variable, modes, visiting, cast(visiting.len(), R.u32()))
      end)
    end
  end

  @spec drawable(variable_value(), variable_type()) :: R.option(variable_value())
  defrust drawable(value, type) do
    if value_type(ref(value)) == type, do: some(value), else: nil
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
          R.ref(HashSet.t(GuidKey.t()))
        ) ::
          R.option(variable_value())
  defrust evaluate_formula(vars, formula, modes, visiting) do
    case formula do
      {:literal, literal} ->
        finite(literal.clone())

      {:alias, id} ->
        resolve_reference(vars, deref(id), modes, visiting)
        |> and_then(fn value -> finite(value) end)

      {:operation, operation} ->
        evaluated_operands(vars, ref(operation.operands), modes, visiting)
        |> and_then(fn operands -> apply_operator(operation.operator, operands) end)
        |> and_then(fn value -> finite(value) end)
    end
  end

  @spec evaluated_operands(
          R.ref(variables()),
          R.slice(formula()),
          R.ref(modes()),
          R.ref(HashSet.t(GuidKey.t()))
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
    case operands.as_slice() do
      [operand] -> unary(operator, operand)
      [left, right] -> binary(operator, left, right)
      [condition, then, otherwise] -> ternary(operator, condition, then, otherwise)
      _ -> nil
    end
  end

  @spec unary(R.u32(), R.ref(variable_value())) :: R.option(variable_value())
  defrust unary(operator, operand) do
    case {operator, operand} do
      {ExpressionFunction.NEGATE, {:float, number}} ->
        some({:float, -deref(number)})

      {ExpressionFunction.NOT, {:boolean, flag}} ->
        some({:boolean, not deref(flag)})

      {ExpressionFunction.STRINGIFY, _operand} ->
        text(operand).map(fn text -> {:string, text} end)

      {ExpressionFunction.IS_TRUTHY, _operand} ->
        truthy(operand).map(fn truthy -> {:boolean, truthy} end)

      _ ->
        nil
    end
  end

  @spec binary(R.u32(), R.ref(variable_value()), R.ref(variable_value())) ::
          R.option(variable_value())
  defrust binary(operator, left, right) do
    case {operator, left, right} do
      {ExpressionFunction.ADDITION, {:float, a}, {:float, b}} ->
        some({:float, a + b})

      {ExpressionFunction.ADDITION, _left, _right} ->
        concatenated(left, right)

      {ExpressionFunction.SUBTRACTION, {:float, a}, {:float, b}} ->
        some({:float, a - b})

      {ExpressionFunction.MULTIPLY, {:float, a}, {:float, b}} ->
        some({:float, a * b})

      {ExpressionFunction.DIVIDE, {:float, _a}, {:float, b}} when deref(b) == 0.0 ->
        nil

      {ExpressionFunction.DIVIDE, {:float, a}, {:float, b}} ->
        some({:float, a / b})

      {ExpressionFunction.EQUALS, _left, _right} ->
        equal(left, right).map(fn same -> {:boolean, same} end)

      {ExpressionFunction.NOT_EQUAL, _left, _right} ->
        equal(left, right).map(fn same -> {:boolean, not same} end)

      {ExpressionFunction.LESS_THAN, {:float, a}, {:float, b}} ->
        some({:boolean, a < b})

      {ExpressionFunction.LESS_THAN_OR_EQUAL, {:float, a}, {:float, b}} ->
        some({:boolean, a <= b})

      {ExpressionFunction.GREATER_THAN, {:float, a}, {:float, b}} ->
        some({:boolean, a > b})

      {ExpressionFunction.GREATER_THAN_OR_EQUAL, {:float, a}, {:float, b}} ->
        some({:boolean, a >= b})

      {ExpressionFunction.AND, {:boolean, a}, {:boolean, b}} ->
        some({:boolean, deref(a) and deref(b)})

      {ExpressionFunction.OR, {:boolean, a}, {:boolean, b}} ->
        some({:boolean, deref(a) or deref(b)})

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
      {ExpressionFunction.TERNARY, {:boolean, chosen}}
      when value_type(then) == value_type(otherwise) ->
        if deref(chosen), do: some(then.clone()), else: some(otherwise.clone())

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
    case {value_type(a), value_type(b)} do
      {:string, :string} ->
        some({:string, text(a).unwrap_or_default() + ref(text(b).unwrap_or_default())})

      {:string, :float} ->
        some({:string, text(a).unwrap_or_default() + ref(text(b).unwrap_or_default())})

      {:float, :string} ->
        some({:string, text(a).unwrap_or_default() + ref(text(b).unwrap_or_default())})

      {:string, :boolean} ->
        some({:string, text(a).unwrap_or_default() + ref(text(b).unwrap_or_default())})

      {:boolean, :string} ->
        some({:string, text(a).unwrap_or_default() + ref(text(b).unwrap_or_default())})

      _ ->
        nil
    end
  end

  # The text a value shows: a string as it is, a boolean as `true` or `false`, and a number as
  # Figma writes it, read at 32-bit precision.
  @spec text(R.ref(variable_value())) :: R.option(String.t())
  defrust text(value) do
    case value do
      {:string, text} -> some(text.clone())
      {:boolean, flag} -> some(flag.to_string())
      {:float, number} -> some(number_text(deref(number)))
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
        "0".to_string()

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
        some(deref(flag))

      {:float, number} ->
        some(deref(number) != 0.0)

      {:string, text} ->
        word = text.trim().to_lowercase()
        some(not text.is_empty() and not ref(["false", "no", "off"]).contains(ref(word.as_str())))

      {:color, _color} ->
        nil
    end
  end
end
