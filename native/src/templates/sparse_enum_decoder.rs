fn __rq_decoder_name<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        __rq_sparse_enum_arms => unreachable!(),
        value => Ok((value as i64).encode(env)),
    }
}
