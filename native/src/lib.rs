#![allow(dead_code)]

#[rustfmt::skip]
include!("generated.rs");

mod runtime;

rustler::init!("Elixir.Figler.Native.Module", load = load);
