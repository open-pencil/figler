#![allow(dead_code)]

#[rustfmt::skip]
include!("generated.rs");

mod runtime;

rustler::init!("Elixir.FigKiwi.Native.Nif", load = load);
