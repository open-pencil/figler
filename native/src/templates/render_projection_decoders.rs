__rq_render_projection_field_constants!();

fn render_nil<'a>(env: Env<'a>) -> Term<'a> {
    Atom::from_str(env, "nil").unwrap().encode(env)
}

fn render_guid<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let session_id = decoder.read_var_uint()?;
    let local_id = decoder.read_var_uint()?;
    Ok((session_id, local_id).encode(env))
}

fn render_repeated_terms<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    decode: KiwiDecodeFn,
) -> NifResult<Term<'a>> {
    let values = decoder.read_repeated(|decoder| decode(env, decoder))?;
    Ok(values.encode(env))
}

fn render_vector_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let nil = render_nil(env);
    let mut blob_index = nil;
    let mut normalized_size = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            RENDER_VECTOR_DATA_FIELD_NETWORK_BLOB => {
                blob_index = decoder.read_var_uint()?.encode(env)
            }
            RENDER_VECTOR_DATA_FIELD_NORMALIZED_SIZE => {
                normalized_size = decode_sparse_vector_from_decoder(env, decoder)?
            }
            RENDER_VECTOR_DATA_FIELD_STYLE_OVERRIDE_TABLE => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    skip_node_change_from_decoder(decoder)?;
                }
            }
            field => kiwi_unknown_field(decoder, "VectorData", field)?,
        }
    }

    Ok(rustler::types::tuple::make_tuple(
        env,
        &[blob_index, normalized_size],
    ))
}

fn render_projection_node_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let nil = render_nil(env);
    let empty = Vec::<Term<'a>>::new().encode(env);
    let mut guid = nil;
    let mut node_type = nil;
    let mut name = nil;
    let mut text_data = nil;
    let mut line_height = nil;
    let mut letter_spacing = nil;
    let mut text_decoration = nil;
    let mut text_decoration_style = nil;
    let mut text_decoration_thickness = nil;
    let mut text_decoration_skip_ink = nil;
    let mut text_underline_offset = nil;
    let mut text_decoration_fill_paints = nil;
    let mut text_case = nil;
    let mut text_align_horizontal = nil;
    let mut text_align_vertical = nil;
    let mut text_auto_resize = nil;
    let mut text_truncation = nil;
    let mut max_lines = nil;
    let mut blend_mode = nil;
    let mut mask = nil;
    let mut mask_type = nil;
    let mut effects = empty;
    let mut fill_paints = empty;
    let mut stroke_paints = empty;
    let mut stroke_weight = nil;
    let mut stroke_align = nil;
    let mut stroke_cap = nil;
    let mut stroke_cap_size = nil;
    let mut stroke_join = nil;
    let mut miter_limit = nil;
    let mut dash_pattern = empty;
    let mut fill_geometry = empty;
    let mut stroke_geometry = empty;
    let mut vector_data = nil;
    let mut boolean_operation = nil;
    let mut count = nil;
    let mut star_inner_scale = nil;
    let mut arc_data = nil;
    let mut corner_radius = nil;
    let mut rectangle_top_left_corner_radius = nil;
    let mut rectangle_top_right_corner_radius = nil;
    let mut rectangle_bottom_right_corner_radius = nil;
    let mut rectangle_bottom_left_corner_radius = nil;
    let mut rectangle_corner_radii_independent = nil;
    let mut corner_smoothing = nil;
    let mut frame_mask_disabled = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            RENDER_FIELD_GUID => guid = render_guid(env, decoder)?,
            RENDER_FIELD_NODE_TYPE => {
                node_type = scene_node_type_name(decoder.read_var_uint()?).encode(env)
            }
            RENDER_FIELD_NAME => name = decoder.read_string(env)?,
            RENDER_FIELD_TEXT_DATA => {
                text_data = decode_sparse_text_data_from_decoder(env, decoder)?
            }
            RENDER_FIELD_LINE_HEIGHT => {
                line_height = decode_sparse_number_from_decoder(env, decoder)?
            }
            RENDER_FIELD_LETTER_SPACING => {
                letter_spacing = decode_sparse_number_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_DECORATION => {
                text_decoration = decode_sparse_text_decoration_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_DECORATION_STYLE => {
                text_decoration_style =
                    decode_sparse_text_decoration_style_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_DECORATION_THICKNESS => {
                text_decoration_thickness = decode_sparse_number_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_DECORATION_SKIP_INK => {
                text_decoration_skip_ink = decoder.read_bool()?.encode(env)
            }
            RENDER_FIELD_TEXT_UNDERLINE_OFFSET => {
                text_underline_offset = decode_sparse_number_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_DECORATION_FILL_PAINTS => {
                text_decoration_fill_paints = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_paint_from_decoder,
                )?
            }
            RENDER_FIELD_TEXT_CASE => {
                text_case = decode_sparse_text_case_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_ALIGN_HORIZONTAL => {
                text_align_horizontal =
                    decode_sparse_text_align_horizontal_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_ALIGN_VERTICAL => {
                text_align_vertical = decode_sparse_text_align_vertical_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_AUTO_RESIZE => {
                text_auto_resize = decode_sparse_text_auto_resize_from_decoder(env, decoder)?
            }
            RENDER_FIELD_TEXT_TRUNCATION => {
                text_truncation = decode_sparse_text_truncation_from_decoder(env, decoder)?
            }
            RENDER_FIELD_MAX_LINES => max_lines = decoder.read_var_int()?.encode(env),
            RENDER_FIELD_BLEND_MODE => {
                blend_mode = decode_sparse_blend_mode_from_decoder(env, decoder)?
            }
            RENDER_FIELD_MASK => mask = decoder.read_bool()?.encode(env),
            RENDER_FIELD_MASK_TYPE => {
                mask_type = decode_sparse_mask_type_from_decoder(env, decoder)?
            }
            RENDER_FIELD_EFFECTS => {
                effects = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_effect_from_decoder,
                )?
            }
            RENDER_FIELD_FILL_PAINTS => {
                fill_paints = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_paint_from_decoder,
                )?
            }
            RENDER_FIELD_STROKE_PAINTS => {
                stroke_paints = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_paint_from_decoder,
                )?
            }
            RENDER_FIELD_STROKE_WEIGHT => stroke_weight = decoder.read_var_float(env)?,
            RENDER_FIELD_STROKE_ALIGN => {
                stroke_align = decode_sparse_stroke_align_from_decoder(env, decoder)?
            }
            RENDER_FIELD_STROKE_CAP => {
                stroke_cap = decode_sparse_stroke_cap_from_decoder(env, decoder)?
            }
            RENDER_FIELD_STROKE_CAP_SIZE => {
                stroke_cap_size = decode_sparse_number_from_decoder(env, decoder)?
            }
            RENDER_FIELD_STROKE_JOIN => {
                stroke_join = decode_sparse_stroke_join_from_decoder(env, decoder)?
            }
            RENDER_FIELD_MITER_LIMIT => miter_limit = decoder.read_var_float(env)?,
            RENDER_FIELD_DASH_PATTERN => {
                let len = decoder.read_var_uint()? as usize;
                let mut values = Vec::with_capacity(len);
                for _ in 0..len {
                    values.push(decoder.read_var_float(env)?);
                }
                dash_pattern = values.encode(env);
            }
            RENDER_FIELD_FILL_GEOMETRY => {
                fill_geometry = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_path_from_decoder,
                )?
            }
            RENDER_FIELD_STROKE_GEOMETRY => {
                stroke_geometry = render_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_path_from_decoder,
                )?
            }
            RENDER_FIELD_VECTOR_DATA => {
                vector_data = render_vector_data_from_decoder(env, decoder)?
            }
            RENDER_FIELD_BOOLEAN_OPERATION => {
                boolean_operation = decode_sparse_boolean_operation_from_decoder(env, decoder)?
            }
            RENDER_FIELD_COUNT => count = decoder.read_var_uint()?.encode(env),
            RENDER_FIELD_STAR_INNER_SCALE => star_inner_scale = decoder.read_var_float(env)?,
            RENDER_FIELD_ARC_DATA => {
                arc_data = decode_sparse_arc_data_from_decoder(env, decoder)?
            }
            RENDER_FIELD_CORNER_RADIUS => corner_radius = decoder.read_var_float(env)?,
            RENDER_FIELD_RECTANGLE_TOP_LEFT_CORNER_RADIUS => {
                rectangle_top_left_corner_radius = decoder.read_var_float(env)?
            }
            RENDER_FIELD_RECTANGLE_TOP_RIGHT_CORNER_RADIUS => {
                rectangle_top_right_corner_radius = decoder.read_var_float(env)?
            }
            RENDER_FIELD_RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS => {
                rectangle_bottom_right_corner_radius = decoder.read_var_float(env)?
            }
            RENDER_FIELD_RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS => {
                rectangle_bottom_left_corner_radius = decoder.read_var_float(env)?
            }
            RENDER_FIELD_RECTANGLE_CORNER_RADII_INDEPENDENT => {
                rectangle_corner_radii_independent = decoder.read_bool()?.encode(env)
            }
            RENDER_FIELD_CORNER_SMOOTHING => corner_smoothing = decoder.read_var_float(env)?,
            RENDER_FIELD_FRAME_MASK_DISABLED => {
                frame_mask_disabled = decoder.read_bool()?.encode(env)
            }
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }

    let record = __rq_render_projection_record!();

    Ok(rustler::types::tuple::make_tuple(env, &record))
}

fn document_page_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Term<'a>>> {
    let nil = render_nil(env);
    let mut guid = nil;
    let mut node_type = None;
    let mut name = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            RENDER_FIELD_GUID => guid = render_guid(env, decoder)?,
            RENDER_FIELD_NODE_TYPE => node_type = Some(decoder.read_var_uint()?),
            RENDER_FIELD_NAME => name = decoder.read_string(env)?,
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }

    if node_type == Some(DOCUMENT_NODE_TYPE_CANVAS) {
        Ok(Some(rustler::types::tuple::make_tuple(env, &[guid, name])))
    } else {
        Ok(None)
    }
}

fn document_metadata_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut pages = Vec::new();
    let mut blobs = Vec::<Term<'a>>::new().encode(env);

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            DOCUMENT_FIELD_NODE_CHANGES => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    if let Some(page) = document_page_from_decoder(env, decoder)? {
                        pages.push(page);
                    }
                }
            }
            DOCUMENT_FIELD_BLOBS => {
                blobs = render_repeated_terms(env, decoder, decode_sparse_blob_from_decoder)?
            }
            field => skip_fig_message_field(decoder, field)?,
        }
    }

    Ok(rustler::types::tuple::make_tuple(
        env,
        &[pages.encode(env), blobs],
    ))
}

fn render_projection_nodes_from_slices<'a>(
    env: Env<'a>,
    bytes: &[u8],
    schema: Option<&KiwiRuntimeSchema>,
    metas: &[GraphFocusMeta],
    wanted: Option<&std::collections::HashSet<GraphFocusGuid>>,
) -> NifResult<Term<'a>> {
    let mut records = Vec::new();

    for meta in metas {
        let keep = match wanted {
            Some(wanted) => meta.guid.map(|guid| wanted.contains(&guid)).unwrap_or(false),
            None => meta.guid.is_some(),
        };

        if keep {
            let mut decoder = Decoder::with_schema(&bytes[meta.byte_start..meta.byte_end], schema);
            records.push(render_projection_node_from_decoder(env, &mut decoder)?);
            decoder.finish()?;
        }
    }

    Ok(records.encode(env))
}
