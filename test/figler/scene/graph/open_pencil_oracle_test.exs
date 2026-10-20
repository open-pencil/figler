defmodule Figler.Scene.Graph.OpenPencilOracleTest do
  use ExUnit.Case, async: true

  alias Figler.Scene.Graph.OpenPencilOracle

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"
  @openpencil_env "FIGLER_OPENPENCIL_DIR"

  setup_all do
    {:ok, graph: @fixture |> File.read!() |> Figler.Scene.graph()}
  end

  # The fixture's last page holds the instances.
  defp instance_page(graph), do: Figler.Scene.node(graph, "9:1459")

  test "projects pages in OpenPencil's shape", %{graph: graph} do
    projected = OpenPencilOracle.project(graph, instance_page(graph))

    assert %{"source_id" => "9:1459", "type" => "CANVAS", "children" => [_ | _]} = projected
  end

  test "pairs children by source id and reports structural differences", %{graph: graph} do
    projected = OpenPencilOracle.project(graph, instance_page(graph))
    [first, second | rest] = projected["children"]

    renamed = Map.put(second, "name", "renamed")
    missing = %{"source_id" => "999:1", "type" => "FRAME", "name" => "Gone", "visible" => true}

    expected = %{
      "pages" => [
        %{
          "id" => projected["source_id"],
          "name" => "page",
          "tree" => %{projected | "children" => [renamed, missing, first | rest]}
        }
      ]
    }

    %{diffs: diffs, by_field: by_field} = OpenPencilOracle.compare(graph, expected)

    assert by_field == %{"name" => 1, "missing_child" => 1, "children.order" => 1}
    assert Enum.any?(diffs, &(&1.field == "name" and &1.openpencil == "renamed"))
    assert Enum.any?(diffs, &(&1.field == "missing_child" and &1.openpencil == "999:1 Gone"))
  end

  if System.get_env(@openpencil_env) do
    @tag :external_fixture
    @tag timeout: 120_000
    test "reads the fixture with OpenPencil's interpreter", %{graph: graph} do
      expected =
        OpenPencilOracle.expected!(@fixture, openpencil: System.fetch_env!(@openpencil_env))

      assert [%{"tree" => %{"type" => "CANVAS"}} | _] = expected["pages"]
      assert %{diffs: diffs} = OpenPencilOracle.compare(graph, expected)
      assert is_list(diffs)
    end
  end
end
