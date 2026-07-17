fn graph_seed_nil<'a>(env: Env<'a>) -> Term<'a> {
    Atom::from_str(env, "nil").unwrap().encode(env)
}

fn graph_seed_guid<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let session_id = decoder.read_var_uint()?;
    let local_id = decoder.read_var_uint()?;
    Ok((session_id, local_id).encode(env))
}

fn graph_seed_parent_index<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<(Term<'a>, Term<'a>)> {
    let parent_guid = graph_seed_guid(env, decoder)?;
    let position = decoder.read_string(env)?;
    Ok((parent_guid, position))
}

fn graph_seed_count_repeated(
    decoder: &mut Decoder<'_>,
    skip: fn(&mut Decoder<'_>) -> NifResult<()>,
) -> NifResult<usize> {
    let len = decoder.read_var_uint()? as usize;
    for _ in 0..len {
        skip(decoder)?;
    }
    Ok(len)
}

fn graph_seed_repeated_terms<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    decode: KiwiSparseDecodeFn,
) -> NifResult<Term<'a>> {
    let values = decoder.read_repeated(|decoder| decode(env, decoder))?;
    Ok(values.encode(env))
}

fn graph_seed_symbol_data<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<(Term<'a>, Term<'a>)> {
    let nil = graph_seed_nil(env);
    let empty = Vec::<Term<'a>>::new().encode(env);
    let mut symbol_id = nil;
    let mut symbol_overrides = empty;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => symbol_id = graph_seed_guid(env, decoder)?,
            2 => {
                symbol_overrides =
                    graph_seed_repeated_terms(env, decoder, decode_sparse_node_change_from_decoder)?;
            }
            3 => {
                decoder.read_var_float_value()?;
            }
            field => graph_focus_skip_symbol_data_field(decoder, field)?,
        }
    }

    Ok((symbol_id, symbol_overrides))
}

fn graph_seed_node_record<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let nil = graph_seed_nil(env);
    let empty = Vec::<Term<'a>>::new().encode(env);

    let mut guid = nil;
    let mut node_type = nil;
    let mut name = nil;
    let mut parent_guid = nil;
    let mut position = nil;
    let mut size = nil;
    let mut transform = nil;
    let mut visible = nil;
    let mut locked = nil;
    let mut opacity = nil;
    let mut text = nil;
    let mut font_family = nil;
    let font_style = nil;
    let font_postscript = nil;
    let mut font_size = nil;
    let mut text_style_guid = nil;
    let mut component_key = nil;
    let mut origin_component_key = nil;
    let mut fill_style_guid = nil;
    let mut stroke_style_guid = nil;
    let mut effect_style_guid = nil;
    let mut grid_style_guid = nil;
    let mut fill_count = nil;
    let mut stroke_count = nil;
    let mut override_key = nil;
    let mut stack_mode = nil;
    let mut stack_spacing = nil;
    let mut stack_horizontal_padding = nil;
    let mut stack_vertical_padding = nil;
    let mut stack_padding_right = nil;
    let mut stack_padding_bottom = nil;
    let mut symbol_id = nil;
    let mut symbol_overrides = empty;
    let mut component_prop_defs = empty;
    let mut component_prop_refs = empty;
    let mut component_prop_assignments = empty;
    let mut derived_symbol_data = empty;
    let mut variable_consumption = nil;
    let mut variable_data_values = nil;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => guid = graph_seed_guid(env, decoder)?,
            3 => {
                let (next_parent_guid, next_position) = graph_seed_parent_index(env, decoder)?;
                parent_guid = next_parent_guid;
                position = next_position;
            }
            4 => node_type = scene_node_type_name(decoder.read_var_uint()?).encode(env),
            5 => name = decoder.read_string(env)?,
            6 => visible = decoder.read_bool()?.encode(env),
            7 => locked = decoder.read_bool()?.encode(env),
            8 => opacity = decoder.read_var_float(env)?,
            11 => size = decode_sparse_vector_from_decoder(env, decoder)?,
            12 => transform = decode_sparse_matrix_from_decoder(env, decoder)?,
            21 => font_size = decoder.read_var_float(env)?,
            38 => fill_count = graph_seed_count_repeated(decoder, skip_paint_from_decoder)?.encode(env),
            39 => stroke_count = graph_seed_count_repeated(decoder, skip_paint_from_decoder)?.encode(env),
            41 => font_family = decode_sparse_font_name_from_decoder(env, decoder)?,
            42 => text = decode_sparse_text_data_from_decoder(env, decoder)?,
            105 => stack_mode = decode_sparse_stack_mode_from_decoder(env, decoder)?,
            107 => stack_spacing = decoder.read_var_float(env)?,
            113 => {
                let (next_symbol_id, next_symbol_overrides) = graph_seed_symbol_data(env, decoder)?;
                symbol_id = next_symbol_id;
                symbol_overrides = next_symbol_overrides;
            }
            125 => {
                derived_symbol_data =
                    graph_seed_repeated_terms(env, decoder, decode_sparse_node_change_from_decoder)?;
            }
            209 => stack_horizontal_padding = decoder.read_var_float(env)?,
            210 => stack_vertical_padding = decoder.read_var_float(env)?,
            213 => override_key = graph_seed_guid(env, decoder)?,
            233 => stack_padding_right = decoder.read_var_float(env)?,
            234 => stack_padding_bottom = decoder.read_var_float(env)?,
            266 => {
                component_prop_defs =
                    graph_seed_repeated_terms(env, decoder, decode_sparse_component_prop_def_from_decoder)?;
            }
            267 => {
                component_prop_refs =
                    graph_seed_repeated_terms(env, decoder, decode_sparse_component_prop_ref_from_decoder)?;
            }
            268 => {
                component_prop_assignments = graph_seed_repeated_terms(
                    env,
                    decoder,
                    decode_sparse_component_prop_assignment_from_decoder,
                )?;
            }
            307 => variable_consumption = decode_sparse_variable_data_map_from_decoder(env, decoder)?,
            315 => variable_data_values = decode_sparse_variable_data_values_from_decoder(env, decoder)?,
            332 => fill_style_guid = decode_sparse_style_id_from_decoder(env, decoder)?,
            333 => stroke_style_guid = decode_sparse_style_id_from_decoder(env, decoder)?,
            334 => text_style_guid = decode_sparse_style_id_from_decoder(env, decoder)?,
            335 => effect_style_guid = decode_sparse_style_id_from_decoder(env, decoder)?,
            336 => grid_style_guid = decode_sparse_style_id_from_decoder(env, decoder)?,
            216 => component_key = decoder.read_string(env)?,
            252 => origin_component_key = decoder.read_string(env)?,
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }

    let record = __rq_graph_seed_record!();

    Ok(rustler::types::tuple::make_tuple(env, &record))
}

fn graph_seed_records_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut records = Vec::new();

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            4 => {
                let len = decoder.read_var_uint()? as usize;
                records.reserve(len);
                for _ in 0..len {
                    records.push(graph_seed_node_record(env, decoder)?);
                }
            }
            field => skip_fig_message_field(decoder, field)?,
        }
    }

    Ok(records.encode(env))
}
