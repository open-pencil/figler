#[rustler::nif(schedule = "DirtyCpu")]
pub fn __rq_nif_name(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::__rq_runtime_name(resource)
}
