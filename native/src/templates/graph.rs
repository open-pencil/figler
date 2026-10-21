/// The native occurrence interpreter: source records and the effective graph built from them.
// Generated from Rusty-Elixir: `with ... else` fallbacks lower to single-arm matches, closures
// pass functions their arguments, references stay explicit, and list literals become vectors.
#[allow(
    clippy::redundant_closure,
    clippy::needless_borrow,
    clippy::manual_map,
    clippy::useless_vec
)]
pub mod graph {
    use super::*;
    use std::collections::{HashMap, HashSet};

    __rq_graph_records!();
    __rq_graph_prepare!();
    __rq_graph_source_index!();

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
}
