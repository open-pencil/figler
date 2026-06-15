fn __rq_skip_decoder_name(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_uint()?;
    Ok(())
}
