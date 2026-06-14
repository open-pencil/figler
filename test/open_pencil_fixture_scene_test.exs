defmodule FigKiwi.OpenPencilFixtureSceneTest do
  use ExUnit.Case, async: true

  fixtures = [
    {"gold-preview", "gold-preview.fig", 3_519},
    {"material3", "material3.fig", 87_237},
    {"nuxtui", "nuxtui.fig", 315_274}
  ]

  if fixture_dir = System.get_env("FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR") do
    for {name, file, expected_nodes} <- fixtures do
      path = Path.join(fixture_dir, file)

      if File.exists?(path) do
        @tag timeout: 120_000
        test "summarizes OpenPencil fixture #{name}" do
          summary = unquote(path) |> File.read!() |> FigKiwi.Scene.summary()

          assert summary.node_count == unquote(expected_nodes)
          assert summary.parented_count > 0
          assert summary.root_count > 0
          assert {"canvas", canvas_count} = List.keyfind(summary.type_counts, "canvas", 0)
          assert canvas_count > 0
        end
      end
    end
  else
    @tag :external_fixture
    test "OpenPencil fixture tests are disabled" do
      assert System.get_env("FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR") in [nil, ""]
    end
  end
end
