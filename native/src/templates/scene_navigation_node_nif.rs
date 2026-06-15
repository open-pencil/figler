#[rustler::nif(schedule = "DirtyCpu")]
pub fn __rq_nif_name<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::__rq_runtime_name(env, resource, guid)
}
