defmodule Figler.Render.Skia.FontsTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Font
  alias Figler.Render.Node
  alias Figler.Render.Skia.Fonts
  alias Figler.Render.Text

  test "reports unavailable requested families when no fallback covers the text" do
    node = text_node("__Figler Missing Font__", <<0x10FFFF::utf8>>)
    guid = node.guid

    assert {:ok, result} = Fonts.resolve([node], [])
    assert %{^guid => [warning]} = result.warnings
    assert warning.code == :font_unavailable
    assert warning.requested.family == "__Figler Missing Font__"
    refute Map.has_key?(result.fonts, guid)
  end

  test "uses Skia's installed character fallback and reports the substitution" do
    node = text_node("__Figler Missing Font__", "Hello")
    guid = node.guid

    assert {:ok, result} = Fonts.resolve([node], font_languages: ["en"])
    assert %{^guid => [warning]} = result.warnings
    assert warning.code == :font_substituted
    assert warning.resolved.source == :system
    assert %{^guid => resolved} = result.fonts
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

    assert %{^guid => %{source: :supplied}} = result.fonts
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

  test "rejects unreadable fallback font paths" do
    assert {:error, {:fallback_font_load_failed, "/missing/font.ttf", :enoent}} =
             Fonts.resolve([], fallback_font_paths: ["/missing/font.ttf"])
  end

  defp text_node(family, content) do
    %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :text,
      text: %Text{content: content, font: %Font{family: family}}
    }
  end
end
