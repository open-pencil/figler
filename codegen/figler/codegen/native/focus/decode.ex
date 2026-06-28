defmodule Figler.Codegen.Native.Focus.Decode do
  @moduledoc """
  Builds focused graph decoder arms from semantic operations.

  Focused decoding tracks only graph identity, ancestry, symbols, and component
  references. This module owns the RustQ AST for those operations so
  `Figler.Codegen.Native.Focus` can stay focused on selecting schema
  fields.
  """

  alias RustQ.Rust
  alias RustQ.Rust.AST
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rust.AST.PatternBuilder, as: P
  alias RustQ.Rust.AST.Render

  defmodule Operation do
    @moduledoc """
    Semantic focused graph decode operation for one already-read message field.
    """

    @enforce_keys [:kind]
    defstruct [:kind]

    @type kind ::
            :guid
            | :parent_guid
            | :symbol_data
            | :push_guid_ref
            | :component_prop_assignments
            | :component_prop_value

    @type t :: %__MODULE__{kind: kind()}
  end

  @spec arm(non_neg_integer(), Operation.t()) :: RustQ.Rust.Fragment.t()
  def arm(field_id, %Operation{} = operation) do
    %AST.Arm{pattern: P.lit(field_id), body: operation_body(operation)}
    |> Render.render_arm()
    |> Rust.arm()
  end

  @spec guid() :: Operation.t()
  def guid, do: operation(:guid)

  @spec parent_guid() :: Operation.t()
  def parent_guid, do: operation(:parent_guid)

  @spec symbol_data() :: Operation.t()
  def symbol_data, do: operation(:symbol_data)

  @spec push_guid_ref() :: Operation.t()
  def push_guid_ref, do: operation(:push_guid_ref)

  @spec component_prop_assignments() :: Operation.t()
  def component_prop_assignments, do: operation(:component_prop_assignments)

  @spec component_prop_value() :: Operation.t()
  def component_prop_value, do: operation(:component_prop_value)

  defp operation(kind), do: %Operation{kind: kind}

  defp operation_body(%Operation{kind: :guid}) do
    [assign_some(:guid, try_call(:graph_focus_read_guid))]
  end

  defp operation_body(%Operation{kind: :parent_guid}) do
    [assign_some(:parent_guid, try_call(:graph_focus_read_parent_guid))]
  end

  defp operation_body(%Operation{kind: :symbol_data}) do
    [
      A.let(:data, try_call(:graph_focus_read_symbol_data)),
      assign(:symbol_id, A.try(A.call(:graph_focus_extend_symbol_refs, [A.var(:data), refs()])))
    ]
  end

  defp operation_body(%Operation{kind: :push_guid_ref}) do
    [A.stmt(A.try(A.call(:graph_focus_push_guid_ref, [A.var(:decoder), refs()])))]
  end

  defp operation_body(%Operation{kind: :component_prop_assignments}) do
    [
      A.stmt(
        A.try(A.call(:graph_focus_extend_component_prop_assignments, [A.var(:decoder), refs()]))
      )
    ]
  end

  defp operation_body(%Operation{kind: :component_prop_value}) do
    [A.stmt(A.try(A.call(:graph_focus_extend_component_prop_value, [A.var(:decoder), refs()])))]
  end

  defp assign_some(target, expression), do: assign(target, A.some(expression))
  defp assign(target, expression), do: A.assign(A.var(target), expression)
  defp try_call(function), do: A.try(A.call(function, [A.var(:decoder)]))
  defp refs, do: A.mut_ref(:refs)
end
