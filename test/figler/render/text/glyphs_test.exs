defmodule Figler.Render.Text.GlyphsTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Paint
  alias Figler.Render.Text
  alias Figler.Render.Text.Glyph
  alias Figler.Render.Text.Glyphs
  alias Figler.Render.Text.Run

  @fixture "test/fixtures/openpencil/variable-override-precedence.fig"

  describe "from_derived/2" do
    test "reads glyph advances in pixels and marks emoji" do
      derived = %{
        glyphs: [
          saved(0, 0.0, 10.0, advance: 0.5),
          saved(1, 6.0, 10.0, emoji_code_points: [0x1F600])
        ]
      }

      assert {[first, emoji], []} = Glyphs.from_derived(derived, "A😀")
      assert %Glyph{commands_blob: 0, advance: 6.0, emoji?: false} = first
      assert %Glyph{commands_blob: 1, advance: nil, emoji?: true} = emoji
    end

    test "hides glyphs from the truncation index on" do
      derived = %{glyphs: Enum.map(0..3, &saved(&1, &1 * 5.0, 10.0)), truncation_start_index: 2}

      assert {[%Glyph{commands_blob: 0}, %Glyph{commands_blob: 1}], []} =
               Glyphs.from_derived(derived, "ABCD")
    end

    test "drops every glyph when one has no outline" do
      derived = %{glyphs: [saved(0, 0.0, 10.0), Map.delete(saved(1, 5.0, 10.0), :commands_blob)]}
      assert {[], []} = Glyphs.from_derived(derived, "AB")
    end

    test "drops text OpenPencil saved without laying it out" do
      derived = %{
        glyphs: [saved(0, 0.0, 14.0), saved(1, 5.0, 14.0)],
        baselines: [%{position: %{x: 0.0, y: 14.0}}],
        logical_index_to_character_offset_map: [0.0, 5.0, 10.0]
      }

      assert {[], []} = Glyphs.from_derived(derived, "AB")
      assert {[_, _], []} = Glyphs.from_derived(%{derived | baselines: []}, "AB")
    end
  end

  describe "drawable?/2" do
    test "needs fills that paint outlines" do
      text = text([glyph(0)], [run(0, 1)])

      assert Glyphs.drawable?(text, [solid()])
      assert Glyphs.drawable?(text, [%Paint{type: :gradient_linear}])
      refute Glyphs.drawable?(text, [%Paint{type: :image}])
      assert Glyphs.drawable?(text, [%Paint{type: :image, visible: false}])
      refute Glyphs.drawable?(%{text | glyphs: []}, [solid()])
    end

    test "gives style runs their own colours only with one visible fill and known characters" do
      text = text([glyph(0), glyph(1)], [run(0, 1), run(1, 1, fill_paints: [solid()])])

      assert Glyphs.drawable?(text, [solid()])
      refute Glyphs.drawable?(text, [solid(), solid()])
      refute Glyphs.drawable?(%{text | glyphs: [glyph(0), glyph(nil)]}, [solid()])

      blended = %{text | runs: [run(0, 2, fill_paints: [%{solid() | blend_mode: :multiply}])]}
      refute Glyphs.drawable?(blended, [solid()])
    end

    test "needs decorations saved for decorated text" do
      text = text([glyph(0)], [%{run(0, 1) | text_decoration: :underline}])

      refute Glyphs.drawable?(text, [solid()])
      assert Glyphs.drawable?(%{text | decorations: [%{style_id: 0, rects: []}]}, [solid()])
    end
  end

  describe "placements/1" do
    test "snaps straight baselines and flips font units into the layer" do
      text = text([%{glyph(0) | x: 3.0, y: 10.4, font_size: 12.0}], [run(0, 1)])

      assert [{nil, [{_glyph, {12.0, +0.0, 3.0, +0.0, -12.0, 10.0}}]}] = Glyphs.placements(text)
    end

    test "keeps rotated baselines and turns each glyph against its rotation" do
      rotated = %{glyph(0) | y: 10.4, font_size: 1.0, rotation: -:math.pi() / 2}

      assert [{nil, [{_glyph, {a, b, _c, d, e, 10.4}}]}] =
               Glyphs.placements(text([rotated], [run(0, 1)]))

      assert_in_delta a, 0.0, 1.0e-9
      assert_in_delta b, 1.0, 1.0e-9
      assert_in_delta d, 1.0, 1.0e-9
      assert_in_delta e, 0.0, 1.0e-9
    end

    test "groups glyphs by the style run whose fills paint them and skips emoji" do
      coloured = run(1, 2, fill_paints: [solid()])
      glyphs = [glyph(0), glyph(1), %{glyph(2) | emoji?: true}, glyph(2), glyph(3)]

      assert [{nil, [_]}, {^coloured, [_, _]}, {nil, [_]}] =
               Glyphs.placements(text(glyphs, [run(0, 1), coloured, run(3, 1)]))
    end
  end

  test "renders glyphs saved for unchanged text and lays out overridden text" do
    {:ok, scene} = @fixture |> File.read!() |> Figler.Render.prepare()

    texts =
      scene.render_nodes
      |> Map.values()
      |> Enum.filter(& &1.text)
      |> Map.new(&{&1.guid, &1.text})

    assert Enum.any?(texts, fn {_guid, text} -> text.glyphs != [] end)

    assert Enum.all?(texts, fn {_guid, text} ->
             text.content != "Different" or text.glyphs == []
           end)
  end

  defp saved(blob, x, y, attrs \\ []) do
    Map.merge(
      %{commands_blob: blob, position: %{x: x, y: y}, font_size: 12.0, first_character: blob},
      Map.new(attrs)
    )
  end

  defp glyph(character),
    do: %Glyph{commands_blob: 0, x: 0.0, y: 0.0, font_size: 12.0, first_character: character}

  defp text(glyphs, runs),
    do: %Text{content: "", font: nil, glyphs: glyphs, runs: runs}

  defp run(start, length, attrs \\ []) do
    struct!(
      %Run{index: 0, start: start, length: length, content: "", font: nil, style_id: start},
      Keyword.merge([fill_override?: Keyword.has_key?(attrs, :fill_paints)], attrs)
    )
  end

  defp solid, do: %Paint{type: :solid, visible: true}
end
