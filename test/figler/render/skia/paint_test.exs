defmodule Figler.Render.Skia.PaintTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Skia.Paint

  test "maps radial and angular Figma gradients into positioned Skia shaders" do
    size = %{x: 200.0, y: 100.0}

    assert {:ok, %{paint: %Skia.Shader.RadialGradient{} = radial, warnings: []}} =
             Paint.resolve(gradient(:gradient_radial), size, %{})

    assert radial.center == {0.5, 0.5}
    assert radial.radius == 0.5
    assert radial.matrix == {200.0, 0.0, 0.0, 0.0, 100.0, 0.0}
    assert Enum.map(radial.colors, & &1.position) == [0.0, 1.0]

    assert {:ok, %{paint: %Skia.Shader.SweepGradient{} = angular, warnings: []}} =
             Paint.resolve(gradient(:gradient_angular), size, %{})

    assert angular.center == {0.5, 0.5}
    assert angular.start_degrees == 0.0
    assert angular.end_degrees == 360.0
  end

  test "maps tile, stretch, crop transforms, scale, and rotation" do
    {:ok, png} = Skia.canvas(2, 1) |> Skia.clear(:white) |> Skia.to_png()
    {:ok, image} = Skia.Image.decode(png)
    images = %{"cafe" => image}
    base = %{type: :image, visible: true, image: %{hash: <<0xCA, 0xFE>>}}

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = tiled}} =
             Paint.resolve(Map.put(base, :image_scale_mode, :tile), %{x: 20.0, y: 10.0}, images)

    assert tiled.tile_x == :repeat
    assert tiled.tile_y == :repeat
    assert tiled.matrix == {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}

    stretched = Map.put(base, :image_scale_mode, :stretch)

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = stretched_shader}} =
             Paint.resolve(stretched, %{x: 20.0, y: 10.0}, images)

    assert stretched_shader.matrix == {10.0, 0.0, 0.0, 0.0, 10.0, 0.0}

    scaled_and_rotated =
      base
      |> Map.put(:image_scale_mode, :tile)
      |> Map.put(:scale, 2.0)
      |> Map.put(:rotation, 90.0)

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = rotated_shader}} =
             Paint.resolve(scaled_and_rotated, %{x: 20.0, y: 10.0}, images)

    # The 2x1 image turned a quarter, its 1x2 bounds at the origin, then tiled at twice its size.
    [a, b, c, d, e, f] = Tuple.to_list(rotated_shader.matrix)
    assert_in_delta a, 0.0, 1.0e-12
    assert_in_delta b, -2.0, 1.0e-12
    assert_in_delta c, 2.0, 1.0e-12
    assert_in_delta d, 2.0, 1.0e-12
    assert_in_delta e, 0.0, 1.0e-12
    assert_in_delta f, 0.0, 1.0e-12

    transformed_tile =
      base
      |> Map.put(:image_scale_mode, :tile)
      |> Map.put(:scale, 2.0)
      |> Map.put(:transform, %{m00: 0.5, m01: 0.0, m02: 0.0, m10: 0.0, m11: 0.5, m12: 0.0})

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = transformed_tile_shader}} =
             Paint.resolve(transformed_tile, %{x: 20.0, y: 10.0}, images)

    assert transformed_tile_shader.matrix == {2.0, 0.0, 0.0, 0.0, 2.0, 0.0}

    fitted = Map.put(base, :image_scale_mode, :fit)

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = fitted_shader}} =
             Paint.resolve(fitted, %{x: 20.0, y: 20.0}, images)

    assert fitted_shader.tile_x == :decal
    assert fitted_shader.matrix == {10.0, 0.0, 0.0, 0.0, 10.0, 5.0}

    cropped =
      base
      |> Map.put(:image_scale_mode, :stretch)
      |> Map.put(:transform, %{m00: 0.5, m01: 0.0, m02: 0.25, m10: 0.0, m11: 0.5, m12: 0.25})

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = shader}} =
             Paint.resolve(cropped, %{x: 20.0, y: 10.0}, images)

    assert shader.tile_x == :clamp
    assert shader.matrix == {20.0, 0.0, -10.0, 0.0, 20.0, -5.0}
  end

  test "renders true transformed diamond gradients" do
    assert {:ok,
            %{
              paint:
                %Skia.Shader.RuntimeEffect{
                  children: %{gradient: %Skia.Shader.LinearGradient{}},
                  matrix: matrix
                } = shader,
              warnings: []
            }} = Paint.resolve(gradient(:gradient_diamond), %{x: 20.0, y: 20.0}, %{})

    assert matrix == {20.0, 0, 0, 0, 20.0, 0}

    assert {:ok, %{data: data}} =
             Skia.canvas(20, 20)
             |> Skia.rect(x: 0, y: 0, width: 20, height: 20, fill: shader)
             |> Skia.to_raw()

    <<center_red, _center_green, center_blue, 255>> =
      binary_part(data, 4 * (10 * 20 + 10), 4)

    <<edge_red, _edge_green, edge_blue, 255>> = binary_part(data, 4 * 10, 4)
    assert center_red > center_blue
    assert edge_blue > edge_red
  end

  test "rejects malformed image rotations and tiles unscaled images at their size" do
    {:ok, png} = Skia.canvas(2, 1) |> Skia.clear(:white) |> Skia.to_png()
    {:ok, image} = Skia.Image.decode(png)
    images = %{"cafe" => image}

    base = %{
      type: :image,
      visible: true,
      image: %{hash: <<0xCA, 0xFE>>},
      image_scale_mode: :tile
    }

    assert {:ok, %{paint: %{matrix: {1.0, +0.0, +0.0, +0.0, 1.0, +0.0}}}} =
             Paint.resolve(Map.put(base, :scale, 0), %{x: 2, y: 1}, images)

    assert {:error, :invalid_image_rotation} =
             Paint.resolve(Map.put(base, :rotation, :invalid), %{x: 2, y: 1}, images)
  end

  defp gradient(type) do
    %{
      type: type,
      visible: true,
      opacity: 1.0,
      transform: %{m00: 1.0, m01: 0.0, m02: 0.0, m10: 0.0, m11: 1.0, m12: 0.0},
      stops: [
        %{color: %{r: 1.0, g: 0.0, b: 0.0, a: 1.0}, position: 0.0},
        %{color: %{r: 0.0, g: 0.0, b: 1.0, a: 1.0}, position: 1.0}
      ]
    }
  end
end
