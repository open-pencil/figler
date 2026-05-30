use rustler::types::atom::Atom;
use rustler::{Binary, Env, NifResult, Term};

use crate::runtime::Decoder;

kiwi_codegen::definitions!();
kiwi_codegen::entrypoints!();
