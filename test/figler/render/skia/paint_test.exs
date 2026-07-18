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

  test "maps tile and transformed stretch image modes" do
    {:ok, png} = Skia.canvas(2, 1) |> Skia.clear(:white) |> Skia.to_png()
    {:ok, image} = Skia.Image.decode(png)
    images = %{"cafe" => image}
    base = %{type: :image, visible: true, image: %{hash: <<0xCA, 0xFE>>}}

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = tiled}} =
             Paint.resolve(Map.put(base, :image_scale_mode, :tile), %{x: 20.0, y: 10.0}, images)

    assert tiled.tile_x == :repeat
    assert tiled.tile_y == :repeat
    assert tiled.matrix == {1.0, 0.0, 0.0, 0.0, 1.0, 0.0}

    cropped =
      base
      |> Map.put(:image_scale_mode, :stretch)
      |> Map.put(:transform, %{m00: 0.5, m01: 0.0, m02: 0.25, m10: 0.0, m11: 0.5, m12: 0.25})

    assert {:ok, %{paint: %Skia.Shader.ImageShader{} = shader}} =
             Paint.resolve(cropped, %{x: 20.0, y: 10.0}, images)

    assert shader.tile_x == :clamp
    assert shader.matrix == {20.0, 0.0, -10.0, 0.0, 20.0, -5.0}
  end

  test "marks diamond gradients as an explicit approximation" do
    assert {:ok,
            %{
              paint: %Skia.Shader.RadialGradient{},
              warnings: [:gradient_diamond_approximated]
            }} = Paint.resolve(gradient(:gradient_diamond), %{x: 20.0, y: 10.0}, %{})
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
