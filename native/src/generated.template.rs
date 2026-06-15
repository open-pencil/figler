#![allow(dead_code)]

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

#[derive(rustler::NifMap)]
pub struct SceneSummary {
    node_count: usize,
    parented_count: usize,
    root_count: usize,
    type_counts: Vec<(String, usize)>,
}

#[derive(Clone, Debug, rustler::NifMap)]
pub struct SceneSize {
    x: f64,
    y: f64,
}

#[derive(Clone, Debug, rustler::NifMap)]
pub struct SceneTransform {
    m00: f64,
    m01: f64,
    m02: f64,
    m10: f64,
    m11: f64,
    m12: f64,
}

#[derive(rustler::NifMap)]
pub struct SceneQueryNode {
    guid: String,
    node_type: String,
    name: Option<String>,
    parent_guid: Option<String>,
    position: Option<String>,
    size: Option<SceneSize>,
    transform: Option<SceneTransform>,
    visible: Option<bool>,
    locked: Option<bool>,
}

fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        __rq_node_type_name_arms => unreachable!(),
        _ => "unknown",
    }
}

__rq_definitions!();
__rq_entrypoints!();
__rq_sparse_decoders!();
__rq_skip_decoders!();
__rq_scene_runtime!();

#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_sparse_message<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

pub fn load(env: Env<'_>, _term: Term<'_>) -> bool {
    env.register::<scene_xpath_runtime::SceneIndexResource>().is_ok()
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_scene_summary<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let mut node_count: usize = 0;
    let mut parented_count: usize = 0;
    let mut type_counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();

    decode_scene_message_from_decoder(&mut decoder, &mut node_count, &mut parented_count, &mut type_counts)?;
    decoder.finish()?;
    let mut type_counts = type_counts.into_iter().collect::<Vec<_>>();
    type_counts.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));

    Ok(SceneSummary {
        node_count,
        parented_count,
        root_count: node_count.saturating_sub(parented_count),
        type_counts,
    }.encode(env))
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn build_scene_index(bytes: Binary<'_>) -> NifResult<rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>> {
    scene_xpath_runtime::build_scene_index_value(bytes)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_xpath<'a>(env: Env<'a>, bytes: Binary<'a>, xpath: String) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_value(env, bytes, xpath)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_index<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_value(env, resource, xpath)
}
