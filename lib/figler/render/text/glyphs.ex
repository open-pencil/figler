defmodule Figler.Render.Text.Glyphs do
  @moduledoc """
  Text drawn from the glyphs Figma saved with it, as OpenPencil draws it: the outlines Figma laid
  out, placed where Figma placed them, rather than a fresh layout from the fonts at hand.
  """

  alias Figler.Render.Affine
  alias Figler.Render.Text
  alias Figler.Render.Text.Glyph
  alias Figler.Render.Text.Run

  @gradient_types [:gradient_linear, :gradient_radial, :gradient_angular, :gradient_diamond]

  @type decoration :: %{
          rect: {float(), float(), float(), float()},
          style: atom() | nil,
          fill_paints: [Figler.Render.Paint.t()]
        }

  @doc """
  Reads the saved glyphs and decoration rects of `derivedTextData`. Glyphs OpenPencil saved without
  laying them out, or saved without an outline, are not drawn: they would misplace or drop text.
  """
  @spec from_derived(map() | nil, String.t()) :: {[Glyph.t()], [map()]}
  def from_derived(nil, _content), do: {[], []}

  def from_derived(derived, content) when is_map(derived) do
    saved = Map.get(derived, :glyphs) || []

    if unshaped_open_pencil_text?(derived, saved, content) do
      {[], []}
    else
      {saved |> truncate(Map.get(derived, :truncation_start_index)) |> glyphs(),
       Enum.map(Map.get(derived, :decorations) || [], &saved_decoration/1)}
    end
  end

  # OpenPencil wrote text it had no glyphs for as one unwrapped line, with a character offset map
  # one entry longer than the text; Figma's has one entry per character.
  defp unshaped_open_pencil_text?(derived, saved, content) do
    offsets = Map.get(derived, :logical_index_to_character_offset_map) || []

    with true <- length(offsets) == utf16_length(content) + 1,
         [baseline] <- Map.get(derived, :baselines) || [] do
      baseline_y = baseline.position.y
      Enum.all?(saved, &((Map.get(&1, :rotation) || 0.0) == 0.0 and &1.position.y == baseline_y))
    else
      _shaped -> false
    end
  end

  # Truncated text is laid out whole, with an ellipsis where it is cut; Figma hides the glyphs
  # from `truncationStartIndex` on.
  defp truncate(saved, index) when is_integer(index) and index >= 0, do: Enum.take(saved, index)
  defp truncate(saved, _index), do: saved

  defp glyphs(saved) do
    Enum.reduce_while(saved, [], fn glyph, glyphs ->
      case Map.get(glyph, :commands_blob) do
        nil -> {:halt, []}
        blob -> {:cont, [glyph(glyph, blob) | glyphs]}
      end
    end)
    |> Enum.reverse()
  end

  defp glyph(saved, blob) do
    font_size = Map.get(saved, :font_size) || 0.0

    %Glyph{
      commands_blob: blob,
      x: saved.position.x,
      y: saved.position.y,
      font_size: font_size,
      first_character: Map.get(saved, :first_character),
      # Kiwi stores the advance in ems.
      advance: if(advance = Map.get(saved, :advance), do: advance * font_size),
      rotation: Map.get(saved, :rotation) || 0.0,
      emoji: emoji_text(Map.get(saved, :emoji_code_points))
    }
  end

  defp emoji_text([_ | _] = code_points), do: List.to_string(code_points)
  defp emoji_text(_code_points), do: nil

  defp saved_decoration(decoration) do
    %{
      style_id: Map.get(decoration, :style_id) || 0,
      rects: Enum.map(Map.get(decoration, :rects) || [], &{&1.x, &1.y, &1.w, &1.h})
    }
  end

  @doc """
  Whether the text is drawn from its saved glyphs with `fill_paints`: every visible fill paints
  outlines, its style runs' fills are plain colours it can give each glyph, and the decorations it
  has were saved too.
  """
  @spec drawable?(Text.t(), [Figler.Render.Paint.t()]) :: boolean()
  def drawable?(%Text{glyphs: []}, _fill_paints), do: false

  def drawable?(%Text{} = text, fill_paints) do
    visible = Enum.filter(fill_paints, &(&1.visible != false))

    Enum.all?(visible, &(&1.type == :solid or &1.type in @gradient_types)) and
      runs_drawable?(text, visible) and decorations_saved?(text)
  end

  defp runs_drawable?(text, visible_fills) do
    not Enum.any?(text.runs, & &1.fill_override?) or
      (match?([_], visible_fills) and Enum.all?(text.glyphs, & &1.first_character) and
         Enum.all?(text.runs, &plain_run_fills?/1))
  end

  defp plain_run_fills?(%Run{fill_override?: false}), do: true

  defp plain_run_fills?(%Run{fill_paints: paints}),
    do: Enum.all?(paints, &(&1.type == :solid and &1.blend_mode in [nil, :normal]))

  defp decorations_saved?(%Text{decorations: [_ | _]}), do: true
  defp decorations_saved?(%Text{runs: runs}), do: not Enum.any?(runs, &decorated?/1)

  defp decorated?(%Run{text_decoration: decoration}), do: decoration not in [nil, :none]

  @doc """
  Groups the glyphs to draw by the style run whose fills paint them, or `nil` for the layer's
  fill, each with the matrix placing its em-unit outline in the layer. Emoji outlines are
  placeholder squares and are left out.
  """
  @spec placements(Text.t()) :: [{Run.t() | nil, [{Glyph.t(), Affine.matrix()}]}]
  def placements(%Text{glyphs: glyphs, runs: runs}) do
    # Baselines snap to whole pixels only when straight; path text stair-steps otherwise.
    snap? = Enum.all?(glyphs, &(&1.rotation == 0.0))

    glyphs
    |> Enum.reject(& &1.emoji)
    |> Enum.chunk_by(&fill_run(runs, &1))
    |> Enum.map(fn [first | _] = chunk ->
      {fill_run(runs, first), Enum.map(chunk, &{&1, matrix(&1, snap?)})}
    end)
  end

  defp fill_run(_runs, %Glyph{first_character: nil}), do: nil

  defp fill_run(runs, %Glyph{first_character: character}) do
    Enum.find(
      runs,
      &(&1.fill_override? and character >= &1.start and character < &1.start + &1.length)
    )
  end

  # Pen position, then the rotation (negated for the y-down canvas), then font units to pixels
  # with the font's y-up axis flipped.
  defp matrix(glyph, snap?) do
    y = if snap?, do: round(glyph.y) * 1.0, else: glyph.y
    angle = 0.0 - glyph.rotation
    cos = :math.cos(angle) * glyph.font_size
    sin = :math.sin(angle) * glyph.font_size
    {cos, sin, glyph.x, sin, -cos, y}
  end

  @doc """
  The emoji among the glyphs, each at its pen position and size. Their saved outlines are
  placeholder squares, 1 em wide.
  """
  @spec emoji(Text.t()) :: [%{emoji: String.t(), x: float(), baseline: float(), size: float()}]
  def emoji(%Text{glyphs: glyphs}) do
    for %Glyph{emoji: emoji} = glyph when is_binary(emoji) <- glyphs,
        do: %{emoji: emoji, x: glyph.x, baseline: glyph.y, size: glyph.font_size}
  end

  @doc "The saved decoration rects, each with its style run's decoration style and paints."
  @spec decorations(Text.t()) :: [decoration()]
  def decorations(%Text{decorations: decorations, runs: runs}) do
    Enum.flat_map(decorations, fn %{style_id: style_id, rects: rects} ->
      run = Enum.find(runs, &(&1.style_id == style_id)) || List.first(runs)
      paints = decoration_paints(run)
      Enum.map(rects, &%{rect: &1, style: run && run.text_decoration_style, fill_paints: paints})
    end)
  end

  # No paints of its own: the decoration takes the fill the glyphs are drawn in.
  defp decoration_paints(%Run{text_decoration_fill_paints: [_ | _] = paints}), do: paints
  defp decoration_paints(%Run{fill_override?: true, fill_paints: paints}), do: paints
  defp decoration_paints(_run), do: []

  defp utf16_length(content),
    do: content |> String.to_charlist() |> Enum.sum_by(&if(&1 > 0xFFFF, do: 2, else: 1))
end
