defmodule Figler.Error do
  @moduledoc """
  Stable public error raised by document, scene-query, and graph entrypoints.

  Functions that return values directly raise this exception for malformed
  input. Tuple-returning APIs, such as `Figler.Document.open/1`, return the same
  exception as `{:error, error}`. Callers should branch on `:code` and
  `:operation`; the operation may identify the public call or the failing
  decoding stage, while `:context` contains structured diagnostic details.
  """

  @type code ::
          :invalid_archive
          | :missing_canvas
          | :invalid_document
          | :invalid_query
          | :invalid_guid
          | :invalid_options
          | :insufficient_graph_projection

  @type t :: %__MODULE__{
          code: code(),
          operation: atom(),
          context: map()
        }

  @enforce_keys [:code, :operation]
  defexception [:code, :operation, context: %{}]

  @doc false
  @spec new(code(), atom(), map()) :: t()
  def new(code, operation, context \\ %{})
      when is_atom(code) and is_atom(operation) and is_map(context) do
    %__MODULE__{code: code, operation: operation, context: context}
  end

  @doc false
  @spec invalid_options(atom(), [map()]) :: t()
  def invalid_options(operation, errors) when is_atom(operation) and is_list(errors),
    do: new(:invalid_options, operation, %{errors: errors})

  @doc false
  @spec invalid_guid(atom(), term()) :: t()
  def invalid_guid(operation, guid),
    do: new(:invalid_guid, operation, %{guid: guid})

  @doc false
  @spec protect(atom(), (-> result)) :: result when result: var
  def protect(operation, fun) when is_atom(operation) and is_function(fun, 0) do
    case fun.() do
      {:error, reason} -> raise native_reason(operation, reason)
      result -> result
    end
  rescue
    error in __MODULE__ ->
      reraise error, __STACKTRACE__

    error in [ErlangError, KiwiCodec.DecodeError, KiwiCodec.EncodeError] ->
      reraise native(operation, error), __STACKTRACE__
  end

  @doc false
  @spec native(atom(), Exception.t()) :: t()
  def native(operation, error), do: native_reason(operation, Exception.message(error))

  defp native_reason(operation, reason) do
    code = if operation == :query, do: :invalid_query, else: :invalid_document
    new(code, operation, %{reason: inspect_reason(reason)})
  end

  defp inspect_reason(reason) when is_binary(reason), do: reason
  defp inspect_reason(reason), do: inspect(reason)

  @impl Exception
  def message(%__MODULE__{code: code, operation: operation}) do
    "#{description(code)} during #{operation}"
  end

  defp description(:invalid_archive), do: "invalid FIG archive"
  defp description(:missing_canvas), do: "FIG archive is missing canvas.fig"
  defp description(:invalid_document), do: "invalid Figma document"
  defp description(:invalid_query), do: "invalid scene query"
  defp description(:invalid_guid), do: "invalid scene GUID"
  defp description(:invalid_options), do: "invalid options"
  defp description(:insufficient_graph_projection), do: "graph is missing required projected data"
end
