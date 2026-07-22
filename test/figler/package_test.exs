defmodule Figler.PackageTest do
  use ExUnit.Case, async: true

  test "ships runtime modules and native sources without development generators" do
    files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)

    assert "lib/figler.ex" in files
    assert "lib/figler/native/generated_stubs.ex" in files
    assert "native/src" in files
    assert "priv/schema" in files
    assert "guides" in files

    refute Enum.any?(files, &String.starts_with?(&1, "codegen/"))
    refute Enum.any?(files, &String.starts_with?(&1, "lib/mix/"))
    refute "lib/figler/scene/projection/native.ex" in files
    refute "rustq.exs" in files
    refute "dev/roadmaps/first-beta.md" in files
  end

  test "filters implementation modules from HexDocs without deleting their module docs" do
    filter = Mix.Project.config() |> Keyword.fetch!(:docs) |> Keyword.fetch!(:filter_modules)

    for module <- [
          Figler.Native,
          Figler.Render.Projection,
          Figler.Render.Skia,
          Figler.Scene.Projection,
          Figler.Scene.Query
        ] do
      refute filter.(module, %{})
      assert {:docs_v1, _, _, _, module_doc, _, _} = Code.fetch_docs(module)
      assert is_map(module_doc)
    end

    assert filter.(Figler.Render.SourceNode, %{})
  end

  test "limits RustQ and Reach to development and test compilation" do
    deps = Mix.Project.config() |> Keyword.fetch!(:deps)

    for app <- [:rustq, :reach] do
      {_app, _requirement, opts} = Enum.find(deps, &(elem(&1, 0) == app))

      assert Keyword.fetch!(opts, :only) == [:dev, :test]
      refute Keyword.get(opts, :override, false)
      refute Keyword.get(opts, :runtime, true)
    end
  end
end
