use crate::runtime::Decoder;
use rustler::types::atom::Atom;
use rustler::{Binary, Env, Error, NifResult, Term};
fn decode_guid_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GUID")?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "session_id")?, value)?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "local_id")?, value)?;
    Ok(term)
}
fn decode_vector_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Vector")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "x")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "y")?, value)?;
    Ok(term)
}
fn decode_matrix_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Matrix")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m00")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m01")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m02")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m10")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m11")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m12")?, value)?;
    Ok(term)
}
fn decode_parent_index_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ParentIndex")?;
    let value = decode_guid_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "guid")?, value)?;
    let value = decoder.read_string()?;
    term = term.map_put(Atom::from_str(env, "position")?, value)?;
    Ok(term)
}
fn decode_image_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Image")?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "hash")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "data_blob")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Image",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_guid<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_guid_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_vector<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_vector_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_matrix<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_matrix_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_parent_index<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_parent_index_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_image<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_image_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
