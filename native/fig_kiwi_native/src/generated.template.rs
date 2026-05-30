use rustler::types::atom::Atom;
use rustler::{Binary, Encoder, Env, Error, NifResult, Term};

use std::sync::OnceLock;

use crate::runtime::Decoder;

fn cached_atom(env: Env<'_>, cache: &'static OnceLock<Atom>, name: &str) -> Atom {
    *cache.get_or_init(|| Atom::from_str(env, name).unwrap())
}

fn cached_struct_keys(
    env: Env<'_>,
    cache: &'static OnceLock<Vec<rustler::wrapper::NIF_TERM>>,
    fields: &[&str],
) -> &'static [rustler::wrapper::NIF_TERM] {
    cache.get_or_init(|| {
        let mut keys = Vec::with_capacity(fields.len() + 1);
        keys.push(rustler::types::atom::__struct__().as_c_arg());
        for field in fields {
            keys.push(Atom::from_str(env, field).unwrap().as_c_arg());
        }
        keys
    })
}

fn default_values(module: Atom, len: usize) -> Vec<rustler::wrapper::NIF_TERM> {
    let mut values = vec![rustler::types::atom::nil().as_c_arg(); len + 1];
    values[0] = module.as_c_arg();
    values
}

fn make_struct<'a>(
    env: Env<'a>,
    keys: &[rustler::wrapper::NIF_TERM],
    values: &[rustler::wrapper::NIF_TERM],
) -> NifResult<Term<'a>> {
    unsafe {
        rustler::wrapper::map::make_map_from_arrays(env.as_c_arg(), keys, values)
            .map(|term| Term::new(env, term))
            .ok_or(Error::BadArg)
    }
}

kiwi_codegen::definitions!();
kiwi_codegen::entrypoints!();
