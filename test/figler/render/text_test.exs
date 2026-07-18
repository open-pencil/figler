defmodule Figler.Render.TextTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Text
  alias Figler.Render.Text.Source
  alias Figler.Render.Text.StyleOverride

  test "merges adjacent style IDs with identical effective styles" do
    source = %Source{
      character_style_ids: [1, 2],
      style_overrides: %{
        1 => %StyleOverride{style_id: 1, font_size: 18.0},
        2 => %StyleOverride{style_id: 2, font_size: 18.0}
      }
    }

    assert %Text{runs: [run], issues: []} =
             Text.from_effective(text_node("AB"), :text, source, [])

    assert {run.index, run.start, run.length, run.content, run.font.size} == {0, 0, 2, "AB", 18.0}
  end

  test "retains exact ranges for missing style overrides" do
    source = %Source{character_style_ids: [0, 9, 9]}
    text = Text.from_effective(text_node("ABC"), :text, source, [])

    assert Enum.map(text.runs, &{&1.start, &1.length, &1.content}) == [{0, 3, "ABC"}]

    assert text.issues == [
             %{
               code: :text_style_override_missing,
               style_id: 9,
               run: %{start: 1, length: 2}
             }
           ]
  end

  test "does not split a non-BMP Unicode scalar across styles" do
    source = %Source{character_style_ids: [1, 2]}
    text = Text.from_effective(text_node("😀"), :text, source, [])

    assert [%{start: 0, length: 2, content: "😀"}] = text.runs
    assert text.issues == [%{code: :text_style_splits_surrogate, start: 0, length: 2}]
  end

  defp text_node(content) do
    %{
      text: content,
      font_family: "Inter",
      font_style: "Regular",
      font_postscript: "Inter-Regular",
      font_size: 14.0
    }
  end
end
