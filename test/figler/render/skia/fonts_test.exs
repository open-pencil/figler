defmodule Figler.Render.Skia.FontsTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Font
  alias Figler.Render.Node
  alias Figler.Render.Skia.Fonts
  alias Figler.Render.Text
  alias Figler.Render.Text.Run

  test "reports unavailable requested families when no fallback covers the text" do
    node = text_node("__Figler Missing Font__", <<0x10FFFF::utf8>>)
    guid = node.guid

    assert {:ok, result} = Fonts.resolve([node], [])
    assert %{^guid => [warning]} = result.warnings
    assert warning.code == :font_unavailable
    assert warning.requested.family == "__Figler Missing Font__"
    assert warning.run == %{index: 0, start: 0, length: 2}
    refute Map.has_key?(result.fonts, {guid, 0, 0})
  end

  test "uses Skia's installed character fallback and reports the substitution" do
    node = text_node("__Figler Missing Font__", "Hello")
    guid = node.guid

    assert {:ok, result} = Fonts.resolve([node], font_languages: ["en"])
    assert %{^guid => [warning]} = result.warnings
    assert warning.code == :font_substituted
    assert warning.resolved.source == :system
    assert %{{^guid, 0, 0} => resolved} = result.fonts
    assert resolved.source == :system
    assert is_binary(resolved.family)
  end

  test "prefers caller-supplied fallback typefaces" do
    assert {:ok, [family | _families]} = Skia.Typeface.families()
    assert {:ok, typeface} = Skia.Typeface.match_character("A", family: family)
    node = text_node("__Figler Missing Font__", "A")
    guid = node.guid

    assert {:ok, result} =
             Fonts.resolve([node],
               fallback_typefaces: [typeface],
               system_font_fallback: false
             )

    assert %{^guid => [%{code: :font_substituted, resolved: %{source: :supplied}}]} =
             result.warnings

    assert %{{^guid, 0, 0} => %{source: :supplied}} = result.fonts
  end

  test "reports exact missing glyph codepoints for an available family" do
    assert {:ok, [family | _families]} = Skia.Typeface.families()
    node = text_node(family, <<0x10FFFF::utf8>>)
    guid = node.guid

    assert {:ok, result} = Fonts.resolve([node], system_font_fallback: false)
    assert %{^guid => [warning]} = result.warnings
    assert warning.code == :glyphs_missing
    assert warning.characters == [<<0x10FFFF::utf8>>]
    assert warning.codepoints == ["U+10FFFF"]
  end

  test "diagnoses missing codepoints at the exact rich-text run range" do
    assert {:ok, typeface} = Skia.Typeface.match_character("A")
    font = %Font{family: typeface.family}

    first = %Run{index: 0, start: 0, length: 1, content: "A", font: font}

    missing =
      %Run{index: 1, start: 1, length: 2, content: <<0x10FFFF::utf8>>, font: font}

    node = %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :text,
      text: %Text{content: first.content <> missing.content, font: font, runs: [first, missing]}
    }

    assert {:ok, result} = Fonts.resolve([node], system_font_fallback: false)
    assert %{{{1, 1}, 0, 0} => _first, {{1, 1}, 1, 0} => _missing} = result.fonts

    assert %{{1, 1} => [warning]} = result.warnings
    assert warning.code == :glyphs_missing
    assert warning.run == %{index: 1, start: 1, length: 2}
    assert warning.codepoints == ["U+10FFFF"]
  end

  test "splits one style run at grapheme fallback boundaries" do
    assert {:ok, fallback} = Skia.Typeface.match_character("A")
    missing = <<0x10FFFF::utf8>>
    node = text_node("__Figler Missing Font__", "A" <> missing <> "B")
    guid = node.guid

    assert {:ok, result} =
             Fonts.resolve([node],
               fallback_typefaces: [fallback],
               system_font_fallback: false
             )

    assert [first, unresolved, last] = result.spans[guid]

    assert {first.start, first.length, first.content, first.resolved.source} ==
             {0, 1, "A", :supplied}

    assert {unresolved.start, unresolved.length, unresolved.content, unresolved.resolved} ==
             {1, 2, missing, nil}

    assert {last.start, last.length, last.content, last.resolved.source} ==
             {3, 1, "B", :supplied}

    assert Enum.map(result.warnings[guid], &{&1.code, &1.run.start, &1.run.length}) == [
             {:font_substituted, 0, 1},
             {:font_unavailable, 1, 2},
             {:font_substituted, 3, 1}
           ]
  end

  test "applies supported text case while preserving UTF-16 source ranges" do
    assert {:ok, typeface} = Skia.Typeface.match_character("S")
    font = %Font{family: typeface.family}

    run = %Run{
      index: 0,
      start: 0,
      length: 1,
      content: "ß",
      font: font,
      text_case: :upper
    }

    node = %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :text,
      text: %Text{content: "ß", font: font, runs: [run]}
    }

    assert {:ok, result} = Fonts.resolve([node], system_font_fallback: false)
    assert [%{content: "SS", start: 0, length: 1}] = result.spans[{1, 1}]
  end

  test "applies title case without changing UTF-16 source ranges" do
    assert {:ok, typeface} = Skia.Typeface.match_character("S")
    font = %Font{family: typeface.family}
    content = "ßeta test"

    run = %Run{
      index: 0,
      start: 0,
      length: utf16_length(content),
      content: content,
      font: font,
      text_case: :title
    }

    node = %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :text,
      text: %Text{content: content, font: font, runs: [run]}
    }

    assert {:ok, result} = Fonts.resolve([node], system_font_fallback: false)
    assert [%{content: "SSeta Test", start: 0, length: 9}] = result.spans[{1, 1}]
  end

  test "rejects unreadable fallback font paths" do
    assert {:error, {:fallback_font_load_failed, "/missing/font.ttf", :enoent}} =
             Fonts.resolve([], fallback_font_paths: ["/missing/font.ttf"])
  end

  defp text_node(family, content) do
    font = %Font{family: family}
    run = %Run{index: 0, start: 0, length: utf16_length(content), content: content, font: font}

    %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :text,
      text: %Text{content: content, font: font, runs: [run]}
    }
  end

  defp utf16_length(content) do
    content
    |> :unicode.characters_to_binary(:utf8, {:utf16, :little})
    |> byte_size()
    |> div(2)
  end
end
