fn decode_scene_message_from_decoder(
    decoder: &mut Decoder<'_>,
    node_count: &mut usize,
    parented_count: &mut usize,
    type_counts: &mut std::collections::HashMap<String, usize>,
) -> NifResult<()> {
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            __rq_scene_message_skip_arms => unreachable!(),
            4 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    decode_scene_node_change_from_decoder(
                        decoder,
                        node_count,
                        parented_count,
                        type_counts,
                    )?;
                }
            }
            field => {
                return Err(
                    Error::Term(
                        Box::new(
                            format!(
                                "unknown field {} while decoding scene summary", field
                            ),
                        ),
                    ),
                );
            }
        }
    }
    Ok(())
}
fn decode_scene_node_change_from_decoder(
    decoder: &mut Decoder<'_>,
    node_count: &mut usize,
    parented_count: &mut usize,
    type_counts: &mut std::collections::HashMap<String, usize>,
) -> NifResult<()> {
    *node_count += 1;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => skip_guid_from_decoder(decoder)?,
            3 => {
                skip_parent_index_from_decoder(decoder)?;
                *parented_count += 1;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                let name = scene_node_type_name(value).to_string();
                *type_counts.entry(name).or_insert(0) += 1;
            }
            5 => decoder.skip_string()?,
            6 => {
                decoder.read_bool()?;
            }
            7 => {
                decoder.read_bool()?;
            }
            11 => {
                skip_vector_from_decoder(decoder)?;
            }
            12 => {
                skip_matrix_from_decoder(decoder)?;
            }
            38 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    skip_paint_from_decoder(decoder)?;
                }
            }
            39 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    skip_paint_from_decoder(decoder)?;
                }
            }
            41 => {
                skip_font_name_from_decoder(decoder)?;
            }
            42 => {
                skip_text_data_from_decoder(decoder)?;
            }
            216 => decoder.skip_string()?,
            252 => decoder.skip_string()?,
            332 => {
                skip_style_id_from_decoder(decoder)?;
            }
            333 => {
                skip_style_id_from_decoder(decoder)?;
            }
            334 => {
                skip_style_id_from_decoder(decoder)?;
            }
            335 => {
                skip_style_id_from_decoder(decoder)?;
            }
            336 => {
                skip_style_id_from_decoder(decoder)?;
            }
            __rq_scene_node_skip_arms => unreachable!(),
            field => {
                return Err(
                    Error::Term(
                        Box::new(
                            format!("unknown field {} while decoding scene node", field),
                        ),
                    ),
                );
            }
        }
    }
    Ok(())
}
