defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias KiwiCodec.Schema
  alias KiwiCodec.Schema.Definition

  @primitive_skip %{
    "bool" => "decoder.read_bool()?;",
    "byte" => "decoder.read_byte()?;",
    "float" => "decoder.read_var_float_value()?;",
    "int" => "decoder.read_var_int()?;",
    "int64" => "decoder.read_var_int64()?;",
    "string" => "decoder.skip_string()?;",
    "uint" => "decoder.read_var_uint()?;",
    "uint64" => "decoder.read_var_uint64()?;"
  }

  def render_splices(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [
      node_type_name: [node_type_name(definition_map)],
      sparse_decoders: Enum.map(schema.definitions, &sparse_definition(&1, definition_map)),
      skip_decoders: Enum.map(schema.definitions, &skip_definition(&1, definition_map)),
      sparse_entrypoints: sparse_entrypoints(),
      scene_runtime: scene_summary(definition_map)
    ]
  end

  def render(%Schema{} = schema) do
    schema
    |> render_splices()
    |> Keyword.values()
    |> List.flatten()
  end

  defp scene_xpath_runtime(message_arms, node_change_arms) do
    """
    mod scene_xpath_runtime {
    use super::*;
    use std::cmp::Ordering;
    use std::sync::Arc;

    use markup5ever::{ns, LocalName, Namespace, Prefix};
    use rustler::{Resource, ResourceArc};
    use servo_xpath::{Attribute, Document, Dom, Element, NamespaceResolver, Node, ProcessingInstruction, Value};

    #[derive(Clone, Debug)]
    struct SceneNodeRecord {
        guid: String,
        node_type: String,
        name: Option<String>,
        parent_guid: Option<String>,
        position: Option<String>,
        size: Option<SceneSize>,
        transform: Option<SceneTransform>,
        visible: Option<bool>,
        locked: Option<bool>,
        parent: Option<usize>,
        children: Vec<usize>,
    }

    #[derive(Clone, Debug)]
    struct SceneIndex {
        nodes: Vec<SceneNodeRecord>,
        roots: Vec<usize>,
        preorder: Vec<usize>,
        ranks: Vec<usize>,
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
        fn attrs(&self) -> Vec<(&'static str, String)> {
            let mut attrs = vec![("guid", self.guid.clone()), ("type", self.node_type.clone())];
            if let Some(value) = self.name.as_ref() {
                attrs.push(("name", value.clone()));
            }
            if let Some(value) = self.parent_guid.as_ref() {
                attrs.push(("parent_guid", value.clone()));
            }
            if let Some(value) = self.position.as_ref() {
                attrs.push(("position", value.clone()));
            }
            if let Some(value) = self.size.as_ref() {
                attrs.push(("x", value.x.to_string()));
                attrs.push(("y", value.y.to_string()));
                attrs.push(("width", value.x.to_string()));
                attrs.push(("height", value.y.to_string()));
            }
            if let Some(value) = self.transform.as_ref() {
                attrs.push(("transform", format!("{},{},{},{},{},{}", value.m00, value.m01, value.m02, value.m10, value.m11, value.m12)));
            }
            if let Some(value) = self.visible {
                attrs.push(("visible", value.to_string()));
            }
            if let Some(value) = self.locked {
                attrs.push(("locked", value.to_string()));
            }
            attrs
        }

        fn attr(&self, index: usize) -> Option<(&'static str, String)> {
            self.attrs().get(index).cloned()
        }

        fn attr_count(&self) -> usize {
            self.attrs().len()
        }
    }

    impl SceneIndex {
        fn new(mut nodes: Vec<SceneNodeRecord>) -> Self {
            let by_guid = nodes
                .iter()
                .enumerate()
                .map(|(index, node)| (node.guid.clone(), index))
                .collect::<std::collections::HashMap<_, _>>();

            let mut roots = Vec::new();
            for index in 0..nodes.len() {
                let parent = nodes[index]
                    .parent_guid
                    .as_ref()
                    .and_then(|guid| by_guid.get(guid).copied());
                nodes[index].parent = parent;

                if let Some(parent) = parent {
                    nodes[parent].children.push(index);
                } else {
                    roots.push(index);
                }
            }

            for index in 0..nodes.len() {
                let mut children = std::mem::take(&mut nodes[index].children);
                children.sort_by(|left, right| {
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

            Self { nodes, roots, preorder, ranks }
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
                SceneHandleKind::Element(index) => Self::push_preorder(&self.nodes, *index, &mut out),
                SceneHandleKind::Attribute { .. } => {}
            }
            out
        }

        fn siblings_before(&self, index: usize) -> Vec<usize> {
            let siblings = self.nodes[index]
                .parent
                .map(|parent| self.nodes[parent].children.as_slice())
                .unwrap_or(self.roots.as_slice());

            siblings.iter().copied().take_while(|sibling| *sibling != index).collect()
        }

        fn siblings_after(&self, index: usize) -> Vec<usize> {
            let siblings = self.nodes[index]
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
            Self { scene, kind: SceneHandleKind::Document }
        }

        fn element(scene: Arc<SceneIndex>, index: usize) -> Self {
            Self { scene, kind: SceneHandleKind::Element(index) }
        }

        fn attribute(scene: Arc<SceneIndex>, owner: usize, index: usize) -> Self {
            Self { scene, kind: SceneHandleKind::Attribute { owner, index } }
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

        fn resolve_namespace_prefix(&self, _cx: &mut (), _prefix: &str) -> Option<String> {
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

        fn is_comment(&self) -> bool { false }
        fn is_text(&self) -> bool { false }

        fn text_content(&self) -> String {
            match self.kind {
                SceneHandleKind::Document => String::new(),
                SceneHandleKind::Element(index) => self.scene.nodes[index].name.clone().unwrap_or_default(),
                SceneHandleKind::Attribute { owner, index } => self.scene.nodes[owner]
                    .attr(index)
                    .map(|(_, value)| value)
                    .unwrap_or_default(),
            }
        }

        fn language(&self) -> Option<String> { None }

        fn parent(&self) -> Option<Self> {
            match self.kind {
                SceneHandleKind::Document => None,
                SceneHandleKind::Element(index) => self.scene.nodes[index]
                    .parent
                    .map(|parent| Self::element(self.scene.clone(), parent))
                    .or_else(|| Some(Self::document(self.scene.clone()))),
                SceneHandleKind::Attribute { owner, .. } => Some(Self::element(self.scene.clone(), owner)),
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
                    SceneHandleKind::Attribute { owner, index } => handle.scene.ranks[owner] + 1_000_000_000 + index,
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
            handles.extend(
                self.scene
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
            let cutoff = self.element_index().map(|index| self.scene.ranks[index]).unwrap_or(0);
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
            let indexes = self.scene.preorder.iter().copied().skip(start).collect::<Vec<_>>();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }

        fn preceding_siblings(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let indexes = self.element_index().map(|index| self.scene.siblings_before(index)).unwrap_or_default();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }

        fn following_siblings(&self) -> impl Iterator<Item = Self> {
            let scene = self.scene.clone();
            let indexes = self.element_index().map(|index| self.scene.siblings_after(index)).unwrap_or_default();
            indexes.into_iter().map(move |index| Self::element(scene.clone(), index))
        }

        fn owner_document(&self) -> Self::Document { SceneDocument(self.scene.clone()) }
        fn to_opaque(&self) -> Self::Opaque { self.kind.clone() }
        fn as_processing_instruction(&self) -> Option<Self::ProcessingInstruction> { None }
        fn as_attribute(&self) -> Option<Self::Attribute> {
            matches!(self.kind, SceneHandleKind::Attribute { .. }).then(|| SceneAttribute(self.clone()))
        }
        fn as_element(&self) -> Option<Self::Element> {
            matches!(self.kind, SceneHandleKind::Element(_)).then(|| SceneElement(self.clone()))
        }
        fn get_root_node(&self) -> Self { Self::document(self.scene.clone()) }
    }

    impl ProcessingInstruction for SceneProcessingInstruction {
        fn target(&self) -> String { String::new() }
    }

    impl Document for SceneDocument {
        type Node = SceneHandle;

        fn get_elements_with_id(&self, id: &str) -> impl Iterator<Item = <Self::Node as Node>::Element> {
            let scene = self.0.clone();
            let indexes = scene
                .preorder
                .iter()
                .copied()
                .filter(|index| scene.nodes[*index].guid == id)
                .collect::<Vec<_>>();
            indexes.into_iter().map(move |index| SceneElement(SceneHandle::element(scene.clone(), index)))
        }
    }

    impl Element for SceneElement {
        type Context = ();
        type Node = SceneHandle;
        type Attribute = SceneAttribute;

        fn as_node(&self) -> Self::Node { self.0.clone() }
        fn prefix(&self) -> Option<Prefix> { None }
        fn namespace(&self) -> Namespace { ns!() }
        fn local_name(&self) -> LocalName {
            let SceneHandleKind::Element(index) = self.0.kind else { unreachable!() };
            LocalName::from(self.0.scene.nodes[index].node_type.as_str())
        }
        fn attributes(&self, _cx: &mut ()) -> impl Iterator<Item = Self::Attribute> {
            let SceneHandleKind::Element(owner) = self.0.kind else { unreachable!() };
            let scene = self.0.scene.clone();
            let count = self.0.scene.nodes[owner].attr_count();
            (0..count).map(move |index| SceneAttribute(SceneHandle::attribute(scene.clone(), owner, index)))
        }
        fn is_html_element_in_html_document(&self) -> bool { false }
    }

    impl Attribute for SceneAttribute {
        type Node = SceneHandle;

        fn as_node(&self) -> Self::Node { self.0.clone() }
        fn prefix(&self) -> Option<Prefix> { None }
        fn namespace(&self) -> Namespace { ns!() }
        fn local_name(&self) -> LocalName {
            let SceneHandleKind::Attribute { owner, index } = self.0.kind else { unreachable!() };
            LocalName::from(self.0.scene.nodes[owner].attr(index).map(|(name, _)| name).unwrap_or(""))
        }
    }

    fn read_guid_value(decoder: &mut Decoder<'_>) -> NifResult<String> {
        let session_id = decoder.read_var_uint()?;
        let local_id = decoder.read_var_uint()?;
        Ok(format!("{}:{}", session_id, local_id))
    }

    fn read_parent_index_value(decoder: &mut Decoder<'_>) -> NifResult<(String, String)> {
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

    fn read_scene_transform_value(decoder: &mut Decoder<'_>) -> NifResult<SceneTransform> {
        Ok(SceneTransform {
            m00: decoder.read_var_float_value()? as f64,
            m01: decoder.read_var_float_value()? as f64,
            m02: decoder.read_var_float_value()? as f64,
            m10: decoder.read_var_float_value()? as f64,
            m11: decoder.read_var_float_value()? as f64,
            m12: decoder.read_var_float_value()? as f64,
        })
    }

    fn scene_query_node(index: &SceneIndex, node_index: usize) -> SceneQueryNode {
        let node = &index.nodes[node_index];
        SceneQueryNode {
            guid: node.guid.clone(),
            node_type: node.node_type.clone(),
            name: node.name.clone(),
            parent_guid: node.parent_guid.clone(),
            position: node.position.clone(),
            size: node.size.clone(),
            transform: node.transform.clone(),
            visible: node.visible,
            locked: node.locked,
        }
    }

    pub fn build_scene_index_value(bytes: Binary<'_>) -> NifResult<ResourceArc<SceneIndexResource>> {
        let mut decoder = Decoder::new(bytes.as_slice());
        let mut nodes = Vec::new();
        decode_scene_index_message_from_decoder(&mut decoder, &mut nodes)?;
        decoder.finish()?;

        Ok(ResourceArc::new(SceneIndexResource { index: Arc::new(SceneIndex::new(nodes)) }))
    }

    pub fn query_scene_xpath_value<'a>(env: Env<'a>, bytes: Binary<'a>, xpath: String) -> NifResult<Term<'a>> {
        let resource = build_scene_index_value(bytes)?;
        query_scene_index_value(env, resource, xpath)
    }

    pub fn query_scene_index_value<'a>(
        env: Env<'a>,
        resource: ResourceArc<SceneIndexResource>,
        xpath: String,
    ) -> NifResult<Term<'a>> {
        let index = resource.index.clone();
        let root = SceneHandle::document(index.clone());
        let mut cx = ();
        let expression = servo_xpath::parse::<SceneNamespaceResolver>(&mut cx, &xpath, None, false)
            .map_err(|error| Error::Term(Box::new(format!("invalid XPath: {:?}", error))))?;
        let value = servo_xpath::evaluate_parsed_xpath::<SceneDom>(&mut cx, &expression, root)
            .map_err(|error| Error::Term(Box::new(format!("XPath evaluation failed: {:?}", error))))?;

        let matched = match value {
            Value::NodeSet(node_set) => node_set
                .into_iter()
                .filter_map(|handle| match handle.kind {
                    SceneHandleKind::Element(node_index) => Some(scene_query_node(&index, node_index)),
                    SceneHandleKind::Attribute { owner, .. } => Some(scene_query_node(&index, owner)),
                    SceneHandleKind::Document => None,
                })
                .collect::<Vec<_>>(),
            _ => Vec::new(),
        };

        Ok(matched.encode(env))
    }

    fn decode_scene_index_message_from_decoder(
        decoder: &mut Decoder<'_>,
        nodes: &mut Vec<SceneNodeRecord>,
    ) -> NifResult<()> {
        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(message_arms, 12)}
                4 => {
                    let len = decoder.read_var_uint()? as usize;
                    nodes.reserve(len);
                    for _ in 0..len {
                        nodes.push(decode_scene_index_node_change_from_decoder(decoder)?);
                    }
                },
                field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene index", field)))),
            }
        }
        Ok(())
    }

    fn decode_scene_index_node_change_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<SceneNodeRecord> {
        let mut guid = None;
        let mut node_type = None;
        let mut name = None;
        let mut parent_guid = None;
        let mut position = None;
        let mut size = None;
        let mut transform = None;
        let mut visible = None;
        let mut locked = None;

        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => guid = Some(read_guid_value(decoder)?),
                3 => {
                    let (parent, pos) = read_parent_index_value(decoder)?;
                    parent_guid = Some(parent);
                    position = Some(pos);
                },
                4 => node_type = Some(scene_node_type_name(decoder.read_var_uint()?).to_string()),
                5 => name = Some(decoder.read_string_value()?),
                6 => visible = Some(decoder.read_bool()?),
                7 => locked = Some(decoder.read_bool()?),
                11 => size = Some(read_scene_size_value(decoder)?),
                12 => transform = Some(read_scene_transform_value(decoder)?),
    #{indent(node_change_arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene index node", field)))),
            }
        }

        Ok(SceneNodeRecord {
            guid: guid.unwrap_or_default(),
            node_type: node_type.unwrap_or_else(|| "unknown".to_string()),
            name,
            parent_guid,
            position,
            size,
            transform,
            visible,
            locked,
            parent: None,
            children: Vec::new(),
        })
    }
    }
    """
  end

  defp node_type_name(definition_map) do
    arms =
      definition_map
      |> Map.fetch!("NodeType")
      |> then(& &1.fields)
      |> Enum.map_join("\n", fn field ->
        "#{field.value} => \"#{Macro.underscore(field.name)}\","
      end)

    """
    fn scene_node_type_name(value: u32) -> &'static str {
        match value {
    #{indent(arms, 8)}
            _ => "unknown",
        }
    }
    """
  end

  defp sparse_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    body = Enum.map_join(fields, "\n", &sparse_struct_field(&1, definition_map))
    capacity = length(fields) + 1

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        static MODULE_ATOM: OnceLock<Atom> = OnceLock::new();
        static MODULE_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
        let module_atom = cached_atom(env, &MODULE_ATOM, "Elixir.FigKiwi.Schema.#{name}");
        let module_key_atom = cached_atom(env, &MODULE_KEY_ATOM, "__kiwi_module__");
        let mut keys = Vec::with_capacity(#{capacity});
        let mut values = Vec::with_capacity(#{capacity});
        keys.push(module_key_atom.encode(env));
        values.push(module_atom.encode(env));
    #{indent(body, 4)}
        Term::map_from_term_arrays(env, &keys, &values)
    }
    """
  end

  defp sparse_definition(%Definition{kind: :enum, name: name, fields: fields}, _definition_map) do
    arms =
      Enum.map_join(fields, "\n", fn field ->
        "#{field.value} => { static ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new(); Ok(cached_atom(env, &ATOM_#{field.value}, \"#{Macro.underscore(field.name)}\").encode(env)) },"
      end)

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        match decoder.read_var_uint()? {
    #{indent(arms, 8)}
            value => Ok((value as i64).encode(env)),
        }
    }
    """
  end

  defp sparse_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    arms = Enum.map_join(fields, "\n", &sparse_message_arm(&1, definition_map))
    capacity = length(fields) + 1

    """
    fn decode_sparse_#{rust_ident(name)}_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
        static MODULE_ATOM: OnceLock<Atom> = OnceLock::new();
        static MODULE_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
        let module_atom = cached_atom(env, &MODULE_ATOM, "Elixir.FigKiwi.Schema.#{name}");
        let module_key_atom = cached_atom(env, &MODULE_KEY_ATOM, "__kiwi_module__");
        let mut keys = Vec::with_capacity(#{capacity});
        let mut values = Vec::with_capacity(#{capacity});
        keys.push(module_key_atom.encode(env));
        values.push(module_atom.encode(env));

        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding sparse #{name}", field)))),
            }
        }

        Term::map_from_term_arrays(env, &keys, &values)
    }
    """
  end

  defp sparse_entrypoints do
    [
      """
      #[rustler::nif(schedule = "DirtyCpu")]
      pub fn decode_sparse_message<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
          let mut decoder = Decoder::new(bytes.as_slice());
          let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
          decoder.finish()?;
          Ok(value)
      }
      """
    ]
  end

  defp sparse_struct_field(field, definition_map) do
    """
    {
        static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();
        let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");
    #{indent(sparse_decode_field(field, definition_map), 4)}
        keys.push(field_atom.encode(env));
        values.push(value);
    }
    """
  end

  defp sparse_message_arm(field, definition_map) do
    """
    #{field.value} => {
        static FIELD_ATOM_#{field.value}: OnceLock<Atom> = OnceLock::new();
        let field_atom = cached_atom(env, &FIELD_ATOM_#{field.value}, "#{Macro.underscore(field.name)}");
    #{indent(sparse_decode_field(field, definition_map), 4)}
        keys.push(field_atom.encode(env));
        values.push(value);
    },
    """
  end

  defp sparse_decode_field(%{array?: true, type: "byte"}, _definition_map) do
    "let value = decoder.read_byte_array(env)?;"
  end

  defp sparse_decode_field(%{array?: true} = field, definition_map) do
    inner = sparse_decode_scalar(%{field | array?: false}, definition_map)

    """
    let len = decoder.read_var_uint()? as usize;
    let mut items = Vec::with_capacity(len);
    for _ in 0..len {
    #{indent("let item = #{inner};", 4)}
        items.push(item);
    }
    let value = items.encode(env);
    """
  end

  defp sparse_decode_field(field, definition_map) do
    "let value = #{sparse_decode_scalar(field, definition_map)};"
  end

  defp sparse_decode_scalar(%{type: type}, definition_map) do
    cond do
      primitive = sparse_primitive_decode(type) ->
        primitive

      Map.get(definition_map, type) && Map.fetch!(definition_map, type).kind == :enum ->
        "decode_sparse_#{rust_ident(type)}_from_decoder(env, decoder)?"

      Map.get(definition_map, type) &&
          Map.fetch!(definition_map, type).kind in [:message, :struct] ->
        "decode_sparse_#{rust_ident(type)}_from_decoder(env, decoder)?"

      Map.has_key?(definition_map, type) ->
        "decode_#{rust_ident(type)}_from_decoder(env, decoder)?"
    end
  end

  defp sparse_primitive_decode("bool"), do: "decoder.read_bool()?.encode(env)"
  defp sparse_primitive_decode("byte"), do: "decoder.read_byte()?.encode(env)"
  defp sparse_primitive_decode("float"), do: "decoder.read_var_float(env)?"
  defp sparse_primitive_decode("int"), do: "decoder.read_var_int()?.encode(env)"
  defp sparse_primitive_decode("int64"), do: "decoder.read_var_int64()?.encode(env)"
  defp sparse_primitive_decode("string"), do: "decoder.read_string(env)?"
  defp sparse_primitive_decode("uint"), do: "decoder.read_var_uint()?.encode(env)"
  defp sparse_primitive_decode("uint64"), do: "decoder.read_var_uint64()?.encode(env)"
  defp sparse_primitive_decode(_type), do: nil

  defp skip_definition(%Definition{kind: :enum, name: name}, _definition_map) do
    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        decoder.read_var_uint()?;
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    body = Enum.map_join(fields, "\n", &skip_field(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
    #{indent(body, 4)}
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    arms = Enum.map_join(fields, "\n", &skip_message_arm(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while skipping #{name}", field)))),
            }
        }
        Ok(())
    }
    """
  end

  defp scene_summary(definition_map) do
    message_arms =
      definition_map
      |> Map.fetch!("Message")
      |> then(& &1.fields)
      |> Enum.reject(&(&1.value == 4))
      |> Enum.map_join("\n", &skip_message_arm(&1, definition_map))

    node_change_arms =
      definition_map
      |> Map.fetch!("NodeChange")
      |> then(& &1.fields)
      |> Enum.reject(&(&1.value in [1, 3, 4, 5, 6, 7, 11, 12]))
      |> Enum.map_join("\n", &skip_message_arm(&1, definition_map))

    [
      scene_xpath_runtime(message_arms, node_change_arms),
      """
      pub fn load(env: Env<'_>, _term: Term<'_>) -> bool {
          env.register::<scene_xpath_runtime::SceneIndexResource>().is_ok()
      }
      """,
      """
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
      """,
      """
      #[rustler::nif(schedule = "DirtyCpu")]
      pub fn build_scene_index(bytes: Binary<'_>) -> NifResult<rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>> {
          scene_xpath_runtime::build_scene_index_value(bytes)
      }
      """,
      """
      #[rustler::nif(schedule = "DirtyCpu")]
      pub fn query_scene_xpath<'a>(env: Env<'a>, bytes: Binary<'a>, xpath: String) -> NifResult<Term<'a>> {
          scene_xpath_runtime::query_scene_xpath_value(env, bytes, xpath)
      }
      """,
      """
      #[rustler::nif(schedule = "DirtyCpu")]
      pub fn query_scene_index<'a>(
          env: Env<'a>,
          index: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
          xpath: String,
      ) -> NifResult<Term<'a>> {
          scene_xpath_runtime::query_scene_index_value(env, index, xpath)
      }
      """,
      """
      fn decode_scene_message_from_decoder(
          decoder: &mut Decoder<'_>,
          node_count: &mut usize,
          parented_count: &mut usize,
          type_counts: &mut std::collections::HashMap<String, usize>,
      ) -> NifResult<()> {
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
      #{indent(message_arms, 12)}
                  4 => {
                      let len = decoder.read_var_uint()? as usize;
                      for _ in 0..len {
                          decode_scene_node_change_from_decoder(decoder, node_count, parented_count, type_counts)?;
                      }
                  },
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene summary", field)))),
              }
          }
          Ok(())
      }
      """,
      """
      fn decode_scene_node_change_from_decoder(
          decoder: &mut Decoder<'_>,
          node_count: &mut usize,
          parented_count: &mut usize,
          type_counts: &mut std::collections::HashMap<String, usize>,
      ) -> NifResult<()> {
          *node_count += 1;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  1 => skip_guid_from_decoder(decoder)?,
                  3 => {
                      skip_parent_index_from_decoder(decoder)?;
                      *parented_count += 1;
                  },
                  4 => {
                      let value = decoder.read_var_uint()?;
                      let name = scene_node_type_name(value).to_string();
                      *type_counts.entry(name).or_insert(0) += 1;
                  },
                  5 => decoder.skip_string()?,
                  6 => { decoder.read_bool()?; },
                  7 => { decoder.read_bool()?; },
                  11 => { skip_vector_from_decoder(decoder)?; },
                  12 => { skip_matrix_from_decoder(decoder)?; },
      #{indent(node_change_arms, 12)}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene node", field)))),
              }
          }
          Ok(())
      }
      """
    ]
  end

  defp skip_message_arm(field, definition_map) do
    "#{field.value} => { #{skip_field(field, definition_map)} },"
  end

  defp skip_field(%{array?: true, type: "byte"}, _definition_map) do
    "decoder.skip_byte_array()?;"
  end

  defp skip_field(%{array?: true} = field, definition_map) do
    inner = skip_field(%{field | array?: false}, definition_map)

    """
    {
        let len = decoder.read_var_uint()? as usize;
        for _ in 0..len {
    #{indent(inner, 8)}
        }
    }
    """
  end

  defp skip_field(%{type: type}, definition_map) do
    cond do
      primitive = @primitive_skip[type] ->
        primitive

      Map.has_key?(definition_map, type) ->
        "skip_#{rust_ident(type)}_from_decoder(decoder)?;"
    end
  end

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end

  defp indent(text, spaces) do
    padding = String.duplicate(" ", spaces)

    text
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map_join("\n", &(padding <> &1))
  end
end
