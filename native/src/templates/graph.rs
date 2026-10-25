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

    /// An effective graph held natively, with its source records and the indexes
    /// `Figler.Scene.Graph` reads by type and name.
    pub struct GraphResource {
        graph: Graph,
        sources: Sources,
        by_type: HashMap<&'static str, Vec<usize>>,
        by_name: HashMap<String, Vec<usize>>,
    }

    impl rustler::Resource for GraphResource {}

    /// Builds the effective graph of `message`, with the microseconds spent indexing and
    /// interpreting.
    pub fn build_graph_resource(
        message: &KiwiRecord,
        styles: bool,
        variables: bool,
    ) -> NifResult<(GraphResource, u64, u64)> {
        let started = std::time::Instant::now();
        let index = source_index(message, styles)?;
        let indexed = started.elapsed().as_micros() as u64;

        let started = std::time::Instant::now();
        let vars = variables.then(|| new_variables(&index.sources));
        let graph = build_graph(&index, vars.as_ref())?;
        let mut by_type: HashMap<&'static str, Vec<usize>> = HashMap::new();
        let mut by_name: HashMap<String, Vec<usize>> = HashMap::new();
        for (position, node) in graph.nodes.iter().enumerate() {
            if let Some(node_type) = enum_name(node.record.get(kiwi_records::NodeChange::TYPE)) {
                by_type.entry(node_type).or_default().push(position);
            }
            if let Some(name) = node.record.str(kiwi_records::NodeChange::NAME) {
                by_name.entry(name.to_string()).or_default().push(position);
            }
        }
        let interpreted = started.elapsed().as_micros() as u64;

        Ok((GraphResource { graph, sources: index.sources, by_type, by_name }, indexed, interpreted))
    }

    /// Reads a graph GUID as Elixir's graph holds it.
    pub fn decode_graph_guid(term: Term<'_>) -> NifResult<GraphGuid> {
        if let Ok(id) = term.decode::<GuidKey>() {
            return Ok(GraphGuid::Source(id));
        }
        let (tag, root, path): (Atom, GuidKey, Term<'_>) = term.decode()?;
        if tag != Atom::from_str(term.get_env(), "clone")? {
            return Err(Error::BadArg);
        }
        let mut segments = Vec::new();
        decode_clone_path(path, &mut segments)?;
        Ok(GraphGuid::Clone(CloneGuid { root, path: segments }))
    }

    fn decode_clone_path(term: Term<'_>, segments: &mut Vec<GuidKey>) -> NifResult<()> {
        if let Ok(list) = term.decode::<Vec<GuidKey>>() {
            segments.extend(list);
            return Ok(());
        }
        let (prefix, segment): (Term<'_>, GuidKey) = term.decode()?;
        decode_clone_path(prefix, segments)?;
        segments.push(segment);
        Ok(())
    }

    impl GraphResource {
        fn position(&self, guid: Term<'_>) -> Option<usize> {
            decode_graph_guid(guid).ok().and_then(|guid| self.graph.positions.get(&guid).copied())
        }

        fn guid<'a>(&self, env: Env<'a>, position: usize) -> Term<'a> {
            encode_graph_guid(env, &self.graph.nodes[position].guid)
        }

        fn guids<'a>(&self, env: Env<'a>, positions: &[usize]) -> Term<'a> {
            positions.iter().map(|position| self.guid(env, *position)).collect::<Vec<_>>().encode(env)
        }

        /// The scene node at a GUID, or `nil`.
        pub fn node<'a>(&self, env: Env<'a>, guid: Term<'a>) -> NifResult<Term<'a>> {
            match self.position(guid) {
                Some(position) => self.node_at(env, position),
                None => Ok(atom(env, "nil")),
            }
        }

        fn node_at<'a>(&self, env: Env<'a>, position: usize) -> NifResult<Term<'a>> {
            encode_scene_node(env, &self.graph.nodes[position], self.guid(env, position))
        }

        /// The scene nodes at GUIDs, leaving out those the graph lacks.
        pub fn nodes<'a>(&self, env: Env<'a>, guids: Vec<Term<'a>>) -> NifResult<Term<'a>> {
            let nodes = guids
                .into_iter()
                .filter_map(|guid| self.position(guid))
                .map(|position| self.node_at(env, position))
                .collect::<NifResult<Vec<_>>>()?;
            Ok(nodes.encode(env))
        }

        /// The scene nodes from `offset`, at most `limit`, in graph order.
        pub fn node_slice<'a>(&self, env: Env<'a>, offset: usize, limit: usize) -> NifResult<Term<'a>> {
            let end = offset.saturating_add(limit).min(self.graph.nodes.len());
            let nodes = (offset.min(end)..end)
                .map(|position| self.node_at(env, position))
                .collect::<NifResult<Vec<_>>>()?;
            Ok(nodes.encode(env))
        }

        /// The effective record at a GUID, holding only `fields` when given, or `nil`.
        pub fn record<'a>(&self, env: Env<'a>, guid: Term<'a>, fields: Option<Vec<String>>) -> NifResult<Term<'a>> {
            match self.position(guid) {
                Some(position) => self.record_at(env, position, field_ids(fields).as_deref()),
                None => Ok(atom(env, "nil")),
            }
        }

        fn record_at<'a>(&self, env: Env<'a>, position: usize, only: Option<&[u32]>) -> NifResult<Term<'a>> {
            kiwi_encode_record_fields(env, &self.graph.nodes[position].record, only)
        }

        /// The effective records at GUIDs, as `{guid, record}` pairs, leaving out those the
        /// graph lacks.
        pub fn records<'a>(
            &self,
            env: Env<'a>,
            guids: Vec<Term<'a>>,
            fields: Option<Vec<String>>,
        ) -> NifResult<Term<'a>> {
            let only = field_ids(fields);
            let records = guids
                .into_iter()
                .filter_map(|guid| self.position(guid).map(|position| (guid, position)))
                .map(|(guid, position)| Ok((guid, self.record_at(env, position, only.as_deref())?).encode(env)))
                .collect::<NifResult<Vec<_>>>()?;
            Ok(records.encode(env))
        }

        /// The GUIDs of a node's children, in order.
        pub fn children<'a>(&self, env: Env<'a>, guid: Term<'a>) -> Term<'a> {
            match self.position(guid) {
                Some(position) => self.guids(env, &self.graph.nodes[position].children),
                None => Vec::<Term<'a>>::new().encode(env),
            }
        }

        /// Every node's GUID, in graph order.
        pub fn all_guids<'a>(&self, env: Env<'a>) -> Term<'a> {
            (0..self.graph.nodes.len()).map(|position| self.guid(env, position)).collect::<Vec<_>>().encode(env)
        }

        /// The GUIDs of the records the graph starts from.
        pub fn roots<'a>(&self, env: Env<'a>) -> Term<'a> {
            self.graph.roots.encode(env)
        }

        /// The GUIDs of nodes of a type, by its snake-case name, in graph order.
        pub fn of_type<'a>(&self, env: Env<'a>, node_type: &str) -> Term<'a> {
            self.guids(env, self.by_type.get(node_type).map_or(&[], |positions| positions.as_slice()))
        }

        /// The GUIDs of nodes with a name, in graph order.
        pub fn named<'a>(&self, env: Env<'a>, name: &str) -> Term<'a> {
            self.guids(env, self.by_name.get(name).map_or(&[], |positions| positions.as_slice()))
        }

        /// Where a node came from, or `nil` for a source node nothing changed.
        pub fn provenance<'a>(&self, env: Env<'a>, guid: Term<'a>) -> NifResult<Term<'a>> {
            match self.position(guid).and_then(|position| self.graph.nodes[position].provenance.as_ref()) {
                Some(provenance) => encode_provenance(env, provenance),
                None => Ok(atom(env, "nil")),
            }
        }

        /// The overrides and variables the graph could not resolve.
        pub fn unresolved<'a>(&self, env: Env<'a>) -> Term<'a> {
            self.graph
                .unresolved
                .iter()
                .map(|entry| match entry {
                    Unresolved::Variable(diagnostic) => {
                        (atom(env, "unsupported_variable_expression"), diagnostic.variable, diagnostic.mode)
                            .encode(env)
                    }
                    Unresolved::Occurrence(diagnostic) => encode_diagnostic(env, diagnostic),
                })
                .collect::<Vec<_>>()
                .encode(env)
        }

        /// The source record a graph node was built from, or `nil`.
        pub fn source<'a>(&self, env: Env<'a>, id: GuidKey) -> NifResult<Term<'a>> {
            match self.sources.get(&id) {
                Some(record) => kiwi_encode_record(env, record),
                None => Ok(atom(env, "nil")),
            }
        }

        /// The source record a graph node was built from, projected as a scene node, or `nil`.
        pub fn source_node<'a>(&self, env: Env<'a>, id: GuidKey) -> NifResult<Term<'a>> {
            match self.sources.get(&id) {
                Some(record) => {
                    let parent = parent_id(record).map(|parent| parent.encode(env));
                    encode_record_node(env, record, id.encode(env), parent)
                }
                None => Ok(atom(env, "nil")),
            }
        }

        /// Counts of nodes, clones, instances, unresolved overrides, and applied claims.
        pub fn stats<'a>(&self, env: Env<'a>) -> Term<'a> {
            let clones = self
                .graph
                .nodes
                .iter()
                .filter(|node| matches!(node.guid, GraphGuid::Clone(_)))
                .count();
            let applied = self
                .graph
                .nodes
                .iter()
                .filter_map(|node| node.provenance.as_ref())
                .map(|provenance| provenance.applied.len())
                .sum::<usize>();
            map(
                env,
                &[
                    ("node_count", self.graph.nodes.len().encode(env)),
                    ("clone_count", clones.encode(env)),
                    ("instance_count", self.by_type.get("instance").map_or(0, Vec::len).encode(env)),
                    ("unresolved_count", self.graph.unresolved.len().encode(env)),
                    ("applied_count", applied.encode(env)),
                ],
            )
        }

        /// The graph's fields as `Figler.Scene.Graph` once held them, only those named.
        pub fn fields<'a>(&self, env: Env<'a>, only: Vec<String>) -> NifResult<Term<'a>> {
            let wants = |field: &str| only.iter().any(|name| name == field);
            let all = (0..self.graph.nodes.len()).collect::<Vec<_>>();
            let keys = if wants("nodes") || wants("records") || wants("provenance") || wants("children") {
                all.iter().map(|position| self.guid(env, *position)).collect::<Vec<_>>()
            } else {
                Vec::new()
            };
            let mut entries = Vec::new();

            if wants("nodes") {
                let values = all.iter().map(|position| self.node_at(env, *position)).collect::<NifResult<Vec<_>>>()?;
                entries.push(("nodes", Term::map_from_term_arrays(env, &keys, &values)?));
            }
            if wants("records") {
                let values = all.iter().map(|position| self.record_at(env, *position, None)).collect::<NifResult<Vec<_>>>()?;
                entries.push(("records", Term::map_from_term_arrays(env, &keys, &values)?));
            }
            if wants("children") {
                let (child_keys, child_values): (Vec<_>, Vec<_>) = all
                    .iter()
                    .filter(|position| !self.graph.nodes[**position].children.is_empty())
                    .map(|position| (keys[*position], self.guids(env, &self.graph.nodes[*position].children)))
                    .unzip();
                entries.push(("children", Term::map_from_term_arrays(env, &child_keys, &child_values)?));
            }
            if wants("provenance") {
                let mut provenance_keys = Vec::new();
                let mut provenance_values = Vec::new();
                for position in &all {
                    if let Some(provenance) = &self.graph.nodes[*position].provenance {
                        provenance_keys.push(keys[*position]);
                        provenance_values.push(encode_provenance(env, provenance)?);
                    }
                }
                entries.push(("provenance", Term::map_from_term_arrays(env, &provenance_keys, &provenance_values)?));
            }
            if wants("roots") {
                entries.push(("roots", self.roots(env)));
            }
            if wants("by_type") {
                let (type_keys, type_values): (Vec<_>, Vec<_>) =
                    self.by_type.iter().map(|(key, positions)| (key.encode(env), self.guids(env, positions))).unzip();
                entries.push(("by_type", Term::map_from_term_arrays(env, &type_keys, &type_values)?));
            }
            if wants("by_name") {
                let (name_keys, name_values): (Vec<_>, Vec<_>) =
                    self.by_name.iter().map(|(key, positions)| (key.encode(env), self.guids(env, positions))).unzip();
                entries.push(("by_name", Term::map_from_term_arrays(env, &name_keys, &name_values)?));
            }
            if wants("unresolved") {
                entries.push(("unresolved", self.unresolved(env)));
            }
            Ok(map(env, &entries))
        }
    }

    /// The `NodeChange` field ids named by their decoded-map keys; unknown names are left out.
    fn field_ids(fields: Option<Vec<String>>) -> Option<Vec<u32>> {
        fields.map(|fields| {
            fields
                .iter()
                .filter_map(|name| kiwi_record_field(kiwi_record_definitions::NODE_CHANGE, name))
                .collect()
        })
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
        let parent = node.parent.as_ref().map(|parent| encode_graph_guid(env, parent));
        encode_record_node(env, &node.record, guid, parent)
    }

    /// Projects a record into a `Figler.Scene.Node` with the GUIDs given.
    fn encode_record_node<'a>(
        env: Env<'a>,
        record: &KiwiRecord,
        guid: Term<'a>,
        parent: Option<Term<'a>>,
    ) -> NifResult<Term<'a>> {
        use kiwi_records::NodeChange as field;
        let nil = atom(env, "nil");
        let text = record.record(field::TEXT_DATA).and_then(|text| text.str(kiwi_records::TextData::CHARACTERS));
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
                .and_then(|style| guid_key(style.record(kiwi_records::StyleId::GUID)))
                .map_or(nil, |(session, local)| format!("{session}:{local}").encode(env))
        };
        let size = record.record(field::SIZE).and_then(|size| {
            Some(map(
                env,
                &[
                    ("x", kiwi_encode_float(env, size.float(kiwi_records::Vector::X)?)),
                    ("y", kiwi_encode_float(env, size.float(kiwi_records::Vector::Y)?)),
                ],
            ))
        });
        let transform = record.record(field::TRANSFORM).and_then(|matrix| {
            use kiwi_records::Matrix as m;
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
            .and_then(|parent| parent.str(kiwi_records::ParentIndex::POSITION))
            .map_or(nil, |value| value.encode(env));
        let parent = parent.unwrap_or(nil);
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
                ("font_family", font_field(kiwi_records::FontName::FAMILY)),
                ("font_style", font_field(kiwi_records::FontName::STYLE)),
                ("font_postscript", font_field(kiwi_records::FontName::POSTSCRIPT)),
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

    // Formula cases from OpenPencil's formula signatures, as Figma evaluates them.
    #[cfg(test)]
    mod tests {
        use super::*;
        use kiwi_records::ExpressionFunction as function;

        fn float(value: f64) -> VariableValue {
            VariableValue::Float(value)
        }

        fn string(value: &str) -> VariableValue {
            VariableValue::String(value.to_string())
        }

        #[test]
        fn evaluates_operators_with_figma_operand_types() {
            assert!(matches!(binary(function::MULTIPLY, &float(2.0), &float(4.0)), Some(VariableValue::Float(8.0))));
            assert!(matches!(
                binary(function::ADDITION, &string("n="), &float(4.0)),
                Some(VariableValue::String(text)) if text == "n=4"
            ));
            assert!(matches!(
                ternary(function::TERNARY, &VariableValue::Boolean(true), &string("a"), &string("b")),
                Some(VariableValue::String(text)) if text == "a"
            ));
            assert!(matches!(unary(function::IS_TRUTHY, &string("off")), Some(VariableValue::Boolean(false))));
            assert!(binary(function::DIVIDE, &float(1.0), &float(0.0)).is_none());
            assert!(binary(function::SUBTRACTION, &string("a"), &float(1.0)).is_none());
        }

        #[test]
        fn writes_numbers_as_text_the_way_figma_does() {
            assert_eq!(number_text(0.0000001), "0");
            assert_eq!(number_text(3.0), "3");
            assert_eq!(number_text(0.125), "0.12");
            assert_eq!(number_text(0.999), "1.00");
            assert_eq!(number_text(-0.004), "-0.00");
            assert_eq!(text(&VariableValue::Boolean(true)).as_deref(), Some("true"));
        }

        #[test]
        fn reads_text_and_numbers_as_true_or_false() {
            assert_eq!(truthy(&string("No ")), Some(false));
            assert_eq!(truthy(&string("yes")), Some(true));
            assert_eq!(truthy(&float(0.0)), Some(false));
            assert_eq!(truthy(&string("")), Some(false));
        }
    }
}
