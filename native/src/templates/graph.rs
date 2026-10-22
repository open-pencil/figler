/// The native occurrence interpreter: source records and the effective graph built from them.
// Generated from Rusty-Elixir, which writes closures that pass functions their arguments,
// keeps references explicit, matches where `matches!` would do, and sorts by comparison.
#[allow(
    clippy::redundant_closure,
    clippy::needless_borrow,
    clippy::manual_map,
    clippy::useless_vec,
    clippy::match_like_matches_macro,
    clippy::unnecessary_sort_by
)]
pub mod graph {
    use super::*;
    use std::collections::{BTreeMap, HashMap, HashSet};

    __rq_graph_records!();
    __rq_graph_prepare!();
    __rq_graph_source_index!();
    __rq_graph_occurrence!();
    __rq_graph_claims!();
    __rq_graph_bindings!();
    __rq_graph_layer!();
    __rq_graph_geometry!();
    __rq_graph_interpreter!();
    __rq_graph_variables!();
    __rq_graph_variable_bindings!();
    __rq_graph_materialize!();

    /// Encodes the source index of `message` as Elixir's `SourceIndex` holds it: records by
    /// GUID tuple, and each parent's child GUIDs in saved order.
    pub fn encode_source_index<'a>(env: Env<'a>, message: &KiwiRecord) -> NifResult<Term<'a>> {
        let index = source_index(message, true)?;

        let mut source_keys = Vec::with_capacity(index.sources.len());
        let mut source_values = Vec::with_capacity(index.sources.len());
        for (id, record) in &index.sources {
            source_keys.push(id.encode(env));
            source_values.push(kiwi_encode_record(env, record)?);
        }

        let (child_keys, child_values): (Vec<_>, Vec<_>) = index
            .children
            .iter()
            .map(|(parent, ids)| (parent.encode(env), ids.encode(env)))
            .unzip();

        Ok((
            Term::map_from_term_arrays(env, &source_keys, &source_values)?,
            Term::map_from_term_arrays(env, &child_keys, &child_values)?,
        )
            .encode(env))
    }

    /// Interprets `root` from the records of `message` and encodes the occurrence tree and
    /// diagnostics as plain maps, for comparison with Elixir's interpreter.
    pub fn encode_interpretation<'a>(
        env: Env<'a>,
        message: &KiwiRecord,
        root: GuidKey,
    ) -> NifResult<Term<'a>> {
        let index = source_index(message, true)?;
        let (occurrence, diagnostics) = interpret(&index, root)?;
        let diagnostics = diagnostics
            .iter()
            .map(|diagnostic| encode_diagnostic(env, diagnostic))
            .collect::<Vec<_>>();
        Ok((encode_occurrence(env, &occurrence)?, diagnostics).encode(env))
    }

    fn encode_occurrence<'a>(env: Env<'a>, occurrence: &Occurrence) -> NifResult<Term<'a>> {
        let children = occurrence
            .children
            .iter()
            .map(|child| encode_occurrence(env, child))
            .collect::<NifResult<Vec<_>>>()?;
        let property_claims = occurrence
            .property_claims
            .iter()
            .map(|claim| {
                Ok(map(
                    env,
                    &[
                        ("declared_by", claim.declared_by.encode(env)),
                        ("path", claim.path.encode(env)),
                        ("properties", kiwi_encode_record(env, &claim.properties)?),
                    ],
                ))
            })
            .collect::<NifResult<Vec<_>>>()?;
        let binding_claims = occurrence
            .binding_claims
            .iter()
            .map(|claim| {
                map(
                    env,
                    &[
                        ("definition_id", claim.definition_id.encode(env)),
                        ("field", atom(env, bound_field_name(&claim.field))),
                        (
                            "origin",
                            atom(env, match claim.origin {
                                Origin::Default => "default",
                                Origin::Assignment => "assignment",
                            }),
                        ),
                    ],
                )
            })
            .collect::<Vec<_>>();
        let (bound_keys, bound_values): (Vec<_>, Vec<_>) = occurrence
            .bound_fields
            .iter()
            .map(|(field, rank)| (atom(env, node_change_field(*field)), rank.encode(env)))
            .unzip();
        let overridden = occurrence
            .overridden
            .iter()
            .map(|field| atom(env, node_change_field(*field)))
            .collect::<Vec<_>>();
        let derived_size = match &occurrence.derived_size {
            Some(size) => kiwi_encode_record(env, size)?,
            None => atom(env, "nil"),
        };

        Ok(map(
            env,
            &[
                ("source_id", occurrence.source_id.encode(env)),
                ("override_key", occurrence.override_key.encode(env)),
                ("main_component_id", occurrence.main_component_id.encode(env)),
                ("main_component_override_key", occurrence.main_component_override_key.encode(env)),
                ("source_component_id", occurrence.source_component_id.encode(env)),
                (
                    "source_component_override_key",
                    occurrence.source_component_override_key.encode(env),
                ),
                ("derived_size", derived_size),
                ("slot_content_id", occurrence.slot_content_id.encode(env)),
                ("default_instance_name", occurrence.default_instance_name.encode(env)),
                ("properties", kiwi_encode_record(env, &occurrence.properties)?),
                ("children", children.encode(env)),
                ("property_claims", property_claims.encode(env)),
                ("binding_claims", binding_claims.encode(env)),
                ("layout_scale", occurrence.layout_scale.encode(env)),
                ("has_own_name", occurrence.has_own_name.encode(env)),
                ("bound_fields", Term::map_from_term_arrays(env, &bound_keys, &bound_values)?),
                ("replaced_components", occurrence.replaced_components.encode(env)),
                ("overridden", overridden.encode(env)),
            ],
        ))
    }

    fn encode_diagnostic<'a>(env: Env<'a>, diagnostic: &Diagnostic) -> Term<'a> {
        let reason = match diagnostic.reason {
            Some(TargetReason::MissingTarget) => atom(env, "missing_target"),
            Some(TargetReason::AmbiguousTarget) => atom(env, "ambiguous_target"),
            None => atom(env, "nil"),
        };
        let owner = diagnostic.owner.encode(env);
        let component = diagnostic.component.encode(env);
        let path = diagnostic.path.encode(env);

        match diagnostic.kind {
            DiagnosticKind::UnresolvedProperty => {
                (atom(env, "unresolved_property"), owner, component, path, reason).encode(env)
            }
            DiagnosticKind::UnresolvedAssignment => {
                (atom(env, "unresolved_assignment"), owner, component, path, reason).encode(env)
            }
            DiagnosticKind::MissingComponent => {
                (atom(env, "missing_component"), owner, component).encode(env)
            }
            DiagnosticKind::MissingSlotContent => {
                (atom(env, "missing_slot_content"), owner, component).encode(env)
            }
        }
    }

    fn bound_field_name(field: &BoundField) -> &'static str {
        match field {
            BoundField::Visible => "visible",
            BoundField::TextData => "text_data",
            BoundField::SymbolData => "symbol_data",
            BoundField::SlotContent => "slot_content",
        }
    }

    fn node_change_field(field: u32) -> &'static str {
        let fields = KIWI_RECORD_DEFINITIONS[kiwi_record_definitions::NODE_CHANGE as usize].fields;
        fields
            .binary_search_by_key(&field, |candidate| candidate.id)
            .map(|position| fields[position].name)
            .unwrap_or("unknown")
    }

    fn atom<'a>(env: Env<'a>, name: &str) -> Term<'a> {
        Atom::from_str(env, name).expect("atom").encode(env)
    }

    fn map<'a>(env: Env<'a>, entries: &[(&str, Term<'a>)]) -> Term<'a> {
        let keys = entries.iter().map(|(key, _)| atom(env, key)).collect::<Vec<_>>();
        let values = entries.iter().map(|(_, value)| *value).collect::<Vec<_>>();
        Term::map_from_term_arrays(env, &keys, &values).expect("unique keys")
    }

    /// Times indexing and interpreting every page, for benchmarks: microseconds to index, to
    /// interpret, and the occurrences built.
    pub fn time_interpretation(message: &KiwiRecord) -> NifResult<(u64, u64, usize)> {
        let started = std::time::Instant::now();
        let index = source_index(message, true)?;
        let indexed = started.elapsed().as_micros() as u64;

        let mut roots: Vec<GuidKey> = index
            .sources
            .iter()
            .filter(|(_, record)| parent_id(record).is_none_or(|parent| !index.sources.contains_key(&parent)))
            .map(|(id, _)| *id)
            .collect();
        roots.sort();
        let pages: Vec<GuidKey> = roots
            .iter()
            .flat_map(|id| {
                if node_type(&index, *id) == Some(kiwi_records::node_type::DOCUMENT) {
                    children_of(&index, *id).to_vec()
                } else {
                    vec![*id]
                }
            })
            .collect();

        let started = std::time::Instant::now();
        let mut occurrences = 0;
        for page in pages {
            let (occurrence, _diagnostics) = interpret(&index, page)?;
            occurrences += count(&occurrence);
        }
        Ok((indexed, started.elapsed().as_micros() as u64, occurrences))
    }

    fn count(occurrence: &Occurrence) -> usize {
        1 + occurrence.children.iter().map(count).sum::<usize>()
    }

    /// Resolves every variable in each mode of its collection, with the unsupported
    /// expressions reported, for comparison with Elixir's `Variables`.
    pub fn encode_variable_resolution<'a>(env: Env<'a>, message: &KiwiRecord) -> NifResult<Term<'a>> {
        let index = source_index(message, true)?;
        let vars = new_variables(&index.sources);
        let mut resolved = Vec::new();
        for (id, variable) in &vars.variables {
            let collection = &vars.collections[&variable.collection];
            for mode in &collection.modes {
                let modes = HashMap::from([(variable.collection, *mode)]);
                let value = match resolve_variable(&vars, *id, &modes) {
                    Some(value) => encode_variable_value(env, &value),
                    None => atom(env, "nil"),
                };
                resolved.push((*id, *mode, value).encode(env));
            }
        }
        let diagnostics = vars
            .diagnostics
            .iter()
            .map(|diagnostic| {
                (atom(env, "unsupported_variable_expression"), diagnostic.variable, diagnostic.mode).encode(env)
            })
            .collect::<Vec<_>>();
        Ok((resolved, diagnostics).encode(env))
    }

    fn encode_variable_value<'a>(env: Env<'a>, value: &VariableValue) -> Term<'a> {
        match value {
            VariableValue::Float(number) => number.encode(env),
            VariableValue::Boolean(flag) => flag.encode(env),
            VariableValue::String(text) => text.encode(env),
            VariableValue::Color(color) => map(
                env,
                &[
                    ("r", color.r.encode(env)),
                    ("g", color.g.encode(env)),
                    ("b", color.b.encode(env)),
                    ("a", color.a.encode(env)),
                ],
            ),
        }
    }

    /// Builds the effective graph of `message` and encodes the fields `Figler.Scene.Graph`
    /// holds: nodes, records, children, roots, indexes by type and name, provenance, and the
    /// unresolved overrides.
    pub fn encode_graph_fields<'a>(
        env: Env<'a>,
        message: &KiwiRecord,
        styles: bool,
        variables: bool,
    ) -> NifResult<Term<'a>> {
        let index = source_index(message, styles)?;
        let vars = variables.then(|| new_variables(&index.sources));
        let graph = build_graph(&index, vars.as_ref())?;

        let mut node_keys = Vec::with_capacity(graph.nodes.len());
        let mut node_values = Vec::with_capacity(graph.nodes.len());
        let mut record_values = Vec::with_capacity(graph.nodes.len());
        let mut child_keys = Vec::new();
        let mut child_values = Vec::new();
        let mut provenance_keys = Vec::new();
        let mut provenance_values = Vec::new();
        let mut by_type: Vec<(&str, Vec<Term<'a>>)> = Vec::new();
        let mut type_positions: HashMap<&str, usize> = HashMap::new();
        let mut by_name: Vec<(&str, Vec<Term<'a>>)> = Vec::new();
        let mut name_positions: HashMap<&str, usize> = HashMap::new();

        for node in &graph.nodes {
            let guid = encode_graph_guid(env, &node.guid);
            let node_type = enum_name(node.record.get(kiwi_records::node_change::TYPE));
            let name = node.record.str(kiwi_records::node_change::NAME);

            node_keys.push(guid);
            node_values.push(encode_scene_node(env, node, guid)?);
            record_values.push(kiwi_encode_record(env, &node.record)?);

            if !node.children.is_empty() {
                child_keys.push(guid);
                child_values.push(
                    node.children
                        .iter()
                        .map(|child| encode_graph_guid(env, &graph.nodes[*child].guid))
                        .collect::<Vec<_>>()
                        .encode(env),
                );
            }
            if let Some(provenance) = &node.provenance {
                provenance_keys.push(guid);
                provenance_values.push(encode_provenance(env, provenance)?);
            }
            if let Some(node_type) = node_type {
                let position = *type_positions.entry(node_type).or_insert_with(|| {
                    by_type.push((node_type, Vec::new()));
                    by_type.len() - 1
                });
                by_type[position].1.push(guid);
            }
            if let Some(name) = name {
                let position = *name_positions.entry(name).or_insert_with(|| {
                    by_name.push((name, Vec::new()));
                    by_name.len() - 1
                });
                by_name[position].1.push(guid);
            }
        }

        let (type_keys, type_values): (Vec<_>, Vec<_>) =
            by_type.into_iter().map(|(key, guids)| (key.encode(env), guids.encode(env))).unzip();
        let (name_keys, name_values): (Vec<_>, Vec<_>) =
            by_name.into_iter().map(|(key, guids)| (key.encode(env), guids.encode(env))).unzip();
        let unresolved = graph
            .unresolved
            .iter()
            .map(|entry| match entry {
                Unresolved::Variable(diagnostic) => {
                    (atom(env, "unsupported_variable_expression"), diagnostic.variable, diagnostic.mode)
                        .encode(env)
                }
                Unresolved::Occurrence(diagnostic) => encode_diagnostic(env, diagnostic),
            })
            .collect::<Vec<_>>();

        Ok(map(
            env,
            &[
                ("nodes", Term::map_from_term_arrays(env, &node_keys, &node_values)?),
                ("records", Term::map_from_term_arrays(env, &node_keys, &record_values)?),
                ("children", Term::map_from_term_arrays(env, &child_keys, &child_values)?),
                ("roots", graph.roots.encode(env)),
                ("by_type", Term::map_from_term_arrays(env, &type_keys, &type_values)?),
                ("by_name", Term::map_from_term_arrays(env, &name_keys, &name_values)?),
                ("provenance", Term::map_from_term_arrays(env, &provenance_keys, &provenance_values)?),
                ("unresolved", unresolved.encode(env)),
            ],
        ))
    }

    /// A graph GUID as Elixir's graph holds it: `{session, local}` for a source record, and
    /// `{:clone, root, path}` for a layer of an instance expansion, its path nested to the
    /// left: `[a]`, `{[a], b}`, `{{[a], b}, c}`.
    fn encode_graph_guid<'a>(env: Env<'a>, guid: &GraphGuid) -> Term<'a> {
        match guid {
            GraphGuid::Source(id) => id.encode(env),
            GraphGuid::Clone(clone) => {
                let mut path = vec![clone.path[0]].encode(env);
                for segment in &clone.path[1..] {
                    path = (path, *segment).encode(env);
                }
                (atom(env, "clone"), clone.root, path).encode(env)
            }
        }
    }

    fn encode_scene_node<'a>(env: Env<'a>, node: &GraphNode, guid: Term<'a>) -> NifResult<Term<'a>> {
        use kiwi_records::node_change as field;
        let record = &node.record;
        let nil = atom(env, "nil");
        let text = record.record(field::TEXT_DATA).and_then(|text| text.str(kiwi_records::text_data::CHARACTERS));
        let font = record.record(field::FONT_NAME);
        let font_field = |name: u32| font.and_then(|font| font.str(name)).map_or(nil, |value| value.encode(env));
        let float = |name: u32| record.float(name).map_or(nil, |value| kiwi_encode_float(env, value));
        let flag = |name: u32| record.bool(name).map_or(nil, |value| value.encode(env));
        let string = |name: u32| record.str(name).map_or(nil, |value| value.encode(env));
        let count = |name: u32| match record.get(name) {
            Some(KiwiValue::Array(values)) => values.len().encode(env),
            _ => nil,
        };
        let style = |name: u32| {
            record
                .record(name)
                .and_then(|style| guid_key(style.record(kiwi_records::style_id::GUID)))
                .map_or(nil, |(session, local)| format!("{session}:{local}").encode(env))
        };
        let size = record.record(field::SIZE).and_then(|size| {
            Some(map(
                env,
                &[
                    ("x", kiwi_encode_float(env, size.float(kiwi_records::vector::X)?)),
                    ("y", kiwi_encode_float(env, size.float(kiwi_records::vector::Y)?)),
                ],
            ))
        });
        let transform = record.record(field::TRANSFORM).and_then(|matrix| {
            use kiwi_records::matrix as m;
            let entry = |name: &'static str, id: u32| Some((name, kiwi_encode_float(env, matrix.float(id)?)));
            Some(map(
                env,
                &[
                    entry("m00", m::M00)?,
                    entry("m01", m::M01)?,
                    entry("m02", m::M02)?,
                    entry("m10", m::M10)?,
                    entry("m11", m::M11)?,
                    entry("m12", m::M12)?,
                ],
            ))
        });
        let position = record
            .record(field::PARENT_INDEX)
            .and_then(|parent| parent.str(kiwi_records::parent_index::POSITION))
            .map_or(nil, |value| value.encode(env));
        let parent = node.parent.as_ref().map_or(nil, |parent| encode_graph_guid(env, parent));
        let node_type = enum_name(record.get(field::TYPE)).map_or(nil, |name| name.encode(env));

        Ok(map(
            env,
            &[
                ("__struct__", atom(env, "Elixir.Figler.Scene.Node")),
                ("guid", guid),
                ("node_type", node_type),
                ("name", string(field::NAME)),
                ("parent_guid", parent),
                ("position", position),
                ("size", size.unwrap_or(nil)),
                ("transform", transform.unwrap_or(nil)),
                ("visible", flag(field::VISIBLE)),
                ("locked", flag(field::LOCKED)),
                ("opacity", float(field::OPACITY)),
                ("text", text.map_or(nil, |text| text.encode(env))),
                ("font_family", font_field(kiwi_records::font_name::FAMILY)),
                ("font_style", font_field(kiwi_records::font_name::STYLE)),
                ("font_postscript", font_field(kiwi_records::font_name::POSTSCRIPT)),
                ("font_size", float(field::FONT_SIZE)),
                ("text_style_guid", style(field::STYLE_ID_FOR_TEXT)),
                ("component_key", string(field::COMPONENT_KEY)),
                ("origin_component_key", string(field::ORIGIN_COMPONENT_KEY)),
                ("fill_style_guid", style(field::STYLE_ID_FOR_FILL)),
                ("stroke_style_guid", style(field::STYLE_ID_FOR_STROKE_FILL)),
                ("effect_style_guid", style(field::STYLE_ID_FOR_EFFECT)),
                ("grid_style_guid", style(field::STYLE_ID_FOR_GRID)),
                ("fill_count", count(field::FILL_PAINTS)),
                ("stroke_count", count(field::STROKE_PAINTS)),
                ("children", nil),
            ],
        ))
    }

    fn encode_provenance<'a>(env: Env<'a>, provenance: &Provenance) -> NifResult<Term<'a>> {
        let nil = atom(env, "nil");
        let applied = provenance
            .applied
            .iter()
            .map(|claim| {
                let mut fields = claim
                    .properties
                    .field_ids()
                    .into_iter()
                    .map(node_change_field)
                    .collect::<Vec<_>>();
                fields.sort_unstable();
                map(
                    env,
                    &[
                        ("declared_by", claim.declared_by.encode(env)),
                        ("path", claim.path.encode(env)),
                        ("fields", fields.iter().map(|field| atom(env, field)).collect::<Vec<_>>().encode(env)),
                    ],
                )
            })
            .collect::<Vec<_>>();
        let bindings = provenance
            .bindings
            .iter()
            .map(|claim| {
                map(
                    env,
                    &[
                        ("definition_id", claim.definition_id.encode(env)),
                        ("field", atom(env, bound_field_name(&claim.field))),
                        (
                            "origin",
                            atom(env, match claim.origin {
                                Origin::Default => "default",
                                Origin::Assignment => "assignment",
                            }),
                        ),
                    ],
                )
            })
            .collect::<Vec<_>>();

        Ok(map(
            env,
            &[
                ("source", atom(env, if provenance.clone { "instance_clone" } else { "source" })),
                ("source_guid", provenance.source_guid.encode(env)),
                (
                    "instance_guid",
                    provenance.instance_guid.as_ref().map_or(nil, |guid| encode_graph_guid(env, guid)),
                ),
                ("component_guid", provenance.component_guid.encode(env)),
                ("applied", applied.encode(env)),
                ("bindings", bindings.encode(env)),
                ("unresolved", Vec::<Term<'a>>::new().encode(env)),
            ],
        ))
    }

    /// The variant name of an enum value, as a decoded record's atom spells it.
    fn enum_name(value: Option<&KiwiValue>) -> Option<&'static str> {
        match value {
            Some(KiwiValue::Enum(value, definition)) => {
                let variants = KIWI_RECORD_DEFINITIONS[*definition as usize].variants;
                variants
                    .binary_search_by_key(value, |variant| variant.value)
                    .ok()
                    .map(|index| variants[index].name)
            }
            _ => None,
        }
    }
}
