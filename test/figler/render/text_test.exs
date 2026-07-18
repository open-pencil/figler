defmodule Figler.Render.TextTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Text
  alias Figler.Render.Text.Measurement
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

  test "normalizes base and run typography against each effective font size" do
    node =
      text_node("AB")
      |> Map.merge(%{
        line_height: %{value: 150.0, units: :percent},
        letter_spacing: %{value: 0.5, units: :raw},
        text_decoration: :underline,
        text_case: :upper,
        text_align_horizontal: :center,
        text_align_vertical: :bottom,
        text_auto_resize: :height,
        text_truncation: :ending,
        max_lines: 2
      })

    source = %Source{
      character_style_ids: [0, 1],
      style_overrides: %{
        1 => %StyleOverride{
          style_id: 1,
          font_size: 20.0,
          line_height: %Measurement{value: 1.2, units: :raw},
          letter_spacing: %Measurement{value: 10.0, units: :percent},
          text_decoration: :strikethrough,
          text_decoration_style: :wavy,
          text_decoration_skip_ink: false,
          text_decoration_thickness: %Measurement{value: 2.0, units: :pixels},
          text_underline_offset: %Measurement{value: 1.0, units: :pixels},
          text_case: :lower
        }
      }
    }

    assert %Text{
             align_horizontal: :center,
             align_vertical: :bottom,
             auto_resize: :height,
             truncation: :ending,
             max_lines: 2,
             runs: [base, overridden]
           } = Text.from_effective(node, :text, source, [])

    assert {base.line_height, base.letter_spacing, base.text_decoration, base.text_case} ==
             {21.0, 0.5, :underline, :upper}

    assert {
             overridden.font.size,
             overridden.line_height,
             overridden.letter_spacing,
             overridden.text_decoration,
             overridden.text_decoration_style,
             overridden.text_decoration_skip_ink,
             overridden.text_decoration_thickness,
             overridden.text_underline_offset,
             overridden.text_case
           } ==
             {
               20.0,
               24.0,
               2.0,
               :strikethrough,
               :wavy,
               false,
               %Measurement{value: 2.0, units: :pixels},
               %Measurement{value: 1.0, units: :pixels},
               :lower
             }
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
