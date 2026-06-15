defmodule FigKiwi.OracleFixtureTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene.Graph.Oracle

  @committed_manifest "test/fixtures/oracles/basic/manifest.json"
  @committed_fixture "test/fixtures/oracles/basic/basic.fig"

  test "committed oracle fixture matches effective graph projection" do
    assert_manifest(@committed_fixture, @committed_manifest)
  end

  test "optional external oracle fixtures match effective graph projection" do
    fixture_dir = System.get_env("FIG_KIWI_EXTERNAL_ORACLE_DIR")

    if is_nil(fixture_dir) or fixture_dir == "" do
      :ok
    else
      manifests = Path.wildcard(Path.join(fixture_dir, "**/manifest.json"))
      assert manifests != []

      for manifest <- manifests do
        fixture =
          manifest |> Path.dirname() |> Path.join("*.fig") |> Path.wildcard() |> List.first()

        assert is_binary(fixture), "no .fig fixture found next to #{manifest}"
        assert_manifest(fixture, manifest)
      end
    end
  end

  defp assert_manifest(fixture_path, manifest_path) do
    base_dir = Path.dirname(manifest_path)
    fixture = fixture_path |> File.read!() |> FigKiwi.Scene.payload!()

    results = Enum.map(Oracle.entries!(manifest_path), &Oracle.run(fixture, base_dir, &1))

    assert Enum.all?(results, &(&1.diff_count == 0))
  end
end
