defmodule FigKiwi.OpenPencilNodeOracleTest do
  use ExUnit.Case, async: true

  @moduletag :external_fixture

  @cli_env "FIG_KIWI_OPEN_PENCIL_NODE_CLI"
  @fixture_env "FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR"

  if System.get_env(@cli_env) && System.get_env(@fixture_env) do
    @tag timeout: 120_000
    test "compares document info with OpenPencil Node CLI" do
      fixture = Path.join(System.fetch_env!(@fixture_env), "gold-preview.fig")
      cli = System.fetch_env!(@cli_env)

      assert File.regular?(fixture)

      open_pencil = open_pencil_info!(cli, fixture)
      summary = fixture |> File.read!() |> FigKiwi.Scene.summary()

      assert summary.node_count == open_pencil["totalNodes"]
      assert {"canvas", canvas_count} = List.keyfind(summary.type_counts, "canvas", 0)
      assert canvas_count == open_pencil["pages"]
    end

    defp open_pencil_info!(cli, fixture) do
      {json, 0} = System.cmd("node", [cli, "info", fixture, "--json"], stderr_to_stdout: true)
      Jason.decode!(json)
    end
  else
    test "OpenPencil Node oracle tests are disabled" do
      assert System.get_env(@cli_env) in [nil, ""] or System.get_env(@fixture_env) in [nil, ""]
    end
  end
end
