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
    __rq_scene_query_node_fields: (),
}

fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        __rq_node_type_name_arms => unreachable!(),
        _ => "unknown",
    }
}
