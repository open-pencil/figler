defmodule FigKiwi.Schema.NodeChange do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:guid_tag, 53, type: :uint, source_name: "guidTag")
  field(:phase, 2, type: {:enum, FigKiwi.Schema.NodePhase}, source_name: "phase")
  field(:phase_tag, 54, type: :uint, source_name: "phaseTag")
  field(:parent_index, 3, type: FigKiwi.Schema.ParentIndex, source_name: "parentIndex")
  field(:parent_index_tag, 55, type: :uint, source_name: "parentIndexTag")
  field(:type, 4, type: {:enum, FigKiwi.Schema.NodeType}, source_name: "type")
  field(:type_tag, 56, type: :uint, source_name: "typeTag")
  field(:name, 5, type: :string, source_name: "name")
  field(:name_tag, 57, type: :uint, source_name: "nameTag")
  field(:is_publishable, 174, type: :bool, source_name: "isPublishable")
  field(:description, 318, type: :string, source_name: "description")

  field(:library_move_info, 256,
    type: FigKiwi.Schema.LibraryMoveInfo,
    source_name: "libraryMoveInfo"
  )

  field(:library_move_history, 281,
    repeated: true,
    type: FigKiwi.Schema.LibraryMoveHistoryItem,
    source_name: "libraryMoveHistory"
  )

  field(:key, 319, type: :string, source_name: "key")
  field(:file_asset_ids, 383, type: FigKiwi.Schema.AssetIdMap, source_name: "fileAssetIds")
  field(:style_id, 49, type: :uint, source_name: "styleID")
  field(:style_id_tag, 101, type: :uint, source_name: "styleIDTag")
  field(:is_fill_style, 157, type: :bool, source_name: "isFillStyle")
  field(:is_stroke_style, 161, type: :bool, source_name: "isStrokeStyle")
  field(:is_override_over_text_style, 376, type: :bool, source_name: "isOverrideOverTextStyle")
  field(:style_type, 163, type: {:enum, FigKiwi.Schema.StyleType}, source_name: "styleType")
  field(:style_description, 191, type: :string, source_name: "styleDescription")
  field(:version, 171, type: :string, source_name: "version")
  field(:user_facing_version, 399, type: :string, source_name: "userFacingVersion")
  field(:sort_position, 320, type: :string, source_name: "sortPosition")

  field(:ojans_super_secret_node_field, 345,
    type: FigKiwi.Schema.SharedStyleMasterData,
    source_name: "ojansSuperSecretNodeField"
  )

  field(:sev_moonlit_lily_data, 348,
    type: FigKiwi.Schema.SharedStyleMasterData,
    source_name: "sevMoonlitLilyData"
  )

  field(:is_soft_deleted_style, 176, type: :bool, source_name: "isSoftDeletedStyle")
  field(:is_non_updateable, 177, type: :bool, source_name: "isNonUpdateable")

  field(:shared_style_master_data, 172,
    type: FigKiwi.Schema.SharedStyleMasterData,
    source_name: "sharedStyleMasterData"
  )

  field(:shared_style_reference, 173,
    type: FigKiwi.Schema.SharedStyleReference,
    source_name: "sharedStyleReference"
  )

  field(:inherit_fill_style_id, 158, type: FigKiwi.Schema.GUID, source_name: "inheritFillStyleID")

  field(:inherit_stroke_style_id, 162,
    type: FigKiwi.Schema.GUID,
    source_name: "inheritStrokeStyleID"
  )

  field(:inherit_text_style_id, 167, type: FigKiwi.Schema.GUID, source_name: "inheritTextStyleID")

  field(:inherit_export_style_id, 168,
    type: FigKiwi.Schema.GUID,
    source_name: "inheritExportStyleID"
  )

  field(:inherit_effect_style_id, 169,
    type: FigKiwi.Schema.GUID,
    source_name: "inheritEffectStyleID"
  )

  field(:inherit_grid_style_id, 170, type: FigKiwi.Schema.GUID, source_name: "inheritGridStyleID")

  field(:inherit_fill_style_id_for_stroke, 185,
    type: FigKiwi.Schema.GUID,
    source_name: "inheritFillStyleIDForStroke"
  )

  field(:style_id_for_fill, 332, type: FigKiwi.Schema.StyleId, source_name: "styleIdForFill")

  field(:style_id_for_stroke_fill, 333,
    type: FigKiwi.Schema.StyleId,
    source_name: "styleIdForStrokeFill"
  )

  field(:style_id_for_text, 334, type: FigKiwi.Schema.StyleId, source_name: "styleIdForText")
  field(:style_id_for_effect, 335, type: FigKiwi.Schema.StyleId, source_name: "styleIdForEffect")
  field(:style_id_for_grid, 336, type: FigKiwi.Schema.StyleId, source_name: "styleIdForGrid")

  field(:style_animations, 580,
    repeated: true,
    type: FigKiwi.Schema.StyleAnimation,
    source_name: "styleAnimations"
  )

  field(:background_paints, 193,
    repeated: true,
    type: FigKiwi.Schema.Paint,
    source_name: "backgroundPaints"
  )

  field(:inherit_fill_style_id_for_background, 194,
    type: FigKiwi.Schema.GUID,
    source_name: "inheritFillStyleIDForBackground"
  )

  field(:is_state_group, 225, type: :bool, source_name: "isStateGroup")

  field(:state_group_property_value_orders, 238,
    repeated: true,
    type: FigKiwi.Schema.StateGroupPropertyValueOrder,
    source_name: "stateGroupPropertyValueOrders"
  )

  field(:partial_paste_annotation, 581,
    type: FigKiwi.Schema.PartialPasteAnnotation,
    source_name: "partialPasteAnnotation"
  )

  field(:shared_symbol_reference, 122,
    type: FigKiwi.Schema.SharedSymbolReference,
    source_name: "sharedSymbolReference"
  )

  field(:is_symbol_publishable, 123, type: :bool, source_name: "isSymbolPublishable")

  field(:shared_symbol_mappings, 124,
    repeated: true,
    type: FigKiwi.Schema.GUIDPathMapping,
    source_name: "sharedSymbolMappings"
  )

  field(:shared_symbol_version, 126, type: :string, source_name: "sharedSymbolVersion")

  field(:shared_component_master_data, 152,
    type: FigKiwi.Schema.SharedComponentMasterData,
    source_name: "sharedComponentMasterData"
  )

  field(:symbol_description, 144, type: :string, source_name: "symbolDescription")

  field(:unflattening_mappings, 164,
    repeated: true,
    type: FigKiwi.Schema.GUIDPathMapping,
    source_name: "unflatteningMappings"
  )

  field(:force_unflattening_mappings, 228,
    repeated: true,
    type: FigKiwi.Schema.GUIDPathMapping,
    source_name: "forceUnflatteningMappings"
  )

  field(:publish_file, 214, type: :string, source_name: "publishFile")
  field(:source_library_key, 395, type: :string, source_name: "sourceLibraryKey")
  field(:publish_id, 215, type: FigKiwi.Schema.GUID, source_name: "publishID")
  field(:component_key, 216, type: :string, source_name: "componentKey")
  field(:is_c2, 217, type: :bool, source_name: "isC2")
  field(:published_version, 218, type: :string, source_name: "publishedVersion")
  field(:origin_component_key, 252, type: :string, source_name: "originComponentKey")

  field(:component_prop_defs, 266,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropDef,
    source_name: "componentPropDefs"
  )

  field(:component_prop_refs, 267,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropRef,
    source_name: "componentPropRefs"
  )

  field(:variant_prop_specs, 483,
    repeated: true,
    type: FigKiwi.Schema.VariantPropSpec,
    source_name: "variantPropSpecs"
  )

  field(:symbol_data, 113, type: FigKiwi.Schema.SymbolData, source_name: "symbolData")
  field(:symbol_data_tag, 114, type: :uint, source_name: "symbolDataTag")

  field(:derived_symbol_data, 125,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "derivedSymbolData"
  )

  field(:nested_instance_resize_enabled, 394,
    type: :bool,
    source_name: "nestedInstanceResizeEnabled"
  )

  field(:overridden_symbol_id, 143, type: FigKiwi.Schema.GUID, source_name: "overriddenSymbolID")

  field(:component_prop_assignments, 268,
    repeated: true,
    type: FigKiwi.Schema.ComponentPropAssignment,
    source_name: "componentPropAssignments"
  )

  field(:props_are_bubbled, 305, type: :bool, source_name: "propsAreBubbled")

  field(:override_stash, 248,
    repeated: true,
    type: FigKiwi.Schema.InstanceOverrideStash,
    source_name: "overrideStash"
  )

  field(:override_stash_v2, 250,
    repeated: true,
    type: FigKiwi.Schema.InstanceOverrideStashV2,
    source_name: "overrideStashV2"
  )

  field(:guid_path, 111, type: FigKiwi.Schema.GUIDPath, source_name: "guidPath")
  field(:guid_path_tag, 112, type: :uint, source_name: "guidPathTag")
  field(:override_level, 321, type: :int, source_name: "overrideLevel")
  field(:module_type, 382, type: {:enum, FigKiwi.Schema.ModuleType}, source_name: "moduleType")
  field(:is_slot, 463, type: :bool, source_name: "isSlot")
  field(:is_slot_content, 495, type: :bool, source_name: "isSlotContent")
  field(:font_size, 21, type: :float, source_name: "fontSize")
  field(:font_size_tag, 73, type: :uint, source_name: "fontSizeTag")
  field(:paragraph_indent, 22, type: :float, source_name: "paragraphIndent")
  field(:paragraph_indent_tag, 74, type: :uint, source_name: "paragraphIndentTag")
  field(:paragraph_spacing, 23, type: :float, source_name: "paragraphSpacing")
  field(:paragraph_spacing_tag, 75, type: :uint, source_name: "paragraphSpacingTag")

  field(:text_align_horizontal, 32,
    type: {:enum, FigKiwi.Schema.TextAlignHorizontal},
    source_name: "textAlignHorizontal"
  )

  field(:text_align_horizontal_tag, 84, type: :uint, source_name: "textAlignHorizontalTag")

  field(:text_align_vertical, 33,
    type: {:enum, FigKiwi.Schema.TextAlignVertical},
    source_name: "textAlignVertical"
  )

  field(:text_align_vertical_tag, 85, type: :uint, source_name: "textAlignVerticalTag")
  field(:text_case, 34, type: {:enum, FigKiwi.Schema.TextCase}, source_name: "textCase")
  field(:text_case_tag, 86, type: :uint, source_name: "textCaseTag")

  field(:text_decoration, 35,
    type: {:enum, FigKiwi.Schema.TextDecoration},
    source_name: "textDecoration"
  )

  field(:text_decoration_tag, 87, type: :uint, source_name: "textDecorationTag")
  field(:line_height, 40, type: FigKiwi.Schema.Number, source_name: "lineHeight")
  field(:line_height_tag, 92, type: :uint, source_name: "lineHeightTag")
  field(:font_name, 41, type: FigKiwi.Schema.FontName, source_name: "fontName")
  field(:font_name_tag, 93, type: :uint, source_name: "fontNameTag")
  field(:text_data, 42, type: FigKiwi.Schema.TextData, source_name: "textData")
  field(:text_data_tag, 94, type: :uint, source_name: "textDataTag")

  field(:derived_text_data, 359,
    type: FigKiwi.Schema.DerivedTextData,
    source_name: "derivedTextData"
  )

  field(:font_variant_common_ligatures, 127,
    type: :bool,
    source_name: "fontVariantCommonLigatures"
  )

  field(:font_variant_contextual_ligatures, 128,
    type: :bool,
    source_name: "fontVariantContextualLigatures"
  )

  field(:font_variant_discretionary_ligatures, 129,
    type: :bool,
    source_name: "fontVariantDiscretionaryLigatures"
  )

  field(:font_variant_historical_ligatures, 130,
    type: :bool,
    source_name: "fontVariantHistoricalLigatures"
  )

  field(:font_variant_ordinal, 131, type: :bool, source_name: "fontVariantOrdinal")
  field(:font_variant_slashed_zero, 132, type: :bool, source_name: "fontVariantSlashedZero")

  field(:font_variant_numeric_figure, 133,
    type: {:enum, FigKiwi.Schema.FontVariantNumericFigure},
    source_name: "fontVariantNumericFigure"
  )

  field(:font_variant_numeric_spacing, 134,
    type: {:enum, FigKiwi.Schema.FontVariantNumericSpacing},
    source_name: "fontVariantNumericSpacing"
  )

  field(:font_variant_numeric_fraction, 135,
    type: {:enum, FigKiwi.Schema.FontVariantNumericFraction},
    source_name: "fontVariantNumericFraction"
  )

  field(:font_variant_caps, 136,
    type: {:enum, FigKiwi.Schema.FontVariantCaps},
    source_name: "fontVariantCaps"
  )

  field(:font_variant_position, 137,
    type: {:enum, FigKiwi.Schema.FontVariantPosition},
    source_name: "fontVariantPosition"
  )

  field(:letter_spacing, 165, type: FigKiwi.Schema.Number, source_name: "letterSpacing")
  field(:font_version, 202, type: :string, source_name: "fontVersion")
  field(:leading_trim, 322, type: {:enum, FigKiwi.Schema.LeadingTrim}, source_name: "leadingTrim")
  field(:hanging_punctuation, 337, type: :bool, source_name: "hangingPunctuation")
  field(:hanging_list, 339, type: :bool, source_name: "hangingList")
  field(:fallback_glyphs, 550, type: :bool, source_name: "fallbackGlyphs")
  field(:max_lines, 351, type: :int, source_name: "maxLines")

  field(:responsive_text_style_variants, 417,
    repeated: true,
    type: FigKiwi.Schema.ResponsiveTextStyleVariant,
    source_name: "responsiveTextStyleVariants"
  )

  field(:section_status, 352,
    type: {:enum, FigKiwi.Schema.SectionStatus},
    source_name: "sectionStatus"
  )

  field(:section_status_info, 355,
    type: FigKiwi.Schema.SectionStatusInfo,
    source_name: "sectionStatusInfo"
  )

  field(:text_user_layout_version, 203, type: :uint, source_name: "textUserLayoutVersion")
  field(:text_explicit_layout_version, 396, type: :uint, source_name: "textExplicitLayoutVersion")

  field(:toggled_on_ot_features, 205,
    repeated: true,
    type: {:enum, FigKiwi.Schema.OpenTypeFeature},
    source_name: "toggledOnOTFeatures"
  )

  field(:toggled_off_ot_features, 206,
    repeated: true,
    type: {:enum, FigKiwi.Schema.OpenTypeFeature},
    source_name: "toggledOffOTFeatures"
  )

  field(:hyperlink, 223, type: FigKiwi.Schema.Hyperlink, source_name: "hyperlink")
  field(:mention, 340, type: FigKiwi.Schema.Mention, source_name: "mention")

  field(:font_variations, 260,
    repeated: true,
    type: FigKiwi.Schema.FontVariation,
    source_name: "fontVariations"
  )

  field(:text_bidi_version, 279, type: :uint, source_name: "textBidiVersion")

  field(:text_truncation, 280,
    type: {:enum, FigKiwi.Schema.TextTruncation},
    source_name: "textTruncation"
  )

  field(:has_had_rtl_text, 292, type: :bool, source_name: "hasHadRTLText")

  field(:emoji_image_set, 391,
    type: {:enum, FigKiwi.Schema.EmojiImageSet},
    source_name: "emojiImageSet"
  )

  field(:slide_thumbnail_hash, 392, type: :string, source_name: "slideThumbnailHash")
  field(:visible, 6, type: :bool, source_name: "visible")
  field(:visible_tag, 58, type: :uint, source_name: "visibleTag")
  field(:locked, 7, type: :bool, source_name: "locked")
  field(:locked_tag, 59, type: :uint, source_name: "lockedTag")
  field(:lock_mode, 434, type: {:enum, FigKiwi.Schema.LockMode}, source_name: "lockMode")
  field(:opacity, 8, type: :float, source_name: "opacity")
  field(:opacity_tag, 60, type: :uint, source_name: "opacityTag")
  field(:blend_mode, 9, type: {:enum, FigKiwi.Schema.BlendMode}, source_name: "blendMode")
  field(:blend_mode_tag, 61, type: :uint, source_name: "blendModeTag")
  field(:size, 11, type: FigKiwi.Schema.Vector, source_name: "size")
  field(:size_tag, 63, type: :uint, source_name: "sizeTag")
  field(:transform, 12, type: FigKiwi.Schema.Matrix, source_name: "transform")
  field(:transform_tag, 64, type: :uint, source_name: "transformTag")
  field(:dash_pattern, 13, repeated: true, type: :float, source_name: "dashPattern")
  field(:dash_pattern_tag, 65, type: :uint, source_name: "dashPatternTag")
  field(:mask, 16, type: :bool, source_name: "mask")
  field(:mask_tag, 68, type: :uint, source_name: "maskTag")
  field(:rotation_origin, 424, type: FigKiwi.Schema.Vector, source_name: "rotationOrigin")
  field(:mask_is_outline, 18, type: :bool, source_name: "maskIsOutline")
  field(:mask_is_outline_tag, 70, type: :uint, source_name: "maskIsOutlineTag")
  field(:mask_type, 317, type: {:enum, FigKiwi.Schema.MaskType}, source_name: "maskType")
  field(:background_opacity, 19, type: :float, source_name: "backgroundOpacity")
  field(:background_opacity_tag, 71, type: :uint, source_name: "backgroundOpacityTag")
  field(:corner_radius, 20, type: :float, source_name: "cornerRadius")
  field(:corner_radius_tag, 72, type: :uint, source_name: "cornerRadiusTag")
  field(:stroke_weight, 26, type: :float, source_name: "strokeWeight")
  field(:stroke_weight_tag, 78, type: :uint, source_name: "strokeWeightTag")
  field(:stroke_align, 29, type: {:enum, FigKiwi.Schema.StrokeAlign}, source_name: "strokeAlign")
  field(:stroke_align_tag, 81, type: :uint, source_name: "strokeAlignTag")
  field(:stroke_cap, 30, type: {:enum, FigKiwi.Schema.StrokeCap}, source_name: "strokeCap")
  field(:stroke_cap_tag, 82, type: :uint, source_name: "strokeCapTag")
  field(:stroke_cap_size, 497, type: FigKiwi.Schema.Number, source_name: "strokeCapSize")
  field(:stroke_join, 31, type: {:enum, FigKiwi.Schema.StrokeJoin}, source_name: "strokeJoin")
  field(:stroke_join_tag, 83, type: :uint, source_name: "strokeJoinTag")
  field(:fill_paints, 38, repeated: true, type: FigKiwi.Schema.Paint, source_name: "fillPaints")
  field(:fill_paints_tag, 90, type: :uint, source_name: "fillPaintsTag")

  field(:stroke_paints, 39,
    repeated: true,
    type: FigKiwi.Schema.Paint,
    source_name: "strokePaints"
  )

  field(:stroke_paints_tag, 91, type: :uint, source_name: "strokePaintsTag")
  field(:effects, 43, repeated: true, type: FigKiwi.Schema.Effect, source_name: "effects")
  field(:effects_tag, 95, type: :uint, source_name: "effectsTag")
  field(:background_color, 50, type: FigKiwi.Schema.Color, source_name: "backgroundColor")
  field(:background_color_tag, 102, type: :uint, source_name: "backgroundColorTag")

  field(:fill_geometry, 51,
    repeated: true,
    type: FigKiwi.Schema.Path,
    source_name: "fillGeometry"
  )

  field(:fill_geometry_tag, 103, type: :uint, source_name: "fillGeometryTag")

  field(:stroke_geometry, 52,
    repeated: true,
    type: FigKiwi.Schema.Path,
    source_name: "strokeGeometry"
  )

  field(:stroke_geometry_tag, 104, type: :uint, source_name: "strokeGeometryTag")

  field(:offset_fill_mask_geometry, 564,
    repeated: true,
    type: FigKiwi.Schema.Path,
    source_name: "offsetFillMaskGeometry"
  )

  field(:text_decoration_fill_paints, 411,
    repeated: true,
    type: FigKiwi.Schema.Paint,
    source_name: "textDecorationFillPaints"
  )

  field(:text_decoration_skip_ink, 412, type: :bool, source_name: "textDecorationSkipInk")

  field(:text_underline_offset, 413,
    type: FigKiwi.Schema.Number,
    source_name: "textUnderlineOffset"
  )

  field(:text_decoration_thickness, 415,
    type: FigKiwi.Schema.Number,
    source_name: "textDecorationThickness"
  )

  field(:text_decoration_style, 416,
    type: {:enum, FigKiwi.Schema.TextDecorationStyle},
    source_name: "textDecorationStyle"
  )

  field(:transform_modifiers, 455,
    repeated: true,
    type: FigKiwi.Schema.TransformModifier,
    source_name: "transformModifiers"
  )

  field(:transform3d, 570, type: FigKiwi.Schema.Transform3d, source_name: "transform3d")
  field(:stroke_data, 571, type: FigKiwi.Schema.StrokeData, source_name: "strokeData")
  field(:scene3d, 572, type: FigKiwi.Schema.Scene3d, source_name: "scene3d")

  field(:transform_origin, 587,
    type: FigKiwi.Schema.TransformOrigin,
    source_name: "transformOrigin"
  )

  field(:rectangle_top_left_corner_radius, 145,
    type: :float,
    source_name: "rectangleTopLeftCornerRadius"
  )

  field(:rectangle_top_right_corner_radius, 146,
    type: :float,
    source_name: "rectangleTopRightCornerRadius"
  )

  field(:rectangle_bottom_left_corner_radius, 147,
    type: :float,
    source_name: "rectangleBottomLeftCornerRadius"
  )

  field(:rectangle_bottom_right_corner_radius, 148,
    type: :float,
    source_name: "rectangleBottomRightCornerRadius"
  )

  field(:rectangle_corner_radii_independent, 149,
    type: :bool,
    source_name: "rectangleCornerRadiiIndependent"
  )

  field(:rectangle_corner_tool_independent, 150,
    type: :bool,
    source_name: "rectangleCornerToolIndependent"
  )

  field(:proportions_constrained, 151, type: :bool, source_name: "proportionsConstrained")

  field(:target_aspect_ratio, 423,
    type: FigKiwi.Schema.OptionalVector,
    source_name: "targetAspectRatio"
  )

  field(:use_absolute_bounds, 258, type: :bool, source_name: "useAbsoluteBounds")
  field(:border_top_hidden, 287, type: :bool, source_name: "borderTopHidden")
  field(:border_bottom_hidden, 288, type: :bool, source_name: "borderBottomHidden")
  field(:border_left_hidden, 289, type: :bool, source_name: "borderLeftHidden")
  field(:border_right_hidden, 290, type: :bool, source_name: "borderRightHidden")
  field(:borders_take_space, 294, type: :bool, source_name: "bordersTakeSpace")
  field(:border_top_weight, 295, type: :float, source_name: "borderTopWeight")
  field(:border_bottom_weight, 296, type: :float, source_name: "borderBottomWeight")
  field(:border_left_weight, 297, type: :float, source_name: "borderLeftWeight")
  field(:border_right_weight, 298, type: :float, source_name: "borderRightWeight")

  field(:border_stroke_weights_independent, 299,
    type: :bool,
    source_name: "borderStrokeWeightsIndependent"
  )

  field(:horizontal_constraint, 28,
    type: {:enum, FigKiwi.Schema.ConstraintType},
    source_name: "horizontalConstraint"
  )

  field(:horizontal_constraint_tag, 80, type: :uint, source_name: "horizontalConstraintTag")
  field(:stack_mode, 105, type: {:enum, FigKiwi.Schema.StackMode}, source_name: "stackMode")
  field(:stack_mode_tag, 106, type: :uint, source_name: "stackModeTag")
  field(:stack_spacing, 107, type: :float, source_name: "stackSpacing")
  field(:stack_spacing_tag, 108, type: :uint, source_name: "stackSpacingTag")
  field(:stack_padding, 109, type: :float, source_name: "stackPadding")
  field(:stack_padding_tag, 110, type: :uint, source_name: "stackPaddingTag")

  field(:stack_counter_align, 120,
    type: {:enum, FigKiwi.Schema.StackCounterAlign},
    source_name: "stackCounterAlign"
  )

  field(:stack_justify, 121,
    type: {:enum, FigKiwi.Schema.StackJustify},
    source_name: "stackJustify"
  )

  field(:stack_align, 208, type: {:enum, FigKiwi.Schema.StackAlign}, source_name: "stackAlign")
  field(:stack_horizontal_padding, 209, type: :float, source_name: "stackHorizontalPadding")
  field(:stack_vertical_padding, 210, type: :float, source_name: "stackVerticalPadding")
  field(:stack_width, 211, type: {:enum, FigKiwi.Schema.StackSize}, source_name: "stackWidth")
  field(:stack_height, 212, type: {:enum, FigKiwi.Schema.StackSize}, source_name: "stackHeight")

  field(:stack_primary_sizing, 229,
    type: {:enum, FigKiwi.Schema.StackSize},
    source_name: "stackPrimarySizing"
  )

  field(:stack_primary_align_items, 230,
    type: {:enum, FigKiwi.Schema.StackJustify},
    source_name: "stackPrimaryAlignItems"
  )

  field(:stack_counter_align_items, 231,
    type: {:enum, FigKiwi.Schema.StackAlign},
    source_name: "stackCounterAlignItems"
  )

  field(:stack_child_primary_grow, 232, type: :float, source_name: "stackChildPrimaryGrow")
  field(:stack_padding_right, 233, type: :float, source_name: "stackPaddingRight")
  field(:stack_padding_bottom, 234, type: :float, source_name: "stackPaddingBottom")

  field(:stack_child_align_self, 236,
    type: {:enum, FigKiwi.Schema.StackCounterAlign},
    source_name: "stackChildAlignSelf"
  )

  field(:stack_positioning, 269,
    type: {:enum, FigKiwi.Schema.StackPositioning},
    source_name: "stackPositioning"
  )

  field(:stack_reverse_z_index, 271, type: :bool, source_name: "stackReverseZIndex")
  field(:stack_wrap, 323, type: {:enum, FigKiwi.Schema.StackWrap}, source_name: "stackWrap")
  field(:stack_counter_spacing, 324, type: :float, source_name: "stackCounterSpacing")
  field(:min_size, 325, type: FigKiwi.Schema.OptionalVector, source_name: "minSize")
  field(:max_size, 326, type: FigKiwi.Schema.OptionalVector, source_name: "maxSize")

  field(:stack_counter_align_content, 343,
    type: {:enum, FigKiwi.Schema.StackCounterAlignContent},
    source_name: "stackCounterAlignContent"
  )

  field(:sorted_moving_child_indices, 406,
    repeated: true,
    type: :int,
    source_name: "sortedMovingChildIndices"
  )

  field(:stack_layout_version, 574, type: :uint, source_name: "stackLayoutVersion")
  field(:grid_rows, 435, type: FigKiwi.Schema.GUIDPositionMap, source_name: "gridRows")
  field(:grid_columns, 436, type: FigKiwi.Schema.GUIDPositionMap, source_name: "gridColumns")
  field(:grid_row_gap, 437, type: :float, source_name: "gridRowGap")
  field(:grid_column_gap, 438, type: :float, source_name: "gridColumnGap")
  field(:grid_row_anchor, 439, type: FigKiwi.Schema.GUID, source_name: "gridRowAnchor")
  field(:grid_column_anchor, 440, type: FigKiwi.Schema.GUID, source_name: "gridColumnAnchor")
  field(:grid_row_span, 441, type: :uint, source_name: "gridRowSpan")
  field(:grid_column_span, 442, type: :uint, source_name: "gridColumnSpan")

  field(:grid_columns_sizing, 474,
    type: FigKiwi.Schema.GUIDGridTrackSizeMap,
    source_name: "gridColumnsSizing"
  )

  field(:grid_rows_sizing, 475,
    type: FigKiwi.Schema.GUIDGridTrackSizeMap,
    source_name: "gridRowsSizing"
  )

  field(:grid_child_vertical_align, 476,
    type: {:enum, FigKiwi.Schema.GridChildAlign},
    source_name: "gridChildVerticalAlign"
  )

  field(:grid_child_horizontal_align, 477,
    type: {:enum, FigKiwi.Schema.GridChildAlign},
    source_name: "gridChildHorizontalAlign"
  )

  field(:grid_auto_tracks, 555,
    type: {:enum, FigKiwi.Schema.GridAutoTracks},
    source_name: "gridAutoTracks"
  )

  field(:grid_reflow_enabled, 556, type: :bool, source_name: "gridReflowEnabled")
  field(:is_snake_game_board, 344, type: :bool, source_name: "isSnakeGameBoard")
  field(:transition_node_id, 139, type: FigKiwi.Schema.GUID, source_name: "transitionNodeID")

  field(:prototype_start_node_id, 140,
    type: FigKiwi.Schema.GUID,
    source_name: "prototypeStartNodeID"
  )

  field(:prototype_background_color, 141,
    type: FigKiwi.Schema.Color,
    source_name: "prototypeBackgroundColor"
  )

  field(:transition_info, 153, type: FigKiwi.Schema.TransitionInfo, source_name: "transitionInfo")

  field(:transition_type, 154,
    type: {:enum, FigKiwi.Schema.TransitionType},
    source_name: "transitionType"
  )

  field(:transition_duration, 155, type: :float, source_name: "transitionDuration")
  field(:easing_type, 156, type: {:enum, FigKiwi.Schema.EasingType}, source_name: "easingType")
  field(:transition_preserve_scroll, 181, type: :bool, source_name: "transitionPreserveScroll")

  field(:connection_type, 182,
    type: {:enum, FigKiwi.Schema.ConnectionType},
    source_name: "connectionType"
  )

  field(:connection_url, 183, type: :string, source_name: "connectionURL")

  field(:prototype_device, 184,
    type: FigKiwi.Schema.PrototypeDevice,
    source_name: "prototypeDevice"
  )

  field(:interaction_type, 187,
    type: {:enum, FigKiwi.Schema.InteractionType},
    source_name: "interactionType"
  )

  field(:transition_timeout, 188, type: :float, source_name: "transitionTimeout")
  field(:interaction_maintained, 189, type: :bool, source_name: "interactionMaintained")
  field(:interaction_duration, 190, type: :float, source_name: "interactionDuration")
  field(:destination_is_overlay, 192, type: :bool, source_name: "destinationIsOverlay")

  field(:transition_should_smart_animate, 207,
    type: :bool,
    source_name: "transitionShouldSmartAnimate"
  )

  field(:prototype_interactions, 226,
    repeated: true,
    type: FigKiwi.Schema.PrototypeInteraction,
    source_name: "prototypeInteractions"
  )

  field(:object_animations, 426,
    repeated: true,
    type: FigKiwi.Schema.PrototypeInteraction,
    source_name: "objectAnimations"
  )

  field(:prototype_starting_point, 249,
    type: FigKiwi.Schema.PrototypeStartingPoint,
    source_name: "prototypeStartingPoint"
  )

  field(:plugin_data, 204,
    repeated: true,
    type: FigKiwi.Schema.PluginData,
    source_name: "pluginData"
  )

  field(:plugin_relaunch_data, 219,
    repeated: true,
    type: FigKiwi.Schema.PluginRelaunchData,
    source_name: "pluginRelaunchData"
  )

  field(:connector_start, 242,
    type: FigKiwi.Schema.ConnectorEndpoint,
    source_name: "connectorStart"
  )

  field(:connector_end, 243, type: FigKiwi.Schema.ConnectorEndpoint, source_name: "connectorEnd")

  field(:connector_line_style, 244,
    type: {:enum, FigKiwi.Schema.ConnectorLineStyle},
    source_name: "connectorLineStyle"
  )

  field(:connector_start_cap, 245,
    type: {:enum, FigKiwi.Schema.StrokeCap},
    source_name: "connectorStartCap"
  )

  field(:connector_end_cap, 246,
    type: {:enum, FigKiwi.Schema.StrokeCap},
    source_name: "connectorEndCap"
  )

  field(:connector_control_points, 253,
    repeated: true,
    type: FigKiwi.Schema.ConnectorControlPoint,
    source_name: "connectorControlPoints"
  )

  field(:connector_bezier_control_points, 479,
    repeated: true,
    type: FigKiwi.Schema.ConnectorControlPoint,
    source_name: "connectorBezierControlPoints"
  )

  field(:connector_text_midpoint, 255,
    type: FigKiwi.Schema.ConnectorTextMidpoint,
    source_name: "connectorTextMidpoint"
  )

  field(:connector_type, 373,
    type: {:enum, FigKiwi.Schema.ConnectorType},
    source_name: "connectorType"
  )

  field(:connector_version, 533, type: :int, source_name: "connectorVersion")

  field(:annotations, 369,
    repeated: true,
    type: FigKiwi.Schema.Annotation,
    source_name: "annotations"
  )

  field(:measurements, 384,
    repeated: true,
    type: FigKiwi.Schema.AnnotationMeasurement,
    source_name: "measurements"
  )

  field(:annotation_categories, 453,
    type: FigKiwi.Schema.AnnotationCategories,
    source_name: "annotationCategories"
  )

  field(:shape_with_text_type, 241,
    type: {:enum, FigKiwi.Schema.ShapeWithTextType},
    source_name: "shapeWithTextType"
  )

  field(:shape_user_height, 247, type: :float, source_name: "shapeUserHeight")
  field(:is_stroke_paint_derived, 530, type: :bool, source_name: "isStrokePaintDerived")

  field(:derived_immutable_frame_data, 254,
    type: FigKiwi.Schema.DerivedImmutableFrameData,
    source_name: "derivedImmutableFrameData"
  )

  field(:derived_immutable_frame_data_version, 338,
    type: FigKiwi.Schema.MultiplayerFieldVersion,
    source_name: "derivedImmutableFrameDataVersion"
  )

  field(:node_generation_data, 240,
    type: FigKiwi.Schema.NodeGenerationData,
    source_name: "nodeGenerationData"
  )

  field(:jsx_data, 491, type: FigKiwi.Schema.JsxData, source_name: "jsxData")

  field(:derived_jsx_data, 492,
    type: FigKiwi.Schema.DerivedJsxData,
    source_name: "derivedJsxData"
  )

  field(:stable_key, 493, type: :string, source_name: "stableKey")

  field(:code_block_language, 259,
    type: {:enum, FigKiwi.Schema.CodeBlockLanguage},
    source_name: "codeBlockLanguage"
  )

  field(:code_block_theme, 433,
    type: {:enum, FigKiwi.Schema.CodeBlockTheme},
    source_name: "codeBlockTheme"
  )

  field(:link_preview_data, 278,
    type: FigKiwi.Schema.LinkPreviewData,
    source_name: "linkPreviewData"
  )

  field(:shape_truncates, 282, type: :bool, source_name: "shapeTruncates")
  field(:section_contents_hidden, 283, type: :bool, source_name: "sectionContentsHidden")
  field(:video_playback, 300, type: FigKiwi.Schema.VideoPlayback, source_name: "videoPlayback")
  field(:stamp_data, 301, type: FigKiwi.Schema.StampData, source_name: "stampData")

  field(:section_preset_info, 370,
    type: FigKiwi.Schema.SectionPresetInfo,
    source_name: "sectionPresetInfo"
  )

  field(:platform_shape_definition, 409,
    type: FigKiwi.Schema.PlatformShapeDefinition,
    source_name: "platformShapeDefinition"
  )

  field(:widget_synced_state, 273,
    type: FigKiwi.Schema.MultiplayerMap,
    source_name: "widgetSyncedState"
  )

  field(:widget_sync_cursor, 274, type: :uint, source_name: "widgetSyncCursor")

  field(:widget_derived_subtree_cursor, 275,
    type: FigKiwi.Schema.WidgetDerivedSubtreeCursor,
    source_name: "widgetDerivedSubtreeCursor"
  )

  field(:widget_cached_ancestor, 276,
    type: FigKiwi.Schema.WidgetPointer,
    source_name: "widgetCachedAncestor"
  )

  field(:widget_input_behavior, 285,
    type: {:enum, FigKiwi.Schema.WidgetInputBehavior},
    source_name: "widgetInputBehavior"
  )

  field(:widget_tooltip, 286, type: :string, source_name: "widgetTooltip")

  field(:widget_hover_style, 291,
    type: FigKiwi.Schema.WidgetHoverStyle,
    source_name: "widgetHoverStyle"
  )

  field(:is_widget_stickable, 293, type: :bool, source_name: "isWidgetStickable")

  field(:should_hide_cursors_on_widget_hover, 360,
    type: :bool,
    source_name: "shouldHideCursorsOnWidgetHover"
  )

  field(:widget_metadata, 262, type: FigKiwi.Schema.WidgetMetadata, source_name: "widgetMetadata")

  field(:widget_events, 263,
    repeated: true,
    type: {:enum, FigKiwi.Schema.WidgetEvent},
    source_name: "widgetEvents"
  )

  field(:widget_property_menu_items, 265,
    repeated: true,
    type: FigKiwi.Schema.WidgetPropertyMenuItem,
    source_name: "widgetPropertyMenuItems"
  )

  field(:widget_input_text_node_type, 401,
    type: {:enum, FigKiwi.Schema.WidgetInputTextNodeType},
    source_name: "widgetInputTextNodeType"
  )

  field(:jsx_props, 489, type: FigKiwi.Schema.MultiplayerMap, source_name: "jsxProps")

  field(:table_row_positions, 308,
    type: FigKiwi.Schema.TableRowColumnPositionMap,
    source_name: "tableRowPositions"
  )

  field(:table_column_positions, 309,
    type: FigKiwi.Schema.TableRowColumnPositionMap,
    source_name: "tableColumnPositions"
  )

  field(:table_row_heights, 310,
    type: FigKiwi.Schema.TableRowColumnSizeMap,
    source_name: "tableRowHeights"
  )

  field(:table_column_widths, 311,
    type: FigKiwi.Schema.TableRowColumnSizeMap,
    source_name: "tableColumnWidths"
  )

  field(:table_merged_cells, 538,
    type: FigKiwi.Schema.TableMergedCellMap,
    source_name: "tableMergedCells"
  )

  field(:interactive_slide_config_data, 371,
    type: FigKiwi.Schema.MultiplayerMap,
    source_name: "interactiveSlideConfigData"
  )

  field(:interactive_slide_participant_data, 372,
    type: FigKiwi.Schema.MultiplayerMap,
    source_name: "interactiveSlideParticipantData"
  )

  field(:flapp_type, 402, type: {:enum, FigKiwi.Schema.FlappType}, source_name: "flappType")
  field(:is_embedded_prototype, 486, type: :bool, source_name: "isEmbeddedPrototype")
  field(:slide_speaker_notes, 389, type: :string, source_name: "slideSpeakerNotes")
  field(:is_skipped_slide, 410, type: :bool, source_name: "isSkippedSlide")

  field(:presentation_outlines, 573,
    type: FigKiwi.Schema.MultiplayerMap,
    source_name: "presentationOutlines"
  )

  field(:theme_id, 379, type: FigKiwi.Schema.ThemeID, source_name: "themeID")

  field(:slide_theme_data, 381,
    type: FigKiwi.Schema.SlideThemeData,
    source_name: "slideThemeData"
  )

  field(:slide_theme_map, 390, type: FigKiwi.Schema.SlideThemeMap, source_name: "slideThemeMap")
  field(:slide_template_file_key, 393, type: :string, source_name: "slideTemplateFileKey")
  field(:slide_number, 443, type: {:enum, FigKiwi.Schema.SlideNumber}, source_name: "slideNumber")
  field(:slide_number_separator, 456, type: :string, source_name: "slideNumberSeparator")
  field(:diagram_parent_id, 363, type: FigKiwi.Schema.GUID, source_name: "diagramParentId")
  field(:layout_root, 362, type: FigKiwi.Schema.GUID, source_name: "layoutRoot")
  field(:layout_position, 364, type: :string, source_name: "layoutPosition")

  field(:diagram_layout_rule_type, 366,
    type: {:enum, FigKiwi.Schema.DiagramLayoutRuleType},
    source_name: "diagramLayoutRuleType"
  )

  field(:diagram_parent_index, 367,
    type: FigKiwi.Schema.DiagramParentIndex,
    source_name: "diagramParentIndex"
  )

  field(:diagram_layout_paused, 368,
    type: {:enum, FigKiwi.Schema.DiagramLayoutPaused},
    source_name: "diagramLayoutPaused"
  )

  field(:is_page_divider, 380, type: :bool, source_name: "isPageDivider")

  field(:internal_enum_for_test, 251,
    type: {:enum, FigKiwi.Schema.InternalEnumForTest},
    source_name: "internalEnumForTest"
  )

  field(:internal_data_for_test, 257,
    type: FigKiwi.Schema.InternalDataForTest,
    source_name: "internalDataForTest"
  )

  field(:auto_rename, 14, type: :bool, source_name: "autoRename")
  field(:auto_rename_tag, 66, type: :uint, source_name: "autoRenameTag")
  field(:background_enabled, 15, type: :bool, source_name: "backgroundEnabled")
  field(:background_enabled_tag, 67, type: :uint, source_name: "backgroundEnabledTag")
  field(:export_contents_only, 17, type: :bool, source_name: "exportContentsOnly")
  field(:export_contents_only_tag, 69, type: :uint, source_name: "exportContentsOnlyTag")
  field(:miter_limit, 25, type: :float, source_name: "miterLimit")
  field(:miter_limit_tag, 77, type: :uint, source_name: "miterLimitTag")
  field(:text_tracking, 27, type: :float, source_name: "textTracking")
  field(:text_tracking_tag, 79, type: :uint, source_name: "textTrackingTag")

  field(:vertical_constraint, 37,
    type: {:enum, FigKiwi.Schema.ConstraintType},
    source_name: "verticalConstraint"
  )

  field(:vertical_constraint_tag, 89, type: :uint, source_name: "verticalConstraintTag")

  field(:export_settings, 45,
    repeated: true,
    type: FigKiwi.Schema.ExportSettings,
    source_name: "exportSettings"
  )

  field(:export_settings_tag, 97, type: :uint, source_name: "exportSettingsTag")

  field(:text_auto_resize, 46,
    type: {:enum, FigKiwi.Schema.TextAutoResize},
    source_name: "textAutoResize"
  )

  field(:text_auto_resize_tag, 98, type: :uint, source_name: "textAutoResizeTag")

  field(:layout_grids, 47,
    repeated: true,
    type: FigKiwi.Schema.LayoutGrid,
    source_name: "layoutGrids"
  )

  field(:layout_grids_tag, 99, type: :uint, source_name: "layoutGridsTag")
  field(:frame_mask_disabled, 115, type: :bool, source_name: "frameMaskDisabled")
  field(:frame_mask_disabled_tag, 116, type: :uint, source_name: "frameMaskDisabledTag")
  field(:resize_to_fit, 117, type: :bool, source_name: "resizeToFit")
  field(:resize_to_fit_tag, 118, type: :uint, source_name: "resizeToFitTag")

  field(:boolean_operation, 36,
    type: {:enum, FigKiwi.Schema.BooleanOperation},
    source_name: "booleanOperation"
  )

  field(:boolean_operation_tag, 88, type: :uint, source_name: "booleanOperationTag")

  field(:handle_mirroring, 44,
    type: {:enum, FigKiwi.Schema.VectorMirror},
    source_name: "handleMirroring"
  )

  field(:handle_mirroring_tag, 96, type: :uint, source_name: "handleMirroringTag")
  field(:count, 10, type: :uint, source_name: "count")
  field(:count_tag, 62, type: :uint, source_name: "countTag")
  field(:star_inner_scale, 24, type: :float, source_name: "starInnerScale")
  field(:star_inner_scale_tag, 76, type: :uint, source_name: "starInnerScaleTag")
  field(:arc_data, 195, type: FigKiwi.Schema.ArcData, source_name: "arcData")
  field(:vector_data, 48, type: FigKiwi.Schema.VectorData, source_name: "vectorData")
  field(:vector_data_tag, 100, type: :uint, source_name: "vectorDataTag")
  field(:vector_operation_version, 425, type: :uint, source_name: "vectorOperationVersion")
  field(:text_path_start, 432, type: FigKiwi.Schema.TextPathStart, source_name: "textPathStart")
  field(:export_background_disabled, 119, type: :bool, source_name: "exportBackgroundDisabled")
  field(:guides, 138, repeated: true, type: FigKiwi.Schema.Guide, source_name: "guides")
  field(:internal_only, 142, type: :bool, source_name: "internalOnly")

  field(:scroll_direction, 159,
    type: {:enum, FigKiwi.Schema.ScrollDirection},
    source_name: "scrollDirection"
  )

  field(:corner_smoothing, 160, type: :float, source_name: "cornerSmoothing")
  field(:scroll_offset, 166, type: FigKiwi.Schema.Vector, source_name: "scrollOffset")
  field(:export_text_as_svg_text, 175, type: :bool, source_name: "exportTextAsSVGText")

  field(:scroll_contracted_state, 178,
    type: {:enum, FigKiwi.Schema.ScrollContractedState},
    source_name: "scrollContractedState"
  )

  field(:contracted_size, 179, type: FigKiwi.Schema.Vector, source_name: "contractedSize")
  field(:fixed_children_divider, 180, type: :string, source_name: "fixedChildrenDivider")

  field(:scroll_behavior, 186,
    type: {:enum, FigKiwi.Schema.ScrollBehavior},
    source_name: "scrollBehavior"
  )

  field(:derived_symbol_data_layout_version, 196,
    type: :int,
    source_name: "derivedSymbolDataLayoutVersion"
  )

  field(:navigation_type, 197,
    type: {:enum, FigKiwi.Schema.NavigationType},
    source_name: "navigationType"
  )

  field(:overlay_position_type, 198,
    type: {:enum, FigKiwi.Schema.OverlayPositionType},
    source_name: "overlayPositionType"
  )

  field(:overlay_relative_position, 199,
    type: FigKiwi.Schema.Vector,
    source_name: "overlayRelativePosition"
  )

  field(:overlay_background_interaction, 200,
    type: {:enum, FigKiwi.Schema.OverlayBackgroundInteraction},
    source_name: "overlayBackgroundInteraction"
  )

  field(:overlay_background_appearance, 201,
    type: FigKiwi.Schema.OverlayBackgroundAppearance,
    source_name: "overlayBackgroundAppearance"
  )

  field(:override_key, 213, type: FigKiwi.Schema.GUID, source_name: "overrideKey")

  field(:container_supports_fill_stroke_and_corners, 220,
    type: :bool,
    source_name: "containerSupportsFillStrokeAndCorners"
  )

  field(:stack_counter_sizing, 221,
    type: {:enum, FigKiwi.Schema.StackSize},
    source_name: "stackCounterSizing"
  )

  field(:containers_support_fill_stroke_and_corners, 222,
    type: :bool,
    source_name: "containersSupportFillStrokeAndCorners"
  )

  field(:key_trigger, 224, type: FigKiwi.Schema.KeyTrigger, source_name: "keyTrigger")
  field(:voice_event_phrase, 227, type: :string, source_name: "voiceEventPhrase")

  field(:ancestor_path_before_deletion, 235,
    repeated: true,
    type: FigKiwi.Schema.GUID,
    source_name: "ancestorPathBeforeDeletion"
  )

  field(:symbol_links, 237,
    repeated: true,
    type: FigKiwi.Schema.SymbolLink,
    source_name: "symbolLinks"
  )

  field(:text_list_data, 239, type: FigKiwi.Schema.TextListData, source_name: "textListData")

  field(:detach_optical_size_from_font_size, 261,
    type: :bool,
    source_name: "detachOpticalSizeFromFontSize"
  )

  field(:list_spacing, 264, type: :float, source_name: "listSpacing")
  field(:embed_data, 270, type: FigKiwi.Schema.EmbedData, source_name: "embedData")
  field(:rich_media_data, 272, type: FigKiwi.Schema.RichMediaData, source_name: "richMediaData")

  field(:rendered_synced_state, 277,
    type: FigKiwi.Schema.MultiplayerMap,
    source_name: "renderedSyncedState"
  )

  field(:simplify_instance_panels, 284, type: :bool, source_name: "simplifyInstancePanels")

  field(:accessible_html_tag, 302,
    type: {:enum, FigKiwi.Schema.HTMLTag},
    source_name: "accessibleHTMLTag"
  )

  field(:aria_role, 303, type: {:enum, FigKiwi.Schema.ARIARole}, source_name: "ariaRole")

  field(:aria_attributes, 357,
    type: FigKiwi.Schema.ARIAAttributesMap,
    source_name: "ariaAttributes"
  )

  field(:accessible_label, 304, type: :string, source_name: "accessibleLabel")
  field(:is_decorative_image, 490, type: :bool, source_name: "isDecorativeImage")
  field(:variable_data, 306, type: FigKiwi.Schema.VariableData, source_name: "variableData")

  field(:variable_consumption_map, 307,
    type: FigKiwi.Schema.VariableDataMap,
    source_name: "variableConsumptionMap"
  )

  field(:variable_mode_by_set_map, 316,
    type: FigKiwi.Schema.VariableModeBySetMap,
    source_name: "variableModeBySetMap"
  )

  field(:variable_set_modes, 312,
    repeated: true,
    type: FigKiwi.Schema.VariableSetMode,
    source_name: "variableSetModes"
  )

  field(:variable_set_id, 313, type: FigKiwi.Schema.VariableSetID, source_name: "variableSetID")

  field(:variable_resolved_type, 314,
    type: {:enum, FigKiwi.Schema.VariableResolvedDataType},
    source_name: "variableResolvedType"
  )

  field(:variable_data_values, 315,
    type: FigKiwi.Schema.VariableDataValues,
    source_name: "variableDataValues"
  )

  field(:variable_token_name, 350, type: :string, source_name: "variableTokenName")

  field(:timing_display_unit, 566,
    type: {:enum, FigKiwi.Schema.VariableTimingDisplayUnit},
    source_name: "timingDisplayUnit"
  )

  field(:variable_scopes, 353,
    repeated: true,
    type: {:enum, FigKiwi.Schema.VariableScope},
    source_name: "variableScopes"
  )

  field(:parameter_consumption_map, 445,
    type: FigKiwi.Schema.VariableDataMap,
    source_name: "parameterConsumptionMap"
  )

  field(:code_syntax, 358, type: FigKiwi.Schema.CodeSyntaxMap, source_name: "codeSyntax")
  field(:paste_source, 388, type: FigKiwi.Schema.PasteSource, source_name: "pasteSource")
  field(:page_type, 397, type: {:enum, FigKiwi.Schema.EditorType}, source_name: "pageType")
  field(:stroke_brush_guid, 446, type: FigKiwi.Schema.GUID, source_name: "strokeBrushGuid")
  field(:stroke_seed, 482, type: :uint64, source_name: "strokeSeed")

  field(:variable_width_points, 447,
    repeated: true,
    type: FigKiwi.Schema.VariableWidthPoint,
    source_name: "variableWidthPoints"
  )

  field(:dynamic_stroke_settings, 448,
    type: FigKiwi.Schema.DynamicStrokeSettings,
    source_name: "dynamicStrokeSettings"
  )

  field(:scatter_stroke_settings, 449,
    type: FigKiwi.Schema.ScatterStrokeSettings,
    source_name: "scatterStrokeSettings"
  )

  field(:stretch_stroke_settings, 450,
    type: FigKiwi.Schema.StretchStrokeSettings,
    source_name: "stretchStrokeSettings"
  )

  field(:scatter_brush_transforms, 488,
    repeated: true,
    type: FigKiwi.Schema.Matrix,
    source_name: "scatterBrushTransforms"
  )

  field(:brush_type, 452, type: {:enum, FigKiwi.Schema.BrushType}, source_name: "brushType")
  field(:path_trim, 542, type: FigKiwi.Schema.OptionalVector, source_name: "pathTrim")
  field(:stroke_offset, 554, type: :float, source_name: "strokeOffset")

  field(:backing_variable_set_id, 377,
    type: FigKiwi.Schema.VariableSetID,
    source_name: "backingVariableSetId"
  )

  field(:overridden_variable_id, 464,
    type: FigKiwi.Schema.VariableID,
    source_name: "overriddenVariableId"
  )

  field(:backing_variable_id, 378,
    type: FigKiwi.Schema.VariableIdOrVariableOverrideId,
    source_name: "backingVariableId"
  )

  field(:is_collection_extendable, 385, type: :bool, source_name: "isCollectionExtendable")
  field(:root_variable_key, 386, type: :string, source_name: "rootVariableKey")

  field(:inherited_variable_ids, 517,
    type: FigKiwi.Schema.InheritedVariablesData,
    source_name: "inheritedVariableIds"
  )

  field(:handoff_status_map, 361,
    type: FigKiwi.Schema.HandoffStatusMap,
    source_name: "handoffStatusMap"
  )

  field(:agenda_position_map, 327,
    type: FigKiwi.Schema.AgendaPositionMap,
    source_name: "agendaPositionMap"
  )

  field(:agenda_metadata_map, 328,
    type: FigKiwi.Schema.AgendaMetadataMap,
    source_name: "agendaMetadataMap"
  )

  field(:migration_status, 329,
    type: FigKiwi.Schema.MigrationStatus,
    source_name: "migrationStatus"
  )

  field(:is_soft_deleted, 330, type: :bool, source_name: "isSoftDeleted")
  field(:edit_info, 331, type: FigKiwi.Schema.EditInfo, source_name: "editInfo")

  field(:color_profile, 341,
    type: {:enum, FigKiwi.Schema.ColorProfile},
    source_name: "colorProfile"
  )

  field(:detached_symbol_id, 342, type: FigKiwi.Schema.SymbolId, source_name: "detachedSymbolId")

  field(:child_reading_direction, 346,
    type: {:enum, FigKiwi.Schema.ChildReadingDirection},
    source_name: "childReadingDirection"
  )

  field(:reading_index, 347, type: :string, source_name: "readingIndex")

  field(:document_color_profile, 349,
    type: {:enum, FigKiwi.Schema.DocumentColorProfile},
    source_name: "documentColorProfile"
  )

  field(:developer_related_links, 354,
    repeated: true,
    type: FigKiwi.Schema.DeveloperRelatedLink,
    source_name: "developerRelatedLinks"
  )

  field(:slide_active_theme_lib_key, 356, type: :string, source_name: "slideActiveThemeLibKey")
  field(:edit_scope_info, 365, type: FigKiwi.Schema.EditScopeInfo, source_name: "editScopeInfo")

  field(:semantic_weight, 374,
    type: {:enum, FigKiwi.Schema.SemanticWeight},
    source_name: "semanticWeight"
  )

  field(:semantic_italic, 375,
    type: {:enum, FigKiwi.Schema.SemanticItalic},
    source_name: "semanticItalic"
  )

  field(:are_slides_manually_indented, 403, type: :bool, source_name: "areSlidesManuallyIndented")
  field(:is_responsive_set, 387, type: :bool, source_name: "isResponsiveSet")

  field(:derived_breakpoint_data, 500,
    type: FigKiwi.Schema.DerivedBreakpointData,
    source_name: "derivedBreakpointData"
  )

  field(:default_responsive_set_id, 398,
    type: FigKiwi.Schema.GUID,
    source_name: "defaultResponsiveSetId"
  )

  field(:is_primary_breakpoint, 458, type: :bool, source_name: "isPrimaryBreakpoint")

  field(:primary_responsive_node_id, 457,
    type: FigKiwi.Schema.GUID,
    source_name: "primaryResponsiveNodeId"
  )

  field(:multi_edit_glue_id, 462, type: FigKiwi.Schema.GUID, source_name: "multiEditGlueId")
  field(:breakpoint_min_width, 501, type: :float, source_name: "breakpointMinWidth")
  field(:is_breakpoint_in_focus, 522, type: :bool, source_name: "isBreakpointInFocus")

  field(:responsive_set_settings, 400,
    type: FigKiwi.Schema.ResponsiveSetSettings,
    source_name: "responsiveSetSettings"
  )

  field(:behaviors, 404, type: FigKiwi.Schema.NodeBehaviors, source_name: "behaviors")
  field(:source_code, 414, type: :string, source_name: "sourceCode")

  field(:source_code_collaborative_text_version, 534,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextOpID,
    source_name: "sourceCodeCollaborativeTextVersion"
  )

  field(:collaborative_source_code, 444,
    type: FigKiwi.Schema.CollaborativePlainText,
    source_name: "collaborativeSourceCode"
  )

  field(:belongs_to_code_library_id, 427,
    type: FigKiwi.Schema.CodeLibraryId,
    source_name: "belongsToCodeLibraryId"
  )

  field(:imported_code_files, 467,
    type: FigKiwi.Schema.ImportedCodeFiles,
    source_name: "importedCodeFiles"
  )

  field(:code_file_canvas_node_id, 468,
    type: FigKiwi.Schema.CanvasNodeId,
    source_name: "codeFileCanvasNodeId"
  )

  field(:is_entrypoint_code_file, 498, type: :bool, source_name: "isEntrypointCodeFile")

  field(:component_or_state_group_key, 502,
    type: :string,
    source_name: "componentOrStateGroupKey"
  )

  field(:component_or_state_group_version, 503,
    type: :uint,
    source_name: "componentOrStateGroupVersion"
  )

  field(:source_code_library_key, 504, type: :string, source_name: "sourceCodeLibraryKey")

  field(:source_code_library_keys, 515,
    repeated: true,
    type: :string,
    source_name: "sourceCodeLibraryKeys"
  )

  field(:used_make_libraries, 524,
    repeated: true,
    type: FigKiwi.Schema.UsedMakeLibrary,
    source_name: "usedMakeLibraries"
  )

  field(:make_library_component_id, 518, type: :string, source_name: "makeLibraryComponentId")

  field(:should_hide_preview_for_make_kit_creation, 520,
    type: :bool,
    source_name: "shouldHidePreviewForMakeKitCreation"
  )

  field(:is_make_kit, 551, type: :bool, source_name: "isMakeKit")

  field(:code_preview_settings, 531,
    type: FigKiwi.Schema.PrototypeDevice,
    source_name: "codePreviewSettings"
  )

  field(:code_examples, 525,
    repeated: true,
    type: FigKiwi.Schema.CodeExample,
    source_name: "codeExamples"
  )

  field(:exported_from_code_file_id, 428,
    type: FigKiwi.Schema.CodeFileId,
    source_name: "exportedFromCodeFileId"
  )

  field(:code_export_name, 430, type: :string, source_name: "codeExportName")
  field(:code_component_description, 547, type: :string, source_name: "codeComponentDescription")

  field(:backing_code_component_id, 429,
    type: FigKiwi.Schema.CodeComponentId,
    source_name: "backingCodeComponentId"
  )

  field(:is_main_code_component, 487, type: :bool, source_name: "isMainCodeComponent")

  field(:code_snapshot_state, 431,
    type: {:enum, FigKiwi.Schema.CodeSnapshotState},
    source_name: "codeSnapshotState"
  )

  field(:chat_messages, 451,
    repeated: true,
    type: FigKiwi.Schema.NodeChatMessage,
    source_name: "chatMessages"
  )

  field(:chat_compression_state, 485,
    type: FigKiwi.Schema.NodeChatCompressionState,
    source_name: "chatCompressionState"
  )

  field(:ai_chat_thread, 496, type: FigKiwi.Schema.AIChatThread, source_name: "aiChatThread")
  field(:code_chat_messages_key, 484, type: :string, source_name: "codeChatMessagesKey")
  field(:code_snapshot, 459, type: FigKiwi.Schema.CodeSnapshot, source_name: "codeSnapshot")

  field(:code_snapshot_layers, 589,
    type: FigKiwi.Schema.CodeSnapshotLayers,
    source_name: "codeSnapshotLayers"
  )

  field(:code_snapshot_invalidated_at, 480, type: :uint, source_name: "codeSnapshotInvalidatedAt")
  field(:is_code_behavior, 465, type: :bool, source_name: "isCodeBehavior")
  field(:auto_fork_code, 469, type: :bool, source_name: "autoForkCode")
  field(:has_been_manually_renamed, 470, type: :bool, source_name: "hasBeenManuallyRenamed")
  field(:code_created_from_design, 471, type: :bool, source_name: "codeCreatedFromDesign")

  field(:code_created_from_design_node_id, 481,
    type: FigKiwi.Schema.CanvasNodeId,
    source_name: "codeCreatedFromDesignNodeId"
  )

  field(:image_imports, 473, type: FigKiwi.Schema.ImageImportMap, source_name: "imageImports")

  field(:code_object_type, 516,
    type: {:enum, FigKiwi.Schema.CodeObjectType},
    source_name: "codeObjectType"
  )

  field(:code_file_path, 472, type: :string, source_name: "codeFilePath")

  field(:code_behavior_data, 478,
    type: FigKiwi.Schema.CodeBehaviorData,
    source_name: "codeBehaviorData"
  )

  field(:code_library_format, 519, type: :uint, source_name: "codeLibraryFormat")

  field(:is_code_preview_playing_on_canvas, 527,
    type: :bool,
    source_name: "isCodePreviewPlayingOnCanvas"
  )

  field(:code_embed_info, 532, type: FigKiwi.Schema.CodeEmbedInfo, source_name: "codeEmbedInfo")
  field(:is_embed_code_layer, 546, type: :bool, source_name: "isEmbedCodeLayer")

  field(:code_source_info, 558,
    type: FigKiwi.Schema.CodeSourceInfo,
    source_name: "codeSourceInfo"
  )

  field(:mime_type, 536, type: :string, source_name: "mimeType")
  field(:blob_ref, 537, repeated: true, type: :byte, source_name: "blobRef")
  field(:cms_selector, 419, type: FigKiwi.Schema.CMSSelector, source_name: "cmsSelector")

  field(:cms_consumption_map, 420,
    type: FigKiwi.Schema.CMSConsumptionMap,
    source_name: "cmsConsumptionMap"
  )

  field(:cms_rich_text_style_map, 460,
    type: FigKiwi.Schema.CMSRichTextStyleMap,
    source_name: "cmsRichTextStyleMap"
  )

  field(:repeater_symbol_id, 539, type: FigKiwi.Schema.SymbolId, source_name: "repeaterSymbolId")

  field(:repeater_cms_override_data, 540,
    type: FigKiwi.Schema.RepeaterCmsOverrideData,
    source_name: "repeaterCmsOverrideData"
  )

  field(:repeater_symbol_override_data, 549,
    type: FigKiwi.Schema.RepeaterSymbolOverrideData,
    source_name: "repeaterSymbolOverrideData"
  )

  field(:repeater_override_data, 541,
    type: FigKiwi.Schema.RepeaterOverrideData,
    source_name: "repeaterOverrideData"
  )

  field(:ai_edited_node_change_field_numbers, 405,
    repeated: true,
    type: :uint,
    source_name: "aiEditedNodeChangeFieldNumbers"
  )

  field(:ai_edit_scope_label, 408, type: :string, source_name: "aiEditScopeLabel")

  field(:first_draft_data, 407,
    type: FigKiwi.Schema.FirstDraftData,
    source_name: "firstDraftData"
  )

  field(:first_draft_kit_element_data, 418,
    type: FigKiwi.Schema.FirstDraftKitElementData,
    source_name: "firstDraftKitElementData"
  )

  field(:cooper_revert_data, 421,
    type: FigKiwi.Schema.CooperRevertData,
    source_name: "cooperRevertData"
  )

  field(:cooper_template_data, 461,
    type: FigKiwi.Schema.CooperTemplateData,
    source_name: "cooperTemplateData"
  )

  field(:buzz_approval_requests, 528,
    type: FigKiwi.Schema.BuzzApprovalRequests,
    source_name: "buzzApprovalRequests"
  )

  field(:buzz_approval_node_status_info, 529,
    type: FigKiwi.Schema.BuzzApprovalNodeStatusInfo,
    source_name: "buzzApprovalNodeStatusInfo"
  )

  field(:hub_file_attribution, 422,
    type: FigKiwi.Schema.HubFileAttribution,
    source_name: "hubFileAttribution"
  )

  field(:managed_string_data, 454,
    type: FigKiwi.Schema.ManagedStringData,
    source_name: "managedStringData"
  )

  field(:thumbnail_info, 466, type: FigKiwi.Schema.ThumbnailInfo, source_name: "thumbnailInfo")

  field(:ai_canvas_prompt, 494,
    type: FigKiwi.Schema.AiCanvasPrompt,
    source_name: "aiCanvasPrompt"
  )

  field(:backing_node_id, 499, type: FigKiwi.Schema.CanvasNodeId, source_name: "backingNodeId")
  field(:page_status, 548, type: :string, source_name: "pageStatus")

  field(:motion_transform, 523,
    type: FigKiwi.Schema.TRSSTransform2D,
    source_name: "motionTransform"
  )

  field(:timeline_position, 506, type: :int64, source_name: "timelinePosition")

  field(:keyframe_value, 507,
    type: FigKiwi.Schema.KeyframeValueData,
    source_name: "keyframeValue"
  )

  field(:keyframe_value_ref, 586,
    type: FigKiwi.Schema.VariableData,
    source_name: "keyframeValueRef"
  )

  field(:interpolation_type, 505,
    type: {:enum, FigKiwi.Schema.InterpolationType},
    source_name: "interpolationType"
  )

  field(:bezier_handles, 508, type: FigKiwi.Schema.BezierHandles, source_name: "bezierHandles")
  field(:easing_data, 535, type: FigKiwi.Schema.EasingData, source_name: "easingData")

  field(:keyframe_operation, 509,
    type: {:enum, FigKiwi.Schema.KeyframeOperation},
    source_name: "keyframeOperation"
  )

  field(:timeline_position_type, 510,
    type: {:enum, FigKiwi.Schema.TimelinePositionType},
    source_name: "timelinePositionType"
  )

  field(:is_clip, 545, type: :bool, source_name: "isClip")
  field(:clip_id, 511, type: FigKiwi.Schema.GUID, source_name: "clipId")
  field(:timeline_duration, 512, type: :uint64, source_name: "timelineDuration")
  field(:timeline_offset, 513, type: :int64, source_name: "timelineOffset")
  field(:timeline_disabled, 543, type: :bool, source_name: "timelineDisabled")

  field(:playback_style, 514,
    type: {:enum, FigKiwi.Schema.PlaybackStyle},
    source_name: "playbackStyle"
  )

  field(:timeline_definitions, 552,
    type: FigKiwi.Schema.TimelineDefinitionsMap,
    source_name: "timelineDefinitions"
  )

  field(:timeline_assignments, 553,
    type: FigKiwi.Schema.TimelineAssignmentsMap,
    source_name: "timelineAssignments"
  )

  field(:animation_presets, 521,
    type: FigKiwi.Schema.AnimationPresets,
    source_name: "animationPresets"
  )

  field(:style_ids_for_animation, 582,
    repeated: true,
    type: FigKiwi.Schema.StyleIdForAnimation,
    source_name: "styleIdsForAnimation"
  )

  field(:backing_animation_preset_id, 583,
    type: FigKiwi.Schema.AnimationPresetId,
    source_name: "backingAnimationPresetId"
  )

  field(:tools, 568, type: FigKiwi.Schema.Tools, source_name: "tools")
  field(:custom_effects, 569, type: FigKiwi.Schema.CustomEffects, source_name: "customEffects")

  field(:transition_overrides, 526,
    type: FigKiwi.Schema.TransitionOverrideData,
    source_name: "transitionOverrides"
  )

  field(:use_legacy_smart_animate, 544, type: :bool, source_name: "useLegacySmartAnimate")

  field(:source_control_config, 557,
    type: FigKiwi.Schema.SourceControlConfig,
    source_name: "sourceControlConfig"
  )

  field(:spec_block_type, 559,
    type: {:enum, FigKiwi.Schema.SpecBlockType},
    source_name: "specBlockType"
  )

  field(:spec_block_content, 560,
    type: FigKiwi.Schema.CollaborativePlainText,
    source_name: "specBlockContent"
  )

  field(:spec_code_block_language, 561, type: :string, source_name: "specCodeBlockLanguage")
  field(:spec_block_table_alignment, 562, type: :string, source_name: "specBlockTableAlignment")
  field(:spec_block_indent_level, 563, type: :int, source_name: "specBlockIndentLevel")
  field(:spec_image_hash, 575, type: :string, source_name: "specImageHash")
  field(:spec_width, 576, type: :int, source_name: "specWidth")
  field(:spec_height, 577, type: :int, source_name: "specHeight")

  field(:spec_block_table_row_heights, 578,
    type: FigKiwi.Schema.TableRowColumnSizeMap,
    source_name: "specBlockTableRowHeights"
  )

  field(:spec_block_table_column_widths, 579,
    type: FigKiwi.Schema.TableRowColumnSizeMap,
    source_name: "specBlockTableColumnWidths"
  )

  field(:spec_embed_url, 590, type: :string, source_name: "specEmbedUrl")
  field(:placeholder, 565, type: :bool, source_name: "placeholder")

  field(:placeholder_client_lifecycle_id, 584,
    type: :string,
    source_name: "placeholderClientLifecycleId"
  )

  field(:placeholder_invalidate_at, 585, type: :int, source_name: "placeholderInvalidateAt")
  field(:disable_jit_dst, 567, type: :bool, source_name: "disableJitDst")

  field(:custom_tool_artifact_ref, 588,
    type: FigKiwi.Schema.CustomToolArtifactRef,
    source_name: "customToolArtifactRef"
  )
end
