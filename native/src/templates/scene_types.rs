#[derive(rustler::NifMap)]
pub struct SceneSummary {
    node_count: usize,
    parented_count: usize,
    root_count: usize,
    type_counts: Vec<(String, usize)>,
}

__rq_scene_value_types!();

__rq_scene_query_node!();

fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        __rq_node_type_name_arms => unreachable!(),
        _ => "unknown",
    }
}
