__rq_render_projection_field_constants!();

fn render_projection_node_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let nil = graph_seed_nil(env);
    let empty = Vec::<Term<'a>>::new().encode(env);
    let mut guid = nil;
    let mut node_type = nil;
    let mut name = nil;
    let mut fill_paints = empty;
    let mut stroke_paints = empty;
    let mut corner_radius = nil;
    let mut stroke_weight = nil;
    let mut frame_mask_disabled = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            RENDER_FIELD_GUID => guid = graph_seed_guid(env, decoder)?,
            RENDER_FIELD_NODE_TYPE => {
                node_type = scene_node_type_name(decoder.read_var_uint()?).encode(env)
            }
            RENDER_FIELD_NAME => name = decoder.read_string(env)?,
            RENDER_FIELD_FILL_PAINTS => {
                fill_paints = graph_seed_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_paint_from_decoder,
                )?
            }
            RENDER_FIELD_STROKE_PAINTS => {
                stroke_paints = graph_seed_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_paint_from_decoder,
                )?
            }
            RENDER_FIELD_CORNER_RADIUS => corner_radius = decoder.read_var_float(env)?,
            RENDER_FIELD_STROKE_WEIGHT => stroke_weight = decoder.read_var_float(env)?,
            RENDER_FIELD_FRAME_MASK_DISABLED => {
                frame_mask_disabled = decoder.read_bool()?.encode(env)
            }
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }

    let record = [
        guid,
        node_type,
        name,
        fill_paints,
        stroke_paints,
        corner_radius,
        stroke_weight,
        frame_mask_disabled,
    ];

    Ok(rustler::types::tuple::make_tuple(env, &record))
}

fn document_page_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Term<'a>>> {
    let nil = graph_seed_nil(env);
    let mut guid = nil;
    let mut node_type = None;
    let mut name = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            RENDER_FIELD_GUID => guid = graph_seed_guid(env, decoder)?,
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
                blobs = graph_seed_repeated_terms(env, decoder, decode_sparse_blob_from_decoder)?
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
            let mut decoder = Decoder::new(&bytes[meta.byte_start..meta.byte_end]);
            records.push(render_projection_node_from_decoder(env, &mut decoder)?);
            decoder.finish()?;
        }
    }

    Ok(records.encode(env))
}
