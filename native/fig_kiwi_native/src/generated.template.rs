use rustler::types::atom::Atom;
use rustler::{Binary, Encoder, Env, Error, NifResult, Term};

use std::sync::OnceLock;

use crate::runtime::Decoder;

fn cached_atom(env: Env<'_>, cache: &'static OnceLock<Atom>, name: &str) -> Atom {
    *cache.get_or_init(|| Atom::from_str(env, name).unwrap())
}

fn cached_atoms(env: Env<'_>, cache: &'static OnceLock<Vec<Atom>>, names: &[&str]) -> &'static [Atom] {
    cache.get_or_init(|| names.iter().map(|name| Atom::from_str(env, name).unwrap()).collect())
}

fn default_values<'a>(env: Env<'a>, len: usize) -> Vec<Term<'a>> {
    vec![rustler::types::atom::nil().encode(env); len]
}

fn make_struct<'a>(
    env: Env<'a>,
    module: Atom,
    fields: &[Atom],
    field_values: &[Term<'a>],
) -> NifResult<Term<'a>> {
    let mut keys = Vec::with_capacity(fields.len() + 1);
    let mut values = Vec::with_capacity(fields.len() + 1);

    keys.push(rustler::types::atom::__struct__().encode(env));
    values.push(module.encode(env));

    for (field, value) in fields.iter().zip(field_values) {
        keys.push(field.encode(env));
        values.push(*value);
    }

    Term::map_from_term_arrays(env, &keys, &values)
}

kiwi_codegen::definitions!();
kiwi_codegen::entrypoints!();
