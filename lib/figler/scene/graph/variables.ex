defmodule Figler.Scene.Graph.Variables do
  @moduledoc """
  Variable collections and values read from a document, resolved in a mode
  context, following OpenPencil's reader (`document/variables.ts`) and scene
  graph (`variables/resolution.ts`).

  A collection (`VARIABLE_SET` record) has modes; its first mode is the
  default. A variable (`VARIABLE` record) has one value per mode: a literal, an
  alias of another variable, a formula, or a color composed from a color and
  an opacity. Each layer resolves a variable in the modes it and its ancestors
  set, falling back to each collection's default mode.

  Expressions OpenPencil cannot evaluate, such as `VAR_MODE_LOOKUP`, are kept
  unresolved and reported as `{:unsupported_variable_expression, variable, mode}`.
  """

  alias Figler.Scene.Graph.Occurrence.GUID
  alias Figler.Scene.Graph.Variables.Formula

  defstruct collections: %{}, variables: %{}, keys: %{}, diagnostics: []

  @type id :: GUID.t()
  @type modes :: %{optional(id()) => id()}
  @type t :: %__MODULE__{
          collections: %{optional(id()) => %{default_mode: id(), modes: [id()]}},
          variables: %{optional(id()) => map()},
          keys: %{optional(String.t()) => %{optional(String.t()) => id()}},
          diagnostics: [tuple()]
        }

  @max_depth 64
  @types [:float, :boolean, :string, :color]

  @doc "Reads the collections and variables among `records`."
  @spec new(%{optional(id()) => map()}) :: t()
  def new(records) do
    keys = asset_keys(records)
    vars = %__MODULE__{keys: keys}

    vars =
      for {_id, %{type: :variable_set} = record} <- records, reduce: vars do
        vars -> put_collection(record, vars)
      end

    for({id, %{type: :variable} = record} <- records, do: {id, record})
    |> Enum.sort()
    |> Enum.reduce(vars, fn {_id, record}, vars -> put_variable(record, vars) end)
    |> then(&%{&1 | diagnostics: Enum.reverse(&1.diagnostics)})
  end

  # Library resources are named by key, and by key and version.
  defp asset_keys(records) do
    for {id, %{key: key} = record} <- records, is_binary(key), reduce: %{} do
      keys ->
        version = if is_binary(Map.get(record, :version)), do: record.version, else: ""
        Map.update(keys, key, %{version => id}, &Map.put(&1, version, id))
    end
  end

  @doc """
  The resource a reference names: `%{guid: _}` or `%{asset_ref: %{key: _}}`.
  An unversioned reference to a key with several versions names nothing.
  """
  @spec reference(t(), map() | nil) :: id() | nil
  def reference(_vars, %{guid: guid}) when guid != nil, do: GUID.key(guid)

  def reference(%__MODULE__{keys: keys}, %{asset_ref: %{key: key} = asset}) do
    versions = Map.get(keys, key, %{})

    case Map.get(asset, :version) do
      version when is_binary(version) and version != "" -> Map.get(versions, version)
      _unversioned -> Map.get(versions, "") || single_version(versions)
    end
  end

  def reference(_vars, _reference), do: nil

  defp single_version(versions) when map_size(versions) == 1, do: versions |> Map.values() |> hd()
  defp single_version(_versions), do: nil

  defp put_collection(record, vars) do
    case Enum.map(Map.get(record, :variable_set_modes) || [], &GUID.key(&1.id)) do
      [default | _rest] = modes ->
        collection = %{default_mode: default, modes: modes}
        %{vars | collections: Map.put(vars.collections, GUID.key(record.guid), collection)}

      [] ->
        vars
    end
  end

  defp put_variable(record, vars) do
    collection =
      reference(vars, Map.get(record, :variable_set_id)) ||
        GUID.key(get_in(record, [:parent_index, :guid]))

    type = Map.get(record, :variable_resolved_type)

    with true <- type in @types,
         %{modes: modes} <- Map.get(vars.collections, collection),
         {values, vars} <- mode_values(record, modes, vars),
         true <- values != %{} do
      variable = %{id: GUID.key(record.guid), type: type, collection: collection, values: values}
      %{vars | variables: Map.put(vars.variables, variable.id, variable)}
    else
      _unsupported -> vars
    end
  end

  defp mode_values(record, modes, vars) do
    record
    |> get_in([:variable_data_values, :entries])
    |> List.wrap()
    |> Enum.reduce({%{}, vars}, fn entry, {values, vars} ->
      mode = GUID.key(Map.get(entry, :mode_id))

      case mode in modes && value(Map.get(entry, :variable_data), vars, 0) do
        false ->
          {values, vars}

        :unsupported ->
          diagnostic = {:unsupported_variable_expression, GUID.key(record.guid), mode}

          {Map.put(values, mode, :unsupported),
           %{vars | diagnostics: [diagnostic | vars.diagnostics]}}

        value ->
          {Map.put(values, mode, value), vars}
      end
    end)
  end

  # A stored value: a literal, `{:alias, id}`, `{:formula, type, node}`,
  # `{:compose_color, color, opacity}`, or `:unsupported`.
  defp value(nil, _vars, _depth), do: :unsupported
  defp value(_data, _vars, depth) when depth > @max_depth, do: :unsupported

  @literal_fields %{
    color: :color_value,
    boolean: :bool_value,
    string: :text_value,
    float: :float_value
  }

  defp value(data, vars, depth) do
    value = Map.get(data, :value) || %{}

    case Map.get(data, :data_type) || Map.get(data, :resolved_data_type) do
      :alias ->
        alias_value(vars, Map.get(value, :alias))

      :expression ->
        expression(data, vars, depth)

      type when is_map_key(@literal_fields, type) ->
        value |> Map.get(@literal_fields[type]) |> literal()

      _other ->
        :unsupported
    end
  end

  defp literal(nil), do: :unsupported
  defp literal(%{r: r, g: g, b: b} = color), do: %{r: r, g: g, b: b, a: Map.get(color, :a, 1.0)}
  defp literal(value), do: value

  defp alias_value(vars, reference) do
    case reference(vars, reference) do
      nil -> :unsupported
      id -> {:alias, id}
    end
  end

  defp expression(data, vars, depth) do
    expression = get_in(data, [:value, :expression_value]) || %{}
    arguments = Map.get(expression, :expression_arguments) || []

    case Map.get(expression, :expression_function) do
      function when function in [:compose_color, 20] -> compose_color(arguments, vars, depth)
      function -> formula(function, arguments, Map.get(data, :resolved_data_type), vars, depth)
    end
  end

  defp compose_color([color, opacity], vars, depth) do
    operands = Enum.map([color, opacity], &value(&1, vars, depth + 1))

    if Enum.any?(operands, &(&1 == :unsupported or match?({:formula, _, _}, &1))),
      do: :unsupported,
      else: List.to_tuple([:compose_color | operands])
  end

  defp compose_color(_arguments, _vars, _depth), do: :unsupported

  defp formula(function, arguments, type, vars, depth) do
    if function in Formula.operators() do
      operands = Enum.map(arguments, &formula_operand(value(&1, vars, depth + 1)))

      if Enum.member?(operands, :unsupported),
        do: :unsupported,
        else: {:formula, type, {function, operands}}
    else
      :unsupported
    end
  end

  defp formula_operand({:formula, _type, node}), do: node
  defp formula_operand({:compose_color, _color, _opacity}), do: :unsupported
  defp formula_operand(operand), do: operand

  @doc """
  Resolves a variable in a mode context, following aliases and evaluating
  formulas. `modes` maps collections to the mode a layer uses; collections it
  leaves out use their default mode. Returns `nil` when the variable cannot be
  resolved to a value of its own type.
  """
  @spec resolve(t(), id(), modes()) :: Formula.literal() | nil
  def resolve(%__MODULE__{} = vars, id, modes) do
    case Map.get(vars.variables, id) do
      nil -> nil
      variable -> resolve_chain(vars, variable, modes, MapSet.new(), 0)
    end
  end

  defp resolve_chain(_vars, _variable, _modes, _visiting, depth) when depth >= @max_depth, do: nil

  defp resolve_chain(vars, variable, modes, visiting, depth) do
    case value_in_mode(vars, variable, modes) do
      {:alias, next} ->
        with false <- MapSet.member?(visiting, next),
             %{} = target <- Map.get(vars.variables, next),
             result when result != nil <-
               resolve_chain(vars, target, modes, MapSet.put(visiting, variable.id), depth + 1) do
          drawable(result, variable.type)
        else
          _unresolved -> nil
        end

      value ->
        value
        |> evaluate(vars, modes, MapSet.put(visiting, variable.id))
        |> drawable(variable.type)
    end
  end

  defp value_in_mode(vars, variable, modes) do
    collection = Map.get(vars.collections, variable.collection)
    mode = Map.get(modes, variable.collection) || collection.default_mode

    cond do
      Map.has_key?(variable.values, mode) ->
        Map.fetch!(variable.values, mode)

      Map.has_key?(variable.values, collection.default_mode) ->
        variable.values[collection.default_mode]

      true ->
        variable.values |> Map.values() |> hd()
    end
  end

  defp evaluate(:unsupported, _vars, _modes, _visiting), do: nil

  defp evaluate({:formula, _type, node}, vars, modes, visiting) do
    Formula.evaluate(node, &resolve_reference(vars, &1, modes, visiting))
  rescue
    ArgumentError -> nil
  end

  defp evaluate({:compose_color, color, opacity}, vars, modes, visiting) do
    with %{r: _} = color <- operand(color, vars, modes, visiting),
         opacity when is_number(opacity) <- operand(opacity, vars, modes, visiting) do
      %{color | a: opacity |> Kernel./(100) |> max(0.0) |> min(1.0)}
    else
      _unresolved -> nil
    end
  end

  defp evaluate(literal, _vars, _modes, _visiting), do: literal

  defp operand({:alias, id}, vars, modes, visiting),
    do: resolve_reference(vars, id, modes, visiting)

  defp operand(literal, _vars, _modes, _visiting), do: literal

  defp resolve_reference(vars, id, modes, visiting) do
    if MapSet.member?(visiting, id) do
      nil
    else
      case Map.get(vars.variables, id) do
        nil -> nil
        variable -> resolve_chain(vars, variable, modes, visiting, MapSet.size(visiting))
      end
    end
  end

  defp drawable(value, type) do
    if Formula.type(value) == type, do: value
  end
end
