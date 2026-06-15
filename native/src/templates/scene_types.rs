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
    text: Option<String>,
    font_family: Option<String>,
    font_style: Option<String>,
    font_postscript: Option<String>,
    text_style_guid: Option<String>,
    component_key: Option<String>,
    origin_component_key: Option<String>,
    fill_style_guid: Option<String>,
    stroke_style_guid: Option<String>,
    effect_style_guid: Option<String>,
    grid_style_guid: Option<String>,
    fill_count: Option<usize>,
    stroke_count: Option<usize>,
}

fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        __rq_node_type_name_arms => unreachable!(),
        _ => "unknown",
    }
}
