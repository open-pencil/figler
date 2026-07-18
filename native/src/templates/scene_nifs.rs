pub fn decode_sparse_message_impl<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

pub fn decode_graph_seed_records_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    stage_flags: u8,
) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = graph_seed_records_from_decoder(env, &mut decoder, stage_flags)?;
    decoder.finish()?;
    Ok(value)
}

pub fn decode_graph_focused_sparse_message_impl<'a>(
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

    let value = graph_focus_sparse_message_from_slices(env, bytes.as_slice(), &metas, &wanted)?;
    Ok(value)
}

pub fn decode_document_metadata_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = document_metadata_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

pub fn decode_render_source_nodes_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    focus: Vec<String>,
) -> NifResult<Term<'a>> {
    let mut index_decoder = Decoder::new(bytes.as_slice());
    let metas = graph_focus_index_message(&mut index_decoder)?;
    index_decoder.finish()?;

    if focus.is_empty() {
        return render_projection_nodes_from_slices(env, bytes.as_slice(), &metas, None);
    }

    let wanted = graph_focus_wanted(&metas, &focus);
    render_projection_nodes_from_slices(env, bytes.as_slice(), &metas, Some(&wanted))
}

pub fn load(env: Env<'_>, _term: Term<'_>) -> bool {
    env.register::<scene_xpath_runtime::SceneIndexResource>().is_ok()
}

pub fn decode_scene_summary_impl<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
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

pub fn build_scene_index_impl(bytes: Binary<'_>) -> NifResult<rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>> {
    scene_xpath_runtime::build_scene_index_value(bytes)
}

pub fn build_scene_index_with_summary_impl(bytes: Binary<'_>) -> NifResult<(rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>, SceneSummary)> {
    scene_xpath_runtime::build_scene_index_with_summary_value(bytes)
}

pub fn query_scene_xpath_impl<'a>(env: Env<'a>, bytes: Binary<'a>, xpath: String) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_value(env, bytes, xpath)
}

pub fn query_scene_xpath_fields_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_fields_value(env, bytes, xpath, fields)
}

pub fn query_scene_index_impl<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_value(env, resource, xpath)
}

pub fn query_scene_index_fields_impl<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_fields_value(env, resource, xpath, fields)
}

__rq_scene_nif_wrappers!();
__rq_scene_navigation_nifs!();
