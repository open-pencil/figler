__rq_scene_types!();

__rq_scene_query_node!();

fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        __rq_node_type_name_arms => unreachable!(),
        _ => "unknown",
    }
}
