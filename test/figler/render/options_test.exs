defmodule Figler.Render.OptionsTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Options

  test "accepts the documented option contract" do
    assert :ok =
             Options.validate(
               root: "1:2",
               graph: [root: "1:2"],
               scale: 2,
               background: :transparent,
               format: :png,
               quality: 90,
               strict: true,
               fallback_font_paths: ["Inter.ttf"],
               fallback_typefaces: [:typeface],
               font_languages: ["en"],
               system_font_fallback: false
             )
  end

  test "returns stable errors for unknown and malformed options" do
    assert {:error, {:invalid_render_options, errors}} =
             Options.validate(
               root: -1,
               scale: 0,
               format: :svg,
               strict: :yes,
               background: "not-a-color",
               unknown: true
             )

    assert Enum.map(errors, &{&1.option, &1.code}) == [
             root: :invalid_selection,
             scale: :invalid_scale,
             format: :invalid_format,
             strict: :invalid_boolean,
             background: :invalid_background,
             unknown: :unknown_option
           ]

    assert {:error,
            {:invalid_render_options,
             [%{option: :options, code: :invalid_keyword_list, value: [:not_an_option]}]}} =
             Options.validate([:not_an_option])
  end

  test "rejects conflicting root and page selection" do
    assert {:error,
            {:invalid_render_options, [%{option: :selection, code: :conflicting_root_and_page}]}} =
             Options.validate(root: "1:2", page: 0)
  end
end
