macro_rules! fig_scene_skip_field_decoder {
    (
        fn $name:ident;
        decoder $decoder:ident;
        definition $definition_name:literal;
        fields [$($field_id:literal => $field_mode:ident $field_skip:ident;)*]
    ) => {
        fn $name($decoder: &mut Decoder<'_>, field: u32) -> NifResult<()> {
            match field {
                $($field_id => kiwi_skip_kind($decoder, &kiwi_skip_kind!($field_mode $field_skip))?,)*
                field => {
                    return Err(Error::Term(Box::new(format!(
                        "unknown field {} while decoding {}",
                        field,
                        $definition_name
                    ))));
                }
            }
            Ok(())
        }
    };
}

__rq_scene_message_skip_field_decoder!();
__rq_scene_node_skip_field_decoder!();

fn decode_scene_message_from_decoder(
    decoder: &mut Decoder<'_>,
    node_count: &mut usize,
    parented_count: &mut usize,
    type_counts: &mut std::collections::HashMap<String, usize>,
) -> NifResult<()> {
    loop {
        match decoder.read_var_uint()? {
            0 => break,
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
            field => skip_fig_message_field(decoder, field)?,
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
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }
    Ok(())
}
