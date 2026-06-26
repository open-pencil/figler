defmodule Figler.OracleFixtureTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph.Oracle

  @committed_manifest "test/fixtures/oracles/basic/manifest.json"
  @committed_fixture "test/fixtures/oracles/basic/basic.fig"

  test "committed oracle fixture matches effective graph projection" do
    assert_manifest(@committed_fixture, @committed_manifest)
  end

  test "optional external oracle fixtures match effective graph projection" do
    fixture_dir = System.get_env("FIGLER_EXTERNAL_ORACLE_DIR")

    if is_binary(fixture_dir) and fixture_dir != "" do
      Mix.Task.rerun("figler.oracles", ["--dir", fixture_dir])
    end
  end

  defp assert_manifest(fixture_path, manifest_path) do
    base_dir = Path.dirname(manifest_path)
    fixture = fixture_path |> File.read!() |> Figler.Scene.payload!()

    results = Enum.map(Oracle.entries!(manifest_path), &Oracle.run(fixture, base_dir, &1))

    assert Enum.all?(results, &(&1.diff_count == 0))
  end
end
