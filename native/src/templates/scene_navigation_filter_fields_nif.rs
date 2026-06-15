#[rustler::nif(schedule = "DirtyCpu")]
pub fn __rq_nif_name<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    value: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::__rq_runtime_name(env, resource, value, fields)
}
