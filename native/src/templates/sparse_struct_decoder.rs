fn __rq_decoder_name<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    static MODULE_ATOM: OnceLock<Atom> = OnceLock::new();
    static MODULE_KEY_ATOM: OnceLock<Atom> = OnceLock::new();

    let module_atom = cached_atom(env, &MODULE_ATOM, __rq_module_name!());
    let module_key_atom = cached_atom(env, &MODULE_KEY_ATOM, "__kiwi_module__");
    let mut keys = Vec::with_capacity(__rq_capacity!());
    let mut values = Vec::with_capacity(__rq_capacity!());

    keys.push(module_key_atom.encode(env));
    values.push(module_atom.encode(env));

    __rq_sparse_fields!();

    Term::map_from_term_arrays(env, &keys, &values)
}
