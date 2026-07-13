defmodule Figler.Codegen.Native.Scene.Decode do
  @moduledoc """
  Builds schema-driven scene index decode arms from semantic operations.

  `Figler.Codegen.Native.Scene` decides which projection field maps to a
  Kiwi field id. This module owns the RustQ AST for the operation performed when
  that field is encountered while building the native scene index.
  """

  alias RustQ.Rust.AST
  alias RustQ.Rust.AST.Builder, as: A
  alias RustQ.Rust.AST.PatternBuilder, as: P

  defmodule Operation do
    @moduledoc """
    Semantic scene decode operation for one already-read `NodeChange` field.
    """

    @enforce_keys [:kind]
    defstruct [:kind, :target]

    @type kind ::
            :font_name
            | :text_data
            | :style_id
            | :bool
            | :float
            | :vector
            | :matrix
            | :counted_paints
            | :string

    @type t :: %__MODULE__{kind: kind(), target: atom() | nil}
  end

  @spec arm(non_neg_integer(), Operation.t()) :: AST.Arm.t()
  def arm(field_id, %Operation{} = operation) do
    %AST.Arm{pattern: P.lit(field_id), body: operation_body(operation)}
  end

  @spec font_name() :: Operation.t()
  def font_name, do: %Operation{kind: :font_name}

  @spec text_data(atom() | String.t()) :: Operation.t()
  def text_data(target), do: targeted(:text_data, target)

  @spec style_id(atom() | String.t()) :: Operation.t()
  def style_id(target), do: targeted(:style_id, target)

  @spec bool(atom() | String.t()) :: Operation.t()
  def bool(target), do: targeted(:bool, target)

  @spec float(atom() | String.t()) :: Operation.t()
  def float(target), do: targeted(:float, target)

  @spec vector() :: Operation.t()
  def vector, do: %Operation{kind: :vector, target: :size}

  @spec matrix() :: Operation.t()
  def matrix, do: %Operation{kind: :matrix, target: :transform}

  @spec counted_paints(atom() | String.t()) :: Operation.t()
  def counted_paints(target), do: targeted(:counted_paints, target)

  @spec string(atom() | String.t()) :: Operation.t()
  def string(target), do: targeted(:string, target)

  defp targeted(kind, target), do: %Operation{kind: kind, target: target_atom(target)}

  defp operation_body(%Operation{kind: :font_name}) do
    [
      A.let(:font_name, try_call(:read_scene_font_name_value)),
      assign(:font_family, A.field(:font_name, 0)),
      assign(:font_style, A.field(:font_name, 1)),
      assign(:font_postscript, A.field(:font_name, 2))
    ]
  end

  defp operation_body(%Operation{kind: :text_data, target: target}) do
    [assign(target, try_call(:read_scene_text_data_value))]
  end

  defp operation_body(%Operation{kind: :style_id, target: target}) do
    [assign(target, try_call(:read_scene_style_id_value))]
  end

  defp operation_body(%Operation{kind: :bool, target: target}) do
    [assign(target, A.some(try_method(:read_bool)))]
  end

  defp operation_body(%Operation{kind: :float, target: target}) do
    [assign(target, A.some(try_method(:read_var_float_value)))]
  end

  defp operation_body(%Operation{kind: :vector, target: target}) do
    [assign(target, A.some(try_call(:read_scene_size_value)))]
  end

  defp operation_body(%Operation{kind: :matrix, target: target}) do
    [assign(target, A.some(try_call(:read_scene_transform_value)))]
  end

  defp operation_body(%Operation{kind: :counted_paints, target: target}) do
    [
      assign(
        target,
        A.try(
          A.call(:read_scene_counted_array_value, [
            A.var(:decoder),
            A.path(:skip_paint_from_decoder)
          ])
        )
      )
    ]
  end

  defp operation_body(%Operation{kind: :string, target: target}) do
    [assign(target, A.some(try_method(:read_string_value)))]
  end

  defp assign(target, expression), do: A.assign(A.var(target), expression)

  defp try_call(function), do: A.try(A.call(function, [A.var(:decoder)]))
  defp try_method(method), do: A.try(A.method(:decoder, method))

  defp target_atom(target) when is_atom(target), do: target
  defp target_atom(target) when is_binary(target), do: String.to_existing_atom(target)
end
