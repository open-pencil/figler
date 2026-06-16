defmodule FigKiwi.NativeSceneGeneratorTest do
  use ExUnit.Case, async: true

  alias FigKiwi.NativeSceneGenerator
  alias FigKiwi.NativeSceneGenerator.Scene
  alias FigKiwi.NativeSceneGenerator.Skip
  alias FigKiwi.NativeSceneGenerator.Sparse

  test "root generator exposes expected splice groups" do
    splices = NativeSceneGenerator.render_splices(FigKiwi.schema())

    assert Keyword.has_key?(splices, :sparse_decoders)
    assert Keyword.has_key?(splices, :skip_decoders)
    assert Keyword.has_key?(splices, :graph_focus_decoders)
    assert Keyword.has_key?(splices, :scene_record_fields)
  end

  test "split generator modules render focused fragments" do
    schema = FigKiwi.schema()
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    assert Sparse.render(schema.definitions, definition_map) |> List.flatten() |> Enum.join("\n") =~
             "decode_sparse_message_from_decoder"

    assert Skip.render(schema.definitions, definition_map) |> List.flatten() |> Enum.join("\n") =~
             "skip_message_from_decoder"

    assert Scene.render(definition_map)[:scene_record_fields]
  end
end
