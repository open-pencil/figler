defmodule Figler.Scene.Graph.Occurrence.Fields do
  @moduledoc """
  Raw `NodeChange` fields an instance owner may claim through `symbolOverrides`.

  This is the single registry for override fields, mirroring OpenPencil's
  `instance-overrides/fields.ts`. Each entry records its `kind`, whether uniform
  instance scale multiplies it (`length: true`), and for `:node` claims the
  value Figma reads when a record omits the field (`absent`).
  """

  @cleared_style %{guid: %{session_id: 0xFFFFFFFF, local_id: 0xFFFFFFFF}}

  @fields [
    name: [kind: :scalar],
    opacity: [kind: :scalar],
    font_size: [kind: :scalar, length: true],
    visible: [kind: :visible],
    variable_mode_by_set_map: [kind: :node, absent: %{entries: []}],
    text_data: [kind: :text],
    style_id_for_text: [kind: :text_style],
    fill_paints: [kind: :paint],
    stroke_paints: [kind: :paint],
    size: [kind: :size, length: true],
    stack_spacing: [kind: :layout_distance, length: true],
    stack_counter_spacing: [kind: :layout_distance, length: true],
    stack_horizontal_padding: [kind: :layout_distance, length: true],
    stack_vertical_padding: [kind: :layout_distance, length: true],
    stack_padding_right: [kind: :layout_distance, length: true],
    stack_padding_bottom: [kind: :layout_distance, length: true],
    text_auto_resize: [kind: :layout_mode],
    stack_child_primary_grow: [kind: :layout_mode],
    stack_primary_sizing: [kind: :layout_mode],
    stack_counter_sizing: [kind: :layout_mode],
    stack_child_align_self: [kind: :layout_mode],
    corner_radius: [kind: :node, length: true, absent: 0],
    rectangle_top_left_corner_radius: [kind: :node, length: true, absent: 0],
    rectangle_top_right_corner_radius: [kind: :node, length: true, absent: 0],
    rectangle_bottom_right_corner_radius: [kind: :node, length: true, absent: 0],
    rectangle_bottom_left_corner_radius: [kind: :node, length: true, absent: 0],
    rectangle_corner_radii_independent: [kind: :node, absent: false],
    corner_smoothing: [kind: :node, absent: 0],
    stroke_weight: [kind: :node, length: true],
    stroke_align: [kind: :node, absent: :center],
    border_top_weight: [kind: :node, length: true],
    border_right_weight: [kind: :node, length: true],
    border_bottom_weight: [kind: :node, length: true],
    border_left_weight: [kind: :node, length: true],
    border_stroke_weights_independent: [kind: :node, absent: false],
    stroke_cap: [kind: :node, absent: :none],
    stroke_join: [kind: :node, absent: :miter],
    miter_limit: [kind: :node],
    dash_pattern: [kind: :node, length: true, absent: []],
    blend_mode: [kind: :node, absent: :pass_through],
    effects: [kind: :node, absent: []],
    locked: [kind: :node, absent: false],
    layout_grids: [kind: :node, absent: []],
    style_id_for_fill: [kind: :node, absent: @cleared_style],
    style_id_for_stroke_fill: [kind: :node, absent: @cleared_style],
    style_id_for_effect: [kind: :node, absent: @cleared_style],
    stack_primary_align_items: [kind: :node],
    stack_counter_align_items: [kind: :node],
    stack_positioning: [kind: :node],
    font_name: [kind: :node],
    font_variations: [kind: :node, absent: []],
    line_height: [kind: :node, absent: %{value: 100, units: :percent}],
    letter_spacing: [kind: :node],
    paragraph_spacing: [kind: :node, length: true, absent: 0],
    text_case: [kind: :node, absent: :original],
    text_decoration: [kind: :node, absent: :none],
    text_align_horizontal: [kind: :node],
    text_align_vertical: [kind: :node],
    text_truncation: [kind: :node, absent: :disabled],
    max_lines: [kind: :node]
  ]

  @layout_distances for {field, opts} <- @fields, opts[:kind] == :layout_distance, do: field

  # A component's own identity, which an instance does not take from it.
  @component_identity [
    :component_key,
    :source_library_key,
    :publish_id,
    :published_version,
    :shared_symbol_version,
    :is_symbol_publishable,
    :variant_prop_specs,
    :component_prop_defs,
    :override_key
  ]

  # Fields whose change invalidates saved glyphs unless the claim supplies new ones.
  @text_shaping [
    :font_size,
    :font_name,
    :font_variations,
    :letter_spacing,
    :line_height,
    :text_case,
    :text_align_horizontal,
    :text_align_vertical,
    :text_auto_resize,
    :style_id_for_text,
    :font_variant_common_ligatures,
    :font_variant_contextual_ligatures
  ]

  @type kind ::
          :scalar
          | :visible
          | :text
          | :text_style
          | :paint
          | :size
          | :layout_distance
          | :layout_mode
          | :node

  @doc "Every claimable field with its options."
  @spec all() :: keyword(keyword())
  def all, do: @fields

  @doc "The registry entry for a raw field, or `nil` when instances cannot claim it."
  @spec fetch(atom()) :: keyword() | nil
  def fetch(field), do: Keyword.get(@fields, field)

  @doc "Stack padding and spacing fields, which uniform scale treats as lengths."
  @spec layout_distances() :: [atom()]
  def layout_distances, do: @layout_distances

  @doc "Component fields an instance does not inherit."
  @spec component_identity() :: [atom()]
  def component_identity, do: @component_identity

  @doc "Fields that change text shaping."
  @spec text_shaping() :: [atom()]
  def text_shaping, do: @text_shaping
end
