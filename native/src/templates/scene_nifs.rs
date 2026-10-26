use crate::runtime::runtime_schema;


pub fn decode_sparse_message_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

/// Decodes the message into native records, then encodes them as `decode_sparse_message_impl`
/// returns it.
pub fn decode_record_message_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let record = kiwi_decode_record(&mut decoder, kiwi_record_definitions::MESSAGE)?;
    decoder.finish()?;
    kiwi_encode_record(env, &record)
}

/// The occurrence tree the native interpreter builds for `root`, encoded for comparison with
/// Elixir's.
pub fn graph_interpret_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
    root: (u32, u32),
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let message = kiwi_decode_record(&mut decoder, kiwi_record_definitions::MESSAGE)?;
    decoder.finish()?;
    graph::encode_interpretation(env, &message, root)
}

/// Every variable resolved natively in each mode of its collection; a parity check.
pub fn graph_resolve_variables_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let message = kiwi_decode_record(&mut decoder, kiwi_record_definitions::MESSAGE)?;
    decoder.finish()?;
    graph::encode_variable_resolution(env, &message)
}

type GraphRef = rustler::ResourceArc<graph::GraphResource>;

/// Builds the effective graph natively, keeping it in a resource, with the microseconds spent
/// decoding, indexing, and interpreting. With `focus`, only those subtrees, their ancestors,
/// and the components they use are decoded.
pub fn graph_new_impl<'a>(
    bytes: Binary<'a>,
    schema: Binary<'a>,
    styles: bool,
    variables: bool,
    focus: Vec<String>,
) -> NifResult<(GraphRef, u64, u64, u64)> {
    let started = std::time::Instant::now();
    let schema = runtime_schema(&schema)?;
    let message = if focus.is_empty() {
        let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
        let message = kiwi_decode_record(&mut decoder, kiwi_record_definitions::MESSAGE)?;
        decoder.finish()?;
        message
    } else {
        let mut index_decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
        let metas = graph_focus_index_message(&mut index_decoder)?;
        index_decoder.finish()?;
        let wanted = graph_focus_wanted(&metas, &focus);
        let mut records = Vec::new();
        for meta in &metas {
            if meta.guid.is_some_and(|guid| wanted.contains(&guid)) {
                let slice = &bytes.as_slice()[meta.byte_start..meta.byte_end];
                let mut decoder = Decoder::with_schema(slice, schema.as_ref());
                records.push(kiwi_decode_record(&mut decoder, kiwi_record_definitions::NODE_CHANGE)?);
                decoder.finish()?;
            }
        }
        KiwiRecord::new(kiwi_record_definitions::MESSAGE)
            .put_records(kiwi_records::Message::NODE_CHANGES, records)
    };
    let decoded = started.elapsed().as_micros() as u64;
    let (graph, indexed, interpreted) = graph::build_graph_resource(&message, styles, variables)?;
    Ok((rustler::ResourceArc::new(graph), decoded, indexed, interpreted))
}

pub fn graph_node_impl<'a>(env: Env<'a>, graph: GraphRef, guid: Term<'a>) -> NifResult<Term<'a>> {
    graph.node(env, guid)
}

pub fn graph_nodes_impl<'a>(env: Env<'a>, graph: GraphRef, guids: Vec<Term<'a>>) -> NifResult<Term<'a>> {
    graph.nodes(env, guids)
}

pub fn graph_node_slice_impl<'a>(
    env: Env<'a>,
    graph: GraphRef,
    offset: usize,
    limit: usize,
) -> NifResult<Term<'a>> {
    graph.node_slice(env, offset, limit)
}

pub fn graph_record_impl<'a>(
    env: Env<'a>,
    graph: GraphRef,
    guid: Term<'a>,
    fields: Option<Vec<String>>,
) -> NifResult<Term<'a>> {
    graph.record(env, guid, fields)
}

pub fn graph_records_impl<'a>(
    env: Env<'a>,
    graph: GraphRef,
    guids: Vec<Term<'a>>,
    fields: Option<Vec<String>>,
) -> NifResult<Term<'a>> {
    graph.records(env, guids, fields)
}

pub fn graph_children_impl<'a>(env: Env<'a>, graph: GraphRef, guid: Term<'a>) -> NifResult<Term<'a>> {
    Ok(graph.children(env, guid))
}

pub fn graph_guids_impl<'a>(env: Env<'a>, graph: GraphRef) -> NifResult<Term<'a>> {
    Ok(graph.all_guids(env))
}

pub fn graph_roots_impl<'a>(env: Env<'a>, graph: GraphRef) -> NifResult<Term<'a>> {
    Ok(graph.roots(env))
}

pub fn graph_of_type_impl<'a>(env: Env<'a>, graph: GraphRef, node_type: String) -> NifResult<Term<'a>> {
    Ok(graph.of_type(env, &node_type))
}

pub fn graph_named_impl<'a>(env: Env<'a>, graph: GraphRef, name: String) -> NifResult<Term<'a>> {
    Ok(graph.named(env, &name))
}

pub fn graph_provenance_impl<'a>(env: Env<'a>, graph: GraphRef, guid: Term<'a>) -> NifResult<Term<'a>> {
    graph.provenance(env, guid)
}

pub fn graph_unresolved_impl<'a>(env: Env<'a>, graph: GraphRef) -> NifResult<Term<'a>> {
    Ok(graph.unresolved(env))
}

pub fn graph_source_impl<'a>(env: Env<'a>, graph: GraphRef, id: (u32, u32)) -> NifResult<Term<'a>> {
    graph.source(env, id)
}

pub fn graph_source_node_impl<'a>(env: Env<'a>, graph: GraphRef, id: (u32, u32)) -> NifResult<Term<'a>> {
    graph.source_node(env, id)
}

pub fn graph_stats_impl<'a>(env: Env<'a>, graph: GraphRef) -> NifResult<Term<'a>> {
    Ok(graph.stats(env))
}

pub fn graph_fields_impl<'a>(env: Env<'a>, graph: GraphRef, only: Vec<String>) -> NifResult<Term<'a>> {
    graph.fields(env, only)
}

pub fn decode_graph_focused_sparse_message_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
    focus: Vec<String>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    if focus.is_empty() {
        let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
        let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
        decoder.finish()?;
        return Ok(value);
    }

    let mut index_decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let metas = graph_focus_index_message(&mut index_decoder)?;
    index_decoder.finish()?;
    let wanted = graph_focus_wanted(&metas, &focus);

    graph_focus_sparse_message_from_slices(env, bytes.as_slice(), schema.as_ref(), &metas, &wanted)
}

pub fn decode_document_metadata_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let value = document_metadata_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}

pub fn decode_render_source_nodes_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
    focus: Vec<String>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut index_decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
    let metas = graph_focus_index_message(&mut index_decoder)?;
    index_decoder.finish()?;

    if focus.is_empty() {
        return render_projection_nodes_from_slices(env, bytes.as_slice(), schema.as_ref(), &metas, None);
    }

    let wanted = graph_focus_wanted(&metas, &focus);
    render_projection_nodes_from_slices(env, bytes.as_slice(), schema.as_ref(), &metas, Some(&wanted))
}

pub fn load(env: Env<'_>, _term: Term<'_>) -> bool {
    env.register::<scene_xpath_runtime::SceneIndexResource>().is_ok()
        && env.register::<graph::GraphResource>().is_ok()
}

pub fn decode_scene_summary_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    let mut decoder = Decoder::with_schema(bytes.as_slice(), schema.as_ref());
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

pub fn build_scene_index_impl<'a>(
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>> {
    let schema = runtime_schema(&schema)?;
    scene_xpath_runtime::build_scene_index_value(bytes, schema.as_ref())
}

pub fn build_scene_index_with_summary_impl<'a>(
    bytes: Binary<'a>,
    schema: Binary<'a>,
) -> NifResult<(rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>, SceneSummary)> {
    let schema = runtime_schema(&schema)?;
    scene_xpath_runtime::build_scene_index_with_summary_value(bytes, schema.as_ref())
}

pub fn query_scene_xpath_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
    xpath: String,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    scene_xpath_runtime::query_scene_xpath_value(env, bytes, schema.as_ref(), xpath)
}

pub fn query_scene_xpath_fields_impl<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    schema: Binary<'a>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    let schema = runtime_schema(&schema)?;
    scene_xpath_runtime::query_scene_xpath_fields_value(env, bytes, schema.as_ref(), xpath, fields)
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
