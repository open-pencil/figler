#[allow(dead_code)]

use rustler::types::atom::Atom;
use rustler::{Binary, Encoder, Env, Error, NifResult, Term};

use std::sync::OnceLock;

use crate::runtime::Decoder;

__rq_rustler_helpers!();

__rq_include!("templates/scene_types.rs");

__rq_definitions!();
__rq_entrypoints!();
__rq_sparse_decoders!();
__rq_skip_decoders!();
__rq_graph_focus_decoders!();

__rq_include!("templates/scene_xpath_runtime.rs");
__rq_include!("templates/scene_summary_decoders.rs");
__rq_include!("templates/scene_nifs.rs");
