defmodule Figler.Scene.Graph.Options do
  @moduledoc """
  Validation and types for the public effective-graph option contract.

  Invalid options raise `Figler.Error` with code `:invalid_options` and
  structured errors under `error.context.errors`.
  """

  alias Figler.Error
  alias Figler.OptionError
  alias Figler.Scene.Graph.GUID

  @stages [
    :populate_instances,
    :symbol_overrides,
    :sync_overrides,
    :component_props,
    :sync_component_props,
    :derived_symbol_data,
    :stack_layout,
    :variables
  ]

  @build_keys [
    :stages,
    :only,
    :until,
    :skip,
    :focus,
    :root,
    :resolve_variables,
    :resolve_styles,
    :fields,
    :projection_stages,
    :native
  ]

  @type stage ::
          :populate_instances
          | :symbol_overrides
          | :sync_overrides
          | :component_props
          | :sync_component_props
          | :derived_symbol_data
          | :stack_layout
          | :variables

  @type build_option ::
          {:stages, stage() | [stage()]}
          | {:only, stage() | [stage()]}
          | {:until, stage()}
          | {:skip, stage() | [stage()]}
          | {:focus, String.t() | GUID.graph_guid() | [String.t() | GUID.graph_guid()]}
          | {:root, String.t() | GUID.graph_guid()}
          | {:resolve_variables, false | :known | :preserve}
          | {:resolve_styles, false | :refs | :known}
          | {:fields, :all | [atom() | String.t()]}

  @type option_error :: OptionError.t()

  @doc false
  @spec validate_build!(keyword()) :: :ok
  def validate_build!(opts) do
    validate_keyword!(:graph, opts, &build_option/1)
    validate_exclusive!(opts, [:stages, :only, :until], :conflicting_stage_selection)
    validate_exclusive!(opts, [:focus, :root], :conflicting_focus_selection)
  end

  @doc false
  @spec validate_tree!(keyword()) :: :ok
  def validate_tree!(opts), do: validate_keyword!(:graph_tree, opts, &tree_option/1)

  @doc false
  @spec validate_diff!(keyword()) :: :ok
  def validate_diff!(opts), do: validate_keyword!(:graph_diff, opts, &root_option/1)

  @doc false
  @spec validate_unresolved!(keyword()) :: :ok
  def validate_unresolved!(opts), do: validate_keyword!(:graph_unresolved, opts, &limit_option/1)

  @doc "Returns the supported resolver stages in execution order."
  @spec stages() :: [stage()]
  def stages, do: @stages

  defp build_option({key, value}) when key in [:stages, :only, :skip],
    do: stage_list_error(key, value)

  defp build_option({:until, value}), do: stage_error(:until, value)
  defp build_option({:focus, value}), do: focus_error(:focus, value)
  defp build_option({:root, value}), do: root_option({:root, value})

  defp build_option({:resolve_variables, value}) do
    if value in [false, :known, :preserve],
      do: [],
      else: [error(:resolve_variables, :invalid_resolution_mode, value)]
  end

  defp build_option({:resolve_styles, value}) do
    if value in [false, :refs, :known],
      do: [],
      else: [error(:resolve_styles, :invalid_resolution_mode, value)]
  end

  defp build_option({:fields, value}), do: fields_error(value)

  defp build_option({:projection_stages, :all}), do: []

  defp build_option({:projection_stages, value}),
    do: stage_list_error(:projection_stages, value)

  defp build_option({:native, value}) when is_boolean(value), do: []
  defp build_option({:native, value}), do: [error(:native, :invalid_boolean, value)]

  defp build_option({key, value}) when key not in @build_keys,
    do: [error(key, :unknown_option, value)]

  defp tree_option({:root, value}), do: root_option({:root, value})
  defp tree_option({:depth, value}) when is_integer(value) and value >= 0, do: []
  defp tree_option({:depth, value}), do: [error(:depth, :invalid_depth, value)]
  defp tree_option({key, value}), do: [error(key, :unknown_option, value)]

  defp root_option({:root, value}) do
    if valid_guid?(value), do: [], else: [error(:root, :invalid_guid, value)]
  end

  defp root_option({key, value}), do: [error(key, :unknown_option, value)]

  defp limit_option({:limit, :all}), do: []
  defp limit_option({:limit, value}) when is_integer(value) and value >= 0, do: []
  defp limit_option({:limit, value}), do: [error(:limit, :invalid_limit, value)]
  defp limit_option({key, value}), do: [error(key, :unknown_option, value)]

  defp stage_list_error(key, value) do
    stages = List.wrap(value)

    if is_nil(value) or not Enum.all?(stages, &(&1 in @stages)),
      do: [error(key, :invalid_stage, value)],
      else: []
  end

  defp stage_error(key, value) do
    if value in @stages, do: [], else: [error(key, :invalid_stage, value)]
  end

  defp focus_error(key, value) do
    values = List.wrap(value)

    if values != [] and Enum.all?(values, &valid_guid?/1),
      do: [],
      else: [error(key, :invalid_guid, value)]
  end

  defp valid_guid?(value) when is_binary(value) or is_tuple(value),
    do: not is_nil(GUID.parse(value))

  defp valid_guid?(_value), do: false

  defp fields_error(:all), do: []

  defp fields_error(fields) when is_list(fields) do
    if Enum.all?(fields, &(is_atom(&1) or is_binary(&1))),
      do: [],
      else: [error(:fields, :invalid_field_list, fields)]
  end

  defp fields_error(value), do: [error(:fields, :invalid_fields, value)]

  defp validate_keyword!(operation, opts, validator) do
    errors =
      if Keyword.keyword?(opts),
        do: Enum.flat_map(opts, validator),
        else: [error(:options, :invalid_keyword_list, opts)]

    if errors == [], do: :ok, else: raise(Error.invalid_options(operation, errors))
  end

  defp validate_exclusive!(opts, keys, code) do
    present = Enum.filter(keys, &Keyword.has_key?(opts, &1))

    case present do
      [] ->
        :ok

      [_single] ->
        :ok

      _conflicting ->
        raise Error.invalid_options(:graph, [
                error(:selection, code, Keyword.take(opts, present))
              ])
    end
  end

  defp error(option, code, value), do: OptionError.new(option, code, value)
end
