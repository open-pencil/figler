#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_sparse_message<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_graph_focused_sparse_message<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    focus: Vec<String>,
) -> NifResult<Term<'a>> {
    if focus.is_empty() {
        let mut decoder = Decoder::new(bytes.as_slice());
        let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
        decoder.finish()?;
        return Ok(value);
    }

    let mut index_decoder = Decoder::new(bytes.as_slice());
    let metas = graph_focus_index_message(&mut index_decoder)?;
    index_decoder.finish()?;
    let wanted = graph_focus_wanted(&metas, &focus);

    let mut decoder = Decoder::new(bytes.as_slice());
    let value = graph_focus_sparse_message_from_decoder(env, &mut decoder, &metas, &wanted)?;
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
pub fn build_scene_index_with_summary(bytes: Binary<'_>) -> NifResult<(rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>, SceneSummary)> {
    scene_xpath_runtime::build_scene_index_with_summary_value(bytes)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_xpath<'a>(env: Env<'a>, bytes: Binary<'a>, xpath: String) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_value(env, bytes, xpath)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_xpath_fields<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_fields_value(env, bytes, xpath, fields)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_index<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_value(env, resource, xpath)
}

#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_index_fields<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_fields_value(env, resource, xpath, fields)
}

__rq_scene_navigation_nifs!();
