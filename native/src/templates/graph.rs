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
    use std::collections::{HashMap, HashSet};

    __rq_graph_records!();
    __rq_graph_prepare!();
    __rq_graph_source_index!();
    __rq_graph_occurrence!();
    __rq_graph_claims!();
    __rq_graph_bindings!();
    __rq_graph_layer!();
    __rq_graph_geometry!();
    __rq_graph_interpreter!();

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
}
