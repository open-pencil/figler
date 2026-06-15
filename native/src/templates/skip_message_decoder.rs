fn __rq_skip_decoder_name(decoder: &mut Decoder<'_>) -> NifResult<()> {
    let definition_name = __rq_definition_name!();

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            __rq_skip_field_arms => unreachable!(),
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while skipping {}",
                    field, definition_name
                ))));
            }
        }
    }

    Ok(())
}
