#[derive(Clone, Copy, Eq, Hash, PartialEq)]
struct GraphFocusGuid {
    session_id: u32,
    local_id: u32,
}

struct GraphFocusMeta {
    guid: Option<GraphFocusGuid>,
    parent_guid: Option<GraphFocusGuid>,
    symbol_id: Option<GraphFocusGuid>,
    refs: Option<Vec<GraphFocusGuid>>,
    byte_start: usize,
    byte_end: usize,
}

struct GraphFocusSymbolData {
    symbol_id: Option<GraphFocusGuid>,
    refs: Option<Vec<GraphFocusGuid>>,
}

fn graph_focus_skip_symbol_data_field(decoder: &mut Decoder<'_>, field: u32) -> NifResult<()> {
    match field {
        __rq_symbol_skip_field_arms => unreachable!(),
        field => {
            return Err(Error::Term(Box::new(format!(
                "unknown field {} while indexing SymbolData",
                field
            ))));
        }
    }
    Ok(())
}

fn graph_focus_skip_component_prop_assignment_field(
    decoder: &mut Decoder<'_>,
    field: u32,
) -> NifResult<()> {
    match field {
        __rq_prop_assignment_skip_field_arms => unreachable!(),
        field => {
            return Err(Error::Term(Box::new(format!(
                "unknown field {} while indexing ComponentPropAssignment",
                field
            ))));
        }
    }
    Ok(())
}

fn graph_focus_skip_component_prop_value_field(
    decoder: &mut Decoder<'_>,
    field: u32,
) -> NifResult<()> {
    match field {
        __rq_prop_value_skip_field_arms => unreachable!(),
        field => {
            return Err(Error::Term(Box::new(format!(
                "unknown field {} while indexing ComponentPropValue",
                field
            ))));
        }
    }
    Ok(())
}

fn graph_focus_parse_guid(value: &str) -> Option<GraphFocusGuid> {
    let (session_id, local_id) = value.split_once(':')?;
    Some(GraphFocusGuid {
        session_id: session_id.parse().ok()?,
        local_id: local_id.parse().ok()?,
    })
}

fn graph_focus_read_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
    Ok(GraphFocusGuid {
        session_id: decoder.read_var_uint()?,
        local_id: decoder.read_var_uint()?,
    })
}

fn graph_focus_read_parent_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
    let guid = graph_focus_read_guid(decoder)?;
    decoder.skip_string()?;
    Ok(guid)
}

fn graph_focus_push_ref(refs: &mut Option<Vec<GraphFocusGuid>>, guid: GraphFocusGuid) {
    refs.get_or_insert_with(Vec::new).push(guid);
}

fn graph_focus_extend_refs(refs: &mut Option<Vec<GraphFocusGuid>>, next: Option<Vec<GraphFocusGuid>>) {
    if let Some(next) = next {
        refs.get_or_insert_with(Vec::new).extend(next);
    }
}

fn graph_focus_read_symbol_data(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusSymbolData> {
    let mut symbol_id = None;
    let mut refs = None;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                symbol_id = Some(graph_focus_read_guid(decoder)?);
            }
            2 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    let meta = graph_focus_index_node_change(decoder)?;
                    graph_focus_extend_refs(&mut refs, meta.refs);
                }
            }
            field => graph_focus_skip_symbol_data_field(decoder, field)?,
        }
    }

    Ok(GraphFocusSymbolData { symbol_id, refs })
}

fn graph_focus_read_component_prop_value(
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Vec<GraphFocusGuid>>> {
    let mut refs = None;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            __rq_prop_value_arms => unreachable!(),
            field => graph_focus_skip_component_prop_value_field(decoder, field)?,
        }
    }

    Ok(refs)
}

fn graph_focus_read_component_prop_assignment(
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Vec<GraphFocusGuid>>> {
    let mut refs = None;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            __rq_prop_assignment_arms => unreachable!(),
            field => graph_focus_skip_component_prop_assignment_field(decoder, field)?,
        }
    }

    Ok(refs)
}

fn graph_focus_index_node_change(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusMeta> {
    let mut guid = None;
    let mut parent_guid = None;
    let mut symbol_id = None;
    let mut refs = None;

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            __rq_node_focus_arms => unreachable!(),
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }

    Ok(GraphFocusMeta {
        guid,
        parent_guid,
        symbol_id,
        refs,
        byte_start: 0,
        byte_end: 0,
    })
}

fn graph_focus_index_message(decoder: &mut Decoder<'_>) -> NifResult<Vec<GraphFocusMeta>> {
    let mut nodes = Vec::new();

    loop {
        match decoder.read_var_uint()? {
            0 => break,
            4 => {
                let len = decoder.read_var_uint()? as usize;
                nodes.reserve(len);
                for _ in 0..len {
                    let byte_start = decoder.position();
                    let mut meta = graph_focus_index_node_change(decoder)?;
                    meta.byte_start = byte_start;
                    meta.byte_end = decoder.position();
                    nodes.push(meta);
                }
            }
            field => skip_fig_message_field(decoder, field)?,
        }
    }

    Ok(nodes)
}

fn graph_focus_collect_subtree(
    wanted: &mut std::collections::HashSet<GraphFocusGuid>,
    guid: GraphFocusGuid,
    by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
    children: &std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>>,
) {
    if !by_guid.contains_key(&guid) || !wanted.insert(guid) {
        return;
    }

    if let Some(child_guids) = children.get(&guid) {
        for child_guid in child_guids {
            graph_focus_collect_subtree(wanted, *child_guid, by_guid, children);
        }
    }
}

fn graph_focus_collect_ancestors(
    wanted: &mut std::collections::HashSet<GraphFocusGuid>,
    guid: GraphFocusGuid,
    metas: &[GraphFocusMeta],
    by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
) {
    let mut current = guid;

    while let Some(index) = by_guid.get(&current) {
        let Some(parent_guid) = metas[*index].parent_guid else {
            break;
        };
        wanted.insert(parent_guid);
        current = parent_guid;
    }
}

fn graph_focus_wanted(
    metas: &[GraphFocusMeta],
    focus: &[String],
) -> std::collections::HashSet<GraphFocusGuid> {
    let mut by_guid = std::collections::HashMap::new();
    let mut children: std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>> =
        std::collections::HashMap::new();

    for (index, meta) in metas.iter().enumerate() {
        if let Some(guid) = meta.guid {
            by_guid.insert(guid, index);
            if let Some(parent_guid) = meta.parent_guid {
                children.entry(parent_guid).or_default().push(guid);
            }
        }
    }

    let mut wanted = std::collections::HashSet::new();

    for guid in focus.iter().filter_map(|value| graph_focus_parse_guid(value)) {
        graph_focus_collect_subtree(&mut wanted, guid, &by_guid, &children);
    }

    loop {
        let before = wanted.len();
        let current = wanted.iter().copied().collect::<Vec<_>>();

        for guid in current {
            if let Some(index) = by_guid.get(&guid) {
                if let Some(symbol_id) = metas[*index].symbol_id {
                    graph_focus_collect_subtree(&mut wanted, symbol_id, &by_guid, &children);
                }

                if let Some(refs) = &metas[*index].refs {
                    for ref_id in refs {
                        graph_focus_collect_subtree(&mut wanted, *ref_id, &by_guid, &children);
                    }
                }
            }
        }

        if wanted.len() == before {
            break;
        }
    }

    let current = wanted.iter().copied().collect::<Vec<_>>();
    for guid in current {
        graph_focus_collect_ancestors(&mut wanted, guid, metas, &by_guid);
    }

    wanted
}

fn graph_focus_sparse_message_from_slices<'a>(
    env: Env<'a>,
    bytes: &[u8],
    metas: &[GraphFocusMeta],
    wanted: &std::collections::HashSet<GraphFocusGuid>,
) -> NifResult<Term<'a>> {
    static NODE_CHANGES_ATOM: OnceLock<Atom> = OnceLock::new();
    let node_changes_atom = cached_atom(env, &NODE_CHANGES_ATOM, "node_changes");
    let mut node_changes = Vec::new();

    for meta in metas {
        let keep = meta
            .guid
            .map(|guid| wanted.contains(&guid))
            .unwrap_or(false);
        if keep {
            let mut decoder = Decoder::new(&bytes[meta.byte_start..meta.byte_end]);
            node_changes.push(decode_sparse_node_change_from_decoder(env, &mut decoder)?);
            decoder.finish()?;
        }
    }

    Term::map_from_term_arrays(
        env,
        &[node_changes_atom.encode(env)],
        &[node_changes.encode(env)],
    )
}
