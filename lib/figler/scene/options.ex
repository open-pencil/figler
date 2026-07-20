defmodule Figler.Scene.Options do
  @moduledoc """
  Validation and types for public scene query and tree options.

  Invalid options raise `Figler.Error` with code `:invalid_options` and
  structured errors under `error.context.errors`.
  """

  alias Figler.Error
  alias Figler.OptionError
  alias Figler.Scene.Graph.GUID

  @type fields :: :all | [atom() | String.t()]
  @type query_option :: {:fields, fields()}
  @type tree_option :: {:root, String.t()} | {:depth, non_neg_integer()}
  @type find_option ::
          {:type, atom() | String.t()}
          | {:name, String.t()}
          | {:name_contains, String.t()}
          | {:text_contains, String.t()}

  @type option_error :: OptionError.t()

  @doc false
  @spec validate_query!(keyword()) :: :ok
  def validate_query!(opts), do: validate!(:query, opts, &query_option/1)

  @doc false
  @spec validate_find!(keyword()) :: :ok
  def validate_find!(opts), do: validate!(:find, opts, &find_option/1)

  @doc false
  @spec validate_tree!(keyword()) :: :ok
  def validate_tree!(opts), do: validate!(:tree, opts, &tree_option/1)

  defp validate!(operation, opts, validator) do
    errors =
      if Keyword.keyword?(opts) do
        Enum.flat_map(opts, validator)
      else
        [error(:options, :invalid_keyword_list, opts)]
      end

    if errors == [], do: :ok, else: raise(Error.invalid_options(operation, errors))
  end

  defp query_option({:fields, :all}), do: []

  defp query_option({:fields, fields}) when is_list(fields) do
    if Enum.all?(fields, &(is_atom(&1) or is_binary(&1))),
      do: [],
      else: [error(:fields, :invalid_field_list, fields)]
  end

  defp query_option({:fields, value}), do: [error(:fields, :invalid_fields, value)]
  defp query_option({option, value}), do: [error(option, :unknown_option, value)]

  defp find_option({:type, value}) when is_atom(value) or is_binary(value), do: []

  defp find_option({option, value}) when option in [:name, :name_contains, :text_contains] do
    if is_binary(value), do: [], else: [error(option, :invalid_string, value)]
  end

  defp find_option({option, value}), do: [error(option, :unknown_option, value)]

  defp tree_option({:root, value}) when is_binary(value) do
    if GUID.parse(value), do: [], else: [error(:root, :invalid_guid, value)]
  end

  defp tree_option({:root, value}), do: [error(:root, :invalid_guid, value)]
  defp tree_option({:depth, value}) when is_integer(value) and value >= 0, do: []
  defp tree_option({:depth, value}), do: [error(:depth, :invalid_depth, value)]
  defp tree_option({option, value}), do: [error(option, :unknown_option, value)]

  defp error(option, code, value), do: OptionError.new(option, code, value)
end
