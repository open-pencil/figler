defmodule FigKiwi.OracleFixtureTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene.Graph.Oracle

  @fixture "test/fixtures/oracles/basic/basic.fig"
  @manifest "test/fixtures/oracles/basic/manifest.json"

  test "committed oracle fixture matches effective graph projection" do
    base_dir = Path.dirname(@manifest)
    fixture = @fixture |> File.read!() |> FigKiwi.Scene.payload!()

    results = Enum.map(Oracle.entries!(@manifest), &Oracle.run(fixture, base_dir, &1))

    assert Enum.map(results, & &1.diff_count) == [0]
  end
end
