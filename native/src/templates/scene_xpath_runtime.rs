mod scene_xpath_runtime {
    use super::*;
    use std::cmp::Ordering;
    use std::sync::Arc;
    use markup5ever::{ns, LocalName, Namespace, Prefix};
    use rustler::{Resource, ResourceArc};
    use servo_xpath::{
        Attribute, Document, Dom, Element, NamespaceResolver, Node,
        ProcessingInstruction, Value,
    };
    #[derive(Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
    struct SceneGuid {
        session_id: u32,
        local_id: u32,
    }
    impl SceneGuid {
        fn parse(value: &str) -> Option<Self> {
            let (session_id, local_id) = value.split_once(':')?;
            Some(Self {
                session_id: session_id.parse().ok()?,
                local_id: local_id.parse().ok()?,
            })
        }
    }
    impl std::fmt::Display for SceneGuid {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            write!(f, "{}:{}", self.session_id, self.local_id)
        }
    }

    #[derive(Clone, Debug)]
    struct SceneNodeRecord {
        guid: SceneGuid,
        node_type: &'static str,
        __rq_scene_record_fields: (),
        parent: Option<usize>,
        children: Vec<usize>,
    }
    #[derive(Clone, Debug)]
    struct SceneIndex {
        nodes: Vec<SceneNodeRecord>,
        roots: Vec<usize>,
        preorder: Vec<usize>,
        ranks: Vec<usize>,
        by_guid: std::collections::HashMap<SceneGuid, usize>,
        by_type: std::collections::HashMap<&'static str, Vec<usize>>,
        by_name: std::collections::HashMap<String, Vec<usize>>,
    }
    #[derive(Clone, Debug, Eq, PartialEq, std::hash::Hash)]
    enum SceneHandleKind {
        Document,
        Element(usize),
        Attribute { owner: usize, index: usize },
    }
    #[derive(Clone, Debug)]
    struct SceneHandle {
        scene: Arc<SceneIndex>,
        kind: SceneHandleKind,
    }
    impl PartialEq for SceneHandle {
        fn eq(&self, other: &Self) -> bool {
            Arc::ptr_eq(&self.scene, &other.scene) && self.kind == other.kind
        }
    }
    impl Eq for SceneHandle {}
    #[derive(Clone, Debug, Eq, PartialEq)]
    struct SceneElement(SceneHandle);
    #[derive(Clone, Debug, Eq, PartialEq)]
    struct SceneAttribute(SceneHandle);
    #[derive(Clone, Debug, Eq, PartialEq)]
    struct SceneProcessingInstruction;
    #[derive(Clone, Debug)]
    struct SceneDocument(Arc<SceneIndex>);
    impl PartialEq for SceneDocument {
        fn eq(&self, other: &Self) -> bool {
            Arc::ptr_eq(&self.0, &other.0)
        }
    }
    impl Eq for SceneDocument {}
    #[derive(Clone, Debug, Eq, PartialEq)]
    struct SceneNamespaceResolver;
    pub struct SceneIndexResource {
        index: Arc<SceneIndex>,
    }
    impl Resource for SceneIndexResource {}
    struct SceneDom;
    impl SceneNodeRecord {
        fn attr(&self, index: usize) -> Option<(&'static str, String)> {
            let mut cursor = 0;
            if index == cursor {
                return Some(("guid", self.guid.to_string()));
            }
            cursor += 1;
            if index == cursor {
                return Some(("type", self.node_type.to_string()));
            }
            cursor += 1;
            __rq_scene_attr_lookup!();
            None
        }
        fn attr_count(&self) -> usize {
            let mut count = 2;
            __rq_scene_attr_count!();
            count
        }
    }
    impl SceneIndex {
        fn new(mut nodes: Vec<SceneNodeRecord>) -> Self {
            let by_guid = nodes
                .iter()
                .enumerate()
                .map(|(index, node)| (node.guid, index))
                .collect::<std::collections::HashMap<_, _>>();
            let mut roots = Vec::new();
            for index in 0..nodes.len() {
                let parent = nodes[index]
                    .parent_guid
                    .and_then(|guid| by_guid.get(&guid).copied());
                nodes[index].parent = parent;
                if let Some(parent) = parent {
                    nodes[parent].children.push(index);
                } else {
                    roots.push(index);
                }
            }
            for index in 0..nodes.len() {
                let mut children = std::mem::take(&mut nodes[index].children);
                children
                    .sort_by(|left, right| {
                        nodes[*left]
                            .position
                            .cmp(&nodes[*right].position)
                            .then_with(|| nodes[*left].guid.cmp(&nodes[*right].guid))
                    });
                nodes[index].children = children;
            }
            roots.sort_by(|left, right| nodes[*left].guid.cmp(&nodes[*right].guid));
            let mut preorder = Vec::with_capacity(nodes.len());
            for root in roots.iter().copied() {
                Self::push_preorder(&nodes, root, &mut preorder);
            }
            let mut ranks = vec![0; nodes.len()];
            for (rank, index) in preorder.iter().copied().enumerate() {
                ranks[index] = rank;
            }
            let mut by_type: std::collections::HashMap<&'static str, Vec<usize>> = std::collections::HashMap::new();
            let mut by_name: std::collections::HashMap<String, Vec<usize>> = std::collections::HashMap::new();
            for index in preorder.iter().copied() {
                by_type.entry(nodes[index].node_type).or_default().push(index);
                if let Some(name) = nodes[index].name.as_ref() {
                    by_name.entry(name.clone()).or_default().push(index);
                }
            }
            Self {
                nodes,
                roots,
                preorder,
                ranks,
                by_guid,
                by_type,
                by_name,
            }
        }
        fn push_preorder(nodes: &[SceneNodeRecord], index: usize, out: &mut Vec<usize>) {
            out.push(index);
            for child in nodes[index].children.iter().copied() {
                Self::push_preorder(nodes, child, out);
            }
        }
        fn children_of(&self, handle: &SceneHandleKind) -> Vec<usize> {
            match handle {
                SceneHandleKind::Document => self.roots.clone(),
                SceneHandleKind::Element(index) => self.nodes[*index].children.clone(),
                SceneHandleKind::Attribute { .. } => Vec::new(),
            }
        }
        fn descendants_of(&self, handle: &SceneHandleKind) -> Vec<usize> {
            let mut out = Vec::new();
            match handle {
                SceneHandleKind::Document => {
                    for root in self.roots.iter().copied() {
                        Self::push_preorder(&self.nodes, root, &mut out);
                    }
                }
                SceneHandleKind::Element(index) => {
                    Self::push_preorder(&self.nodes, *index, &mut out)
                }
                SceneHandleKind::Attribute { .. } => {}
            }
            out
        }
        fn siblings_before(&self, index: usize) -> Vec<usize> {
            let siblings = self
                .nodes[index]
                .parent
                .map(|parent| self.nodes[parent].children.as_slice())
                .unwrap_or(self.roots.as_slice());
            siblings.iter().copied().take_while(|sibling| *sibling != index).collect()
        }
        fn siblings_after(&self, index: usize) -> Vec<usize> {
            let siblings = self
                .nodes[index]
                .parent
                .map(|parent| self.nodes[parent].children.as_slice())
                .unwrap_or(self.roots.as_slice());
            siblings
                .iter()
                .copied()
                .skip_while(|sibling| *sibling != index)
                .skip(1)
                .collect()
        }
    }
    impl SceneHandle {
        fn document(scene: Arc<SceneIndex>) -> Self {
            Self {
                scene,
                kind: SceneHandleKind::Document,
            }
        }
        fn element(scene: Arc<SceneIndex>, index: usize) -> Self {
            Self {
                scene,
                kind: SceneHandleKind::Element(index),
            }
        }
        fn attribute(scene: Arc<SceneIndex>, owner: usize, index: usize) -> Self {
            Self {
                scene,
                kind: SceneHandleKind::Attribute {
                    owner,
                    index,
                },
            }
        }
        fn element_index(&self) -> Option<usize> {
            match self.kind {
                SceneHandleKind::Element(index) => Some(index),
                _ => None,
            }
        }
    }
    impl NamespaceResolver for SceneNamespaceResolver {
        type Context = ();
        fn resolve_namespace_prefix(
            &self,
            _cx: &mut (),
            _prefix: &str,
        ) -> Option<String> {
            None
        }
    }
    impl Dom for SceneDom {
        type Context = ();
        type Node = SceneHandle;
        type NamespaceResolver = SceneNamespaceResolver;
    }
    impl Node for SceneHandle {
        type Context = ();
        type ProcessingInstruction = SceneProcessingInstruction;
        type Document = SceneDocument;
        type Attribute = SceneAttribute;
        type Element = SceneElement;
        type Opaque = SceneHandleKind;
        fn is_comment(&self) -> bool {
            false
        }
        fn is_text(&self) -> bool {
            false
        }
        fn text_content(&self) -> String {
            match self.kind {
                SceneHandleKind::Document => String::new(),
                SceneHandleKind::Element(index) => {
                    self.scene.nodes[index].name.clone().unwrap_or_default()
                }
                SceneHandleKind::Attribute { owner, index } => {
                    self.scene
                        .nodes[owner]
                        .attr(index)
                        .map(|(_, value)| value)
                        .unwrap_or_default()
                }
            }
        }
        fn language(&self) -> Option<String> {
            None
        }
        fn parent(&self) -> Option<Self> {
            match self.kind {
                SceneHandleKind::Document => None,
                SceneHandleKind::Element(index) => {
                    self.scene
                        .nodes[index]
                        .parent
                        .map(|parent| Self::element(self.scene.clone(), parent))
                        .or_else(|| Some(Self::document(self.scene.clone())))
                }
                SceneHandleKind::Attribute { owner, .. } => {
                    Some(Self::element(self.scene.clone(), owner))
                }
            }
        }
        fn children(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            self.scene
                .children_of(&self.kind)
                .into_iter()
                .map(move |index| Self::element(scene.clone(), index))
        }
        fn compare_tree_order(&self, other: &Self) -> Ordering {
            fn rank(handle: &SceneHandle) -> usize {
                match handle.kind {
                    SceneHandleKind::Document => 0,
                    SceneHandleKind::Element(index) => handle.scene.ranks[index] + 1,
                    SceneHandleKind::Attribute { owner, index } => {
                        handle.scene.ranks[owner] + 1_000_000_000 + index
                    }
                }
            }
            rank(self).cmp(&rank(other))
        }
        fn traverse_preorder(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let mut handles = Vec::new();
            if matches!(self.kind, SceneHandleKind::Document) {
                handles.push(Self::document(scene.clone()));
            }
            handles
                .extend(
                    self
                        .scene
                        .descendants_of(&self.kind)
                        .into_iter()
                        .map(move |index| Self::element(scene.clone(), index)),
                );
            handles.into_iter()
        }
        fn inclusive_ancestors(&self) -> impl Iterator<Item = Self> {
            let mut ancestors = Vec::new();
            let mut current = Some(self.clone());
            while let Some(node) = current {
                current = node.parent();
                ancestors.push(node);
            }
            ancestors.into_iter()
        }
        fn preceding_nodes(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let ancestors = self
                .inclusive_ancestors()
                .filter_map(|node| node.element_index())
                .collect::<Vec<_>>();
            let cutoff = self
                .element_index()
                .map(|index| self.scene.ranks[index])
                .unwrap_or(0);
            let indexes = self
                .scene
                .preorder
                .iter()
                .copied()
                .take(cutoff)
                .filter(|index| !ancestors.contains(index))
                .collect::<Vec<_>>();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }
        fn following_nodes(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let descendants = self.scene.descendants_of(&self.kind);
            let start = descendants
                .last()
                .map(|index| self.scene.ranks[*index] + 1)
                .unwrap_or(0);
            let indexes = self
                .scene
                .preorder
                .iter()
                .copied()
                .skip(start)
                .collect::<Vec<_>>();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }
        fn preceding_siblings(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let indexes = self
                .element_index()
                .map(|index| self.scene.siblings_before(index))
                .unwrap_or_default();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }
        fn following_siblings(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let indexes = self
                .element_index()
                .map(|index| self.scene.siblings_after(index))
                .unwrap_or_default();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }
        fn owner_document(&self) -> Self::Document {
            SceneDocument(self.scene.clone())
        }
        fn to_opaque(&self) -> Self::Opaque {
            self.kind.clone()
        }
        fn as_processing_instruction(&self) -> Option<Self::ProcessingInstruction> {
            None
        }
        fn as_attribute(&self) -> Option<Self::Attribute> {
            matches!(self.kind, SceneHandleKind::Attribute { .. })
                .then(|| SceneAttribute(self.clone()))
        }
        fn as_element(&self) -> Option<Self::Element> {
            matches!(self.kind, SceneHandleKind::Element(_))
                .then(|| SceneElement(self.clone()))
        }
        fn get_root_node(&self) -> Self {
            Self::document(self.scene.clone())
        }
    }
    impl ProcessingInstruction for SceneProcessingInstruction {
        fn target(&self) -> String {
            String::new()
        }
    }
    impl Document for SceneDocument {
        type Node = SceneHandle;
        fn get_elements_with_id(
            &self,
            id: &str,
        ) -> impl Iterator<Item = <Self::Node as Node>::Element> {
            let scene = self.0.clone();
            let indexes = scene
                .preorder
                .iter()
                .copied()
                .filter(|index| SceneGuid::parse(id).is_some_and(|guid| scene.nodes[*index].guid == guid))
                .collect::<Vec<_>>();
            indexes
                .into_iter()
                .map(move |index| SceneElement(
                    SceneHandle::element(scene.clone(), index),
                ))
        }
    }
    impl Element for SceneElement {
        type Context = ();
        type Node = SceneHandle;
        type Attribute = SceneAttribute;
        fn as_node(&self) -> Self::Node {
            self.0.clone()
        }
        fn prefix(&self) -> Option<Prefix> {
            None
        }
        fn namespace(&self) -> Namespace {
            ns!()
        }
        fn local_name(&self) -> LocalName {
            let SceneHandleKind::Element(index) = self.0.kind else { unreachable!() };
            LocalName::from(self.0.scene.nodes[index].node_type)
        }
        fn attributes(&self, _cx: &mut ()) -> impl Iterator<Item = Self::Attribute> {
            let SceneHandleKind::Element(owner) = self.0.kind else { unreachable!() };
            let scene = self.0.scene.clone();
            let count = self.0.scene.nodes[owner].attr_count();
            (0..count)
                .map(move |index| SceneAttribute(
                    SceneHandle::attribute(scene.clone(), owner, index),
                ))
        }
        fn is_html_element_in_html_document(&self) -> bool {
            false
        }
    }
    impl Attribute for SceneAttribute {
        type Node = SceneHandle;
        fn as_node(&self) -> Self::Node {
            self.0.clone()
        }
        fn prefix(&self) -> Option<Prefix> {
            None
        }
        fn namespace(&self) -> Namespace {
            ns!()
        }
        fn local_name(&self) -> LocalName {
            let SceneHandleKind::Attribute { owner, index } = self.0.kind else {
                unreachable!()
            };
            LocalName::from(
                self.0.scene.nodes[owner].attr(index).map(|(name, _)| name).unwrap_or(""),
            )
        }
    }
    fn read_guid_value(decoder: &mut Decoder<'_>) -> NifResult<SceneGuid> {
        let session_id = decoder.read_var_uint()?;
        let local_id = decoder.read_var_uint()?;
        Ok(SceneGuid { session_id, local_id })
    }
    fn read_parent_index_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<(SceneGuid, String)> {
        let guid = read_guid_value(decoder)?;
        let position = decoder.read_string_value()?;
        Ok((guid, position))
    }
    fn read_scene_size_value(decoder: &mut Decoder<'_>) -> NifResult<SceneSize> {
        Ok(SceneSize {
            x: decoder.read_var_float_value()? as f64,
            y: decoder.read_var_float_value()? as f64,
        })
    }
    fn read_scene_transform_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<SceneTransform> {
        Ok(SceneTransform {
            m00: decoder.read_var_float_value()? as f64,
            m01: decoder.read_var_float_value()? as f64,
            m02: decoder.read_var_float_value()? as f64,
            m10: decoder.read_var_float_value()? as f64,
            m11: decoder.read_var_float_value()? as f64,
            m12: decoder.read_var_float_value()? as f64,
        })
    }
    fn read_scene_font_name_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<(Option<String>, Option<String>, Option<String>)> {
        let family = Some(decoder.read_string_value()?);
        let style = Some(decoder.read_string_value()?);
        let postscript = Some(decoder.read_string_value()?);
        Ok((family, style, postscript))
    }
    fn read_scene_counted_array_value(
        decoder: &mut Decoder<'_>,
        mut skip_item: impl FnMut(&mut Decoder<'_>) -> NifResult<()>,
    ) -> NifResult<Option<usize>> {
        let len = decoder.read_var_uint()? as usize;
        for _ in 0..len {
            skip_item(decoder)?;
        }
        Ok(Some(len))
    }

    fn read_scene_text_data_value(decoder: &mut Decoder<'_>) -> NifResult<Option<String>> {
        let mut text = None;
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => text = Some(decoder.read_string_value()?),
                __rq_scene_text_data_skip_arms => unreachable!(),
                field => {
                    return Err(Error::Term(Box::new(format!(
                        "unknown field {} while decoding scene text data",
                        field
                    ))));
                }
            }
        }
        Ok(text)
    }
    fn read_scene_style_id_value(decoder: &mut Decoder<'_>) -> NifResult<Option<String>> {
        let mut guid = None;
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => guid = Some(read_guid_value(decoder)?.to_string()),
                __rq_scene_style_id_skip_arms => unreachable!(),
                field => {
                    return Err(Error::Term(Box::new(format!(
                        "unknown field {} while decoding scene style id",
                        field
                    ))));
                }
            }
        }
        Ok(guid)
    }
    fn scene_query_node(index: &SceneIndex, node_index: usize) -> SceneQueryNode {
        let node = &index.nodes[node_index];
        SceneQueryNode {
            guid: node.guid.to_string(),
            node_type: node.node_type.to_string(),
            __rq_scene_query_node_build_fields: (),
        }
    }

    fn wants_field(fields: &[String], field: &str) -> bool {
        fields.iter().any(|selected| selected == field)
    }

    fn scene_query_node_term<'a>(
        env: Env<'a>,
        index: &SceneIndex,
        node_index: usize,
        fields: &[String],
    ) -> NifResult<Term<'a>> {
        static GUID_ATOM: OnceLock<Atom> = OnceLock::new();
        static NODE_TYPE_ATOM: OnceLock<Atom> = OnceLock::new();
        __rq_scene_query_field_atoms!();

        let node = &index.nodes[node_index];
        let mut keys = Vec::with_capacity(fields.len().max(2));
        let mut values = Vec::with_capacity(fields.len().max(2));

        keys.push(cached_atom(env, &GUID_ATOM, "guid").encode(env));
        values.push(node.guid.to_string().encode(env));
        keys.push(cached_atom(env, &NODE_TYPE_ATOM, "node_type").encode(env));
        values.push(node.node_type.encode(env));

        __rq_scene_query_field_encoders!();

        Term::map_from_term_arrays(env, &keys, &values)
    }
    pub fn build_scene_index_value(
        bytes: Binary<'_>,
    ) -> NifResult<ResourceArc<SceneIndexResource>> {
        let mut decoder = Decoder::new(bytes.as_slice());
        let mut nodes = Vec::new();
        decode_scene_index_message_from_decoder(&mut decoder, &mut nodes)?;
        decoder.finish()?;
        Ok(scene_index_resource(SceneIndex::new(nodes)))
    }

    pub fn build_scene_index_with_summary_value(
        bytes: Binary<'_>,
    ) -> NifResult<(ResourceArc<SceneIndexResource>, SceneSummary)> {
        let mut decoder = Decoder::new(bytes.as_slice());
        let mut nodes = Vec::new();
        decode_scene_index_message_from_decoder(&mut decoder, &mut nodes)?;
        decoder.finish()?;

        let index = SceneIndex::new(nodes);
        let summary = scene_index_summary(&index);
        Ok((scene_index_resource(index), summary))
    }

    fn scene_index_resource(index: SceneIndex) -> ResourceArc<SceneIndexResource> {
        ResourceArc::new(SceneIndexResource {
            index: Arc::new(index),
        })
    }

    fn scene_index_summary(index: &SceneIndex) -> SceneSummary {
        let node_count = index.nodes.len();
        let parented_count = node_count.saturating_sub(index.roots.len());
        let mut type_counts = index
            .by_type
            .iter()
            .map(|(node_type, nodes)| ((*node_type).to_string(), nodes.len()))
            .collect::<Vec<_>>();
        type_counts.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));

        SceneSummary {
            node_count,
            parented_count,
            root_count: index.roots.len(),
            type_counts,
        }
    }
    pub fn query_scene_xpath_value<'a>(
        env: Env<'a>,
        bytes: Binary<'a>,
        xpath: String,
    ) -> NifResult<Term<'a>> {
        let resource = build_scene_index_value(bytes)?;
        query_scene_index_value(env, resource, xpath)
    }

    pub fn query_scene_xpath_fields_value<'a>(
        env: Env<'a>,
        bytes: Binary<'a>,
        xpath: String,
        fields: Vec<String>,
    ) -> NifResult<Term<'a>> {
        let resource = build_scene_index_value(bytes)?;
        query_scene_index_fields_value(env, resource, xpath, fields)
    }

    fn evaluate_scene_xpath(index: Arc<SceneIndex>, xpath: &str) -> NifResult<Vec<usize>> {
        let root = SceneHandle::document(index);
        let mut cx = ();
        let expression = servo_xpath::parse::<SceneNamespaceResolver>(&mut cx, xpath, None, false)
            .map_err(|error| Error::Term(Box::new(format!("invalid XPath: {:?}", error))))?;
        let value = servo_xpath::evaluate_parsed_xpath::<SceneDom>(&mut cx, &expression, root)
            .map_err(|error| Error::Term(Box::new(format!("XPath evaluation failed: {:?}", error))))?;

        Ok(match value {
            Value::NodeSet(node_set) => node_set
                .into_iter()
                .filter_map(|handle| match handle.kind {
                    SceneHandleKind::Element(node_index) => Some(node_index),
                    SceneHandleKind::Attribute { owner, .. } => Some(owner),
                    SceneHandleKind::Document => None,
                })
                .collect(),
            _ => Vec::new(),
        })
    }

    pub fn query_scene_index_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        xpath: String,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let matched = evaluate_scene_xpath(index.clone(), &xpath)?
            .into_iter()
            .map(|node_index| scene_query_node(&index, node_index))
            .collect::<Vec<_>>();
        Ok(matched.encode(env))
    }

    pub fn query_scene_index_fields_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        xpath: String,
        fields: Vec<String>,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let matched = evaluate_scene_xpath(index.clone(), &xpath)?
            .into_iter()
            .map(|node_index| scene_query_node_term(env, &index, node_index, &fields))
            .collect::<NifResult<Vec<_>>>()?;
        Ok(matched.encode(env))
    }
    fn find_node_index(index: &SceneIndex, guid: &str) -> Option<usize> {
        SceneGuid::parse(guid).and_then(|guid| index.by_guid.get(&guid).copied())
    }

    pub fn scene_index_node_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        match find_node_index(&index, &guid) {
            Some(node_index) => Ok(scene_query_node(&index, node_index).encode(env)),
            None => Ok(None::<SceneQueryNode>.encode(env)),
        }
    }

    pub fn scene_index_parent_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        match find_node_index(&index, &guid).and_then(|node_index| index.nodes[node_index].parent) {
            Some(parent_index) => Ok(scene_query_node(&index, parent_index).encode(env)),
            None => Ok(None::<SceneQueryNode>.encode(env)),
        }
    }

    pub fn scene_index_roots_value(
        resource: ResourceArc<SceneIndexResource>,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        index.roots.iter().copied().map(|node_index| scene_query_node(&index, node_index)).collect()
    }

    pub fn scene_index_children_value(
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        find_node_index(&index, &guid)
            .map(|node_index| {
                index.nodes[node_index]
                    .children
                    .iter()
                    .copied()
                    .map(|child| scene_query_node(&index, child))
                    .collect()
            })
            .unwrap_or_default()
    }

    pub fn scene_index_siblings_value(
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        find_node_index(&index, &guid)
            .map(|node_index| {
                let siblings = index.nodes[node_index]
                    .parent
                    .map(|parent| index.nodes[parent].children.as_slice())
                    .unwrap_or(index.roots.as_slice());
                siblings
                    .iter()
                    .copied()
                    .filter(|sibling| *sibling != node_index)
                    .map(|sibling| scene_query_node(&index, sibling))
                    .collect()
            })
            .unwrap_or_default()
    }

    fn scene_query_nodes_matching(
        index: &SceneIndex,
        predicate: impl Fn(&SceneNodeRecord) -> bool,
    ) -> Vec<SceneQueryNode> {
        index
            .preorder
            .iter()
            .copied()
            .filter(|node_index| predicate(&index.nodes[*node_index]))
            .map(|node_index| scene_query_node(index, node_index))
            .collect()
    }

    fn encode_scene_indexes<'a>(
        env: Env<'a>,
        index: &SceneIndex,
        node_indexes: impl IntoIterator<Item = usize>,
        fields: &[String],
    ) -> NifResult<Term<'a>> {
        let mut out = Vec::new();
        for node_index in node_indexes {
            out.push(scene_query_node_term(env, index, node_index, fields)?);
        }
        Ok(out.encode(env))
    }

    pub fn scene_index_by_type_value(
        resource: ResourceArc<SceneIndexResource>,
        node_type: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        index
            .by_type
            .get(node_type.as_str())
            .into_iter()
            .flatten()
            .copied()
            .map(|node_index| scene_query_node(&index, node_index))
            .collect()
    }

    pub fn scene_index_by_type_fields_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        node_type: String,
        fields: Vec<String>,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let node_indexes = index
            .by_type
            .get(node_type.as_str())
            .into_iter()
            .flatten()
            .copied()
            .collect::<Vec<_>>();
        encode_scene_indexes(env, &index, node_indexes, &fields)
    }

    pub fn scene_index_named_value(
        resource: ResourceArc<SceneIndexResource>,
        name: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        index
            .by_name
            .get(&name)
            .into_iter()
            .flatten()
            .copied()
            .map(|node_index| scene_query_node(&index, node_index))
            .collect()
    }

    pub fn scene_index_name_contains_value(
        resource: ResourceArc<SceneIndexResource>,
        needle: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        scene_query_nodes_matching(&index, |node| {
            node.name.as_ref().is_some_and(|name| name.contains(&needle))
        })
    }

    pub fn scene_index_name_contains_fields_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        needle: String,
        fields: Vec<String>,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let node_indexes = index
            .preorder
            .iter()
            .copied()
            .filter(|node_index| {
                index.nodes[*node_index]
                    .name
                    .as_ref()
                    .is_some_and(|name| name.contains(&needle))
            })
            .collect::<Vec<_>>();
        encode_scene_indexes(env, &index, node_indexes, &fields)
    }

    pub fn scene_index_text_contains_value(
        resource: ResourceArc<SceneIndexResource>,
        needle: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        scene_query_nodes_matching(&index, |node| {
            node.text.as_ref().is_some_and(|text| text.contains(&needle))
        })
    }

    pub fn scene_index_text_contains_fields_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        needle: String,
        fields: Vec<String>,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let node_indexes = index
            .preorder
            .iter()
            .copied()
            .filter(|node_index| {
                index.nodes[*node_index]
                    .text
                    .as_ref()
                    .is_some_and(|text| text.contains(&needle))
            })
            .collect::<Vec<_>>();
        encode_scene_indexes(env, &index, node_indexes, &fields)
    }

    pub fn scene_index_components_value(
        resource: ResourceArc<SceneIndexResource>,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        scene_query_nodes_matching(&index, |node| node.component_key.is_some())
    }

    pub fn scene_index_with_fills_value(
        resource: ResourceArc<SceneIndexResource>,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        scene_query_nodes_matching(&index, |node| node.fill_count.unwrap_or(0) > 0)
    }

    pub fn scene_index_with_strokes_value(
        resource: ResourceArc<SceneIndexResource>,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        scene_query_nodes_matching(&index, |node| node.stroke_count.unwrap_or(0) > 0)
    }

    pub fn scene_index_ancestors_value(
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        let mut out = Vec::new();
        let mut current = find_node_index(&index, &guid).and_then(|node_index| index.nodes[node_index].parent);
        while let Some(node_index) = current {
            out.push(scene_query_node(&index, node_index));
            current = index.nodes[node_index].parent;
        }
        out.reverse();
        out
    }

    pub fn scene_index_descendants_value(
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        let mut out = Vec::new();
        if let Some(node_index) = find_node_index(&index, &guid) {
            for child in index.nodes[node_index].children.iter().copied() {
                let mut preorder = Vec::new();
                SceneIndex::push_preorder(&index.nodes, child, &mut preorder);
                out.extend(preorder.into_iter().map(|index_node| scene_query_node(&index, index_node)));
            }
        }
        out
    }

    fn decode_scene_index_message_from_decoder(
        decoder: &mut Decoder<'_>,
        nodes: &mut Vec<SceneNodeRecord>,
    ) -> NifResult<()> {
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                __rq_scene_message_skip_arms => unreachable!(),
                4 => {
                    let len = decoder.read_var_uint()? as usize;
                    nodes.reserve(len);
                    for _ in 0..len {
                        nodes
                            .push(decode_scene_index_node_change_from_decoder(decoder)?);
                    }
                }
                field => {
                    return Err(
                        Error::Term(
                            Box::new(
                                format!(
                                    "unknown field {} while decoding scene index", field
                                ),
                            ),
                        ),
                    );
                }
            }
        }
        Ok(())
    }
    fn decode_scene_index_node_change_from_decoder(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<SceneNodeRecord> {
        let mut guid = None;
        let mut node_type: Option<&'static str> = None;
        __rq_scene_decode_locals!();
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => guid = Some(read_guid_value(decoder)?),
                3 => {
                    let (parent, pos) = read_parent_index_value(decoder)?;
                    parent_guid = Some(parent);
                    position = Some(pos);
                }
                4 => {
                    node_type = Some(scene_node_type_name(decoder.read_var_uint()?));
                }
                __rq_scene_decode_arms => unreachable!(),
                __rq_scene_node_skip_arms => unreachable!(),
                field => {
                    return Err(
                        Error::Term(
                            Box::new(
                                format!(
                                    "unknown field {} while decoding scene index node", field
                                ),
                            ),
                        ),
                    );
                }
            }
        }
        Ok(SceneNodeRecord {
            guid: guid.unwrap_or_default(),
            node_type: node_type.unwrap_or("unknown"),
            __rq_scene_record_build_fields: (),
            parent: None,
            children: Vec::new(),
        })
    }
}
