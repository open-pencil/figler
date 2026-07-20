defmodule Figler.Render.VectorNetworkTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Skia.VectorNetwork, as: SkiaVectorNetwork
  alias Figler.Render.Vector
  alias Figler.Render.VectorNetwork

  test "decodes, validates, scales, and compiles closed vector regions" do
    assert {:ok, network} =
             VectorNetwork.decode(square_blob(), %Vector{x: 100.0, y: 100.0}, %Vector{
               x: 200.0,
               y: 50.0
             })

    assert Enum.map(network.vertices, &{&1.position.x, &1.position.y}) == [
             {0.0, 0.0},
             {200.0, 0.0},
             {200.0, 50.0},
             {0.0, 50.0}
           ]

    assert [%{winding_rule: :even_odd, loops: [[0, 1, 2, 3]]}] = network.regions
    assert {:ok, %{fill: [geometry], stroke: [stroke]}} = SkiaVectorNetwork.paths(network)
    assert geometry.fill_rule == :even_odd
    assert stroke.fill_rule == :even_odd

    assert Skia.Path.segments(geometry.path) == [
             {:move_to, 0.0, 0.0},
             {:line_to, 200.0, 0.0},
             {:line_to, 200.0, 50.0},
             {:line_to, 0.0, 50.0},
             {:line_to, 0.0, 0.0},
             :close
           ]
  end

  test "preserves relative cubic tangent handles" do
    blob =
      network_blob(
        [{0.0, 0.0}, {100.0, 0.0}],
        [{0, {25.0, 40.0}, 1, {-25.0, 40.0}}],
        []
      )

    assert {:ok, network} = VectorNetwork.decode(blob)
    assert {:ok, %{stroke: [geometry]}} = SkiaVectorNetwork.paths(network)

    assert Skia.Path.segments(geometry.path) == [
             {:move_to, 0.0, 0.0},
             {:cubic_to, 25.0, 40.0, 75.0, 40.0, 100.0, 0.0}
           ]
  end

  test "rejects malformed counts, indices, and trailing bytes" do
    assert {:error, :invalid_vector_network_counts} =
             VectorNetwork.decode(
               <<10::little-unsigned-32, 0::little-unsigned-32, 0::little-unsigned-32>>
             )

    invalid_segment = network_blob([{0.0, 0.0}], [{0, {0.0, 0.0}, 2, {0.0, 0.0}}], [])

    assert {:error, {:invalid_vector_segment_vertex, 0}} =
             VectorNetwork.decode(invalid_segment)

    assert {:error, {:trailing_vector_network_bytes, 1}} =
             VectorNetwork.decode(square_blob() <> <<255>>)
  end

  defp square_blob do
    network_blob(
      [{0.0, 0.0}, {100.0, 0.0}, {100.0, 100.0}, {0.0, 100.0}],
      [
        {0, {0.0, 0.0}, 1, {0.0, 0.0}},
        {1, {0.0, 0.0}, 2, {0.0, 0.0}},
        {2, {0.0, 0.0}, 3, {0.0, 0.0}},
        {3, {0.0, 0.0}, 0, {0.0, 0.0}}
      ],
      [{0, [[0, 1, 2, 3]]}]
    )
  end

  defp network_blob(vertices, segments, regions) do
    header =
      <<length(vertices)::little-unsigned-32, length(segments)::little-unsigned-32,
        length(regions)::little-unsigned-32>>

    vertices =
      Enum.map_join(vertices, fn {x, y} ->
        <<0::little-unsigned-32, x::little-float-32, y::little-float-32>>
      end)

    segments =
      Enum.map_join(segments, fn {start, {tsx, tsy}, finish, {tex, tey}} ->
        <<0::little-unsigned-32, start::little-unsigned-32, tsx::little-float-32,
          tsy::little-float-32, finish::little-unsigned-32, tex::little-float-32,
          tey::little-float-32>>
      end)

    regions =
      Enum.map_join(regions, fn {winding, loops} ->
        encoded_loops =
          Enum.map_join(loops, fn indices ->
            <<length(indices)::little-unsigned-32>> <>
              Enum.map_join(indices, &<<&1::little-unsigned-32>>)
          end)

        <<winding::little-unsigned-32, length(loops)::little-unsigned-32>> <> encoded_loops
      end)

    header <> vertices <> segments <> regions
  end
end
