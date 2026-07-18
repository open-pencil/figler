defmodule Figler.Render.Skia.Paint.Resolved do
  @moduledoc false

  @enforce_keys [:paint]
  defstruct [:paint, opacity: 1.0, warnings: []]

  @type t :: %__MODULE__{paint: term(), opacity: float(), warnings: [atom()]}
end

defmodule Figler.Render.Skia.Paint do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Image, Skia.Shader]}

  alias Figler.Render.Affine
  alias Figler.Render.Skia.Color
  alias Figler.Render.Skia.Paint.Resolved

  @identity {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}

  @type resolved :: Resolved.t()

  @type image_key :: String.t() | {:blob, non_neg_integer()}

  @spec image_key(map()) :: image_key() | nil
  def image_key(%{type: :image, image: image}) when is_map(image) do
    cond do
      Map.get(image, :hash) != nil ->
        image.hash |> IO.iodata_to_binary() |> Base.encode16(case: :lower)

      is_integer(Map.get(image, :data_blob)) ->
        {:blob, image.data_blob}

      true ->
        nil
    end
  end

  def image_key(_paint), do: nil

  @spec resolve(map(), map() | nil, %{optional(image_key()) => Skia.Image.t()}) ::
          {:ok, resolved()} | {:error, atom()}
  def resolve(%{visible: false}, _size, _images), do: {:error, :hidden}

  def resolve(%{type: :solid} = paint, _size, _images) do
    {:ok,
     %Resolved{paint: Color.rgba(paint.color, paint.opacity), warnings: common_warnings(paint)}}
  end

  def resolve(%{type: :gradient_linear} = paint, size, _images),
    do: linear_gradient(paint, size)

  def resolve(%{type: :gradient_radial} = paint, size, _images),
    do: radial_gradient(paint, size, [])

  def resolve(%{type: :gradient_diamond} = paint, size, _images),
    do: radial_gradient(paint, size, [:gradient_diamond_approximated])

  def resolve(%{type: :gradient_angular} = paint, size, _images),
    do: angular_gradient(paint, size)

  def resolve(%{type: :image} = paint, size, images), do: image_shader(paint, size, images)
  def resolve(_paint, _size, _images), do: {:error, :unsupported_paint}

  defp linear_gradient(paint, %{x: width, y: height}) do
    with {:ok, transform} <- paint_matrix(paint),
         {:ok, stops} <- gradient_stops(paint) do
      from =
        {(elem(transform, 0) + elem(transform, 2)) * width,
         (elem(transform, 3) + elem(transform, 5)) * height}

      to = {elem(transform, 2) * width, elem(transform, 5) * height}
      shader = Skia.Shader.linear_gradient(from, to, stops)
      {:ok, %Resolved{paint: shader, warnings: common_warnings(paint)}}
    end
  end

  defp linear_gradient(_paint, _size), do: {:error, :missing_geometry}

  defp radial_gradient(paint, %{x: width, y: height}, warnings) do
    with {:ok, transform} <- paint_matrix(paint),
         {:ok, stops} <- gradient_stops(paint) do
      local_matrix = Affine.multiply({width, 0.0, 0.0, 0.0, height, 0.0}, transform)
      shader = Skia.Shader.radial_gradient({0.5, 0.5}, 0.5, stops, matrix: local_matrix)
      {:ok, %Resolved{paint: shader, warnings: warnings ++ common_warnings(paint)}}
    end
  end

  defp radial_gradient(_paint, _size, _warnings), do: {:error, :missing_geometry}

  defp angular_gradient(paint, %{x: width, y: height}) do
    with {:ok, transform} <- paint_matrix(paint),
         {:ok, stops} <- gradient_stops(paint) do
      local_matrix = Affine.multiply({width, 0.0, 0.0, 0.0, height, 0.0}, transform)
      shader = Skia.Shader.sweep_gradient({0.5, 0.5}, 0.0, 360.0, stops, matrix: local_matrix)
      {:ok, %Resolved{paint: shader, warnings: common_warnings(paint)}}
    end
  end

  defp angular_gradient(_paint, _size), do: {:error, :missing_geometry}

  defp gradient_stops(paint) do
    case Map.get(paint, :stops, []) do
      [] ->
        {:error, :missing_gradient_stops}

      stops ->
        opacity = Map.get(paint, :opacity) || 1.0

        {:ok,
         Enum.map(stops, fn stop ->
           Skia.Shader.stop(Color.rgba(stop.color, opacity), stop.position)
         end)}
    end
  end

  defp image_shader(paint, size, images) do
    case image_key(paint) do
      nil -> resolve_missing_image_hash()
      hash -> resolve_image_asset(paint, size, Map.get(images, hash))
    end
  end

  defp resolve_missing_image_hash, do: {:error, :missing_image_hash}
  defp resolve_image_asset(_paint, _size, nil), do: {:error, :missing_image_asset}

  defp resolve_image_asset(paint, size, %Skia.Image{} = image) do
    with {:ok, matrix, tile} <- image_matrix(paint, size, image) do
      shader = Skia.Shader.image(image, matrix: matrix, tile: tile, sampling: :linear)

      {:ok,
       %Resolved{
         paint: shader,
         opacity: Map.get(paint, :opacity) || 1.0,
         warnings: image_warnings(paint)
       }}
    end
  end

  defp image_matrix(paint, %{x: width, y: height}, image) do
    mode = Map.get(paint, :image_scale_mode) || :fill

    case {mode, Map.get(paint, :transform)} do
      {:tile, nil} ->
        {:ok, @identity, :repeat}

      {:tile, transform} ->
        transformed_image_matrix(transform, width, height, image, :repeat)

      {:stretch, transform} when is_map(transform) ->
        transformed_image_matrix(transform, width, height, image, :clamp)

      _other ->
        fitted_image_matrix(mode, width, height, image)
    end
  end

  defp image_matrix(_paint, _size, _image), do: {:error, :missing_geometry}

  defp transformed_image_matrix(transform, width, height, image, tile) do
    with {:ok, inverse} <- transform |> matrix() |> invert() do
      local_matrix =
        {width, 0.0, 0.0, 0.0, height, 0.0}
        |> Affine.multiply(inverse)
        |> Affine.multiply({1.0 / image.width, 0.0, 0.0, 0.0, 1.0 / image.height, 0.0})

      {:ok, local_matrix, tile}
    end
  end

  defp fitted_image_matrix(mode, width, height, image) do
    scale =
      if mode == :fit,
        do: min(width / image.width, height / image.height),
        else: max(width / image.width, height / image.height)

    source_width = width / scale
    source_height = height / scale
    source_x = (image.width - source_width) / 2
    source_y = (image.height - source_height) / 2

    matrix =
      {width / source_width, 0.0, 0.0, 0.0, height / source_height, 0.0}
      |> Affine.multiply({1.0, 0.0, -source_x, 0.0, 1.0, -source_y})

    {:ok, matrix, :clamp}
  end

  defp common_warnings(paint) do
    case Map.get(paint, :blend_mode) do
      nil -> []
      :normal -> []
      mode -> [{:blend_mode_unsupported, mode}]
    end
  end

  defp image_warnings(paint) do
    warnings = common_warnings(paint)

    if Map.get(paint, :filter_color_adjust) || Map.get(paint, :paint_filter) do
      [:image_filters_unsupported | warnings]
    else
      warnings
    end
  end

  defp paint_matrix(%{transform: transform}) when is_map(transform), do: {:ok, matrix(transform)}
  defp paint_matrix(_paint), do: {:error, :missing_gradient_transform}

  defp matrix(value) do
    {value.m00 || 1.0, value.m01 || 0.0, value.m02 || 0.0, value.m10 || 0.0, value.m11 || 1.0,
     value.m12 || 0.0}
  end

  defp invert({a, b, c, d, e, f}) do
    determinant = a * e - b * d

    if abs(determinant) < 1.0e-12 do
      {:error, :singular_paint_transform}
    else
      {:ok,
       {e / determinant, -b / determinant, (b * f - e * c) / determinant, -d / determinant,
        a / determinant, (d * c - a * f) / determinant}}
    end
  end
end
