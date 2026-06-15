#[rustfmt::skip]
mod generated;
mod runtime;

fn load(env: rustler::Env, _term: rustler::Term) -> bool {
    generated::load(env, _term)
}

rustler::init!("Elixir.FigKiwi.Native.Nif", load = load);
