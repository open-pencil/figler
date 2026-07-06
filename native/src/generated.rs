use rustler::types::atom::Atom;


use rustler::{Binary, Encoder, Env, Error, NifResult, Term};


use std::sync::OnceLock;


use crate::runtime::Decoder;


#[derive(Clone, Debug)]
pub struct KiwiSkipField {
    pub id: u32,
    pub kind: KiwiSkipKind,
}


pub type KiwiSkipFn = fn(&mut Decoder<'_>) -> NifResult<()>;


#[derive(Clone, Debug)]
pub enum KiwiSkipKind {
    One(KiwiSkipFn),
    Repeated(KiwiSkipFn),
    Bytes,
}


#[derive(Clone, Debug)]
pub struct KiwiSkipStructField {
    pub repeated: bool,
    pub bytes: bool,
    pub skip: KiwiSkipFn,
}


macro_rules! kiwi_skip_struct_decoder {
        (fn $name:ident;
        decoder $decoder:ident;
        fields [$($field_repeated:literal $field_bytes:literal $field_skip:ident;)*]) => {
                fn $name($decoder: &mut Decoder<'_>) -> NifResult<()> {
                        kiwi_skip_struct_fields($decoder, &[$(KiwiSkipStructField { repeated: $field_repeated, bytes: $field_bytes, skip: $field_skip },)*], 0)
                }
        };
}

fn kiwi_skip_bool_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_bool()?;
    Ok(())
}


fn kiwi_skip_byte_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_byte()?;
    Ok(())
}


fn kiwi_skip_float_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_float_value()?;
    Ok(())
}


fn kiwi_skip_int_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_int()?;
    Ok(())
}


fn kiwi_skip_int64_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_int64()?;
    Ok(())
}


fn kiwi_skip_string_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.skip_string()?;
    Ok(())
}


fn kiwi_skip_uint_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_uint()?;
    Ok(())
}


fn kiwi_skip_uint64_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.read_var_uint64()?;
    Ok(())
}


fn kiwi_skip_bytes_value(decoder: &mut Decoder<'_>) -> NifResult<()> {
    decoder.skip_byte_array()?;
    Ok(())
}


fn kiwi_skip_repeated(decoder: &mut Decoder<'_>, item: KiwiSkipFn) -> NifResult<()> {
    decoder.read_repeated(|decoder| item(decoder))?;
    Ok(())
}


fn kiwi_skip_struct_field(
    decoder: &mut Decoder<'_>,
    field: &KiwiSkipStructField,
) -> NifResult<()> {
    let skip = field.skip;
    if field.bytes {
        kiwi_skip_bytes_value(decoder)
    } else {
        if field.repeated { kiwi_skip_repeated(decoder, skip) } else { skip(decoder) }
    }
}


fn kiwi_skip_struct_fields(
    decoder: &mut Decoder<'_>,
    fields: &[KiwiSkipStructField],
    index: usize,
) -> NifResult<()> {
    if index == fields.len() {
        Ok(())
    } else {
        let field = fields.get(index).unwrap();
        kiwi_skip_struct_field(decoder, field)?;
        kiwi_skip_struct_fields(decoder, fields, index + 1)
    }
}


fn kiwi_skip_message_fields(
    decoder: &mut Decoder<'_>,
    _definition_name: &str,
    fields: &[KiwiSkipField],
) -> NifResult<()> {
    let field_id = decoder.read_var_uint()?;
    if field_id == 0 {
        Ok(())
    } else {
        match fields.binary_search_by_key(&field_id, |field| field.id) {
            Ok(index) => {
                let matched_field = fields.get(index).unwrap();
                kiwi_skip_kind(decoder, &matched_field.kind)?;
                kiwi_skip_message_fields(decoder, _definition_name, fields)
            }
            Err(_index) => Err(rustler::Error::BadArg),
        }
    }
}


fn kiwi_skip_kind(decoder: &mut Decoder<'_>, kind: &KiwiSkipKind) -> NifResult<()> {
    match kind {
        KiwiSkipKind::One(skip) => skip(decoder),
        KiwiSkipKind::Repeated(skip) => kiwi_skip_repeated(decoder, *skip),
        KiwiSkipKind::Bytes => kiwi_skip_bytes_value(decoder),
    }
}


pub type KiwiSparseDecodeFn = for<'a> fn(
    Env<'a>,
    &mut Decoder<'_>,
) -> NifResult<Term<'a>>;


#[derive(Clone, Debug)]
pub struct KiwiSparseEnumVariant {
    pub value: u32,
    pub name: &'static str,
}


#[derive(Clone, Debug)]
pub struct KiwiSparseField {
    pub id: u32,
    pub name: &'static str,
    pub repeated: bool,
    pub decode: KiwiSparseDecodeFn,
}


#[derive(Clone, Debug)]
pub struct KiwiSparseStructField {
    pub name: &'static str,
    pub repeated: bool,
    pub decode: KiwiSparseDecodeFn,
}


macro_rules! kiwi_sparse_enum_decoder {
        (fn $name:ident;
        env $env:ident;
        decoder $decoder:ident;
        variants [$($variant_value:literal $variant_name:literal;)*]) => {
                fn $name<'a>($env: Env<'a>, $decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
                        kiwi_sparse_enum_value($env, $decoder, &[$(KiwiSparseEnumVariant { value: $variant_value, name: $variant_name },)*])
                }
        };
}

macro_rules! kiwi_sparse_struct_decoder {
        (fn $name:ident;
        env $env:ident;
        decoder $decoder:ident;
        module $module_name:literal;
        capacity $capacity:literal;
        fields [$($field_name:literal $field_repeated:literal $field_decode:ident;)*]) => {
                fn $name<'a>($env: Env<'a>, $decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
                        kiwi_sparse_struct_fields($env, $decoder, $module_name, $capacity, &[$(KiwiSparseStructField { name: $field_name, repeated: $field_repeated, decode: $field_decode },)*])
                }
        };
}

macro_rules! kiwi_sparse_skip_message_descriptor_decoder {
        (sparse_fn $sparse_name:ident;
        skip_fn $skip_name:ident;
        env $env:ident;
        decoder $decoder:ident;
        module $module_name:literal;
        definition $definition_name:literal;
        capacity $capacity:literal;
        fields [$($field_id:literal => $field_name:literal: $field_repeated:literal $field_decode:ident; $field_skip_repeated:literal $field_skip_bytes:literal $field_skip:ident;)*]) => {
                fn $sparse_name<'a>($env: Env<'a>, $decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
                        kiwi_sparse_message_fields($env, $decoder, $module_name, $definition_name, $capacity, &[$(KiwiSparseField { id: $field_id, name: $field_name, repeated: $field_repeated, decode: $field_decode },)*])
                }
                
                fn $skip_name($decoder: &mut Decoder<'_>) -> NifResult<()> {
                        kiwi_skip_message_fields($decoder, $definition_name, &[$(KiwiSkipField { id: $field_id, kind: kiwi_skip_descriptor_kind($field_skip_repeated, $field_skip_bytes, $field_skip) },)*])
                }
        };
}

fn kiwi_sparse_bool_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_bool()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_byte_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_byte()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_float_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    decoder.read_var_float(env)
}


fn kiwi_sparse_int_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_var_int()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_int64_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_var_int64()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_string_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    decoder.read_string(env)
}


fn kiwi_sparse_uint_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_var_uint()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_uint64_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let value = decoder.read_var_uint64()?;
    Ok(value.encode(env))
}


fn kiwi_sparse_bytes_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    decoder.read_byte_array(env)
}


fn kiwi_sparse_enum_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    variants: &[KiwiSparseEnumVariant],
) -> NifResult<Term<'a>> {
    let value = decoder.read_var_uint()?;
    match variants.binary_search_by_key(&value, |variant| variant.value) {
        Ok(index) => {
            let variant = variants.get(index).unwrap();
            Ok(Atom::from_str(env, variant.name).unwrap().encode(env))
        }
        Err(_index) => Ok(value.encode(env)),
    }
}


fn kiwi_sparse_field_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    field: &KiwiSparseField,
) -> NifResult<Term<'a>> {
    let decode = field.decode;
    if field.repeated {
        let values = decoder.read_repeated(|decoder| decode(env, decoder))?;
        Ok(values.encode(env))
    } else {
        decode(env, decoder)
    }
}


fn kiwi_sparse_struct_field_value<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    field: &KiwiSparseStructField,
) -> NifResult<Term<'a>> {
    let decode = field.decode;
    if field.repeated {
        let value = decoder.read_repeated(|decoder| decode(env, decoder))?;
        Ok(value.encode(env))
    } else {
        decode(env, decoder)
    }
}


fn kiwi_sparse_struct_fields<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    module_name: &str,
    capacity: usize,
    fields: &[KiwiSparseStructField],
) -> NifResult<Term<'a>> {
    let module_atom = Atom::from_str(env, module_name).unwrap();
    let module_key_atom = Atom::from_str(env, "__kiwi_module__").unwrap();
    let mut keys = Vec::with_capacity(capacity);
    let mut values = Vec::with_capacity(capacity);
    keys.push(module_key_atom.encode(env));
    values.push(module_atom.encode(env));
    kiwi_sparse_struct_fields_remaining(
        env,
        decoder,
        fields,
        0,
        &mut keys,
        &mut values,
    )?;
    Term::map_from_term_arrays(env, &keys, &values)
}


fn kiwi_skip_descriptor_kind(
    repeated: bool,
    bytes: bool,
    skip: KiwiSkipFn,
) -> KiwiSkipKind {
    let non_bytes_kind = if repeated {
        KiwiSkipKind::Repeated(skip)
    } else {
        KiwiSkipKind::One(skip)
    };
    if bytes { KiwiSkipKind::Bytes } else { non_bytes_kind }
}


fn kiwi_sparse_struct_fields_remaining<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    fields: &[KiwiSparseStructField],
    index: usize,
    keys: &mut Vec<Term<'a>>,
    values: &mut Vec<Term<'a>>,
) -> NifResult<()> {
    if index == fields.len() {
        Ok(())
    } else {
        let field = fields.get(index).unwrap();
        keys.push(Atom::from_str(env, field.name).unwrap().encode(env));
        values.push(kiwi_sparse_struct_field_value(env, decoder, field)?);
        kiwi_sparse_struct_fields_remaining(
            env,
            decoder,
            fields,
            index + 1,
            keys,
            values,
        )
    }
}


fn kiwi_sparse_message_fields<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    module_name: &str,
    _definition_name: &str,
    capacity: usize,
    fields: &[KiwiSparseField],
) -> NifResult<Term<'a>> {
    let module_atom = Atom::from_str(env, module_name).unwrap();
    let module_key_atom = Atom::from_str(env, "__kiwi_module__").unwrap();
    let mut keys = Vec::with_capacity(capacity);
    let mut values = Vec::with_capacity(capacity);
    keys.push(module_key_atom.encode(env));
    values.push(module_atom.encode(env));
    kiwi_sparse_message_fields_remaining(env, decoder, fields, &mut keys, &mut values)?;
    Term::map_from_term_arrays(env, &keys, &values)
}


fn kiwi_sparse_message_fields_remaining<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
    fields: &[KiwiSparseField],
    keys: &mut Vec<Term<'a>>,
    values: &mut Vec<Term<'a>>,
) -> NifResult<()> {
    let field_id = decoder.read_var_uint()?;
    if field_id == 0 {
        Ok(())
    } else {
        match fields.binary_search_by_key(&field_id, |field| field.id) {
            Ok(index) => {
                let field = fields.get(index).unwrap();
                keys.push(Atom::from_str(env, field.name).unwrap().encode(env));
                values.push(kiwi_sparse_field_value(env, decoder, field)?);
                kiwi_sparse_message_fields_remaining(env, decoder, fields, keys, values)
            }
            Err(_index) => Err(rustler::Error::BadArg),
        }
    }
}


fn cached_atom(env: Env, cell: &OnceLock<Atom>, name: &str) -> Atom {
    *cell.get_or_init(|| Atom::from_str(env, name).unwrap())
}


fn cached_struct_keys(
    env: Env<'_>,
    cache: &'static OnceLock<Vec<rustler::wrapper::NIF_TERM>>,
    fields: &[&str],
) -> &'static [rustler::wrapper::NIF_TERM] {
    cache
        .get_or_init(|| {
            let mut keys = Vec::with_capacity(fields.len() + 1);
            keys.push(Atom::from_str(env, "__struct__").unwrap().as_c_arg());
            for field in fields {
                keys.push(Atom::from_str(env, field).unwrap().as_c_arg());
            }
            keys
        })
}


fn default_struct_values(
    env: Env<'_>,
    module: Atom,
    len: usize,
) -> Vec<rustler::wrapper::NIF_TERM> {
    let mut values = Vec::with_capacity(len + 1);
    values.resize(len + 1, Atom::from_str(env, "nil").unwrap().as_c_arg());
    values[0] = module.as_c_arg();
    values
}


fn make_struct_from_nif_term_arrays<'a>(
    env: Env<'a>,
    keys: &[rustler::wrapper::NIF_TERM],
    values: &[rustler::wrapper::NIF_TERM],
) -> NifResult<Term<'a>> {
    if keys.len() == values.len() {
        unsafe {
            rustler::wrapper::map::make_map_from_arrays(env.as_c_arg(), keys, values)
                .map(|term| Term::new(env, term))
                .ok_or(rustler::Error::BadArg)
        }
    } else {
        Err(rustler::Error::BadArg)
    }
}


kiwi_sparse_enum_decoder! { 
    fn decode_sparse_message_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "join_start";
        1 "node_changes";
        2 "user_changes";
        3 "join_end";
        4 "signal";
        5 "style";
        6 "style_set";
        7 "join_start_skip_reload";
        8 "notify_should_upgrade";
        9 "upgrade_done";
        10 "upgrade_refresh";
        11 "scene_graph_query";
        12 "scene_graph_reply";
        13 "diff";
        14 "client_broadcast";
        15 "join_start_journaled";
        16 "stream_start";
        17 "stream_end";
        18 "interactive_slide_change";
        19 "reconnect_scene_graph_query";
        20 "reconnect_scene_graph_reply";
        21 "join_end_incremental_reconnect";
        22 "node_status_change";
        23 "client_rendered";
        24 "buzz_approval_change";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_axis_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "x";
        1 "y";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_access_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "read_only";
        1 "read_write";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_node_phase_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "created";
        1 "removed";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_winding_rule_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "nonzero";
        1 "odd";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_node_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "document";
        2 "canvas";
        3 "group";
        4 "frame";
        5 "boolean_operation";
        6 "vector";
        7 "star";
        8 "line";
        9 "ellipse";
        10 "rectangle";
        11 "regular_polygon";
        12 "rounded_rectangle";
        13 "text";
        14 "slice";
        15 "symbol";
        16 "instance";
        17 "sticky";
        18 "shape_with_text";
        19 "connector";
        20 "code_block";
        21 "widget";
        22 "stamp";
        23 "media";
        24 "highlight";
        25 "section";
        26 "section_overlay";
        27 "washi_tape";
        28 "variable";
        29 "table";
        30 "table_cell";
        31 "variable_set";
        32 "slide";
        33 "assisted_layout";
        34 "interactive_slide_element";
        35 "variable_override";
        36 "module";
        37 "slide_grid";
        38 "slide_row";
        39 "responsive_set";
        40 "code_component";
        41 "text_path";
        42 "code_instance";
        43 "code_library";
        44 "code_file";
        45 "code_layer";
        46 "brush";
        47 "managed_string";
        48 "transform";
        49 "cms_rich_text";
        50 "repeater";
        51 "jsx";
        52 "embedded_prototype";
        53 "react_fiber";
        54 "responsive_node_set";
        55 "webpage";
        56 "keyframe";
        57 "keyframe_track";
        58 "animation_preset_instance";
        59 "code_embed";
        60 "binary_file";
        61 "spec_block";
        62 "tool_instance";
        63 "custom_effect_instance";
        64 "native_code_layer_instance";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_shape_with_text_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "square";
        1 "ellipse";
        2 "diamond";
        3 "triangle_up";
        4 "triangle_down";
        5 "rounded_rectangle";
        6 "parallelogram_right";
        7 "parallelogram_left";
        8 "eng_database";
        9 "eng_queue";
        10 "eng_file";
        11 "eng_folder";
        12 "trapezoid";
        13 "predefined_process";
        14 "shield";
        15 "document_single";
        16 "document_multiple";
        17 "manual_input";
        18 "hexagon";
        19 "chevron";
        20 "pentagon";
        21 "octagon";
        22 "star";
        23 "plus";
        24 "arrow_left";
        25 "arrow_right";
        26 "summing_junction";
        27 "or";
        28 "speech_bubble";
        29 "internal_storage";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_blend_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "pass_through";
        1 "normal";
        2 "darken";
        3 "multiply";
        4 "linear_burn";
        5 "color_burn";
        6 "lighten";
        7 "screen";
        8 "linear_dodge";
        9 "color_dodge";
        10 "overlay";
        11 "soft_light";
        12 "hard_light";
        13 "difference";
        14 "exclusion";
        15 "hue";
        16 "saturation";
        17 "color";
        18 "luminosity";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_paint_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "solid";
        1 "gradient_linear";
        2 "gradient_radial";
        3 "gradient_angular";
        4 "gradient_diamond";
        5 "image";
        6 "emoji";
        7 "video";
        8 "pattern";
        9 "noise";
        10 "custom";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_image_scale_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "stretch";
        1 "fit";
        2 "fill";
        3 "tile";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_effect_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "inner_shadow";
        1 "drop_shadow";
        2 "foreground_blur";
        3 "background_blur";
        4 "repeat";
        5 "symmetry";
        6 "grain";
        7 "noise";
        8 "glass";
        9 "custom";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_case_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "original";
        1 "upper";
        2 "lower";
        3 "title";
        4 "small_caps";
        5 "small_caps_forced";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_decoration_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "underline";
        2 "strikethrough";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_decoration_style_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "solid";
        1 "dotted";
        2 "wavy";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_leading_trim_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "cap_height";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_number_units_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "raw";
        1 "pixels";
        2 "percent";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_constraint_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "min";
        1 "center";
        2 "max";
        3 "stretch";
        4 "scale";
        5 "fixed_min";
        6 "fixed_max";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stroke_align_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "center";
        1 "inside";
        2 "outside";
        3 "offset";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stroke_cap_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "round";
        2 "square";
        3 "arrow_lines";
        4 "arrow_equilateral";
        5 "diamond_filled";
        6 "triangle_filled";
        7 "highlight";
        8 "washi_tape_1";
        9 "washi_tape_2";
        10 "washi_tape_3";
        11 "washi_tape_4";
        12 "washi_tape_5";
        13 "washi_tape_6";
        14 "circle_filled";
        15 "erd_zero_or_one";
        16 "erd_exactly_one";
        17 "erd_zero_or_more";
        18 "erd_one_or_more";
        19 "erd_one";
        20 "erd_many";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stroke_join_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "miter";
        1 "bevel";
        2 "round";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_boolean_operation_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "union";
        1 "intersect";
        2 "subtract";
        3 "xor";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_align_horizontal_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "left";
        1 "center";
        2 "right";
        3 "justified";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_align_vertical_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "top";
        1 "center";
        2 "bottom";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_mouse_cursor_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "crosshair";
        2 "eyedropper";
        3 "hand";
        4 "paint_bucket";
        5 "pen";
        6 "pencil";
        7 "marker";
        8 "eraser";
        9 "highlighter";
        10 "lasso";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_vector_mirror_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "angle";
        2 "angle_and_length";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_image_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "png";
        1 "jpeg";
        2 "svg";
        3 "pdf";
        4 "mp4";
        5 "gif";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_export_constraint_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "content_scale";
        1 "content_width";
        2 "content_height";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_layout_grid_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "min";
        1 "center";
        2 "stretch";
        3 "max";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_layout_grid_pattern_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "stripes";
        1 "grid";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_auto_resize_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "width_and_height";
        2 "height";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_text_truncation_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "disabled";
        1 "ending";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_style_set_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "personal";
        1 "team";
        2 "custom";
        3 "frequency";
        4 "temporary";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_style_set_content_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "solid";
        1 "gradient";
        2 "image";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "horizontal";
        2 "vertical";
        3 "grid";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_align_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "min";
        1 "center";
        2 "max";
        3 "baseline";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_counter_align_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "min";
        1 "center";
        2 "max";
        3 "stretch";
        4 "auto";
        5 "baseline";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_justify_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "min";
        1 "center";
        2 "max";
        3 "space_evenly";
        4 "space_between";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_grid_child_align_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "min";
        2 "center";
        3 "max";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_grid_auto_tracks_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "rows";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_size_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "fixed";
        1 "resize_to_fit";
        2 "resize_to_fit_with_implicit_size";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_positioning_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "absolute";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_wrap_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "no_wrap";
        1 "wrap";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_stack_counter_align_content_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "space_between";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connection_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "internal_node";
        2 "url";
        3 "back";
        4 "close";
        5 "set_variable";
        6 "update_media_runtime";
        7 "conditional";
        8 "set_variable_mode";
        9 "object_animation";
        10 "update_animation_timeline_state";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_interaction_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "on_click";
        1 "after_timeout";
        2 "mouse_in";
        3 "mouse_out";
        4 "on_hover";
        5 "mouse_down";
        6 "mouse_up";
        7 "on_press";
        8 "none";
        9 "drag";
        10 "on_key_down";
        11 "on_voice";
        12 "on_media_hit";
        13 "on_media_end";
        14 "mouse_enter";
        15 "mouse_leave";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transition_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "instant_transition";
        1 "dissolve";
        2 "fade";
        3 "slide_from_left";
        4 "slide_from_right";
        5 "slide_from_top";
        6 "slide_from_bottom";
        7 "push_from_left";
        8 "push_from_right";
        9 "push_from_top";
        10 "push_from_bottom";
        11 "move_from_left";
        12 "move_from_right";
        13 "move_from_top";
        14 "move_from_bottom";
        15 "slide_out_to_left";
        16 "slide_out_to_right";
        17 "slide_out_to_top";
        18 "slide_out_to_bottom";
        19 "move_out_to_left";
        20 "move_out_to_right";
        21 "move_out_to_top";
        22 "move_out_to_bottom";
        23 "magic_move";
        24 "smart_animate";
        25 "scroll_animate";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_easing_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "in_cubic";
        1 "out_cubic";
        2 "inout_cubic";
        3 "linear";
        4 "in_back_cubic";
        5 "out_back_cubic";
        6 "inout_back_cubic";
        7 "custom_cubic";
        8 "spring";
        9 "gentle_spring";
        10 "custom_spring";
        11 "spring_preset_one";
        12 "spring_preset_two";
        13 "spring_preset_three";
        14 "hold";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scroll_direction_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "horizontal";
        2 "vertical";
        3 "both";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scroll_contracted_state_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "expanded";
        1 "contracted";
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_guid_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUID";
    capacity 3;
    fields [
        "session_id" false kiwi_sparse_uint_value;
        "local_id" false kiwi_sparse_uint_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_color_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Color";
    capacity 5;
    fields [
        "r" false kiwi_sparse_float_value;
        "g" false kiwi_sparse_float_value;
        "b" false kiwi_sparse_float_value;
        "a" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_vector_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Vector";
    capacity 3;
    fields [
        "x" false kiwi_sparse_float_value;
        "y" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_rect_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Rect";
    capacity 5;
    fields [
        "x" false kiwi_sparse_float_value;
        "y" false kiwi_sparse_float_value;
        "w" false kiwi_sparse_float_value;
        "h" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_color_stop_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorStop";
    capacity 3;
    fields [
        "color" false decode_sparse_color_from_decoder;
        "position" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_color_stop_var_from_decoder;
    skip_fn skip_color_stop_var_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorStopVar";
    definition "ColorStopVar";
    capacity 4;
    fields [
        1 => "color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        2 => "color_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "position": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_matrix_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Matrix";
    capacity 7;
    fields [
        "m00" false kiwi_sparse_float_value;
        "m01" false kiwi_sparse_float_value;
        "m02" false kiwi_sparse_float_value;
        "m10" false kiwi_sparse_float_value;
        "m11" false kiwi_sparse_float_value;
        "m12" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_parent_index_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ParentIndex";
    capacity 3;
    fields [
        "guid" false decode_sparse_guid_from_decoder;
        "position" false kiwi_sparse_string_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_number_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Number";
    capacity 3;
    fields [
        "value" false kiwi_sparse_float_value;
        "units" false decode_sparse_number_units_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_font_name_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FontName";
    capacity 4;
    fields [
        "family" false kiwi_sparse_string_value;
        "style" false kiwi_sparse_string_value;
        "postscript" false kiwi_sparse_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_variant_numeric_figure_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "lining";
        2 "oldstyle";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_variant_numeric_spacing_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "proportional";
        2 "tabular";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_variant_numeric_fraction_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "diagonal";
        2 "stacked";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_variant_caps_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "small";
        2 "all_small";
        3 "petite";
        4 "all_petite";
        5 "unicase";
        6 "titling";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_variant_position_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "sub";
        2 "super";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_font_style_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "italic";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_semantic_weight_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "bold";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_semantic_italic_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "italic";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_code_snapshot_state_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "initial";
        1 "snapshotting";
        2 "ok";
        3 "snapshot_error";
        4 "llm_in_progress";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_snapshot_capture_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "full";
        1 "partial";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_source_info_from_decoder;
    skip_fn skip_code_source_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeSourceInfo";
    definition "CodeSourceInfo";
    capacity 7;
    fields [
        1 => "origin_reference_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "origin_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "linked_snapshot_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "capture_mode": false decode_sparse_snapshot_capture_mode_from_decoder; false false kiwi_skip_uint_value;
        5 => "source_blob_ref": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "source_element_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_code_object_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "web_layer";
        1 "web_interaction";
        2 "native_layer";
        3 "animation_preset";
        4 "tool";
        5 "custom_effect";
        6 "plugin";
        7 "web_layer_generic";
        8 "custom_fill";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_custom_tool_artifact_ref_from_decoder;
    skip_fn skip_custom_tool_artifact_ref_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CustomToolArtifactRef";
    definition "CustomToolArtifactRef";
    capacity 5;
    fields [
        1 => "custom_tool_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "custom_tool_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "published_custom_tool_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "published_custom_tool_version_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_lock_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "all";
        2 "background_only";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_open_type_feature_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "pcap";
        1 "c2_pc";
        2 "case";
        3 "cpsp";
        4 "titl";
        5 "unic";
        6 "zero";
        7 "sinf";
        8 "ordn";
        9 "afrc";
        10 "dnom";
        11 "numr";
        12 "liga";
        13 "clig";
        14 "dlig";
        15 "hlig";
        16 "rlig";
        17 "aalt";
        18 "calt";
        19 "rclt";
        20 "salt";
        21 "rvrn";
        22 "vert";
        23 "swsh";
        24 "cswh";
        25 "nalt";
        26 "ccmp";
        27 "stch";
        28 "hist";
        29 "size";
        30 "ornm";
        31 "ital";
        32 "rand";
        33 "dtls";
        34 "flac";
        35 "mgrk";
        36 "ssty";
        37 "kern";
        38 "fwid";
        39 "hwid";
        40 "halt";
        41 "twid";
        42 "qwid";
        43 "pwid";
        44 "just";
        45 "lfbd";
        46 "opbd";
        47 "rtbd";
        48 "palt";
        49 "pkna";
        50 "ltra";
        51 "ltrm";
        52 "rtla";
        53 "rtlm";
        54 "abrv";
        55 "abvm";
        56 "abvs";
        57 "valt";
        58 "vhal";
        59 "blwf";
        60 "blwm";
        61 "blws";
        62 "akhn";
        63 "cjct";
        64 "cfar";
        65 "cpct";
        66 "curs";
        67 "dist";
        68 "expt";
        69 "falt";
        70 "fina";
        71 "fin2";
        72 "fin3";
        73 "half";
        74 "haln";
        75 "hkna";
        76 "hngl";
        77 "hojo";
        78 "init";
        79 "isol";
        80 "jp78";
        81 "jp83";
        82 "jp90";
        83 "jp04";
        84 "ljmo";
        85 "locl";
        86 "mark";
        87 "medi";
        88 "med2";
        89 "mkmk";
        90 "nlck";
        91 "nukt";
        92 "pref";
        93 "pres";
        94 "vpal";
        95 "pstf";
        96 "psts";
        97 "rkrf";
        98 "rphf";
        99 "ruby";
        100 "smpl";
        101 "tjmo";
        102 "tnam";
        103 "trad";
        104 "vatu";
        105 "vjmo";
        106 "vkna";
        107 "vkrn";
        108 "vrtr";
        109 "vrt2";
        110 "ss01";
        111 "ss02";
        112 "ss03";
        113 "ss04";
        114 "ss05";
        115 "ss06";
        116 "ss07";
        117 "ss08";
        118 "ss09";
        119 "ss10";
        120 "ss11";
        121 "ss12";
        122 "ss13";
        123 "ss14";
        124 "ss15";
        125 "ss16";
        126 "ss17";
        127 "ss18";
        128 "ss19";
        129 "ss20";
        130 "cv01";
        131 "cv02";
        132 "cv03";
        133 "cv04";
        134 "cv05";
        135 "cv06";
        136 "cv07";
        137 "cv08";
        138 "cv09";
        139 "cv10";
        140 "cv11";
        141 "cv12";
        142 "cv13";
        143 "cv14";
        144 "cv15";
        145 "cv16";
        146 "cv17";
        147 "cv18";
        148 "cv19";
        149 "cv20";
        150 "cv21";
        151 "cv22";
        152 "cv23";
        153 "cv24";
        154 "cv25";
        155 "cv26";
        156 "cv27";
        157 "cv28";
        158 "cv29";
        159 "cv30";
        160 "cv31";
        161 "cv32";
        162 "cv33";
        163 "cv34";
        164 "cv35";
        165 "cv36";
        166 "cv37";
        167 "cv38";
        168 "cv39";
        169 "cv40";
        170 "cv41";
        171 "cv42";
        172 "cv43";
        173 "cv44";
        174 "cv45";
        175 "cv46";
        176 "cv47";
        177 "cv48";
        178 "cv49";
        179 "cv50";
        180 "cv51";
        181 "cv52";
        182 "cv53";
        183 "cv54";
        184 "cv55";
        185 "cv56";
        186 "cv57";
        187 "cv58";
        188 "cv59";
        189 "cv60";
        190 "cv61";
        191 "cv62";
        192 "cv63";
        193 "cv64";
        194 "cv65";
        195 "cv66";
        196 "cv67";
        197 "cv68";
        198 "cv69";
        199 "cv70";
        200 "cv71";
        201 "cv72";
        202 "cv73";
        203 "cv74";
        204 "cv75";
        205 "cv76";
        206 "cv77";
        207 "cv78";
        208 "cv79";
        209 "cv80";
        210 "cv81";
        211 "cv82";
        212 "cv83";
        213 "cv84";
        214 "cv85";
        215 "cv86";
        216 "cv87";
        217 "cv88";
        218 "cv89";
        219 "cv90";
        220 "cv91";
        221 "cv92";
        222 "cv93";
        223 "cv94";
        224 "cv95";
        225 "cv96";
        226 "cv97";
        227 "cv98";
        228 "cv99";
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_export_constraint_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ExportConstraint";
    capacity 3;
    fields [
        "type" false decode_sparse_export_constraint_type_from_decoder;
        "value" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_guid_mapping_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDMapping";
    capacity 3;
    fields [
        "from" false decode_sparse_guid_from_decoder;
        "to" false decode_sparse_guid_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_blob_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Blob";
    capacity 2;
    fields [
        "bytes" false kiwi_sparse_bytes_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_image_from_decoder;
    skip_fn skip_image_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Image";
    definition "Image";
    capacity 4;
    fields [
        1 => "hash": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        2 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "data_blob": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_video_from_decoder;
    skip_fn skip_video_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Video";
    definition "Video";
    capacity 3;
    fields [
        1 => "hash": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        2 => "s3_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_paste_source_from_decoder;
    skip_fn skip_paste_source_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PasteSource";
    definition "PasteSource";
    capacity 3;
    fields [
        1 => "src_file": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "src_node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_filter_color_adjust_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FilterColorAdjust";
    capacity 9;
    fields [
        "tint" false kiwi_sparse_float_value;
        "shadows" false kiwi_sparse_float_value;
        "highlights" false kiwi_sparse_float_value;
        "detail" false kiwi_sparse_float_value;
        "exposure" false kiwi_sparse_float_value;
        "vignette" false kiwi_sparse_float_value;
        "temperature" false kiwi_sparse_float_value;
        "vibrance" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_paint_filter_message_from_decoder;
    skip_fn skip_paint_filter_message_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PaintFilterMessage";
    definition "PaintFilterMessage";
    capacity 11;
    fields [
        1 => "tint": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "shadows": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "highlights": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "detail": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "exposure": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        6 => "vignette": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "temperature": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "vibrance": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        9 => "contrast": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        10 => "brightness": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_paint_from_decoder;
    skip_fn skip_paint_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Paint";
    definition "Paint";
    capacity 43;
    fields [
        1 => "type": false decode_sparse_paint_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        3 => "opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "visible": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "blend_mode": false decode_sparse_blend_mode_from_decoder; false false kiwi_skip_uint_value;
        6 => "stops": true decode_sparse_color_stop_from_decoder; true false skip_color_stop_from_decoder;
        7 => "transform": false decode_sparse_matrix_from_decoder; false false skip_matrix_from_decoder;
        8 => "image": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        9 => "image_thumbnail": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        10 => "image_scale_mode": false decode_sparse_image_scale_mode_from_decoder; false false kiwi_skip_uint_value;
        11 => "rotation": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        12 => "scale": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        13 => "filter_color_adjust": false decode_sparse_filter_color_adjust_from_decoder; false false skip_filter_color_adjust_from_decoder;
        14 => "paint_filter": false decode_sparse_paint_filter_message_from_decoder; false false skip_paint_filter_message_from_decoder;
        15 => "emoji_code_points": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        16 => "animated_image": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        17 => "animation_frame": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        18 => "video": false decode_sparse_video_from_decoder; false false skip_video_from_decoder;
        19 => "original_image_width": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        20 => "original_image_height": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        21 => "color_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        22 => "image_should_color_manage": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        23 => "stops_var": true decode_sparse_color_stop_var_from_decoder; true false skip_color_stop_var_from_decoder;
        24 => "thumb_hash_base64": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        25 => "thumb_hash": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        26 => "source_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        27 => "spacing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        28 => "pattern_tile_type": false decode_sparse_pattern_tile_type_from_decoder; false false kiwi_skip_uint_value;
        29 => "vertical_alignment": false decode_sparse_pattern_alignment_from_decoder; false false kiwi_skip_uint_value;
        30 => "horizontal_alignment": false decode_sparse_pattern_alignment_from_decoder; false false kiwi_skip_uint_value;
        31 => "image_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        32 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        33 => "alt_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        34 => "noise_type": false decode_sparse_noise_type_from_decoder; false false kiwi_skip_uint_value;
        35 => "density": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        36 => "noise_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        37 => "pattern_spacing": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        38 => "opacity_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        39 => "custom_effect_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
        40 => "component_prop_assignments": true decode_sparse_component_prop_assignment_from_decoder; true false skip_component_prop_assignment_from_decoder;
        41 => "interpolation_color_space": false decode_sparse_interpolation_color_space_from_decoder; false false kiwi_skip_uint_value;
        42 => "interpolation_hue_method": false decode_sparse_interpolation_hue_method_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_noise_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "multitone";
        1 "monotone";
        2 "duotone";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_pattern_tile_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "rectangular";
        1 "horizontal_hexagonal";
        2 "vertical_hexagonal";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_pattern_alignment_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "start";
        1 "center";
        2 "end";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_interpolation_color_space_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "oklab";
        2 "oklch";
        3 "hsl";
        4 "srgb_linear";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_interpolation_hue_method_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "shorter";
        1 "longer";
        2 "increasing";
        3 "decreasing";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_font_meta_data_from_decoder;
    skip_fn skip_font_meta_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FontMetaData";
    definition "FontMetaData";
    capacity 6;
    fields [
        1 => "key": false decode_sparse_font_name_from_decoder; false false skip_font_name_from_decoder;
        2 => "font_line_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "font_digest": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        4 => "font_style": false decode_sparse_font_style_from_decoder; false false kiwi_skip_uint_value;
        5 => "font_weight": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_font_variation_from_decoder;
    skip_fn skip_font_variation_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FontVariation";
    definition "FontVariation";
    capacity 4;
    fields [
        1 => "axis_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "axis_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_data_from_decoder;
    skip_fn skip_text_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextData";
    definition "TextData";
    capacity 20;
    fields [
        1 => "characters": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "character_style_i_ds": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        3 => "style_override_table": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        4 => "layout_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        5 => "baselines": true decode_sparse_baseline_from_decoder; true false skip_baseline_from_decoder;
        6 => "glyphs": true decode_sparse_glyph_from_decoder; true false skip_glyph_from_decoder;
        7 => "decorations": true decode_sparse_decoration_from_decoder; true false skip_decoration_from_decoder;
        8 => "layout_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        9 => "font_meta_data": true decode_sparse_font_meta_data_from_decoder; true false skip_font_meta_data_from_decoder;
        10 => "fallback_fonts": true decode_sparse_font_name_from_decoder; true false skip_font_name_from_decoder;
        11 => "hyperlink_boxes": true decode_sparse_hyperlink_box_from_decoder; true false skip_hyperlink_box_from_decoder;
        12 => "lines": true decode_sparse_text_line_data_from_decoder; true false skip_text_line_data_from_decoder;
        13 => "truncation_start_index": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        14 => "truncated_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        15 => "logical_index_to_character_offset_map": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        16 => "blockquotes": true decode_sparse_blockquote_from_decoder; true false skip_blockquote_from_decoder;
        17 => "min_content_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        18 => "mention_boxes": true decode_sparse_mention_box_from_decoder; true false skip_mention_box_from_decoder;
        19 => "derived_lines": true decode_sparse_derived_text_line_data_from_decoder; true false skip_derived_text_line_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_derived_text_data_from_decoder;
    skip_fn skip_derived_text_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DerivedTextData";
    definition "DerivedTextData";
    capacity 13;
    fields [
        1 => "layout_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "baselines": true decode_sparse_baseline_from_decoder; true false skip_baseline_from_decoder;
        3 => "glyphs": true decode_sparse_glyph_from_decoder; true false skip_glyph_from_decoder;
        4 => "decorations": true decode_sparse_decoration_from_decoder; true false skip_decoration_from_decoder;
        5 => "blockquotes": true decode_sparse_blockquote_from_decoder; true false skip_blockquote_from_decoder;
        6 => "font_meta_data": true decode_sparse_font_meta_data_from_decoder; true false skip_font_meta_data_from_decoder;
        7 => "hyperlink_boxes": true decode_sparse_hyperlink_box_from_decoder; true false skip_hyperlink_box_from_decoder;
        8 => "truncation_start_index": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        9 => "truncated_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        10 => "logical_index_to_character_offset_map": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        11 => "mention_boxes": true decode_sparse_mention_box_from_decoder; true false skip_mention_box_from_decoder;
        12 => "derived_lines": true decode_sparse_derived_text_line_data_from_decoder; true false skip_derived_text_line_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_hyperlink_box_from_decoder;
    skip_fn skip_hyperlink_box_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.HyperlinkBox";
    definition "HyperlinkBox";
    capacity 7;
    fields [
        1 => "bounds": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        2 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "hyperlink_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        5 => "cms_target": false decode_sparse_cms_item_page_target_from_decoder; false false skip_cms_item_page_target_from_decoder;
        6 => "open_in_new_tab": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_mention_box_from_decoder;
    skip_fn skip_mention_box_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MentionBox";
    definition "MentionBox";
    capacity 6;
    fields [
        1 => "bounds": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        2 => "start_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "end_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "is_valid": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "mention_key": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_baseline_from_decoder;
    skip_fn skip_baseline_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Baseline";
    definition "Baseline";
    capacity 9;
    fields [
        1 => "position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "line_y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "line_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "first_character": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        6 => "end_character": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        7 => "line_ascent": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "ignore_leading_trim": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_glyph_from_decoder;
    skip_fn skip_glyph_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Glyph";
    definition "Glyph";
    capacity 10;
    fields [
        1 => "commands_blob": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "style_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "font_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "first_character": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        6 => "advance": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "emoji_code_points": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        8 => "emoji_image_set": false decode_sparse_emoji_image_set_from_decoder; false false kiwi_skip_uint_value;
        9 => "rotation": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_decoration_from_decoder;
    skip_fn skip_decoration_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Decoration";
    definition "Decoration";
    capacity 3;
    fields [
        1 => "rects": true decode_sparse_rect_from_decoder; true false skip_rect_from_decoder;
        2 => "style_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_blockquote_from_decoder;
    skip_fn skip_blockquote_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Blockquote";
    definition "Blockquote";
    capacity 4;
    fields [
        1 => "vertical_bar": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        2 => "quote_mark_bounds": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        3 => "style_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_vector_data_from_decoder;
    skip_fn skip_vector_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VectorData";
    definition "VectorData";
    capacity 4;
    fields [
        1 => "vector_network_blob": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "normalized_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "style_override_table": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_path_start_from_decoder;
    skip_fn skip_text_path_start_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextPathStart";
    definition "TextPathStart";
    capacity 3;
    fields [
        1 => "t_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "forward": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_path_from_decoder;
    skip_fn skip_guid_path_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDPath";
    definition "GUIDPath";
    capacity 2;
    fields [
        1 => "guids": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_symbol_data_from_decoder;
    skip_fn skip_symbol_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SymbolData";
    definition "SymbolData";
    capacity 4;
    fields [
        1 => "symbol_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "symbol_overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        3 => "uniform_scale_factor": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_path_mapping_from_decoder;
    skip_fn skip_guid_path_mapping_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDPathMapping";
    definition "GUIDPathMapping";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_derived_breakpoint_data_from_decoder;
    skip_fn skip_derived_breakpoint_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DerivedBreakpointData";
    definition "DerivedBreakpointData";
    capacity 2;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_generation_data_from_decoder;
    skip_fn skip_node_generation_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeGenerationData";
    definition "NodeGenerationData";
    capacity 4;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        2 => "use_fine_grained_syncing": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "diff_only_removals": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_derived_immutable_frame_data_from_decoder;
    skip_fn skip_derived_immutable_frame_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DerivedImmutableFrameData";
    definition "DerivedImmutableFrameData";
    capacity 3;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        2 => "version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_jsx_data_from_decoder;
    skip_fn skip_jsx_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.JsxData";
    definition "JsxData";
    capacity 2;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_derived_jsx_data_from_decoder;
    skip_fn skip_derived_jsx_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DerivedJsxData";
    definition "DerivedJsxData";
    capacity 2;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_asset_id_map_from_decoder;
    skip_fn skip_asset_id_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AssetIdMap";
    definition "AssetIdMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_asset_id_entry_from_decoder; true false skip_asset_id_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_asset_id_entry_from_decoder;
    skip_fn skip_asset_id_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AssetIdEntry";
    definition "AssetIdEntry";
    capacity 3;
    fields [
        1 => "asset_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "asset_id": false decode_sparse_asset_id_from_decoder; false false skip_asset_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_asset_ref_from_decoder;
    skip_fn skip_asset_ref_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AssetRef";
    definition "AssetRef";
    capacity 3;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_asset_id_from_decoder;
    skip_fn skip_asset_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AssetId";
    definition "AssetId";
    capacity 8;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
        3 => "state_group_id": false decode_sparse_state_group_id_from_decoder; false false skip_state_group_id_from_decoder;
        4 => "style_id": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        5 => "symbol_id": false decode_sparse_symbol_id_from_decoder; false false skip_symbol_id_from_decoder;
        6 => "variable_id": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
        7 => "variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_state_group_id_from_decoder;
    skip_fn skip_state_group_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StateGroupId";
    definition "StateGroupId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_style_id_from_decoder;
    skip_fn skip_style_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StyleId";
    definition "StyleId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_symbol_id_from_decoder;
    skip_fn skip_symbol_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SymbolId";
    definition "SymbolId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_id_from_decoder;
    skip_fn skip_variable_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableID";
    definition "VariableID";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_override_id_from_decoder;
    skip_fn skip_variable_override_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableOverrideId";
    definition "VariableOverrideId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_set_id_from_decoder;
    skip_fn skip_variable_set_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableSetID";
    definition "VariableSetID";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_theme_id_from_decoder;
    skip_fn skip_theme_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ThemeID";
    definition "ThemeID";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_library_id_from_decoder;
    skip_fn skip_code_library_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeLibraryId";
    definition "CodeLibraryId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_file_id_from_decoder;
    skip_fn skip_code_file_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeFileId";
    definition "CodeFileId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_component_id_from_decoder;
    skip_fn skip_code_component_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeComponentId";
    definition "CodeComponentId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_canvas_node_id_from_decoder;
    skip_fn skip_canvas_node_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CanvasNodeId";
    definition "CanvasNodeId";
    capacity 4;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "symbol_id": false decode_sparse_symbol_id_from_decoder; false false skip_symbol_id_from_decoder;
        3 => "state_group_id": false decode_sparse_state_group_id_from_decoder; false false skip_state_group_id_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_index_range_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.IndexRange";
    capacity 3;
    fields [
        "start_index" false kiwi_sparse_uint_value;
        "end_index_exclusive" false kiwi_sparse_uint_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_collaborative_text_op_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativeTextOpID";
    capacity 3;
    fields [
        "session_id" false kiwi_sparse_uint_value;
        "counter_id" false kiwi_sparse_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_collaborative_text_op_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "insert";
        1 "delete";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_collaborative_text_stripped_op_run_with_i_ds_from_decoder;
    skip_fn skip_collaborative_text_stripped_op_run_with_i_ds_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativeTextStrippedOpRunWithIDs";
    definition "CollaborativeTextStrippedOpRunWithIDs";
    capacity 5;
    fields [
        1 => "first_id": false decode_sparse_collaborative_text_op_id_from_decoder; false false skip_collaborative_text_op_id_from_decoder;
        2 => "run_length": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "parent_ids": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
        4 => "rebased_on_op_ids": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_collaborative_text_stripped_op_run_with_loc_from_decoder;
    skip_fn skip_collaborative_text_stripped_op_run_with_loc_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativeTextStrippedOpRunWithLoc";
    definition "CollaborativeTextStrippedOpRunWithLoc";
    capacity 6;
    fields [
        1 => "type": false decode_sparse_collaborative_text_op_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "range": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
        3 => "range_should_be_iterated_in_reverse": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "content_bytes_in_buffer": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
        5 => "rebased_range": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_collaborative_text_op_run_from_decoder;
    skip_fn skip_collaborative_text_op_run_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativeTextOpRun";
    definition "CollaborativeTextOpRun";
    capacity 9;
    fields [
        1 => "id": false decode_sparse_collaborative_text_op_id_from_decoder; false false skip_collaborative_text_op_id_from_decoder;
        2 => "parent_ids": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
        3 => "type": false decode_sparse_collaborative_text_op_type_from_decoder; false false kiwi_skip_uint_value;
        4 => "range": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
        5 => "range_should_be_iterated_in_reverse": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "content": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        7 => "rebased_on_op_ids": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
        8 => "rebased_range": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_collaborative_plain_text_from_decoder;
    skip_fn skip_collaborative_plain_text_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativePlainText";
    definition "CollaborativePlainText";
    capacity 5;
    fields [
        1 => "history_ops_with_ids": true decode_sparse_collaborative_text_stripped_op_run_with_i_ds_from_decoder; true false skip_collaborative_text_stripped_op_run_with_i_ds_from_decoder;
        2 => "history_ops_with_loc": true decode_sparse_collaborative_text_stripped_op_run_with_loc_from_decoder; true false skip_collaborative_text_stripped_op_run_with_loc_from_decoder;
        3 => "history_string_content_buffer": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        4 => "changes_to_append": true decode_sparse_collaborative_text_op_run_from_decoder; true false skip_collaborative_text_op_run_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_collaborative_text_selection_from_decoder;
    skip_fn skip_collaborative_text_selection_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CollaborativeTextSelection";
    definition "CollaborativeTextSelection";
    capacity 6;
    fields [
        1 => "node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "field": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "selected_range": false decode_sparse_index_range_from_decoder; false false skip_index_range_from_decoder;
        4 => "caret_at_front": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "text_version": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_responsive_text_style_variant_from_decoder;
    skip_fn skip_responsive_text_style_variant_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ResponsiveTextStyleVariant";
    definition "ResponsiveTextStyleVariant";
    capacity 8;
    fields [
        1 => "min_width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "fields": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        3 => "variable_font_size": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "variable_line_height": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        5 => "variable_letter_spacing": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        6 => "variable_paragraph_spacing": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        7 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_flapp_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "poll";
        1 "embed";
        2 "facepile";
        3 "alignment";
        4 "youtube";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slide_theme_props_from_decoder;
    skip_fn skip_slide_theme_props_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlideThemeProps";
    definition "SlideThemeProps";
    capacity 9;
    fields [
        1 => "theme_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        3 => "text_style_ids": true decode_sparse_style_id_from_decoder; true false skip_style_id_from_decoder;
        4 => "is_text_color_manually_selected": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "is_border_color_manually_selected": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "subscribed_theme_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
        7 => "schema_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        8 => "is_generated_from_design": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slide_theme_map_from_decoder;
    skip_fn skip_slide_theme_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlideThemeMap";
    definition "SlideThemeMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_slide_theme_map_entry_from_decoder; true false skip_slide_theme_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slide_theme_map_entry_from_decoder;
    skip_fn skip_slide_theme_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlideThemeMapEntry";
    definition "SlideThemeMapEntry";
    capacity 3;
    fields [
        1 => "theme_id": false decode_sparse_theme_id_from_decoder; false false skip_theme_id_from_decoder;
        2 => "theme_props": false decode_sparse_slide_theme_props_from_decoder; false false skip_slide_theme_props_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_shared_symbol_reference_from_decoder;
    skip_fn skip_shared_symbol_reference_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SharedSymbolReference";
    definition "SharedSymbolReference";
    capacity 10;
    fields [
        1 => "file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "symbol_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "version_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "guid_path_mappings": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        5 => "bytes": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        6 => "library_guid_to_subscribing_guid": true decode_sparse_guid_mapping_from_decoder; true false skip_guid_mapping_from_decoder;
        7 => "component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        8 => "unflattening_mappings": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        9 => "is_unflattened": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_shared_component_master_data_from_decoder;
    skip_fn skip_shared_component_master_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SharedComponentMasterData";
    definition "SharedComponentMasterData";
    capacity 4;
    fields [
        1 => "component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "publishing_guid_path_to_team_library_guid": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        3 => "is_unflattened": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_instance_override_stash_from_decoder;
    skip_fn skip_instance_override_stash_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InstanceOverrideStash";
    definition "InstanceOverrideStash";
    capacity 4;
    fields [
        1 => "override_path_of_swapped_instance": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        2 => "component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_instance_override_stash_v2_from_decoder;
    skip_fn skip_instance_override_stash_v2_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InstanceOverrideStashV2";
    definition "InstanceOverrideStashV2";
    capacity 4;
    fields [
        1 => "override_path_of_swapped_instance": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        2 => "local_symbol_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_imported_code_file_entry_from_decoder;
    skip_fn skip_imported_code_file_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ImportedCodeFileEntry";
    definition "ImportedCodeFileEntry";
    capacity 2;
    fields [
        1 => "code_file_id": false decode_sparse_code_file_id_from_decoder; false false skip_code_file_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_imported_code_files_from_decoder;
    skip_fn skip_imported_code_files_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ImportedCodeFiles";
    definition "ImportedCodeFiles";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_imported_code_file_entry_from_decoder; true false skip_imported_code_file_entry_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_blur_op_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "normal";
        1 "progressive";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_repeat_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "linear";
        1 "radial";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_unit_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "pixels";
        1 "relative";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_repeat_order_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "forward";
        1 "reverse";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_effect_axis_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "x";
        1 "y";
        2 "x_and_y";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_effect_from_decoder;
    skip_fn skip_effect_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Effect";
    definition "Effect";
    capacity 56;
    fields [
        1 => "type": false decode_sparse_effect_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        3 => "offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        4 => "radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "visible": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "blend_mode": false decode_sparse_blend_mode_from_decoder; false false kiwi_skip_uint_value;
        7 => "spread": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "show_shadow_behind_node": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        9 => "radius_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        10 => "color_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        11 => "spread_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        12 => "x_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        13 => "y_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        14 => "count": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        15 => "repeat_type": false decode_sparse_repeat_type_from_decoder; false false kiwi_skip_uint_value;
        16 => "axis": false decode_sparse_effect_axis_from_decoder; false false kiwi_skip_uint_value;
        17 => "unit_type": false decode_sparse_unit_type_from_decoder; false false kiwi_skip_uint_value;
        18 => "order": false decode_sparse_repeat_order_from_decoder; false false kiwi_skip_uint_value;
        19 => "blur_op_type": false decode_sparse_blur_op_type_from_decoder; false false kiwi_skip_uint_value;
        20 => "start_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        21 => "start_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        22 => "noise_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        23 => "clip_to_shape": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        24 => "secondary_color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        25 => "density": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        26 => "noise_type": false decode_sparse_noise_type_from_decoder; false false kiwi_skip_uint_value;
        27 => "opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        28 => "end_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        29 => "seed": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        30 => "refraction_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        31 => "specular_angle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        32 => "specular_intensity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        33 => "bevel_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        34 => "chromatic_aberration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        35 => "reflection_distance": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        36 => "refraction_intensity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        37 => "refraction_radius_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        38 => "specular_angle_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        39 => "specular_intensity_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        40 => "chromatic_aberration_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        41 => "splay_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        42 => "refraction_intensity_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        43 => "custom_effect_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
        44 => "component_prop_assignments": true decode_sparse_component_prop_assignment_from_decoder; true false skip_component_prop_assignment_from_decoder;
        45 => "start_radius_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        46 => "start_offset_x_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        47 => "start_offset_y_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        48 => "end_offset_x_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        49 => "end_offset_y_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        50 => "noise_size_x_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        51 => "noise_size_y_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        52 => "density_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        53 => "effect_opacity_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        54 => "secondary_color_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        55 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transform_modifier_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "repeat";
        1 "symmetry";
        2 "skew";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform_modifier_from_decoder;
    skip_fn skip_transform_modifier_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransformModifier";
    definition "TransformModifier";
    capacity 11;
    fields [
        1 => "type": false decode_sparse_transform_modifier_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "visible": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "count": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "repeat_type": false decode_sparse_repeat_type_from_decoder; false false kiwi_skip_uint_value;
        6 => "axis": false decode_sparse_effect_axis_from_decoder; false false kiwi_skip_uint_value;
        7 => "unit_type": false decode_sparse_unit_type_from_decoder; false false kiwi_skip_uint_value;
        8 => "order": false decode_sparse_repeat_order_from_decoder; false false kiwi_skip_uint_value;
        9 => "skew_x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        10 => "skew_y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transform_schema_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "fixed_order";
        2 "freeform";
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_matrix4f_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Matrix4f";
    capacity 17;
    fields [
        "m00" false kiwi_sparse_float_value;
        "m01" false kiwi_sparse_float_value;
        "m02" false kiwi_sparse_float_value;
        "m03" false kiwi_sparse_float_value;
        "m10" false kiwi_sparse_float_value;
        "m11" false kiwi_sparse_float_value;
        "m12" false kiwi_sparse_float_value;
        "m13" false kiwi_sparse_float_value;
        "m20" false kiwi_sparse_float_value;
        "m21" false kiwi_sparse_float_value;
        "m22" false kiwi_sparse_float_value;
        "m23" false kiwi_sparse_float_value;
        "m30" false kiwi_sparse_float_value;
        "m31" false kiwi_sparse_float_value;
        "m32" false kiwi_sparse_float_value;
        "m33" false kiwi_sparse_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_fixed_order_transform3d_from_decoder;
    skip_fn skip_fixed_order_transform3d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FixedOrderTransform3d";
    definition "FixedOrderTransform3d";
    capacity 6;
    fields [
        1 => "perspective": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "translate_z": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "rotate_x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "rotate_y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "rotate_z": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transform_fn_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "matrix_3_d";
        2 "perspective";
        3 "translate_z";
        4 "rotate_x";
        5 "rotate_y";
        6 "rotate_z";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform_fn_value_from_decoder;
    skip_fn skip_transform_fn_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransformFnValue";
    definition "TransformFnValue";
    capacity 5;
    fields [
        1 => "matrix3d": false decode_sparse_matrix4f_from_decoder; false false skip_matrix4f_from_decoder;
        2 => "perspective": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "rotate_angle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "translate_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform_fn_from_decoder;
    skip_fn skip_transform_fn_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransformFn";
    definition "TransformFn";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_transform_fn_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false decode_sparse_transform_fn_value_from_decoder; false false skip_transform_fn_value_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform_schema_value_from_decoder;
    skip_fn skip_transform_schema_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransformSchemaValue";
    definition "TransformSchemaValue";
    capacity 3;
    fields [
        1 => "fixed_order_transform3d": false decode_sparse_fixed_order_transform3d_from_decoder; false false skip_fixed_order_transform3d_from_decoder;
        2 => "transform_functions": true decode_sparse_transform_fn_from_decoder; true false skip_transform_fn_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform3d_from_decoder;
    skip_fn skip_transform3d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Transform3d";
    definition "Transform3d";
    capacity 4;
    fields [
        1 => "type": false decode_sparse_transform_schema_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false decode_sparse_transform_schema_value_from_decoder; false false skip_transform_schema_value_from_decoder;
        3 => "backface_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_number_vector2_d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NumberVector2D";
    capacity 3;
    fields [
        "x" false decode_sparse_number_from_decoder;
        "y" false decode_sparse_number_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scene3d_from_decoder;
    skip_fn skip_scene3d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Scene3d";
    definition "Scene3d";
    capacity 4;
    fields [
        1 => "perspective": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "perspective_origin": false decode_sparse_number_vector2_d_from_decoder; false false skip_number_vector2_d_from_decoder;
        3 => "preserve3d": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transform_origin_from_decoder;
    skip_fn skip_transform_origin_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransformOrigin";
    definition "TransformOrigin";
    capacity 3;
    fields [
        1 => "x": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        2 => "y": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_info_from_decoder;
    skip_fn skip_transition_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionInfo";
    definition "TransitionInfo";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_transition_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_prototype_device_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "preset";
        2 "custom";
        3 "presentation";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_device_rotation_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "ccw_90";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_device_from_decoder;
    skip_fn skip_prototype_device_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeDevice";
    definition "PrototypeDevice";
    capacity 5;
    fields [
        1 => "type": false decode_sparse_prototype_device_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "preset_identifier": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "rotation": false decode_sparse_device_rotation_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_overlay_position_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "center";
        1 "top_left";
        2 "top_center";
        3 "top_right";
        4 "bottom_left";
        5 "bottom_center";
        6 "bottom_right";
        7 "manual";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_overlay_background_interaction_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "close_on_click_outside";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_overlay_background_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "solid_color";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_overlay_background_appearance_from_decoder;
    skip_fn skip_overlay_background_appearance_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.OverlayBackgroundAppearance";
    definition "OverlayBackgroundAppearance";
    capacity 3;
    fields [
        1 => "background_type": false decode_sparse_overlay_background_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "background_color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_navigation_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "navigate";
        1 "overlay";
        2 "swap";
        3 "swap_state";
        4 "scroll_to";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_export_color_profile_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "document";
        1 "srgb";
        2 "display_p3_v4";
        3 "cmyk";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_export_background_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "solid";
        1 "transparent";
        2 "grid";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_export_settings_from_decoder;
    skip_fn skip_export_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ExportSettings";
    definition "ExportSettings";
    capacity 16;
    fields [
        1 => "suffix": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "image_type": false decode_sparse_image_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "constraint": false decode_sparse_export_constraint_from_decoder; false false skip_export_constraint_from_decoder;
        4 => "svg_data_name": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "svg_id_mode": false decode_sparse_export_svgid_mode_from_decoder; false false kiwi_skip_uint_value;
        6 => "svg_outline_text": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        7 => "contents_only": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        8 => "svg_force_stroke_masks": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        9 => "use_absolute_bounds": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        10 => "color_profile": false decode_sparse_export_color_profile_from_decoder; false false kiwi_skip_uint_value;
        11 => "quality": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        12 => "use_bicubic_sampler": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        13 => "frame_rate": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        14 => "loop_count": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        15 => "background_type": false decode_sparse_export_background_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_export_svgid_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "if_needed";
        1 "always";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_layout_grid_from_decoder;
    skip_fn skip_layout_grid_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LayoutGrid";
    definition "LayoutGrid";
    capacity 14;
    fields [
        1 => "type": false decode_sparse_layout_grid_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "axis": false decode_sparse_axis_from_decoder; false false kiwi_skip_uint_value;
        3 => "visible": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "num_sections": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        5 => "offset": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        6 => "section_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "gutter_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        9 => "pattern": false decode_sparse_layout_grid_pattern_from_decoder; false false kiwi_skip_uint_value;
        10 => "num_sections_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        11 => "offset_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        12 => "section_size_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        13 => "gutter_size_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guide_from_decoder;
    skip_fn skip_guide_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Guide";
    definition "Guide";
    capacity 4;
    fields [
        1 => "axis": false decode_sparse_axis_from_decoder; false false kiwi_skip_uint_value;
        2 => "offset": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_path_from_decoder;
    skip_fn skip_path_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Path";
    definition "Path";
    capacity 4;
    fields [
        1 => "winding_rule": false decode_sparse_winding_rule_from_decoder; false false kiwi_skip_uint_value;
        2 => "commands_blob": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "style_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_style_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "fill";
        2 "stroke";
        3 "text";
        4 "effect";
        5 "export";
        6 "grid";
        7 "animation";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_brush_orientation_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "forward";
        1 "reverse";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_brush_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "stretch";
        1 "scatter";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_dynamic_stroke_settings_from_decoder;
    skip_fn skip_dynamic_stroke_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DynamicStrokeSettings";
    definition "DynamicStrokeSettings";
    capacity 4;
    fields [
        1 => "frequency": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "wiggle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "smoothen": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scatter_stroke_settings_from_decoder;
    skip_fn skip_scatter_stroke_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ScatterStrokeSettings";
    definition "ScatterStrokeSettings";
    capacity 6;
    fields [
        1 => "gap": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "wiggle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "angular_jitter": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "rotation": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "size_jitter": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_stretch_stroke_settings_from_decoder;
    skip_fn skip_stretch_stroke_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StretchStrokeSettings";
    definition "StretchStrokeSettings";
    capacity 2;
    fields [
        1 => "orientation": false decode_sparse_brush_orientation_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_stroke_data_from_decoder;
    skip_fn skip_stroke_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StrokeData";
    definition "StrokeData";
    capacity 3;
    fields [
        1 => "strokes": true decode_sparse_stroke_from_decoder; true false skip_stroke_from_decoder;
        2 => "version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_stroke_from_decoder;
    skip_fn skip_stroke_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Stroke";
    definition "Stroke";
    capacity 15;
    fields [
        1 => "stroke_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        2 => "stroke_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "stroke_weight_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "stroke_paint": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        5 => "style_id_for_stroke_fill": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        6 => "stroke_align": false decode_sparse_stroke_align_from_decoder; false false kiwi_skip_uint_value;
        7 => "stroke_cap": false decode_sparse_stroke_cap_from_decoder; false false kiwi_skip_uint_value;
        8 => "stroke_cap_size": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        9 => "stroke_join": false decode_sparse_stroke_join_from_decoder; false false kiwi_skip_uint_value;
        10 => "miter_limit": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        11 => "dash_pattern": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        12 => "path_trim": false decode_sparse_optional_vector_from_decoder; false false skip_optional_vector_from_decoder;
        13 => "stroke_offset": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        14 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_width_point_from_decoder;
    skip_fn skip_variable_width_point_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableWidthPoint";
    definition "VariableWidthPoint";
    capacity 5;
    fields [
        1 => "position": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "ascent": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "descent": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "segment_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_shared_style_reference_from_decoder;
    skip_fn skip_shared_style_reference_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SharedStyleReference";
    definition "SharedStyleReference";
    capacity 3;
    fields [
        1 => "style_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "version_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_shared_style_master_data_from_decoder;
    skip_fn skip_shared_style_master_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SharedStyleMasterData";
    definition "SharedStyleMasterData";
    capacity 4;
    fields [
        1 => "style_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "sort_position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scroll_behavior_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "scrolls";
        1 "fixed_when_child_of_scrolling_frame";
        2 "sticky_scrolls";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_arc_data_from_decoder;
    skip_fn skip_arc_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ArcData";
    definition "ArcData";
    capacity 4;
    fields [
        1 => "starting_angle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "ending_angle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "inner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_symbol_link_from_decoder;
    skip_fn skip_symbol_link_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SymbolLink";
    definition "SymbolLink";
    capacity 4;
    fields [
        1 => "uri": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "display_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "display_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_plugin_data_from_decoder;
    skip_fn skip_plugin_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PluginData";
    definition "PluginData";
    capacity 4;
    fields [
        1 => "plugin_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_plugin_relaunch_data_from_decoder;
    skip_fn skip_plugin_relaunch_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PluginRelaunchData";
    definition "PluginRelaunchData";
    capacity 6;
    fields [
        1 => "plugin_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "message": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "command": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "custom_tool_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_multiplayer_field_version_from_decoder;
    skip_fn skip_multiplayer_field_version_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MultiplayerFieldVersion";
    definition "MultiplayerFieldVersion";
    capacity 3;
    fields [
        1 => "counter": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connector_magnet_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "auto";
        2 "top";
        3 "left";
        4 "bottom";
        5 "right";
        6 "center";
        7 "auto_horizontal";
        8 "edge";
        9 "absolute";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_connector_endpoint_from_decoder;
    skip_fn skip_connector_endpoint_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ConnectorEndpoint";
    definition "ConnectorEndpoint";
    capacity 5;
    fields [
        1 => "endpoint_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "magnet": false decode_sparse_connector_magnet_from_decoder; false false kiwi_skip_uint_value;
        4 => "relative_position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_connector_control_point_from_decoder;
    skip_fn skip_connector_control_point_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ConnectorControlPoint";
    definition "ConnectorControlPoint";
    capacity 3;
    fields [
        1 => "position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "axis": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connector_text_section_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "middle_to_start";
        1 "middle_to_end";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connector_off_axis_offset_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "above";
        2 "below";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_connector_text_midpoint_from_decoder;
    skip_fn skip_connector_text_midpoint_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ConnectorTextMidpoint";
    definition "ConnectorTextMidpoint";
    capacity 4;
    fields [
        1 => "section": false decode_sparse_connector_text_section_from_decoder; false false kiwi_skip_uint_value;
        2 => "offset": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "off_axis_offset": false decode_sparse_connector_off_axis_offset_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connector_line_style_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "elbowed";
        1 "straight";
        2 "curved";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_connector_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "manual";
        1 "diagram";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_annotation_property_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "fill";
        1 "stroke";
        2 "width";
        3 "height";
        4 "min_width";
        5 "min_height";
        6 "max_width";
        7 "max_height";
        8 "stroke_width";
        9 "corner_radius";
        10 "effect";
        11 "text_style";
        12 "text_align_horizontal";
        13 "font_family";
        14 "font_size";
        15 "font_weight";
        16 "line_height";
        17 "letter_spacing";
        18 "stack_spacing";
        19 "stack_padding";
        20 "stack_mode";
        21 "stack_alignment";
        22 "opacity";
        23 "component";
        24 "font_style";
        25 "grid_row_gap";
        26 "grid_column_gap";
        27 "grid_row_count";
        28 "grid_column_count";
        29 "grid_row_anchor_index";
        30 "grid_column_anchor_index";
        31 "grid_row_span";
        32 "grid_column_span";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_property_from_decoder;
    skip_fn skip_annotation_property_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnnotationProperty";
    definition "AnnotationProperty";
    capacity 2;
    fields [
        1 => "type": false decode_sparse_annotation_property_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_annotation_category_preset_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "accessibility";
        2 "behavior";
        3 "content";
        4 "development";
        5 "interaction";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_annotation_category_color_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "yellow";
        1 "orange";
        2 "red";
        3 "pink";
        4 "violet";
        5 "blue";
        6 "teal";
        7 "green";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_category_custom_from_decoder;
    skip_fn skip_annotation_category_custom_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnnotationCategoryCustom";
    definition "AnnotationCategoryCustom";
    capacity 4;
    fields [
        1 => "color": false decode_sparse_annotation_category_color_from_decoder; false false kiwi_skip_uint_value;
        2 => "custom_color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        3 => "label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_category_from_decoder;
    skip_fn skip_annotation_category_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnnotationCategory";
    definition "AnnotationCategory";
    capacity 4;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "preset": false decode_sparse_annotation_category_preset_from_decoder; false false kiwi_skip_uint_value;
        3 => "custom": false decode_sparse_annotation_category_custom_from_decoder; false false skip_annotation_category_custom_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_categories_from_decoder;
    skip_fn skip_annotation_categories_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnnotationCategories";
    definition "AnnotationCategories";
    capacity 3;
    fields [
        1 => "version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "items": true decode_sparse_annotation_category_from_decoder; true false skip_annotation_category_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_from_decoder;
    skip_fn skip_annotation_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Annotation";
    definition "Annotation";
    capacity 5;
    fields [
        1 => "label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "properties": true decode_sparse_annotation_property_from_decoder; true false skip_annotation_property_from_decoder;
        3 => "label_v2": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "category_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_annotation_measurement_node_side_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "top";
        1 "bottom";
        2 "left";
        3 "right";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_annotation_measurement_from_decoder;
    skip_fn skip_annotation_measurement_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnnotationMeasurement";
    definition "AnnotationMeasurement";
    capacity 10;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "from_node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "to_node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "from_node_side": false decode_sparse_annotation_measurement_node_side_from_decoder; false false kiwi_skip_uint_value;
        5 => "to_same_side": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "inner_offset_relative": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "outer_offset_fixed": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "to_node_stable_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        9 => "free_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_library_move_info_from_decoder;
    skip_fn skip_library_move_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LibraryMoveInfo";
    definition "LibraryMoveInfo";
    capacity 3;
    fields [
        1 => "old_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "paste_file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_library_move_history_item_from_decoder;
    skip_fn skip_library_move_history_item_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LibraryMoveHistoryItem";
    definition "LibraryMoveHistoryItem";
    capacity 3;
    fields [
        1 => "source_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "source_component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_developer_related_link_from_decoder;
    skip_fn skip_developer_related_link_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DeveloperRelatedLink";
    definition "DeveloperRelatedLink";
    capacity 5;
    fields [
        1 => "node_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "link_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "link_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_pointer_from_decoder;
    skip_fn skip_widget_pointer_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetPointer";
    definition "WidgetPointer";
    capacity 2;
    fields [
        1 => "node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_edit_info_from_decoder;
    skip_fn skip_edit_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EditInfo";
    definition "EditInfo";
    capacity 5;
    fields [
        1 => "timestamp_iso8601": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "last_edited_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "created_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_editor_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "design";
        1 "whiteboard";
        2 "slides";
        3 "dev_handoff";
        4 "sites";
        5 "cooper";
        6 "illustration";
        7 "figmake";
        8 "figspec";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_mask_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "alpha";
        1 "outline";
        2 "luminance";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_module_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "single_node";
        2 "multi_node";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_section_status_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "build";
        2 "completed";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_section_status_info_from_decoder;
    skip_fn skip_section_status_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SectionStatusInfo";
    definition "SectionStatusInfo";
    capacity 6;
    fields [
        1 => "status": false decode_sparse_section_status_from_decoder; false false kiwi_skip_uint_value;
        2 => "last_update_unix_timestamp": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "prev_status": false decode_sparse_section_status_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_buzz_approval_request_info_from_decoder;
    skip_fn skip_buzz_approval_request_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BuzzApprovalRequestInfo";
    definition "BuzzApprovalRequestInfo";
    capacity 8;
    fields [
        1 => "request_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "requester_user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "requested_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "reviewer_user_ids": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
        5 => "title": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "note": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        7 => "assets_in_request": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_buzz_approval_requests_from_decoder;
    skip_fn skip_buzz_approval_requests_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BuzzApprovalRequests";
    definition "BuzzApprovalRequests";
    capacity 2;
    fields [
        1 => "requests": true decode_sparse_buzz_approval_request_info_from_decoder; true false skip_buzz_approval_request_info_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_buzz_approval_node_status_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "in_review";
        2 "approved";
        3 "changes_requested";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_buzz_approval_node_status_info_from_decoder;
    skip_fn skip_buzz_approval_node_status_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BuzzApprovalNodeStatusInfo";
    definition "BuzzApprovalNodeStatusInfo";
    capacity 4;
    fields [
        1 => "current_status": false decode_sparse_buzz_approval_node_status_from_decoder; false false kiwi_skip_uint_value;
        2 => "was_previously_approved": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "approval_revoked_at_history": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_embed_info_from_decoder;
    skip_fn skip_code_embed_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeEmbedInfo";
    definition "CodeEmbedInfo";
    capacity 6;
    fields [
        1 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "src_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "title": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "thumbnail_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "is_published_site": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_variable_timing_display_unit_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "milliseconds";
        1 "seconds";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_change_from_decoder;
    skip_fn skip_node_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChange";
    definition "NodeChange";
    capacity 591;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "phase": false decode_sparse_node_phase_from_decoder; false false kiwi_skip_uint_value;
        3 => "parent_index": false decode_sparse_parent_index_from_decoder; false false skip_parent_index_from_decoder;
        4 => "type": false decode_sparse_node_type_from_decoder; false false kiwi_skip_uint_value;
        5 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "visible": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        7 => "locked": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        8 => "opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        9 => "blend_mode": false decode_sparse_blend_mode_from_decoder; false false kiwi_skip_uint_value;
        10 => "count": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        11 => "size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        12 => "transform": false decode_sparse_matrix_from_decoder; false false skip_matrix_from_decoder;
        13 => "dash_pattern": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        14 => "auto_rename": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        15 => "background_enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        16 => "mask": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        17 => "export_contents_only": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        18 => "mask_is_outline": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        19 => "background_opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        20 => "corner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        21 => "font_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        22 => "paragraph_indent": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        23 => "paragraph_spacing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        24 => "star_inner_scale": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        25 => "miter_limit": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        26 => "stroke_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        27 => "text_tracking": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        28 => "horizontal_constraint": false decode_sparse_constraint_type_from_decoder; false false kiwi_skip_uint_value;
        29 => "stroke_align": false decode_sparse_stroke_align_from_decoder; false false kiwi_skip_uint_value;
        30 => "stroke_cap": false decode_sparse_stroke_cap_from_decoder; false false kiwi_skip_uint_value;
        31 => "stroke_join": false decode_sparse_stroke_join_from_decoder; false false kiwi_skip_uint_value;
        32 => "text_align_horizontal": false decode_sparse_text_align_horizontal_from_decoder; false false kiwi_skip_uint_value;
        33 => "text_align_vertical": false decode_sparse_text_align_vertical_from_decoder; false false kiwi_skip_uint_value;
        34 => "text_case": false decode_sparse_text_case_from_decoder; false false kiwi_skip_uint_value;
        35 => "text_decoration": false decode_sparse_text_decoration_from_decoder; false false kiwi_skip_uint_value;
        36 => "boolean_operation": false decode_sparse_boolean_operation_from_decoder; false false kiwi_skip_uint_value;
        37 => "vertical_constraint": false decode_sparse_constraint_type_from_decoder; false false kiwi_skip_uint_value;
        38 => "fill_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        39 => "stroke_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        40 => "line_height": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        41 => "font_name": false decode_sparse_font_name_from_decoder; false false skip_font_name_from_decoder;
        42 => "text_data": false decode_sparse_text_data_from_decoder; false false skip_text_data_from_decoder;
        43 => "effects": true decode_sparse_effect_from_decoder; true false skip_effect_from_decoder;
        44 => "handle_mirroring": false decode_sparse_vector_mirror_from_decoder; false false kiwi_skip_uint_value;
        45 => "export_settings": true decode_sparse_export_settings_from_decoder; true false skip_export_settings_from_decoder;
        46 => "text_auto_resize": false decode_sparse_text_auto_resize_from_decoder; false false kiwi_skip_uint_value;
        47 => "layout_grids": true decode_sparse_layout_grid_from_decoder; true false skip_layout_grid_from_decoder;
        48 => "vector_data": false decode_sparse_vector_data_from_decoder; false false skip_vector_data_from_decoder;
        49 => "style_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        50 => "background_color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        51 => "fill_geometry": true decode_sparse_path_from_decoder; true false skip_path_from_decoder;
        52 => "stroke_geometry": true decode_sparse_path_from_decoder; true false skip_path_from_decoder;
        53 => "guid_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        54 => "phase_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        55 => "parent_index_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        56 => "type_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        57 => "name_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        58 => "visible_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        59 => "locked_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        60 => "opacity_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        61 => "blend_mode_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        62 => "count_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        63 => "size_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        64 => "transform_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        65 => "dash_pattern_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        66 => "auto_rename_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        67 => "background_enabled_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        68 => "mask_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        69 => "export_contents_only_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        70 => "mask_is_outline_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        71 => "background_opacity_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        72 => "corner_radius_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        73 => "font_size_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        74 => "paragraph_indent_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        75 => "paragraph_spacing_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        76 => "star_inner_scale_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        77 => "miter_limit_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        78 => "stroke_weight_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        79 => "text_tracking_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        80 => "horizontal_constraint_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        81 => "stroke_align_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        82 => "stroke_cap_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        83 => "stroke_join_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        84 => "text_align_horizontal_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        85 => "text_align_vertical_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        86 => "text_case_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        87 => "text_decoration_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        88 => "boolean_operation_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        89 => "vertical_constraint_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        90 => "fill_paints_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        91 => "stroke_paints_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        92 => "line_height_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        93 => "font_name_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        94 => "text_data_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        95 => "effects_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        96 => "handle_mirroring_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        97 => "export_settings_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        98 => "text_auto_resize_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        99 => "layout_grids_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        100 => "vector_data_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        101 => "style_id_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        102 => "background_color_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        103 => "fill_geometry_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        104 => "stroke_geometry_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        105 => "stack_mode": false decode_sparse_stack_mode_from_decoder; false false kiwi_skip_uint_value;
        106 => "stack_mode_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        107 => "stack_spacing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        108 => "stack_spacing_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        109 => "stack_padding": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        110 => "stack_padding_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        111 => "guid_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        112 => "guid_path_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        113 => "symbol_data": false decode_sparse_symbol_data_from_decoder; false false skip_symbol_data_from_decoder;
        114 => "symbol_data_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        115 => "frame_mask_disabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        116 => "frame_mask_disabled_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        117 => "resize_to_fit": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        118 => "resize_to_fit_tag": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        119 => "export_background_disabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        120 => "stack_counter_align": false decode_sparse_stack_counter_align_from_decoder; false false kiwi_skip_uint_value;
        121 => "stack_justify": false decode_sparse_stack_justify_from_decoder; false false kiwi_skip_uint_value;
        122 => "shared_symbol_reference": false decode_sparse_shared_symbol_reference_from_decoder; false false skip_shared_symbol_reference_from_decoder;
        123 => "is_symbol_publishable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        124 => "shared_symbol_mappings": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        125 => "derived_symbol_data": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        126 => "shared_symbol_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        127 => "font_variant_common_ligatures": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        128 => "font_variant_contextual_ligatures": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        129 => "font_variant_discretionary_ligatures": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        130 => "font_variant_historical_ligatures": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        131 => "font_variant_ordinal": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        132 => "font_variant_slashed_zero": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        133 => "font_variant_numeric_figure": false decode_sparse_font_variant_numeric_figure_from_decoder; false false kiwi_skip_uint_value;
        134 => "font_variant_numeric_spacing": false decode_sparse_font_variant_numeric_spacing_from_decoder; false false kiwi_skip_uint_value;
        135 => "font_variant_numeric_fraction": false decode_sparse_font_variant_numeric_fraction_from_decoder; false false kiwi_skip_uint_value;
        136 => "font_variant_caps": false decode_sparse_font_variant_caps_from_decoder; false false kiwi_skip_uint_value;
        137 => "font_variant_position": false decode_sparse_font_variant_position_from_decoder; false false kiwi_skip_uint_value;
        138 => "guides": true decode_sparse_guide_from_decoder; true false skip_guide_from_decoder;
        139 => "transition_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        140 => "prototype_start_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        141 => "prototype_background_color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        142 => "internal_only": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        143 => "overridden_symbol_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        144 => "symbol_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        145 => "rectangle_top_left_corner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        146 => "rectangle_top_right_corner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        147 => "rectangle_bottom_left_corner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        148 => "rectangle_bottom_right_corner_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        149 => "rectangle_corner_radii_independent": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        150 => "rectangle_corner_tool_independent": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        151 => "proportions_constrained": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        152 => "shared_component_master_data": false decode_sparse_shared_component_master_data_from_decoder; false false skip_shared_component_master_data_from_decoder;
        153 => "transition_info": false decode_sparse_transition_info_from_decoder; false false skip_transition_info_from_decoder;
        154 => "transition_type": false decode_sparse_transition_type_from_decoder; false false kiwi_skip_uint_value;
        155 => "transition_duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        156 => "easing_type": false decode_sparse_easing_type_from_decoder; false false kiwi_skip_uint_value;
        157 => "is_fill_style": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        158 => "inherit_fill_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        159 => "scroll_direction": false decode_sparse_scroll_direction_from_decoder; false false kiwi_skip_uint_value;
        160 => "corner_smoothing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        161 => "is_stroke_style": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        162 => "inherit_stroke_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        163 => "style_type": false decode_sparse_style_type_from_decoder; false false kiwi_skip_uint_value;
        164 => "unflattening_mappings": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        165 => "letter_spacing": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        166 => "scroll_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        167 => "inherit_text_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        168 => "inherit_export_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        169 => "inherit_effect_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        170 => "inherit_grid_style_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        171 => "version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        172 => "shared_style_master_data": false decode_sparse_shared_style_master_data_from_decoder; false false skip_shared_style_master_data_from_decoder;
        173 => "shared_style_reference": false decode_sparse_shared_style_reference_from_decoder; false false skip_shared_style_reference_from_decoder;
        174 => "is_publishable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        175 => "export_text_as_svg_text": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        176 => "is_soft_deleted_style": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        177 => "is_non_updateable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        178 => "scroll_contracted_state": false decode_sparse_scroll_contracted_state_from_decoder; false false kiwi_skip_uint_value;
        179 => "contracted_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        180 => "fixed_children_divider": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        181 => "transition_preserve_scroll": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        182 => "connection_type": false decode_sparse_connection_type_from_decoder; false false kiwi_skip_uint_value;
        183 => "connection_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        184 => "prototype_device": false decode_sparse_prototype_device_from_decoder; false false skip_prototype_device_from_decoder;
        185 => "inherit_fill_style_id_for_stroke": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        186 => "scroll_behavior": false decode_sparse_scroll_behavior_from_decoder; false false kiwi_skip_uint_value;
        187 => "interaction_type": false decode_sparse_interaction_type_from_decoder; false false kiwi_skip_uint_value;
        188 => "transition_timeout": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        189 => "interaction_maintained": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        190 => "interaction_duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        191 => "style_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        192 => "destination_is_overlay": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        193 => "background_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        194 => "inherit_fill_style_id_for_background": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        195 => "arc_data": false decode_sparse_arc_data_from_decoder; false false skip_arc_data_from_decoder;
        196 => "derived_symbol_data_layout_version": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        197 => "navigation_type": false decode_sparse_navigation_type_from_decoder; false false kiwi_skip_uint_value;
        198 => "overlay_position_type": false decode_sparse_overlay_position_type_from_decoder; false false kiwi_skip_uint_value;
        199 => "overlay_relative_position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        200 => "overlay_background_interaction": false decode_sparse_overlay_background_interaction_from_decoder; false false kiwi_skip_uint_value;
        201 => "overlay_background_appearance": false decode_sparse_overlay_background_appearance_from_decoder; false false skip_overlay_background_appearance_from_decoder;
        202 => "font_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        203 => "text_user_layout_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        204 => "plugin_data": true decode_sparse_plugin_data_from_decoder; true false skip_plugin_data_from_decoder;
        205 => "toggled_on_ot_features": true decode_sparse_open_type_feature_from_decoder; true false kiwi_skip_uint_value;
        206 => "toggled_off_ot_features": true decode_sparse_open_type_feature_from_decoder; true false kiwi_skip_uint_value;
        207 => "transition_should_smart_animate": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        208 => "stack_align": false decode_sparse_stack_align_from_decoder; false false kiwi_skip_uint_value;
        209 => "stack_horizontal_padding": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        210 => "stack_vertical_padding": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        211 => "stack_width": false decode_sparse_stack_size_from_decoder; false false kiwi_skip_uint_value;
        212 => "stack_height": false decode_sparse_stack_size_from_decoder; false false kiwi_skip_uint_value;
        213 => "override_key": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        214 => "publish_file": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        215 => "publish_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        216 => "component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        217 => "is_c2": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        218 => "published_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        219 => "plugin_relaunch_data": true decode_sparse_plugin_relaunch_data_from_decoder; true false skip_plugin_relaunch_data_from_decoder;
        220 => "container_supports_fill_stroke_and_corners": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        221 => "stack_counter_sizing": false decode_sparse_stack_size_from_decoder; false false kiwi_skip_uint_value;
        222 => "containers_support_fill_stroke_and_corners": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        223 => "hyperlink": false decode_sparse_hyperlink_from_decoder; false false skip_hyperlink_from_decoder;
        224 => "key_trigger": false decode_sparse_key_trigger_from_decoder; false false skip_key_trigger_from_decoder;
        225 => "is_state_group": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        226 => "prototype_interactions": true decode_sparse_prototype_interaction_from_decoder; true false skip_prototype_interaction_from_decoder;
        227 => "voice_event_phrase": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        228 => "force_unflattening_mappings": true decode_sparse_guid_path_mapping_from_decoder; true false skip_guid_path_mapping_from_decoder;
        229 => "stack_primary_sizing": false decode_sparse_stack_size_from_decoder; false false kiwi_skip_uint_value;
        230 => "stack_primary_align_items": false decode_sparse_stack_justify_from_decoder; false false kiwi_skip_uint_value;
        231 => "stack_counter_align_items": false decode_sparse_stack_align_from_decoder; false false kiwi_skip_uint_value;
        232 => "stack_child_primary_grow": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        233 => "stack_padding_right": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        234 => "stack_padding_bottom": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        235 => "ancestor_path_before_deletion": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        236 => "stack_child_align_self": false decode_sparse_stack_counter_align_from_decoder; false false kiwi_skip_uint_value;
        237 => "symbol_links": true decode_sparse_symbol_link_from_decoder; true false skip_symbol_link_from_decoder;
        238 => "state_group_property_value_orders": true decode_sparse_state_group_property_value_order_from_decoder; true false skip_state_group_property_value_order_from_decoder;
        239 => "text_list_data": false decode_sparse_text_list_data_from_decoder; false false skip_text_list_data_from_decoder;
        240 => "node_generation_data": false decode_sparse_node_generation_data_from_decoder; false false skip_node_generation_data_from_decoder;
        241 => "shape_with_text_type": false decode_sparse_shape_with_text_type_from_decoder; false false kiwi_skip_uint_value;
        242 => "connector_start": false decode_sparse_connector_endpoint_from_decoder; false false skip_connector_endpoint_from_decoder;
        243 => "connector_end": false decode_sparse_connector_endpoint_from_decoder; false false skip_connector_endpoint_from_decoder;
        244 => "connector_line_style": false decode_sparse_connector_line_style_from_decoder; false false kiwi_skip_uint_value;
        245 => "connector_start_cap": false decode_sparse_stroke_cap_from_decoder; false false kiwi_skip_uint_value;
        246 => "connector_end_cap": false decode_sparse_stroke_cap_from_decoder; false false kiwi_skip_uint_value;
        247 => "shape_user_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        248 => "override_stash": true decode_sparse_instance_override_stash_from_decoder; true false skip_instance_override_stash_from_decoder;
        249 => "prototype_starting_point": false decode_sparse_prototype_starting_point_from_decoder; false false skip_prototype_starting_point_from_decoder;
        250 => "override_stash_v2": true decode_sparse_instance_override_stash_v2_from_decoder; true false skip_instance_override_stash_v2_from_decoder;
        251 => "internal_enum_for_test": false decode_sparse_internal_enum_for_test_from_decoder; false false kiwi_skip_uint_value;
        252 => "origin_component_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        253 => "connector_control_points": true decode_sparse_connector_control_point_from_decoder; true false skip_connector_control_point_from_decoder;
        254 => "derived_immutable_frame_data": false decode_sparse_derived_immutable_frame_data_from_decoder; false false skip_derived_immutable_frame_data_from_decoder;
        255 => "connector_text_midpoint": false decode_sparse_connector_text_midpoint_from_decoder; false false skip_connector_text_midpoint_from_decoder;
        256 => "library_move_info": false decode_sparse_library_move_info_from_decoder; false false skip_library_move_info_from_decoder;
        257 => "internal_data_for_test": false decode_sparse_internal_data_for_test_from_decoder; false false skip_internal_data_for_test_from_decoder;
        258 => "use_absolute_bounds": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        259 => "code_block_language": false decode_sparse_code_block_language_from_decoder; false false kiwi_skip_uint_value;
        260 => "font_variations": true decode_sparse_font_variation_from_decoder; true false skip_font_variation_from_decoder;
        261 => "detach_optical_size_from_font_size": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        262 => "widget_metadata": false decode_sparse_widget_metadata_from_decoder; false false skip_widget_metadata_from_decoder;
        263 => "widget_events": true decode_sparse_widget_event_from_decoder; true false kiwi_skip_uint_value;
        264 => "list_spacing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        265 => "widget_property_menu_items": true decode_sparse_widget_property_menu_item_from_decoder; true false skip_widget_property_menu_item_from_decoder;
        266 => "component_prop_defs": true decode_sparse_component_prop_def_from_decoder; true false skip_component_prop_def_from_decoder;
        267 => "component_prop_refs": true decode_sparse_component_prop_ref_from_decoder; true false skip_component_prop_ref_from_decoder;
        268 => "component_prop_assignments": true decode_sparse_component_prop_assignment_from_decoder; true false skip_component_prop_assignment_from_decoder;
        269 => "stack_positioning": false decode_sparse_stack_positioning_from_decoder; false false kiwi_skip_uint_value;
        270 => "embed_data": false decode_sparse_embed_data_from_decoder; false false skip_embed_data_from_decoder;
        271 => "stack_reverse_z_index": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        272 => "rich_media_data": false decode_sparse_rich_media_data_from_decoder; false false skip_rich_media_data_from_decoder;
        273 => "widget_synced_state": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        274 => "widget_sync_cursor": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        275 => "widget_derived_subtree_cursor": false decode_sparse_widget_derived_subtree_cursor_from_decoder; false false skip_widget_derived_subtree_cursor_from_decoder;
        276 => "widget_cached_ancestor": false decode_sparse_widget_pointer_from_decoder; false false skip_widget_pointer_from_decoder;
        277 => "rendered_synced_state": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        278 => "link_preview_data": false decode_sparse_link_preview_data_from_decoder; false false skip_link_preview_data_from_decoder;
        279 => "text_bidi_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        280 => "text_truncation": false decode_sparse_text_truncation_from_decoder; false false kiwi_skip_uint_value;
        281 => "library_move_history": true decode_sparse_library_move_history_item_from_decoder; true false skip_library_move_history_item_from_decoder;
        282 => "shape_truncates": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        283 => "section_contents_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        284 => "simplify_instance_panels": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        285 => "widget_input_behavior": false decode_sparse_widget_input_behavior_from_decoder; false false kiwi_skip_uint_value;
        286 => "widget_tooltip": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        287 => "border_top_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        288 => "border_bottom_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        289 => "border_left_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        290 => "border_right_hidden": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        291 => "widget_hover_style": false decode_sparse_widget_hover_style_from_decoder; false false skip_widget_hover_style_from_decoder;
        292 => "has_had_rtl_text": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        293 => "is_widget_stickable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        294 => "borders_take_space": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        295 => "border_top_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        296 => "border_bottom_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        297 => "border_left_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        298 => "border_right_weight": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        299 => "border_stroke_weights_independent": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        300 => "video_playback": false decode_sparse_video_playback_from_decoder; false false skip_video_playback_from_decoder;
        301 => "stamp_data": false decode_sparse_stamp_data_from_decoder; false false skip_stamp_data_from_decoder;
        302 => "accessible_html_tag": false decode_sparse_html_tag_from_decoder; false false kiwi_skip_uint_value;
        303 => "aria_role": false decode_sparse_aria_role_from_decoder; false false kiwi_skip_uint_value;
        304 => "accessible_label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        305 => "props_are_bubbled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        306 => "variable_data": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        307 => "variable_consumption_map": false decode_sparse_variable_data_map_from_decoder; false false skip_variable_data_map_from_decoder;
        308 => "table_row_positions": false decode_sparse_table_row_column_position_map_from_decoder; false false skip_table_row_column_position_map_from_decoder;
        309 => "table_column_positions": false decode_sparse_table_row_column_position_map_from_decoder; false false skip_table_row_column_position_map_from_decoder;
        310 => "table_row_heights": false decode_sparse_table_row_column_size_map_from_decoder; false false skip_table_row_column_size_map_from_decoder;
        311 => "table_column_widths": false decode_sparse_table_row_column_size_map_from_decoder; false false skip_table_row_column_size_map_from_decoder;
        312 => "variable_set_modes": true decode_sparse_variable_set_mode_from_decoder; true false skip_variable_set_mode_from_decoder;
        313 => "variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        314 => "variable_resolved_type": false decode_sparse_variable_resolved_data_type_from_decoder; false false kiwi_skip_uint_value;
        315 => "variable_data_values": false decode_sparse_variable_data_values_from_decoder; false false skip_variable_data_values_from_decoder;
        316 => "variable_mode_by_set_map": false decode_sparse_variable_mode_by_set_map_from_decoder; false false skip_variable_mode_by_set_map_from_decoder;
        317 => "mask_type": false decode_sparse_mask_type_from_decoder; false false kiwi_skip_uint_value;
        318 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        319 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        320 => "sort_position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        321 => "override_level": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        322 => "leading_trim": false decode_sparse_leading_trim_from_decoder; false false kiwi_skip_uint_value;
        323 => "stack_wrap": false decode_sparse_stack_wrap_from_decoder; false false kiwi_skip_uint_value;
        324 => "stack_counter_spacing": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        325 => "min_size": false decode_sparse_optional_vector_from_decoder; false false skip_optional_vector_from_decoder;
        326 => "max_size": false decode_sparse_optional_vector_from_decoder; false false skip_optional_vector_from_decoder;
        327 => "agenda_position_map": false decode_sparse_agenda_position_map_from_decoder; false false skip_agenda_position_map_from_decoder;
        328 => "agenda_metadata_map": false decode_sparse_agenda_metadata_map_from_decoder; false false skip_agenda_metadata_map_from_decoder;
        329 => "migration_status": false decode_sparse_migration_status_from_decoder; false false skip_migration_status_from_decoder;
        330 => "is_soft_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        331 => "edit_info": false decode_sparse_edit_info_from_decoder; false false skip_edit_info_from_decoder;
        332 => "style_id_for_fill": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        333 => "style_id_for_stroke_fill": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        334 => "style_id_for_text": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        335 => "style_id_for_effect": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        336 => "style_id_for_grid": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        337 => "hanging_punctuation": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        338 => "derived_immutable_frame_data_version": false decode_sparse_multiplayer_field_version_from_decoder; false false skip_multiplayer_field_version_from_decoder;
        339 => "hanging_list": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        340 => "mention": false decode_sparse_mention_from_decoder; false false skip_mention_from_decoder;
        341 => "color_profile": false decode_sparse_color_profile_from_decoder; false false kiwi_skip_uint_value;
        342 => "detached_symbol_id": false decode_sparse_symbol_id_from_decoder; false false skip_symbol_id_from_decoder;
        343 => "stack_counter_align_content": false decode_sparse_stack_counter_align_content_from_decoder; false false kiwi_skip_uint_value;
        344 => "is_snake_game_board": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        345 => "ojans_super_secret_node_field": false decode_sparse_shared_style_master_data_from_decoder; false false skip_shared_style_master_data_from_decoder;
        346 => "child_reading_direction": false decode_sparse_child_reading_direction_from_decoder; false false kiwi_skip_uint_value;
        347 => "reading_index": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        348 => "sev_moonlit_lily_data": false decode_sparse_shared_style_master_data_from_decoder; false false skip_shared_style_master_data_from_decoder;
        349 => "document_color_profile": false decode_sparse_document_color_profile_from_decoder; false false kiwi_skip_uint_value;
        350 => "variable_token_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        351 => "max_lines": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        352 => "section_status": false decode_sparse_section_status_from_decoder; false false kiwi_skip_uint_value;
        353 => "variable_scopes": true decode_sparse_variable_scope_from_decoder; true false kiwi_skip_uint_value;
        354 => "developer_related_links": true decode_sparse_developer_related_link_from_decoder; true false skip_developer_related_link_from_decoder;
        355 => "section_status_info": false decode_sparse_section_status_info_from_decoder; false false skip_section_status_info_from_decoder;
        356 => "slide_active_theme_lib_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        357 => "aria_attributes": false decode_sparse_aria_attributes_map_from_decoder; false false skip_aria_attributes_map_from_decoder;
        358 => "code_syntax": false decode_sparse_code_syntax_map_from_decoder; false false skip_code_syntax_map_from_decoder;
        359 => "derived_text_data": false decode_sparse_derived_text_data_from_decoder; false false skip_derived_text_data_from_decoder;
        360 => "should_hide_cursors_on_widget_hover": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        361 => "handoff_status_map": false decode_sparse_handoff_status_map_from_decoder; false false skip_handoff_status_map_from_decoder;
        362 => "layout_root": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        363 => "diagram_parent_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        364 => "layout_position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        365 => "edit_scope_info": false decode_sparse_edit_scope_info_from_decoder; false false skip_edit_scope_info_from_decoder;
        366 => "diagram_layout_rule_type": false decode_sparse_diagram_layout_rule_type_from_decoder; false false kiwi_skip_uint_value;
        367 => "diagram_parent_index": false decode_sparse_diagram_parent_index_from_decoder; false false skip_diagram_parent_index_from_decoder;
        368 => "diagram_layout_paused": false decode_sparse_diagram_layout_paused_from_decoder; false false kiwi_skip_uint_value;
        369 => "annotations": true decode_sparse_annotation_from_decoder; true false skip_annotation_from_decoder;
        370 => "section_preset_info": false decode_sparse_section_preset_info_from_decoder; false false skip_section_preset_info_from_decoder;
        371 => "interactive_slide_config_data": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        372 => "interactive_slide_participant_data": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        373 => "connector_type": false decode_sparse_connector_type_from_decoder; false false kiwi_skip_uint_value;
        374 => "semantic_weight": false decode_sparse_semantic_weight_from_decoder; false false kiwi_skip_uint_value;
        375 => "semantic_italic": false decode_sparse_semantic_italic_from_decoder; false false kiwi_skip_uint_value;
        376 => "is_override_over_text_style": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        377 => "backing_variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        378 => "backing_variable_id": false decode_sparse_variable_id_or_variable_override_id_from_decoder; false false skip_variable_id_or_variable_override_id_from_decoder;
        379 => "theme_id": false decode_sparse_theme_id_from_decoder; false false skip_theme_id_from_decoder;
        380 => "is_page_divider": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        381 => "slide_theme_data": false decode_sparse_slide_theme_data_from_decoder; false false skip_slide_theme_data_from_decoder;
        382 => "module_type": false decode_sparse_module_type_from_decoder; false false kiwi_skip_uint_value;
        383 => "file_asset_ids": false decode_sparse_asset_id_map_from_decoder; false false skip_asset_id_map_from_decoder;
        384 => "measurements": true decode_sparse_annotation_measurement_from_decoder; true false skip_annotation_measurement_from_decoder;
        385 => "is_collection_extendable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        386 => "root_variable_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        387 => "is_responsive_set": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        388 => "paste_source": false decode_sparse_paste_source_from_decoder; false false skip_paste_source_from_decoder;
        389 => "slide_speaker_notes": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        390 => "slide_theme_map": false decode_sparse_slide_theme_map_from_decoder; false false skip_slide_theme_map_from_decoder;
        391 => "emoji_image_set": false decode_sparse_emoji_image_set_from_decoder; false false kiwi_skip_uint_value;
        392 => "slide_thumbnail_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        393 => "slide_template_file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        394 => "nested_instance_resize_enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        395 => "source_library_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        396 => "text_explicit_layout_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        397 => "page_type": false decode_sparse_editor_type_from_decoder; false false kiwi_skip_uint_value;
        398 => "default_responsive_set_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        399 => "user_facing_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        400 => "responsive_set_settings": false decode_sparse_responsive_set_settings_from_decoder; false false skip_responsive_set_settings_from_decoder;
        401 => "widget_input_text_node_type": false decode_sparse_widget_input_text_node_type_from_decoder; false false kiwi_skip_uint_value;
        402 => "flapp_type": false decode_sparse_flapp_type_from_decoder; false false kiwi_skip_uint_value;
        403 => "are_slides_manually_indented": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        404 => "behaviors": false decode_sparse_node_behaviors_from_decoder; false false skip_node_behaviors_from_decoder;
        405 => "ai_edited_node_change_field_numbers": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        406 => "sorted_moving_child_indices": true kiwi_sparse_int_value; true false kiwi_skip_int_value;
        407 => "first_draft_data": false decode_sparse_first_draft_data_from_decoder; false false skip_first_draft_data_from_decoder;
        408 => "ai_edit_scope_label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        409 => "platform_shape_definition": false decode_sparse_platform_shape_definition_from_decoder; false false skip_platform_shape_definition_from_decoder;
        410 => "is_skipped_slide": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        411 => "text_decoration_fill_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        412 => "text_decoration_skip_ink": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        413 => "text_underline_offset": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        414 => "source_code": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        415 => "text_decoration_thickness": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        416 => "text_decoration_style": false decode_sparse_text_decoration_style_from_decoder; false false kiwi_skip_uint_value;
        417 => "responsive_text_style_variants": true decode_sparse_responsive_text_style_variant_from_decoder; true false skip_responsive_text_style_variant_from_decoder;
        418 => "first_draft_kit_element_data": false decode_sparse_first_draft_kit_element_data_from_decoder; false false skip_first_draft_kit_element_data_from_decoder;
        419 => "cms_selector": false decode_sparse_cms_selector_from_decoder; false false skip_cms_selector_from_decoder;
        420 => "cms_consumption_map": false decode_sparse_cms_consumption_map_from_decoder; false false skip_cms_consumption_map_from_decoder;
        421 => "cooper_revert_data": false decode_sparse_cooper_revert_data_from_decoder; false false skip_cooper_revert_data_from_decoder;
        422 => "hub_file_attribution": false decode_sparse_hub_file_attribution_from_decoder; false false skip_hub_file_attribution_from_decoder;
        423 => "target_aspect_ratio": false decode_sparse_optional_vector_from_decoder; false false skip_optional_vector_from_decoder;
        424 => "rotation_origin": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        425 => "vector_operation_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        426 => "object_animations": true decode_sparse_prototype_interaction_from_decoder; true false skip_prototype_interaction_from_decoder;
        427 => "belongs_to_code_library_id": false decode_sparse_code_library_id_from_decoder; false false skip_code_library_id_from_decoder;
        428 => "exported_from_code_file_id": false decode_sparse_code_file_id_from_decoder; false false skip_code_file_id_from_decoder;
        429 => "backing_code_component_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
        430 => "code_export_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        431 => "code_snapshot_state": false decode_sparse_code_snapshot_state_from_decoder; false false kiwi_skip_uint_value;
        432 => "text_path_start": false decode_sparse_text_path_start_from_decoder; false false skip_text_path_start_from_decoder;
        433 => "code_block_theme": false decode_sparse_code_block_theme_from_decoder; false false kiwi_skip_uint_value;
        434 => "lock_mode": false decode_sparse_lock_mode_from_decoder; false false kiwi_skip_uint_value;
        435 => "grid_rows": false decode_sparse_guid_position_map_from_decoder; false false skip_guid_position_map_from_decoder;
        436 => "grid_columns": false decode_sparse_guid_position_map_from_decoder; false false skip_guid_position_map_from_decoder;
        437 => "grid_row_gap": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        438 => "grid_column_gap": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        439 => "grid_row_anchor": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        440 => "grid_column_anchor": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        441 => "grid_row_span": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        442 => "grid_column_span": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        443 => "slide_number": false decode_sparse_slide_number_from_decoder; false false kiwi_skip_uint_value;
        444 => "collaborative_source_code": false decode_sparse_collaborative_plain_text_from_decoder; false false skip_collaborative_plain_text_from_decoder;
        445 => "parameter_consumption_map": false decode_sparse_variable_data_map_from_decoder; false false skip_variable_data_map_from_decoder;
        446 => "stroke_brush_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        447 => "variable_width_points": true decode_sparse_variable_width_point_from_decoder; true false skip_variable_width_point_from_decoder;
        448 => "dynamic_stroke_settings": false decode_sparse_dynamic_stroke_settings_from_decoder; false false skip_dynamic_stroke_settings_from_decoder;
        449 => "scatter_stroke_settings": false decode_sparse_scatter_stroke_settings_from_decoder; false false skip_scatter_stroke_settings_from_decoder;
        450 => "stretch_stroke_settings": false decode_sparse_stretch_stroke_settings_from_decoder; false false skip_stretch_stroke_settings_from_decoder;
        451 => "chat_messages": true decode_sparse_node_chat_message_from_decoder; true false skip_node_chat_message_from_decoder;
        452 => "brush_type": false decode_sparse_brush_type_from_decoder; false false kiwi_skip_uint_value;
        453 => "annotation_categories": false decode_sparse_annotation_categories_from_decoder; false false skip_annotation_categories_from_decoder;
        454 => "managed_string_data": false decode_sparse_managed_string_data_from_decoder; false false skip_managed_string_data_from_decoder;
        455 => "transform_modifiers": true decode_sparse_transform_modifier_from_decoder; true false skip_transform_modifier_from_decoder;
        456 => "slide_number_separator": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        457 => "primary_responsive_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        458 => "is_primary_breakpoint": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        459 => "code_snapshot": false decode_sparse_code_snapshot_from_decoder; false false skip_code_snapshot_from_decoder;
        460 => "cms_rich_text_style_map": false decode_sparse_cms_rich_text_style_map_from_decoder; false false skip_cms_rich_text_style_map_from_decoder;
        461 => "cooper_template_data": false decode_sparse_cooper_template_data_from_decoder; false false skip_cooper_template_data_from_decoder;
        462 => "multi_edit_glue_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        463 => "is_slot": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        464 => "overridden_variable_id": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
        465 => "is_code_behavior": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        466 => "thumbnail_info": false decode_sparse_thumbnail_info_from_decoder; false false skip_thumbnail_info_from_decoder;
        467 => "imported_code_files": false decode_sparse_imported_code_files_from_decoder; false false skip_imported_code_files_from_decoder;
        468 => "code_file_canvas_node_id": false decode_sparse_canvas_node_id_from_decoder; false false skip_canvas_node_id_from_decoder;
        469 => "auto_fork_code": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        470 => "has_been_manually_renamed": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        471 => "code_created_from_design": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        472 => "code_file_path": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        473 => "image_imports": false decode_sparse_image_import_map_from_decoder; false false skip_image_import_map_from_decoder;
        474 => "grid_columns_sizing": false decode_sparse_guid_grid_track_size_map_from_decoder; false false skip_guid_grid_track_size_map_from_decoder;
        475 => "grid_rows_sizing": false decode_sparse_guid_grid_track_size_map_from_decoder; false false skip_guid_grid_track_size_map_from_decoder;
        476 => "grid_child_vertical_align": false decode_sparse_grid_child_align_from_decoder; false false kiwi_skip_uint_value;
        477 => "grid_child_horizontal_align": false decode_sparse_grid_child_align_from_decoder; false false kiwi_skip_uint_value;
        478 => "code_behavior_data": false decode_sparse_code_behavior_data_from_decoder; false false skip_code_behavior_data_from_decoder;
        479 => "connector_bezier_control_points": true decode_sparse_connector_control_point_from_decoder; true false skip_connector_control_point_from_decoder;
        480 => "code_snapshot_invalidated_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        481 => "code_created_from_design_node_id": false decode_sparse_canvas_node_id_from_decoder; false false skip_canvas_node_id_from_decoder;
        482 => "stroke_seed": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        483 => "variant_prop_specs": true decode_sparse_variant_prop_spec_from_decoder; true false skip_variant_prop_spec_from_decoder;
        484 => "code_chat_messages_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        485 => "chat_compression_state": false decode_sparse_node_chat_compression_state_from_decoder; false false skip_node_chat_compression_state_from_decoder;
        486 => "is_embedded_prototype": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        487 => "is_main_code_component": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        488 => "scatter_brush_transforms": true decode_sparse_matrix_from_decoder; true false skip_matrix_from_decoder;
        489 => "jsx_props": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        490 => "is_decorative_image": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        491 => "jsx_data": false decode_sparse_jsx_data_from_decoder; false false skip_jsx_data_from_decoder;
        492 => "derived_jsx_data": false decode_sparse_derived_jsx_data_from_decoder; false false skip_derived_jsx_data_from_decoder;
        493 => "stable_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        494 => "ai_canvas_prompt": false decode_sparse_ai_canvas_prompt_from_decoder; false false skip_ai_canvas_prompt_from_decoder;
        495 => "is_slot_content": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        496 => "ai_chat_thread": false decode_sparse_ai_chat_thread_from_decoder; false false skip_ai_chat_thread_from_decoder;
        497 => "stroke_cap_size": false decode_sparse_number_from_decoder; false false skip_number_from_decoder;
        498 => "is_entrypoint_code_file": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        499 => "backing_node_id": false decode_sparse_canvas_node_id_from_decoder; false false skip_canvas_node_id_from_decoder;
        500 => "derived_breakpoint_data": false decode_sparse_derived_breakpoint_data_from_decoder; false false skip_derived_breakpoint_data_from_decoder;
        501 => "breakpoint_min_width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        502 => "component_or_state_group_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        503 => "component_or_state_group_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        504 => "source_code_library_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        505 => "interpolation_type": false decode_sparse_interpolation_type_from_decoder; false false kiwi_skip_uint_value;
        506 => "timeline_position": false kiwi_sparse_int64_value; false false kiwi_skip_int64_value;
        507 => "keyframe_value": false decode_sparse_keyframe_value_data_from_decoder; false false skip_keyframe_value_data_from_decoder;
        508 => "bezier_handles": false decode_sparse_bezier_handles_from_decoder; false false skip_bezier_handles_from_decoder;
        509 => "keyframe_operation": false decode_sparse_keyframe_operation_from_decoder; false false kiwi_skip_uint_value;
        510 => "timeline_position_type": false decode_sparse_timeline_position_type_from_decoder; false false kiwi_skip_uint_value;
        511 => "clip_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        512 => "timeline_duration": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        513 => "timeline_offset": false kiwi_sparse_int64_value; false false kiwi_skip_int64_value;
        514 => "playback_style": false decode_sparse_playback_style_from_decoder; false false kiwi_skip_uint_value;
        515 => "source_code_library_keys": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
        516 => "code_object_type": false decode_sparse_code_object_type_from_decoder; false false kiwi_skip_uint_value;
        517 => "inherited_variable_ids": false decode_sparse_inherited_variables_data_from_decoder; false false skip_inherited_variables_data_from_decoder;
        518 => "make_library_component_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        519 => "code_library_format": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        520 => "should_hide_preview_for_make_kit_creation": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        521 => "animation_presets": false decode_sparse_animation_presets_from_decoder; false false skip_animation_presets_from_decoder;
        522 => "is_breakpoint_in_focus": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        523 => "motion_transform": false decode_sparse_trss_transform2_d_from_decoder; false false skip_trss_transform2_d_from_decoder;
        524 => "used_make_libraries": true decode_sparse_used_make_library_from_decoder; true false skip_used_make_library_from_decoder;
        525 => "code_examples": true decode_sparse_code_example_from_decoder; true false skip_code_example_from_decoder;
        526 => "transition_overrides": false decode_sparse_transition_override_data_from_decoder; false false skip_transition_override_data_from_decoder;
        527 => "is_code_preview_playing_on_canvas": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        528 => "buzz_approval_requests": false decode_sparse_buzz_approval_requests_from_decoder; false false skip_buzz_approval_requests_from_decoder;
        529 => "buzz_approval_node_status_info": false decode_sparse_buzz_approval_node_status_info_from_decoder; false false skip_buzz_approval_node_status_info_from_decoder;
        530 => "is_stroke_paint_derived": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        531 => "code_preview_settings": false decode_sparse_prototype_device_from_decoder; false false skip_prototype_device_from_decoder;
        532 => "code_embed_info": false decode_sparse_code_embed_info_from_decoder; false false skip_code_embed_info_from_decoder;
        533 => "connector_version": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        534 => "source_code_collaborative_text_version": true decode_sparse_collaborative_text_op_id_from_decoder; true false skip_collaborative_text_op_id_from_decoder;
        535 => "easing_data": false decode_sparse_easing_data_from_decoder; false false skip_easing_data_from_decoder;
        536 => "mime_type": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        537 => "blob_ref": false kiwi_sparse_bytes_value; false true kiwi_skip_bytes_value;
        538 => "table_merged_cells": false decode_sparse_table_merged_cell_map_from_decoder; false false skip_table_merged_cell_map_from_decoder;
        539 => "repeater_symbol_id": false decode_sparse_symbol_id_from_decoder; false false skip_symbol_id_from_decoder;
        540 => "repeater_cms_override_data": false decode_sparse_repeater_cms_override_data_from_decoder; false false skip_repeater_cms_override_data_from_decoder;
        541 => "repeater_override_data": false decode_sparse_repeater_override_data_from_decoder; false false skip_repeater_override_data_from_decoder;
        542 => "path_trim": false decode_sparse_optional_vector_from_decoder; false false skip_optional_vector_from_decoder;
        543 => "timeline_disabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        544 => "use_legacy_smart_animate": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        545 => "is_clip": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        546 => "is_embed_code_layer": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        547 => "code_component_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        548 => "page_status": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        549 => "repeater_symbol_override_data": false decode_sparse_repeater_symbol_override_data_from_decoder; false false skip_repeater_symbol_override_data_from_decoder;
        550 => "fallback_glyphs": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        551 => "is_make_kit": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        552 => "timeline_definitions": false decode_sparse_timeline_definitions_map_from_decoder; false false skip_timeline_definitions_map_from_decoder;
        553 => "timeline_assignments": false decode_sparse_timeline_assignments_map_from_decoder; false false skip_timeline_assignments_map_from_decoder;
        554 => "stroke_offset": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        555 => "grid_auto_tracks": false decode_sparse_grid_auto_tracks_from_decoder; false false kiwi_skip_uint_value;
        556 => "grid_reflow_enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        557 => "source_control_config": false decode_sparse_source_control_config_from_decoder; false false skip_source_control_config_from_decoder;
        558 => "code_source_info": false decode_sparse_code_source_info_from_decoder; false false skip_code_source_info_from_decoder;
        559 => "spec_block_type": false decode_sparse_spec_block_type_from_decoder; false false kiwi_skip_uint_value;
        560 => "spec_block_content": false decode_sparse_collaborative_plain_text_from_decoder; false false skip_collaborative_plain_text_from_decoder;
        561 => "spec_code_block_language": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        562 => "spec_block_table_alignment": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        563 => "spec_block_indent_level": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        564 => "offset_fill_mask_geometry": true decode_sparse_path_from_decoder; true false skip_path_from_decoder;
        565 => "placeholder": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        566 => "timing_display_unit": false decode_sparse_variable_timing_display_unit_from_decoder; false false kiwi_skip_uint_value;
        567 => "disable_jit_dst": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        568 => "tools": false decode_sparse_tools_from_decoder; false false skip_tools_from_decoder;
        569 => "custom_effects": false decode_sparse_custom_effects_from_decoder; false false skip_custom_effects_from_decoder;
        570 => "transform3d": false decode_sparse_transform3d_from_decoder; false false skip_transform3d_from_decoder;
        571 => "stroke_data": false decode_sparse_stroke_data_from_decoder; false false skip_stroke_data_from_decoder;
        572 => "scene3d": false decode_sparse_scene3d_from_decoder; false false skip_scene3d_from_decoder;
        573 => "presentation_outlines": false decode_sparse_multiplayer_map_from_decoder; false false skip_multiplayer_map_from_decoder;
        574 => "stack_layout_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        575 => "spec_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        576 => "spec_width": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        577 => "spec_height": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        578 => "spec_block_table_row_heights": false decode_sparse_table_row_column_size_map_from_decoder; false false skip_table_row_column_size_map_from_decoder;
        579 => "spec_block_table_column_widths": false decode_sparse_table_row_column_size_map_from_decoder; false false skip_table_row_column_size_map_from_decoder;
        580 => "style_animations": true decode_sparse_style_animation_from_decoder; true false skip_style_animation_from_decoder;
        581 => "partial_paste_annotation": false decode_sparse_partial_paste_annotation_from_decoder; false false skip_partial_paste_annotation_from_decoder;
        582 => "style_ids_for_animation": true decode_sparse_style_id_for_animation_from_decoder; true false skip_style_id_for_animation_from_decoder;
        583 => "backing_animation_preset_id": false decode_sparse_animation_preset_id_from_decoder; false false skip_animation_preset_id_from_decoder;
        584 => "placeholder_client_lifecycle_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        585 => "placeholder_invalidate_at": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        586 => "keyframe_value_ref": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        587 => "transform_origin": false decode_sparse_transform_origin_from_decoder; false false skip_transform_origin_from_decoder;
        588 => "custom_tool_artifact_ref": false decode_sparse_custom_tool_artifact_ref_from_decoder; false false skip_custom_tool_artifact_ref_from_decoder;
        589 => "code_snapshot_layers": false decode_sparse_code_snapshot_layers_from_decoder; false false skip_code_snapshot_layers_from_decoder;
        590 => "spec_embed_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_git_repo_ref_provider_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "ugit";
        1 "github";
        2 "other";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_git_repo_ref_from_decoder;
    skip_fn skip_git_repo_ref_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GitRepoRef";
    definition "GitRepoRef";
    capacity 4;
    fields [
        1 => "provider": false decode_sparse_git_repo_ref_provider_from_decoder; false false kiwi_skip_uint_value;
        2 => "git_repo": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "git_ref": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_source_control_config_from_decoder;
    skip_fn skip_source_control_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SourceControlConfig";
    definition "SourceControlConfig";
    capacity 3;
    fields [
        1 => "origin": false decode_sparse_git_repo_ref_from_decoder; false false skip_git_repo_ref_from_decoder;
        2 => "upstream": false decode_sparse_git_repo_ref_from_decoder; false false skip_git_repo_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_snapshot_from_decoder;
    skip_fn skip_code_snapshot_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeSnapshot";
    definition "CodeSnapshot";
    capacity 8;
    fields [
        1 => "paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        2 => "offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "layout_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        4 => "device_pixel_ratio": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "canvas_size": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        6 => "state": false decode_sparse_code_snapshot_state_from_decoder; false false kiwi_skip_uint_value;
        7 => "invalidated_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_output_layer_from_decoder;
    skip_fn skip_code_output_layer_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeOutputLayer";
    definition "CodeOutputLayer";
    capacity 2;
    fields [
        1 => "node": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_snapshot_layers_from_decoder;
    skip_fn skip_code_snapshot_layers_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeSnapshotLayers";
    definition "CodeSnapshotLayers";
    capacity 4;
    fields [
        1 => "state": false decode_sparse_code_snapshot_state_from_decoder; false false kiwi_skip_uint_value;
        2 => "invalidated_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "layers": true decode_sparse_code_output_layer_from_decoder; true false skip_code_output_layer_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_behavior_data_from_decoder;
    skip_fn skip_code_behavior_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeBehaviorData";
    definition "CodeBehaviorData";
    capacity 6;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "icon": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "node_types": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
        4 => "category": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "api_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_example_from_decoder;
    skip_fn skip_code_example_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeExample";
    definition "CodeExample";
    capacity 3;
    fields [
        1 => "example_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "code_export_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_used_make_library_from_decoder;
    skip_fn skip_used_make_library_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.UsedMakeLibrary";
    definition "UsedMakeLibrary";
    capacity 2;
    fields [
        1 => "make_library_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cookie_banner_text_from_decoder;
    skip_fn skip_cookie_banner_text_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CookieBannerText";
    definition "CookieBannerText";
    capacity 19;
    fields [
        1 => "banner_header": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "banner_disclaimer_explicit": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "banner_disclaimer_implicit": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "policy_label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "accept_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "acknowledge_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        7 => "manage_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        8 => "reject_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "necessary_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        10 => "necessary_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        11 => "analytics_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        12 => "analytics_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        13 => "preferences_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        14 => "preferences_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        15 => "marketing_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        16 => "marketing_description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        17 => "save_label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        18 => "trigger_label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cookie_banner_settings_from_decoder;
    skip_fn skip_cookie_banner_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CookieBannerSettings";
    definition "CookieBannerSettings";
    capacity 12;
    fields [
        1 => "enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "component_type": false decode_sparse_cookie_banner_component_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "x_alignment": false decode_sparse_cookie_x_alignment_from_decoder; false false kiwi_skip_uint_value;
        4 => "y_alignment": false decode_sparse_cookie_y_alignment_from_decoder; false false kiwi_skip_uint_value;
        5 => "trigger_x_alignment": false decode_sparse_cookie_x_alignment_from_decoder; false false kiwi_skip_uint_value;
        6 => "trigger_y_alignment": false decode_sparse_cookie_y_alignment_from_decoder; false false kiwi_skip_uint_value;
        7 => "trigger_component_type": false decode_sparse_trigger_component_type_from_decoder; false false kiwi_skip_uint_value;
        8 => "policy_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "text": false decode_sparse_cookie_banner_text_from_decoder; false false skip_cookie_banner_text_from_decoder;
        10 => "policy_link": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        11 => "locale": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cookie_banner_component_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "banner";
        1 "modal";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_trigger_component_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "banner";
        1 "tag";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cookie_x_alignment_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "left";
        1 "center";
        2 "right";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cookie_y_alignment_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "top";
        1 "center";
        2 "bottom";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_responsive_set_settings_from_decoder;
    skip_fn skip_responsive_set_settings_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ResponsiveSetSettings";
    definition "ResponsiveSetSettings";
    capacity 22;
    fields [
        1 => "title": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "scaling_mode": false decode_sparse_responsive_scaling_mode_from_decoder; false false kiwi_skip_uint_value;
        4 => "scaling_min_font_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "scaling_max_font_size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        6 => "scaling_min_layout_width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "scaling_max_layout_width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "lang": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "favicon_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        10 => "social_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        11 => "google_analytics_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        12 => "block_search_indexing": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        13 => "custom_code_head_start": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        14 => "custom_code_head_end": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        15 => "custom_code_body_start": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        16 => "custom_code_body_end": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        17 => "favicon_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        18 => "social_image_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        19 => "add_bypass_links": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        20 => "ignore_reduced_motion": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        21 => "cookie_banner": false decode_sparse_cookie_banner_settings_from_decoder; false false skip_cookie_banner_settings_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_responsive_scaling_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "reflow";
        1 "scale";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_selector_from_decoder;
    skip_fn skip_cms_selector_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSSelector";
    definition "CMSSelector";
    capacity 5;
    fields [
        1 => "cms_collection_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "filter_criteria": false decode_sparse_cms_filter_critera_from_decoder; false false skip_cms_filter_critera_from_decoder;
        3 => "sorts": true decode_sparse_cms_selector_sort_from_decoder; true false skip_cms_selector_sort_from_decoder;
        4 => "limit": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_filter_critera_from_decoder;
    skip_fn skip_cms_filter_critera_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSFilterCritera";
    definition "CMSFilterCritera";
    capacity 3;
    fields [
        1 => "match_type": false decode_sparse_cms_filter_criteria_match_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "filters": true decode_sparse_cms_selector_filter_from_decoder; true false skip_cms_selector_filter_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cms_filter_criteria_match_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "match_all";
        1 "match_any";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_selector_filter_from_decoder;
    skip_fn skip_cms_selector_filter_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSSelectorFilter";
    definition "CMSSelectorFilter";
    capacity 4;
    fields [
        1 => "cms_field_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "op": false decode_sparse_cms_selector_filter_operator_from_decoder; false false kiwi_skip_uint_value;
        3 => "comparison_value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cms_selector_filter_operator_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "equals";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_selector_sort_from_decoder;
    skip_fn skip_cms_selector_sort_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSSelectorSort";
    definition "CMSSelectorSort";
    capacity 3;
    fields [
        1 => "cms_field_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "order_by": false decode_sparse_cms_field_order_by_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cms_field_order_by_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "ascending";
        1 "descending";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_consumption_map_from_decoder;
    skip_fn skip_cms_consumption_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSConsumptionMap";
    definition "CMSConsumptionMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_cms_consumption_map_entry_from_decoder; true false skip_cms_consumption_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_consumption_map_entry_from_decoder;
    skip_fn skip_cms_consumption_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSConsumptionMapEntry";
    definition "CMSConsumptionMapEntry";
    capacity 3;
    fields [
        1 => "consumption_field": false decode_sparse_cms_consumption_field_from_decoder; false false kiwi_skip_uint_value;
        2 => "cms_field_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cms_consumption_field_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "missing";
        1 "text_data";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_rich_text_style_map_from_decoder;
    skip_fn skip_cms_rich_text_style_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSRichTextStyleMap";
    definition "CMSRichTextStyleMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_cms_rich_text_style_entry_from_decoder; true false skip_cms_rich_text_style_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_rich_text_style_entry_from_decoder;
    skip_fn skip_cms_rich_text_style_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSRichTextStyleEntry";
    definition "CMSRichTextStyleEntry";
    capacity 3;
    fields [
        1 => "style_class": false decode_sparse_cms_rich_text_style_class_from_decoder; false false kiwi_skip_uint_value;
        2 => "text_descriptor": false decode_sparse_cms_rich_text_descriptor_from_decoder; false false skip_cms_rich_text_descriptor_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cms_rich_text_style_class_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "heading1";
        1 "heading2";
        2 "heading3";
        3 "heading4";
        4 "heading5";
        5 "heading6";
        6 "paragraph";
        7 "link";
        8 "blockquote";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_rich_text_descriptor_from_decoder;
    skip_fn skip_cms_rich_text_descriptor_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSRichTextDescriptor";
    definition "CMSRichTextDescriptor";
    capacity 3;
    fields [
        1 => "text_style_id": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        2 => "font_name_variants": true decode_sparse_font_name_from_decoder; true false skip_font_name_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_repeater_cms_override_data_from_decoder;
    skip_fn skip_repeater_cms_override_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.RepeaterCmsOverrideData";
    definition "RepeaterCmsOverrideData";
    capacity 2;
    fields [
        1 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_repeater_override_data_from_decoder;
    skip_fn skip_repeater_override_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.RepeaterOverrideData";
    definition "RepeaterOverrideData";
    capacity 2;
    fields [
        1 => "parent_index_overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_repeater_symbol_override_data_from_decoder;
    skip_fn skip_repeater_symbol_override_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.RepeaterSymbolOverrideData";
    definition "RepeaterSymbolOverrideData";
    capacity 2;
    fields [
        1 => "overrides_by_position": true decode_sparse_repeater_position_overrides_from_decoder; true false skip_repeater_position_overrides_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_repeater_position_overrides_from_decoder;
    skip_fn skip_repeater_position_overrides_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.RepeaterPositionOverrides";
    definition "RepeaterPositionOverrides";
    capacity 3;
    fields [
        1 => "position": false decode_sparse_parent_index_from_decoder; false false skip_parent_index_from_decoder;
        2 => "overrides": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_inherited_variables_data_from_decoder;
    skip_fn skip_inherited_variables_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InheritedVariablesData";
    definition "InheritedVariablesData";
    capacity 2;
    fields [
        1 => "variable_ids": true decode_sparse_inherited_variable_entry_from_decoder; true false skip_inherited_variable_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_inherited_variable_entry_from_decoder;
    skip_fn skip_inherited_variable_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InheritedVariableEntry";
    definition "InheritedVariableEntry";
    capacity 2;
    fields [
        1 => "variable_id": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_hub_file_attribution_from_decoder;
    skip_fn skip_hub_file_attribution_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.HubFileAttribution";
    definition "HubFileAttribution";
    capacity 3;
    fields [
        1 => "hub_file_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "hub_file_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_data_from_decoder;
    skip_fn skip_managed_string_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringData";
    definition "ManagedStringData";
    capacity 6;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "context": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "locale": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "content": false decode_sparse_managed_string_node_from_decoder; false false skip_managed_string_node_from_decoder;
        5 => "content_schema": false decode_sparse_managed_string_content_schema_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_managed_string_content_schema_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "v0";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_managed_string_node_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "text";
        1 "concatenate";
        2 "plural";
        3 "placeholder";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_node_from_decoder;
    skip_fn skip_managed_string_node_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringNode";
    definition "ManagedStringNode";
    capacity 6;
    fields [
        1 => "type": false decode_sparse_managed_string_node_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "text_node_data": false decode_sparse_managed_string_text_node_data_from_decoder; false false skip_managed_string_text_node_data_from_decoder;
        3 => "concatenate_node_data": false decode_sparse_managed_string_concatenate_ast_node_data_from_decoder; false false skip_managed_string_concatenate_ast_node_data_from_decoder;
        4 => "plural_node_data": false decode_sparse_managed_string_plural_ast_node_data_from_decoder; false false skip_managed_string_plural_ast_node_data_from_decoder;
        5 => "placeholder_node_data": false decode_sparse_managed_string_placeholder_ast_node_data_from_decoder; false false skip_managed_string_placeholder_ast_node_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_text_node_data_from_decoder;
    skip_fn skip_managed_string_text_node_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringTextNodeData";
    definition "ManagedStringTextNodeData";
    capacity 2;
    fields [
        1 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_concatenate_ast_node_data_from_decoder;
    skip_fn skip_managed_string_concatenate_ast_node_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringConcatenateAstNodeData";
    definition "ManagedStringConcatenateAstNodeData";
    capacity 2;
    fields [
        1 => "values": true decode_sparse_managed_string_node_from_decoder; true false skip_managed_string_node_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_managed_string_plural_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "zero";
        1 "one";
        2 "two";
        3 "few";
        4 "many";
        5 "other";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_plural_ast_node_data_from_decoder;
    skip_fn skip_managed_string_plural_ast_node_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringPluralAstNodeData";
    definition "ManagedStringPluralAstNodeData";
    capacity 3;
    fields [
        1 => "identifier": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "conditions": true decode_sparse_managed_string_plural_type_map_entry_from_decoder; true false skip_managed_string_plural_type_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_plural_type_map_entry_from_decoder;
    skip_fn skip_managed_string_plural_type_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringPluralTypeMapEntry";
    definition "ManagedStringPluralTypeMapEntry";
    capacity 3;
    fields [
        1 => "key": false decode_sparse_managed_string_plural_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false decode_sparse_managed_string_node_from_decoder; false false skip_managed_string_node_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_managed_string_format_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "text";
        1 "date";
        2 "time";
        3 "number";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_placeholder_ast_node_data_from_decoder;
    skip_fn skip_managed_string_placeholder_ast_node_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringPlaceholderAstNodeData";
    definition "ManagedStringPlaceholderAstNodeData";
    capacity 4;
    fields [
        1 => "identifier": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "format_type": false decode_sparse_managed_string_format_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "format_pattern": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cooper_revert_data_from_decoder;
    skip_fn skip_cooper_revert_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CooperRevertData";
    definition "CooperRevertData";
    capacity 2;
    fields [
        1 => "original_values": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_video_playback_from_decoder;
    skip_fn skip_video_playback_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VideoPlayback";
    definition "VideoPlayback";
    capacity 7;
    fields [
        1 => "autoplay": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "media_loop": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "muted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "show_controls": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "start_time_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        6 => "end_time_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_media_action_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "play";
        1 "pause";
        2 "toggle_play_pause";
        3 "mute";
        4 "unmute";
        5 "toggle_mute_unmute";
        6 "skip_forward";
        7 "skip_backward";
        8 "skip_to";
        9 "set_playback_rate";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_animation_timeline_action_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "play";
        1 "pause";
        2 "toggle_play_pause";
        3 "set_playhead";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_hover_style_from_decoder;
    skip_fn skip_widget_hover_style_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetHoverStyle";
    definition "WidgetHoverStyle";
    capacity 7;
    fields [
        1 => "fill_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        2 => "stroke_paints": true decode_sparse_paint_from_decoder; true false skip_paint_from_decoder;
        3 => "opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "are_fill_paints_set": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "are_stroke_paints_set": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "is_opacity_set": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_derived_subtree_cursor_from_decoder;
    skip_fn skip_widget_derived_subtree_cursor_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetDerivedSubtreeCursor";
    definition "WidgetDerivedSubtreeCursor";
    capacity 3;
    fields [
        1 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "counter": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_multiplayer_map_from_decoder;
    skip_fn skip_multiplayer_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MultiplayerMap";
    definition "MultiplayerMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_multiplayer_map_entry_from_decoder; true false skip_multiplayer_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_multiplayer_map_entry_from_decoder;
    skip_fn skip_multiplayer_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MultiplayerMapEntry";
    definition "MultiplayerMapEntry";
    capacity 3;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_data_map_from_decoder;
    skip_fn skip_variable_data_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableDataMap";
    definition "VariableDataMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_variable_data_map_entry_from_decoder; true false skip_variable_data_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_data_map_entry_from_decoder;
    skip_fn skip_variable_data_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableDataMapEntry";
    definition "VariableDataMapEntry";
    capacity 4;
    fields [
        1 => "node_field": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "variable_data": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "variable_field": false decode_sparse_variable_field_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_variable_field_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "missing";
        1 "corner_radius";
        2 "paragraph_spacing";
        3 "paragraph_indent";
        4 "stroke_weight";
        5 "stack_spacing";
        6 "stack_padding_left";
        7 "stack_padding_top";
        8 "stack_padding_right";
        9 "stack_padding_bottom";
        10 "visible";
        11 "text_data";
        12 "width";
        13 "height";
        14 "rectangle_top_left_corner_radius";
        15 "rectangle_top_right_corner_radius";
        16 "rectangle_bottom_left_corner_radius";
        17 "rectangle_bottom_right_corner_radius";
        18 "border_top_weight";
        19 "border_bottom_weight";
        20 "border_left_weight";
        21 "border_right_weight";
        22 "variant_properties";
        23 "stack_counter_spacing";
        24 "min_width";
        25 "max_width";
        26 "min_height";
        27 "max_height";
        28 "font_family";
        29 "font_style";
        30 "font_variations";
        31 "opacity";
        32 "font_size";
        34 "letter_spacing";
        36 "line_height";
        37 "overridden_symbol_id";
        38 "hyperlink";
        39 "cms_serialized_rich_text_data";
        40 "slot_content_id";
        41 "grid_row_gap";
        42 "grid_column_gap";
        43 "x_position";
        44 "y_position";
        45 "rotation";
        46 "motion_translation_x";
        47 "motion_translation_y";
        48 "motion_rotation";
        49 "motion_scale_x";
        50 "motion_scale_y";
        51 "motion_shear";
        52 "scroll_offset_x";
        53 "scroll_offset_y";
        54 "path_trim_start";
        55 "path_trim_end";
        56 "dissolve_progress";
        57 "easing_data";
        58 "media_current_time";
        59 "transform_3_d_perspective";
        60 "transform_3_d_translation_z";
        61 "transform_3_d_rotation_x";
        62 "transform_3_d_rotation_y";
        63 "transform_3_d_rotation_z";
        64 "polygon_count";
        65 "arc_data_starting_angle";
        66 "arc_data_ending_angle";
        67 "arc_data_inner_radius";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_mode_by_set_map_from_decoder;
    skip_fn skip_variable_mode_by_set_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableModeBySetMap";
    definition "VariableModeBySetMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_variable_mode_by_set_map_entry_from_decoder; true false skip_variable_mode_by_set_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_mode_by_set_map_entry_from_decoder;
    skip_fn skip_variable_mode_by_set_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableModeBySetMapEntry";
    definition "VariableModeBySetMapEntry";
    capacity 4;
    fields [
        1 => "variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        2 => "variable_mode_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "variable_set_extension_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_syntax_map_from_decoder;
    skip_fn skip_code_syntax_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeSyntaxMap";
    definition "CodeSyntaxMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_code_syntax_map_entry_from_decoder; true false skip_code_syntax_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_syntax_map_entry_from_decoder;
    skip_fn skip_code_syntax_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeSyntaxMapEntry";
    definition "CodeSyntaxMapEntry";
    capacity 3;
    fields [
        1 => "platform": false decode_sparse_code_syntax_platform_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_merged_cell_map_from_decoder;
    skip_fn skip_table_merged_cell_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableMergedCellMap";
    definition "TableMergedCellMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_table_merged_cell_map_entry_from_decoder; true false skip_table_merged_cell_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_merged_cell_map_entry_from_decoder;
    skip_fn skip_table_merged_cell_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableMergedCellMapEntry";
    definition "TableMergedCellMapEntry";
    capacity 5;
    fields [
        1 => "row_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "col_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "row_span": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        4 => "col_span": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_row_column_position_map_from_decoder;
    skip_fn skip_table_row_column_position_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableRowColumnPositionMap";
    definition "TableRowColumnPositionMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_table_row_column_position_map_entry_from_decoder; true false skip_table_row_column_position_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_row_column_position_map_entry_from_decoder;
    skip_fn skip_table_row_column_position_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableRowColumnPositionMapEntry";
    definition "TableRowColumnPositionMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_position_map_from_decoder;
    skip_fn skip_guid_position_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDPositionMap";
    definition "GUIDPositionMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_guid_position_map_entry_from_decoder; true false skip_guid_position_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_position_map_entry_from_decoder;
    skip_fn skip_guid_position_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDPositionMapEntry";
    definition "GUIDPositionMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_grid_track_size_map_from_decoder;
    skip_fn skip_guid_grid_track_size_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDGridTrackSizeMap";
    definition "GUIDGridTrackSizeMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_guid_grid_track_size_map_entry_from_decoder; true false skip_guid_grid_track_size_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_guid_grid_track_size_map_entry_from_decoder;
    skip_fn skip_guid_grid_track_size_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDGridTrackSizeMapEntry";
    definition "GUIDGridTrackSizeMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "track_size": false decode_sparse_grid_track_size_from_decoder; false false skip_grid_track_size_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_object_animation_list_from_decoder;
    skip_fn skip_object_animation_list_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ObjectAnimationList";
    definition "ObjectAnimationList";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_object_animation_list_item_from_decoder; true false skip_object_animation_list_item_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_object_animation_list_item_from_decoder;
    skip_fn skip_object_animation_list_item_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ObjectAnimationListItem";
    definition "ObjectAnimationListItem";
    capacity 3;
    fields [
        1 => "target_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "animation": false decode_sparse_prototype_action_from_decoder; false false skip_prototype_action_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_grid_track_size_from_decoder;
    skip_fn skip_grid_track_size_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GridTrackSize";
    definition "GridTrackSize";
    capacity 3;
    fields [
        1 => "min_sizing": false decode_sparse_grid_track_sizing_function_from_decoder; false false skip_grid_track_sizing_function_from_decoder;
        2 => "max_sizing": false decode_sparse_grid_track_sizing_function_from_decoder; false false skip_grid_track_sizing_function_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_grid_track_sizing_function_from_decoder;
    skip_fn skip_grid_track_sizing_function_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GridTrackSizingFunction";
    definition "GridTrackSizingFunction";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_grid_track_sizing_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_grid_track_sizing_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "flex";
        1 "fixed";
        2 "hug";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_row_column_size_map_from_decoder;
    skip_fn skip_table_row_column_size_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableRowColumnSizeMap";
    definition "TableRowColumnSizeMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_table_row_column_size_map_entry_from_decoder; true false skip_table_row_column_size_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_table_row_column_size_map_entry_from_decoder;
    skip_fn skip_table_row_column_size_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TableRowColumnSizeMapEntry";
    definition "TableRowColumnSizeMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "size": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_position_map_from_decoder;
    skip_fn skip_agenda_position_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaPositionMap";
    definition "AgendaPositionMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_agenda_position_map_entry_from_decoder; true false skip_agenda_position_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_position_map_entry_from_decoder;
    skip_fn skip_agenda_position_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaPositionMapEntry";
    definition "AgendaPositionMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_agenda_item_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "node";
        1 "block";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_metadata_map_from_decoder;
    skip_fn skip_agenda_metadata_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaMetadataMap";
    definition "AgendaMetadataMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_agenda_metadata_map_entry_from_decoder; true false skip_agenda_metadata_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_metadata_map_entry_from_decoder;
    skip_fn skip_agenda_metadata_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaMetadataMapEntry";
    definition "AgendaMetadataMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "data": false decode_sparse_agenda_metadata_from_decoder; false false skip_agenda_metadata_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_metadata_from_decoder;
    skip_fn skip_agenda_metadata_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaMetadata";
    definition "AgendaMetadata";
    capacity 7;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "type": false decode_sparse_agenda_item_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "target_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "timer_info": false decode_sparse_agenda_timer_info_from_decoder; false false skip_agenda_timer_info_from_decoder;
        5 => "vote_info": false decode_sparse_agenda_vote_info_from_decoder; false false skip_agenda_vote_info_from_decoder;
        6 => "music_info": false decode_sparse_agenda_music_info_from_decoder; false false skip_agenda_music_info_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_timer_info_from_decoder;
    skip_fn skip_agenda_timer_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaTimerInfo";
    definition "AgendaTimerInfo";
    capacity 2;
    fields [
        1 => "timer_length": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_vote_info_from_decoder;
    skip_fn skip_agenda_vote_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaVoteInfo";
    definition "AgendaVoteInfo";
    capacity 2;
    fields [
        1 => "vote_count": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agenda_music_info_from_decoder;
    skip_fn skip_agenda_music_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgendaMusicInfo";
    definition "AgendaMusicInfo";
    capacity 3;
    fields [
        1 => "song_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "start_time_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_diagram_layout_rule_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "tree";
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_diagram_parent_index_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DiagramParentIndex";
    capacity 3;
    fields [
        "guid" false decode_sparse_guid_from_decoder;
        "position" false kiwi_sparse_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_diagram_layout_paused_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "no";
        1 "yes";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_component_prop_ref_from_decoder;
    skip_fn skip_component_prop_ref_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ComponentPropRef";
    definition "ComponentPropRef";
    capacity 6;
    fields [
        1 => "node_field": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "zombie_fallback_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "component_prop_node_field": false decode_sparse_component_prop_node_field_from_decoder; false false kiwi_skip_uint_value;
        5 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_component_prop_node_field_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "visible";
        1 "text_data";
        2 "overridden_symbol_id";
        3 "inherit_fill_style_id";
        4 "slot_content_id";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_component_prop_assignment_from_decoder;
    skip_fn skip_component_prop_assignment_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ComponentPropAssignment";
    definition "ComponentPropAssignment";
    capacity 5;
    fields [
        1 => "def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "value": false decode_sparse_component_prop_value_from_decoder; false false skip_component_prop_value_from_decoder;
        3 => "var_value": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "legacy_derived_text_data": false decode_sparse_derived_text_data_from_decoder; false false skip_derived_text_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_component_prop_def_from_decoder;
    skip_fn skip_component_prop_def_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ComponentPropDef";
    definition "ComponentPropDef";
    capacity 14;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "initial_value": false decode_sparse_component_prop_value_from_decoder; false false skip_component_prop_value_from_decoder;
        4 => "sort_position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "parent_prop_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        6 => "type": false decode_sparse_component_prop_type_from_decoder; false false kiwi_skip_uint_value;
        7 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        8 => "preferred_values": false decode_sparse_component_prop_preferred_values_from_decoder; false false skip_component_prop_preferred_values_from_decoder;
        9 => "var_value": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        10 => "parameter_config": false decode_sparse_parameter_config_from_decoder; false false skip_parameter_config_from_decoder;
        11 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        12 => "slot_prop_config": false decode_sparse_slot_prop_config_from_decoder; false false skip_slot_prop_config_from_decoder;
        13 => "color_array_config": false decode_sparse_color_array_config_from_decoder; false false skip_color_array_config_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_component_prop_value_from_decoder;
    skip_fn skip_component_prop_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ComponentPropValue";
    definition "ComponentPropValue";
    capacity 13;
    fields [
        1 => "bool_value": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "text_value": false decode_sparse_text_data_from_decoder; false false skip_text_data_from_decoder;
        3 => "guid_value": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "float_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "easing_data": false decode_sparse_easing_data_from_decoder; false false skip_easing_data_from_decoder;
        6 => "vector_value": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        7 => "line_value": false decode_sparse_line_from_decoder; false false skip_line_from_decoder;
        8 => "circle_value": false decode_sparse_circle_from_decoder; false false skip_circle_from_decoder;
        9 => "rotation3_d_value": false decode_sparse_rotation3_d_from_decoder; false false skip_rotation3_d_from_decoder;
        10 => "circle_point_value": false decode_sparse_circle_point_from_decoder; false false skip_circle_point_from_decoder;
        11 => "gradient_value": false decode_sparse_gradient_from_decoder; false false skip_gradient_from_decoder;
        12 => "color_point_value": false decode_sparse_color_point_from_decoder; false false skip_color_point_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_data_from_decoder;
    skip_fn skip_timeline_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineData";
    definition "TimelineData";
    capacity 5;
    fields [
        1 => "duration_us": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        2 => "default_timeline": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "parent_timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "playback_style": false decode_sparse_playback_style_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_definitions_map_from_decoder;
    skip_fn skip_timeline_definitions_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineDefinitionsMap";
    definition "TimelineDefinitionsMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_timeline_definitions_map_entry_from_decoder; true false skip_timeline_definitions_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_definitions_map_entry_from_decoder;
    skip_fn skip_timeline_definitions_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineDefinitionsMapEntry";
    definition "TimelineDefinitionsMapEntry";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "data": false decode_sparse_timeline_data_from_decoder; false false skip_timeline_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_assignment_key_from_decoder;
    skip_fn skip_timeline_assignment_key_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineAssignmentKey";
    definition "TimelineAssignmentKey";
    capacity 3;
    fields [
        1 => "assigned_timeline_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "containing_timeline_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_binding_data_from_decoder;
    skip_fn skip_timeline_binding_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineBindingData";
    definition "TimelineBindingData";
    capacity 3;
    fields [
        1 => "offset_us": false kiwi_sparse_int64_value; false false kiwi_skip_int64_value;
        2 => "disabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_assignments_map_from_decoder;
    skip_fn skip_timeline_assignments_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineAssignmentsMap";
    definition "TimelineAssignmentsMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_timeline_assignments_map_entry_from_decoder; true false skip_timeline_assignments_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timeline_assignments_map_entry_from_decoder;
    skip_fn skip_timeline_assignments_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimelineAssignmentsMapEntry";
    definition "TimelineAssignmentsMapEntry";
    capacity 3;
    fields [
        1 => "key": false decode_sparse_timeline_assignment_key_from_decoder; false false skip_timeline_assignment_key_from_decoder;
        2 => "value": false decode_sparse_timeline_binding_data_from_decoder; false false skip_timeline_binding_data_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_component_prop_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "bool";
        1 "text";
        2 "color";
        3 "instance_swap";
        4 "variant";
        5 "number";
        6 "image";
        7 "slot";
        8 "easing";
        9 "color_array";
        10 "vector";
        11 "line";
        12 "circle";
        13 "rotation_3_d";
        14 "circle_point";
        15 "gradient";
        16 "color_point";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_component_prop_preferred_values_from_decoder;
    skip_fn skip_component_prop_preferred_values_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ComponentPropPreferredValues";
    definition "ComponentPropPreferredValues";
    capacity 3;
    fields [
        1 => "string_values": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
        2 => "instance_swap_values": true decode_sparse_instance_swap_preferred_value_from_decoder; true false skip_instance_swap_preferred_value_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_parameter_config_from_decoder;
    skip_fn skip_parameter_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ParameterConfig";
    definition "ParameterConfig";
    capacity 14;
    fields [
        1 => "number_prop_config": false decode_sparse_number_prop_config_from_decoder; false false skip_number_prop_config_from_decoder;
        2 => "control": false decode_sparse_parameter_config_control_from_decoder; false false kiwi_skip_uint_value;
        3 => "slider_config": false decode_sparse_slider_config_from_decoder; false false skip_slider_config_from_decoder;
        4 => "label": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        5 => "input_config": false decode_sparse_input_config_from_decoder; false false skip_input_config_from_decoder;
        6 => "select_config": false decode_sparse_select_config_from_decoder; false false skip_select_config_from_decoder;
        7 => "point_config": false decode_sparse_point_config_from_decoder; false false skip_point_config_from_decoder;
        8 => "line_config": false decode_sparse_line_config_from_decoder; false false skip_line_config_from_decoder;
        9 => "point_radius_config": false decode_sparse_point_radius_config_from_decoder; false false skip_point_radius_config_from_decoder;
        10 => "rotation3_d_config": false decode_sparse_rotation3_d_config_from_decoder; false false skip_rotation3_d_config_from_decoder;
        11 => "circle_point_config": false decode_sparse_circle_point_config_from_decoder; false false skip_circle_point_config_from_decoder;
        12 => "color_point_config": false decode_sparse_color_point_config_from_decoder; false false skip_color_point_config_from_decoder;
        13 => "show_divider_above": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_parameter_config_control_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "slider";
        2 "input";
        3 "select";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_input_config_from_decoder;
    skip_fn skip_input_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InputConfig";
    definition "InputConfig";
    capacity 4;
    fields [
        1 => "unit": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        2 => "min": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "max": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slider_config_from_decoder;
    skip_fn skip_slider_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SliderConfig";
    definition "SliderConfig";
    capacity 5;
    fields [
        1 => "min": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        2 => "max": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "step": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "unit": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_point_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "canvas_and_ui";
        1 "canvas";
        2 "ui";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_point_config_from_decoder;
    skip_fn skip_point_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PointConfig";
    definition "PointConfig";
    capacity 3;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
        2 => "unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_line_from_decoder;
    skip_fn skip_line_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Line";
    definition "Line";
    capacity 3;
    fields [
        1 => "a": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "b": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_line_config_from_decoder;
    skip_fn skip_line_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LineConfig";
    definition "LineConfig";
    capacity 3;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
        2 => "unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_circle_from_decoder;
    skip_fn skip_circle_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Circle";
    definition "Circle";
    capacity 3;
    fields [
        1 => "center": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_point_radius_config_from_decoder;
    skip_fn skip_point_radius_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PointRadiusConfig";
    definition "PointRadiusConfig";
    capacity 6;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
        2 => "position_unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
        3 => "radius_unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
        4 => "min_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "max_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_rotation3_d_from_decoder;
    skip_fn skip_rotation3_d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Rotation3D";
    definition "Rotation3D";
    capacity 5;
    fields [
        1 => "x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "z": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "translate_z": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_rotation3_d_config_from_decoder;
    skip_fn skip_rotation3_d_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Rotation3DConfig";
    definition "Rotation3DConfig";
    capacity 2;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_circle_point_from_decoder;
    skip_fn skip_circle_point_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CirclePoint";
    definition "CirclePoint";
    capacity 4;
    fields [
        1 => "center": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "angle": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_circle_point_config_from_decoder;
    skip_fn skip_circle_point_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CirclePointConfig";
    definition "CirclePointConfig";
    capacity 6;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
        2 => "position_unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
        3 => "radius_unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
        4 => "min_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "max_radius": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_color_point_from_decoder;
    skip_fn skip_color_point_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorPoint";
    definition "ColorPoint";
    capacity 3;
    fields [
        1 => "point": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "color": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_color_point_config_from_decoder;
    skip_fn skip_color_point_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorPointConfig";
    definition "ColorPointConfig";
    capacity 3;
    fields [
        1 => "mode": false decode_sparse_point_mode_from_decoder; false false kiwi_skip_uint_value;
        2 => "unit": false decode_sparse_number_units_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_gradient_from_decoder;
    skip_fn skip_gradient_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Gradient";
    definition "Gradient";
    capacity 2;
    fields [
        1 => "stops": true decode_sparse_gradient_stop_from_decoder; true false skip_gradient_stop_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_gradient_stop_from_decoder;
    skip_fn skip_gradient_stop_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GradientStop";
    definition "GradientStop";
    capacity 3;
    fields [
        1 => "position": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "color": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_select_option_from_decoder;
    skip_fn skip_select_option_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SelectOption";
    definition "SelectOption";
    capacity 3;
    fields [
        1 => "value": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        2 => "label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_select_config_from_decoder;
    skip_fn skip_select_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SelectConfig";
    definition "SelectConfig";
    capacity 2;
    fields [
        1 => "options": true decode_sparse_select_option_from_decoder; true false skip_select_option_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_color_array_config_from_decoder;
    skip_fn skip_color_array_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorArrayConfig";
    definition "ColorArrayConfig";
    capacity 3;
    fields [
        1 => "min_length": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "max_length": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slot_prop_config_from_decoder;
    skip_fn skip_slot_prop_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlotPropConfig";
    definition "SlotPropConfig";
    capacity 6;
    fields [
        1 => "stretch_child_on_insert": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "display_by_default": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "min_children": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "max_children": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "allow_preferred_values_only": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_number_prop_config_from_decoder;
    skip_fn skip_number_prop_config_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NumberPropConfig";
    definition "NumberPropConfig";
    capacity 5;
    fields [
        1 => "control": false decode_sparse_parameter_config_control_from_decoder; false false kiwi_skip_uint_value;
        2 => "min": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "max": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "step": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_instance_swap_preferred_value_from_decoder;
    skip_fn skip_instance_swap_preferred_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InstanceSwapPreferredValue";
    definition "InstanceSwapPreferredValue";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_instance_swap_preferred_value_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_instance_swap_preferred_value_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "component";
        1 "state_group";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_widget_event_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "mouse_down";
        1 "click";
        2 "text_edit_end";
        3 "attached_stickables_changed";
        4 "stuck_status_changed";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_widget_input_behavior_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "wrap";
        1 "truncate";
        2 "multiline";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_metadata_from_decoder;
    skip_fn skip_widget_metadata_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetMetadata";
    definition "WidgetMetadata";
    capacity 6;
    fields [
        1 => "plugin_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "plugin_version_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "widget_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "is_resizable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "is_rotatable": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_widget_property_menu_item_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "action";
        1 "separator";
        2 "color";
        3 "dropdown";
        4 "color_selector";
        5 "toggle";
        6 "link";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_property_menu_selector_option_from_decoder;
    skip_fn skip_widget_property_menu_selector_option_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetPropertyMenuSelectorOption";
    definition "WidgetPropertyMenuSelectorOption";
    capacity 3;
    fields [
        1 => "option": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "tooltip": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_widget_input_text_node_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "widget_controlled";
        1 "rich_text";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_widget_property_menu_item_from_decoder;
    skip_fn skip_widget_property_menu_item_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.WidgetPropertyMenuItem";
    definition "WidgetPropertyMenuItem";
    capacity 10;
    fields [
        1 => "property_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "tooltip": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "item_type": false decode_sparse_widget_property_menu_item_type_from_decoder; false false kiwi_skip_uint_value;
        4 => "icon": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "options": true decode_sparse_widget_property_menu_selector_option_from_decoder; true false skip_widget_property_menu_selector_option_from_decoder;
        6 => "selected_option": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        7 => "is_toggled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        8 => "href": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "allow_custom_color": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_code_block_language_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "typescript";
        1 "cpp";
        2 "ruby";
        3 "css";
        4 "javascript";
        5 "html";
        6 "json";
        7 "graphql";
        8 "python";
        9 "go";
        10 "sql";
        11 "swift";
        12 "kotlin";
        13 "rust";
        14 "bash";
        15 "plaintext";
        16 "markdown";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_code_block_theme_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "figjam_dark";
        1 "dracula";
        2 "duotone_sea";
        3 "duotone_space";
        4 "duotone_earth";
        5 "duotone_forest";
        6 "duotone_light";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_spec_block_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "paragraph";
        2 "heading_1";
        3 "heading_2";
        4 "heading_3";
        5 "heading_4";
        6 "heading_5";
        7 "heading_6";
        8 "code_block";
        9 "block_quote";
        10 "horizontal_rule";
        11 "ordered_list_item";
        12 "unordered_list_item";
        13 "document";
        14 "table";
        15 "table_row";
        16 "table_cell";
        17 "todo_list_item_unchecked";
        18 "todo_list_item_checked";
        19 "image";
        20 "embed";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_internal_enum_for_test_from_decoder;
    env env;
    decoder decoder;
    variants [
        1 "old";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_internal_data_for_test_from_decoder;
    skip_fn skip_internal_data_for_test_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InternalDataForTest";
    definition "InternalDataForTest";
    capacity 2;
    fields [
        1 => "test_field_a": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_state_group_property_value_order_from_decoder;
    skip_fn skip_state_group_property_value_order_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StateGroupPropertyValueOrder";
    definition "StateGroupPropertyValueOrder";
    capacity 3;
    fields [
        1 => "property": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "values": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_backfill_error_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "transient_retrying";
        2 "permanently_failed";
        3 "paste_failed";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_partial_paste_annotation_from_decoder;
    skip_fn skip_partial_paste_annotation_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PartialPasteAnnotation";
    definition "PartialPasteAnnotation";
    capacity 4;
    fields [
        1 => "is_partial": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "annotated_at": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        3 => "error_state": false decode_sparse_backfill_error_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variant_prop_spec_from_decoder;
    skip_fn skip_variant_prop_spec_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariantPropSpec";
    definition "VariantPropSpec";
    capacity 3;
    fields [
        1 => "prop_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_list_data_from_decoder;
    skip_fn skip_text_list_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextListData";
    definition "TextListData";
    capacity 5;
    fields [
        1 => "list_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        2 => "bullet_type": false decode_sparse_bullet_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "indentation_level": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        4 => "line_number": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_bullet_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "ordered";
        1 "unordered";
        2 "indent";
        3 "no_list";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_line_data_from_decoder;
    skip_fn skip_text_line_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextLineData";
    definition "TextLineData";
    capacity 11;
    fields [
        1 => "line_type": false decode_sparse_line_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "indentation_level": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        3 => "directionality": false decode_sparse_directionality_from_decoder; false false kiwi_skip_uint_value;
        4 => "directionality_intent": false decode_sparse_directionality_intent_from_decoder; false false kiwi_skip_uint_value;
        5 => "downgrade_style_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        6 => "consistency_style_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        7 => "list_start_offset": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        8 => "is_first_line_of_list": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        9 => "source_directionality": false decode_sparse_source_directionality_from_decoder; false false kiwi_skip_uint_value;
        10 => "style_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_derived_text_line_data_from_decoder;
    skip_fn skip_derived_text_line_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.DerivedTextLineData";
    definition "DerivedTextLineData";
    capacity 2;
    fields [
        1 => "directionality": false decode_sparse_directionality_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_line_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "plain";
        1 "ordered_list";
        2 "unordered_list";
        3 "blockquote";
        4 "header";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_source_directionality_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "ltr";
        2 "rtl";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_directionality_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "ltr";
        1 "rtl";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_directionality_intent_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "implicit";
        1 "explicit";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_interaction_from_decoder;
    skip_fn skip_prototype_interaction_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeInteraction";
    definition "PrototypeInteraction";
    capacity 6;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "event": false decode_sparse_prototype_event_from_decoder; false false skip_prototype_event_from_decoder;
        3 => "actions": true decode_sparse_prototype_action_from_decoder; true false skip_prototype_action_from_decoder;
        4 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "state_management_version": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_event_from_decoder;
    skip_fn skip_prototype_event_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeEvent";
    definition "PrototypeEvent";
    capacity 8;
    fields [
        1 => "interaction_type": false decode_sparse_interaction_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "interaction_maintained": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "interaction_duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "key_trigger": false decode_sparse_key_trigger_from_decoder; false false skip_key_trigger_from_decoder;
        5 => "voice_event_phrase": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "transition_timeout": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "media_hit_time": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_variable_target_from_decoder;
    skip_fn skip_prototype_variable_target_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeVariableTarget";
    definition "PrototypeVariableTarget";
    capacity 3;
    fields [
        1 => "id": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
        2 => "node_field_alias": false decode_sparse_node_field_alias_from_decoder; false false skip_node_field_alias_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_conditional_actions_from_decoder;
    skip_fn skip_conditional_actions_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ConditionalActions";
    definition "ConditionalActions";
    capacity 3;
    fields [
        1 => "actions": true decode_sparse_prototype_action_from_decoder; true false skip_prototype_action_from_decoder;
        2 => "condition": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_action_from_decoder;
    skip_fn skip_prototype_action_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeAction";
    definition "PrototypeAction";
    capacity 43;
    fields [
        1 => "transition_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "transition_type": false decode_sparse_transition_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "transition_duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "easing_type": false decode_sparse_easing_type_from_decoder; false false kiwi_skip_uint_value;
        5 => "transition_timeout": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        6 => "transition_should_smart_animate": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        7 => "connection_type": false decode_sparse_connection_type_from_decoder; false false kiwi_skip_uint_value;
        8 => "connection_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "overlay_relative_position": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        10 => "navigation_type": false decode_sparse_navigation_type_from_decoder; false false kiwi_skip_uint_value;
        11 => "transition_preserve_scroll": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        12 => "easing_function": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        13 => "extra_scroll_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        14 => "target_variable_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        15 => "target_variable_value": false decode_sparse_variable_any_value_from_decoder; false false skip_variable_any_value_from_decoder;
        16 => "media_action": false decode_sparse_media_action_from_decoder; false false kiwi_skip_uint_value;
        17 => "transition_reset_video_position": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        18 => "open_url_in_new_tab": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        19 => "target_variable": false decode_sparse_prototype_variable_target_from_decoder; false false skip_prototype_variable_target_from_decoder;
        20 => "target_variable_data": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        21 => "media_skip_to_time": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        22 => "media_skip_by_amount": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        23 => "conditions": true decode_sparse_variable_data_from_decoder; true false skip_variable_data_from_decoder;
        24 => "conditional_actions": true decode_sparse_conditional_actions_from_decoder; true false skip_conditional_actions_from_decoder;
        25 => "transition_reset_scroll_position": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        26 => "transition_reset_interactive_components": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        27 => "target_variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        28 => "target_variable_mode_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        29 => "target_variable_set_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        30 => "animation_type": false decode_sparse_animation_type_from_decoder; false false kiwi_skip_uint_value;
        31 => "animation_target_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        32 => "animation_phase": false decode_sparse_animation_phase_from_decoder; false false kiwi_skip_uint_value;
        33 => "animation_state": false decode_sparse_animation_state_from_decoder; false false skip_animation_state_from_decoder;
        34 => "link_param": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        35 => "cms_target": false decode_sparse_cms_item_page_target_from_decoder; false false skip_cms_item_page_target_from_decoder;
        36 => "media_playback_rate": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        37 => "simple_link": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        38 => "variable_set_target_extension_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        39 => "animation_timeline_action": false decode_sparse_animation_timeline_action_from_decoder; false false kiwi_skip_uint_value;
        40 => "animation_skip_to_time": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        41 => "animation_timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        42 => "transition_overrides_enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_animation_phase_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "in";
        1 "out";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_animation_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "fade";
        2 "slide_from_left";
        3 "slide_from_right";
        4 "slide_from_top";
        5 "slide_from_bottom";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_animation_state_from_decoder;
    skip_fn skip_animation_state_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnimationState";
    definition "AnimationState";
    capacity 3;
    fields [
        1 => "opacity": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "transform": false decode_sparse_matrix_from_decoder; false false skip_matrix_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prototype_starting_point_from_decoder;
    skip_fn skip_prototype_starting_point_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PrototypeStartingPoint";
    definition "PrototypeStartingPoint";
    capacity 4;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_trigger_device_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "keyboard";
        1 "unknown_controller";
        2 "xbox_one";
        3 "ps4";
        4 "switch_pro";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_key_trigger_from_decoder;
    skip_fn skip_key_trigger_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyTrigger";
    definition "KeyTrigger";
    capacity 3;
    fields [
        1 => "key_codes": true kiwi_sparse_int_value; true false kiwi_skip_int_value;
        2 => "trigger_device": false decode_sparse_trigger_device_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_hyperlink_from_decoder;
    skip_fn skip_hyperlink_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Hyperlink";
    definition "Hyperlink";
    capacity 5;
    fields [
        1 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "open_in_new_tab": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "cms_target": false decode_sparse_cms_item_page_target_from_decoder; false false skip_cms_item_page_target_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_item_page_target_from_decoder;
    skip_fn skip_cms_item_page_target_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSItemPageTarget";
    definition "CMSItemPageTarget";
    capacity 4;
    fields [
        1 => "node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "cms_item_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "field_schema_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_mention_source_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "copy_duplicate";
        2 "silent_insert";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_mention_from_decoder;
    skip_fn skip_mention_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Mention";
    definition "Mention";
    capacity 9;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "mentioned_user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "mentioned_by_user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "source": false decode_sparse_mention_source_from_decoder; false false kiwi_skip_uint_value;
        6 => "mentioned_user_id_int": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        7 => "mentioned_by_user_id_int": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        8 => "mentioned_user_group_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_embed_data_from_decoder;
    skip_fn skip_embed_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EmbedData";
    definition "EmbedData";
    capacity 15;
    fields [
        1 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "src_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "title": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "thumbnail_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        6 => "height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        7 => "embed_type": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        8 => "thumbnail_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        9 => "favicon_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        10 => "provider": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        11 => "original_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        12 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        13 => "embed_version_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        14 => "is_published_site": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_stamp_data_from_decoder;
    skip_fn skip_stamp_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StampData";
    definition "StampData";
    capacity 4;
    fields [
        1 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "voting_session_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "stamped_by_user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_link_preview_data_from_decoder;
    skip_fn skip_link_preview_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LinkPreviewData";
    definition "LinkPreviewData";
    capacity 9;
    fields [
        1 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "title": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "provider": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "description": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "thumbnail_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "favicon_image_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        7 => "thumbnail_image_width": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        8 => "thumbnail_image_height": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_viewport_from_decoder;
    skip_fn skip_viewport_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Viewport";
    definition "Viewport";
    capacity 5;
    fields [
        1 => "canvas_space_bounds": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        2 => "pixel_preview": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "pixel_density": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "canvas_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_mouse_from_decoder;
    skip_fn skip_mouse_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Mouse";
    definition "Mouse";
    capacity 6;
    fields [
        1 => "cursor": false decode_sparse_mouse_cursor_from_decoder; false false kiwi_skip_uint_value;
        2 => "canvas_space_location": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        3 => "canvas_space_selection_box": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        4 => "canvas_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        5 => "cursor_hidden_reason": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_click_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Click";
    capacity 3;
    fields [
        "id" false kiwi_sparse_uint_value;
        "point" false decode_sparse_vector_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_scroll_position_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ScrollPosition";
    capacity 3;
    fields [
        "node" false decode_sparse_guid_from_decoder;
        "scroll_offset" false decode_sparse_vector_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_triggered_overlay_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TriggeredOverlay";
    capacity 4;
    fields [
        "overlay_guid" false decode_sparse_guid_from_decoder;
        "hotspot_guid" false decode_sparse_guid_from_decoder;
        "swap_guid" false decode_sparse_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_triggered_overlay_data_from_decoder;
    skip_fn skip_triggered_overlay_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TriggeredOverlayData";
    definition "TriggeredOverlayData";
    capacity 6;
    fields [
        1 => "overlay_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "hotspot_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "swap_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "prototype_interaction_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        5 => "hotspot_blueprint_id": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_triggered_set_variable_action_data_from_decoder;
    skip_fn skip_triggered_set_variable_action_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TriggeredSetVariableActionData";
    definition "TriggeredSetVariableActionData";
    capacity 5;
    fields [
        1 => "node_for_finding_topmost_screen_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "target_variable_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "target_variable_data": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "resolved_variable_modes": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_triggered_set_variable_mode_action_data_from_decoder;
    skip_fn skip_triggered_set_variable_mode_action_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TriggeredSetVariableModeActionData";
    definition "TriggeredSetVariableModeActionData";
    capacity 5;
    fields [
        1 => "node_for_finding_topmost_screen_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "target_variable_set_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "target_variable_mode_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "target_variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_video_state_change_data_from_decoder;
    skip_fn skip_video_state_change_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VideoStateChangeData";
    definition "VideoStateChangeData";
    capacity 6;
    fields [
        1 => "target_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "is_playing": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "is_playing_sound": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "current_times": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        5 => "action_taken_timestamp": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_embedded_prototype_data_from_decoder;
    skip_fn skip_embedded_prototype_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EmbeddedPrototypeData";
    definition "EmbeddedPrototypeData";
    capacity 3;
    fields [
        1 => "node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_presented_state_from_decoder;
    skip_fn skip_presented_state_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PresentedState";
    definition "PresentedState";
    capacity 3;
    fields [
        1 => "base_screen_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "overlays": true decode_sparse_triggered_overlay_data_from_decoder; true false skip_triggered_overlay_data_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transition_direction_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "forward";
        1 "reverse";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_top_level_playback_change_from_decoder;
    skip_fn skip_top_level_playback_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TopLevelPlaybackChange";
    definition "TopLevelPlaybackChange";
    capacity 8;
    fields [
        1 => "old_state": false decode_sparse_presented_state_from_decoder; false false skip_presented_state_from_decoder;
        2 => "new_state": false decode_sparse_presented_state_from_decoder; false false skip_presented_state_from_decoder;
        3 => "hotspot_blueprint_id": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        4 => "interaction_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        5 => "is_hotspot_in_new_presented_state": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        6 => "direction": false decode_sparse_transition_direction_from_decoder; false false kiwi_skip_uint_value;
        7 => "instance_stable_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_instance_state_change_from_decoder;
    skip_fn skip_instance_state_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InstanceStateChange";
    definition "InstanceStateChange";
    capacity 6;
    fields [
        1 => "state_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "interaction_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "hotspot_stable_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        4 => "instance_stable_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        5 => "phase": false decode_sparse_playback_change_phase_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_cursor_from_decoder;
    skip_fn skip_text_cursor_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextCursor";
    definition "TextCursor";
    capacity 4;
    fields [
        1 => "selection_box": false decode_sparse_rect_from_decoder; false false skip_rect_from_decoder;
        2 => "canvas_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "text_node_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_text_selection_from_decoder;
    skip_fn skip_text_selection_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TextSelection";
    definition "TextSelection";
    capacity 8;
    fields [
        1 => "selection_boxes": true decode_sparse_rect_from_decoder; true false skip_rect_from_decoder;
        2 => "canvas_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "text_node_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "text_selection_range": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        5 => "text_node_or_containing_if_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        6 => "table_cell_row_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        7 => "table_cell_col_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_playback_change_phase_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "initiated";
        1 "aborted";
        2 "committed";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_playback_change_keyframe_from_decoder;
    skip_fn skip_playback_change_keyframe_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PlaybackChangeKeyframe";
    definition "PlaybackChangeKeyframe";
    capacity 4;
    fields [
        1 => "phase": false decode_sparse_playback_change_phase_from_decoder; false false kiwi_skip_uint_value;
        2 => "progress": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "timestamp": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_state_mapping_from_decoder;
    skip_fn skip_state_mapping_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StateMapping";
    definition "StateMapping";
    capacity 5;
    fields [
        1 => "stable_path": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        2 => "last_top_level_change": false decode_sparse_top_level_playback_change_from_decoder; false false skip_top_level_playback_change_from_decoder;
        3 => "last_top_level_change_status": false decode_sparse_playback_change_keyframe_from_decoder; false false skip_playback_change_keyframe_from_decoder;
        4 => "timestamp": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scroll_mapping_from_decoder;
    skip_fn skip_scroll_mapping_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ScrollMapping";
    definition "ScrollMapping";
    capacity 4;
    fields [
        1 => "blueprint_id": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        2 => "overlay_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "scroll_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_playback_update_from_decoder;
    skip_fn skip_playback_update_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PlaybackUpdate";
    definition "PlaybackUpdate";
    capacity 8;
    fields [
        1 => "last_top_level_change": false decode_sparse_top_level_playback_change_from_decoder; false false skip_top_level_playback_change_from_decoder;
        2 => "last_top_level_change_status": false decode_sparse_playback_change_keyframe_from_decoder; false false skip_playback_change_keyframe_from_decoder;
        3 => "scroll_mappings": true decode_sparse_scroll_mapping_from_decoder; true false skip_scroll_mapping_from_decoder;
        4 => "timestamp": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "pointer_location": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        6 => "is_top_level_frame_change": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        7 => "state_mappings": true decode_sparse_state_mapping_from_decoder; true false skip_state_mapping_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_chat_message_from_decoder;
    skip_fn skip_chat_message_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ChatMessage";
    definition "ChatMessage";
    capacity 3;
    fields [
        1 => "text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "previous_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_voice_metadata_from_decoder;
    skip_fn skip_voice_metadata_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VoiceMetadata";
    definition "VoiceMetadata";
    capacity 2;
    fields [
        1 => "connected_call_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_april_fun_cursor_from_decoder;
    skip_fn skip_april_fun_cursor_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AprilFunCursor";
    definition "AprilFunCursor";
    capacity 3;
    fields [
        1 => "id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "trail_enabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_april_fun_fig_pal_from_decoder;
    skip_fn skip_april_fun_fig_pal_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AprilFunFigPal";
    definition "AprilFunFigPal";
    capacity 3;
    fields [
        1 => "customization": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_heartbeat_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "foreground";
        1 "background";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_sites_view_state_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "file";
        1 "code";
        2 "dakota";
        3 "settings";
        4 "insert";
        5 "variables";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_design_full_page_view_state_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "design_system";
        2 "variables";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_agent_info_from_decoder;
    skip_fn skip_agent_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AgentInfo";
    definition "AgentInfo";
    capacity 4;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "logo": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "oauth_client_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_user_change_from_decoder;
    skip_fn skip_user_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.UserChange";
    definition "UserChange";
    capacity 47;
    fields [
        1 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "connected": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        3 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "color": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        5 => "image_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "viewport": false decode_sparse_viewport_from_decoder; false false skip_viewport_from_decoder;
        7 => "mouse": false decode_sparse_mouse_from_decoder; false false skip_mouse_from_decoder;
        8 => "selection": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        9 => "observing": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
        10 => "device_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        11 => "recent_clicks": true decode_sparse_click_from_decoder; true false skip_click_from_decoder;
        12 => "scroll_positions": true decode_sparse_scroll_position_from_decoder; true false skip_scroll_position_from_decoder;
        13 => "triggered_overlays": true decode_sparse_triggered_overlay_from_decoder; true false skip_triggered_overlay_from_decoder;
        14 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        15 => "last_triggered_hotspot": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        16 => "last_triggered_prototype_interaction_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        17 => "triggered_overlays_data": true decode_sparse_triggered_overlay_data_from_decoder; true false skip_triggered_overlay_data_from_decoder;
        18 => "playback_updates": true decode_sparse_playback_update_from_decoder; true false skip_playback_update_from_decoder;
        19 => "chat_message": false decode_sparse_chat_message_from_decoder; false false skip_chat_message_from_decoder;
        20 => "voice_metadata": false decode_sparse_voice_metadata_from_decoder; false false skip_voice_metadata_from_decoder;
        21 => "can_write": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        22 => "high_five_status": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        23 => "instance_state_changes": true decode_sparse_instance_state_change_from_decoder; true false skip_instance_state_change_from_decoder;
        24 => "text_cursor": false decode_sparse_text_cursor_from_decoder; false false skip_text_cursor_from_decoder;
        25 => "text_selection": false decode_sparse_text_selection_from_decoder; false false skip_text_selection_from_decoder;
        26 => "connected_at_time_s": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        27 => "focus_on_text_cursor": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        28 => "heartbeat": false decode_sparse_heartbeat_from_decoder; false false kiwi_skip_uint_value;
        29 => "triggered_set_variable_action_data": true decode_sparse_triggered_set_variable_action_data_from_decoder; true false skip_triggered_set_variable_action_data_from_decoder;
        30 => "video_state_change_data": true decode_sparse_video_state_change_data_from_decoder; true false skip_video_state_change_data_from_decoder;
        31 => "client_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        32 => "focused_slide_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        33 => "triggered_set_variable_mode_action_data": true decode_sparse_triggered_set_variable_mode_action_data_from_decoder; true false skip_triggered_set_variable_mode_action_data_from_decoder;
        34 => "april_fun_cursor": false decode_sparse_april_fun_cursor_from_decoder; false false skip_april_fun_cursor_from_decoder;
        35 => "embedded_prototype_data": true decode_sparse_embedded_prototype_data_from_decoder; true false skip_embedded_prototype_data_from_decoder;
        36 => "active_slides_embeddable_prototype": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        37 => "active_code_component_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        38 => "last_triggered_object_animation_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        39 => "april_fun_fig_pal": false decode_sparse_april_fun_fig_pal_from_decoder; false false skip_april_fun_fig_pal_from_decoder;
        40 => "collaborative_text_selection": false decode_sparse_collaborative_text_selection_from_decoder; false false skip_collaborative_text_selection_from_decoder;
        41 => "sites_view_state": false decode_sparse_sites_view_state_from_decoder; false false kiwi_skip_uint_value;
        42 => "node_chat_exchanges": true decode_sparse_node_chat_exchange_from_decoder; true false skip_node_chat_exchange_from_decoder;
        43 => "active_embedded_prototypes": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        44 => "stable_session_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        45 => "design_full_page_view_state": false decode_sparse_design_full_page_view_state_from_decoder; false false kiwi_skip_uint_value;
        46 => "agent_info": false decode_sparse_agent_info_from_decoder; false false skip_agent_info_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_interactive_slide_element_change_from_decoder;
    skip_fn skip_interactive_slide_element_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.InteractiveSlideElementChange";
    definition "InteractiveSlideElementChange";
    capacity 5;
    fields [
        1 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "anonymous_user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "response_data": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_status_change_from_decoder;
    skip_fn skip_node_status_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeStatusChange";
    definition "NodeStatusChange";
    capacity 3;
    fields [
        1 => "node_ids": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        2 => "status_info": false decode_sparse_section_status_info_from_decoder; false false skip_section_status_info_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_buzz_approval_asset_entry_from_decoder;
    skip_fn skip_buzz_approval_asset_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BuzzApprovalAssetEntry";
    definition "BuzzApprovalAssetEntry";
    capacity 3;
    fields [
        1 => "asset_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "approved": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_buzz_approval_change_from_decoder;
    skip_fn skip_buzz_approval_change_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BuzzApprovalChange";
    definition "BuzzApprovalChange";
    capacity 4;
    fields [
        1 => "asset_entries": true decode_sparse_buzz_approval_asset_entry_from_decoder; true false skip_buzz_approval_asset_entry_from_decoder;
        2 => "canvas_grid_node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "request_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scene_graph_query_behavior_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "default";
        1 "containing_page";
        2 "plugin";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scene_graph_query_mode_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "add";
        1 "set";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scene_graph_query_from_decoder;
    skip_fn skip_scene_graph_query_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SceneGraphQuery";
    definition "SceneGraphQuery";
    capacity 4;
    fields [
        1 => "starting_node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "depth": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "behavior": false decode_sparse_scene_graph_query_behavior_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_changes_metadata_from_decoder;
    skip_fn skip_node_changes_metadata_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChangesMetadata";
    definition "NodeChangesMetadata";
    capacity 2;
    fields [
        1 => "blobs_field_offset": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cursor_reaction_from_decoder;
    skip_fn skip_cursor_reaction_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CursorReaction";
    definition "CursorReaction";
    capacity 2;
    fields [
        1 => "image_url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_timer_info_from_decoder;
    skip_fn skip_timer_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TimerInfo";
    definition "TimerInfo";
    capacity 9;
    fields [
        1 => "is_paused": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "time_remaining_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "total_time_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "timer_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "set_by": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        6 => "song_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        7 => "last_received_song_timestamp_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        8 => "song_uuid": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_music_info_from_decoder;
    skip_fn skip_music_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MusicInfo";
    definition "MusicInfo";
    capacity 6;
    fields [
        1 => "is_paused": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "message_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "song_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "last_received_song_timestamp_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "is_stopped": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_presenter_nomination_from_decoder;
    skip_fn skip_presenter_nomination_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PresenterNomination";
    definition "PresenterNomination";
    capacity 3;
    fields [
        1 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "is_cancelled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_presenter_info_from_decoder;
    skip_fn skip_presenter_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PresenterInfo";
    definition "PresenterInfo";
    capacity 4;
    fields [
        1 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "nomination": false decode_sparse_presenter_nomination_from_decoder; false false skip_presenter_nomination_from_decoder;
        3 => "is_reconnected": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_client_broadcast_from_decoder;
    skip_fn skip_client_broadcast_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ClientBroadcast";
    definition "ClientBroadcast";
    capacity 7;
    fields [
        1 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "cursor_reaction": false decode_sparse_cursor_reaction_from_decoder; false false skip_cursor_reaction_from_decoder;
        3 => "timer": false decode_sparse_timer_info_from_decoder; false false skip_timer_info_from_decoder;
        4 => "presenter": false decode_sparse_presenter_info_from_decoder; false false skip_presenter_info_from_decoder;
        5 => "prototype_presenter": false decode_sparse_presenter_info_from_decoder; false false skip_presenter_info_from_decoder;
        6 => "music": false decode_sparse_music_info_from_decoder; false false skip_music_info_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_paste_asset_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "unknown";
        1 "variable";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_message_from_decoder;
    skip_fn skip_message_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Message";
    definition "Message";
    capacity 46;
    fields [
        1 => "type": false decode_sparse_message_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "session_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "ack_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "node_changes": true decode_sparse_node_change_from_decoder; true false skip_node_change_from_decoder;
        5 => "user_changes": true decode_sparse_user_change_from_decoder; true false skip_user_change_from_decoder;
        6 => "blobs": true decode_sparse_blob_from_decoder; true false skip_blob_from_decoder;
        7 => "signal_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        8 => "access": false decode_sparse_access_from_decoder; false false kiwi_skip_uint_value;
        9 => "style_set_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        10 => "style_set_type": false decode_sparse_style_set_type_from_decoder; false false kiwi_skip_uint_value;
        11 => "style_set_content_type": false decode_sparse_style_set_content_type_from_decoder; false false kiwi_skip_uint_value;
        12 => "paste_id": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        13 => "paste_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        14 => "paste_file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        15 => "signal_payload": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        16 => "scene_graph_queries": true decode_sparse_scene_graph_query_from_decoder; true false skip_scene_graph_query_from_decoder;
        17 => "node_changes_metadata": false decode_sparse_node_changes_metadata_from_decoder; false false skip_node_changes_metadata_from_decoder;
        18 => "file_version": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        19 => "paste_is_partially_outside_enclosing_frame": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        20 => "paste_page_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        21 => "is_cut": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        22 => "local_undo_stack": true decode_sparse_message_from_decoder; true false skip_message_from_decoder;
        23 => "local_redo_stack": true decode_sparse_message_from_decoder; true false skip_message_from_decoder;
        24 => "broadcasts": true decode_sparse_client_broadcast_from_decoder; true false skip_client_broadcast_from_decoder;
        25 => "reconnect_sequence_number": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        26 => "paste_branch_source_file_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        27 => "paste_editor_type": false decode_sparse_editor_type_from_decoder; false false kiwi_skip_uint_value;
        28 => "post_sync_actions": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        29 => "published_asset_guids": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        30 => "blob_base_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        31 => "dirty_from_initial_load": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        32 => "interactive_slide_element_change": false decode_sparse_interactive_slide_element_change_from_decoder; false false skip_interactive_slide_element_change_from_decoder;
        33 => "clipboard_selection_regions": true decode_sparse_clipboard_selection_region_from_decoder; true false skip_clipboard_selection_region_from_decoder;
        34 => "encoded_offsets_index": false decode_sparse_encoded_offsets_index_from_decoder; false false skip_encoded_offsets_index_from_decoder;
        35 => "has_repeating_content": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        36 => "node_status_change": false decode_sparse_node_status_change_from_decoder; false false skip_node_status_change_from_decoder;
        37 => "is_retransmission": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        38 => "sent_timestamp": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        39 => "annotation_categories": true decode_sparse_annotation_category_from_decoder; true false skip_annotation_category_from_decoder;
        40 => "client_rendered_metadata": false decode_sparse_client_rendered_metadata_from_decoder; false false skip_client_rendered_metadata_from_decoder;
        41 => "paste_asset_type": false decode_sparse_paste_asset_type_from_decoder; false false kiwi_skip_uint_value;
        42 => "stable_session_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        43 => "object_animations": false decode_sparse_object_animation_list_from_decoder; false false skip_object_animation_list_from_decoder;
        44 => "buzz_approval_change": false decode_sparse_buzz_approval_change_from_decoder; false false skip_buzz_approval_change_from_decoder;
        45 => "scene_graph_query_mode": false decode_sparse_scene_graph_query_mode_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_encoded_offsets_index_from_decoder;
    skip_fn skip_encoded_offsets_index_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EncodedOffsetsIndex";
    definition "EncodedOffsetsIndex";
    capacity 5;
    fields [
        1 => "node_changes_field_offset": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "node_changes_field_length": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        3 => "blobs_field_offset": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "node_change_offsets": true decode_sparse_guid_and_encoded_offset_from_decoder; true false skip_guid_and_encoded_offset_from_decoder;
    ] }

kiwi_sparse_struct_decoder! { 
    fn decode_sparse_guid_and_encoded_offset_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.GUIDAndEncodedOffset";
    capacity 3;
    fields [
        "guid" false decode_sparse_guid_from_decoder;
        "offset" false kiwi_sparse_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_rich_media_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "animated_image";
        1 "video";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_rich_media_data_from_decoder;
    skip_fn skip_rich_media_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.RichMediaData";
    definition "RichMediaData";
    capacity 3;
    fields [
        1 => "media_hash": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "rich_media_type": false decode_sparse_rich_media_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_variable_data_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "boolean";
        1 "float";
        2 "string";
        3 "alias";
        4 "color";
        5 "expression";
        6 "map";
        7 "symbol_id";
        8 "font_style";
        9 "text_data";
        10 "invalid";
        11 "node_field_alias";
        12 "cms_alias";
        13 "prop_ref";
        14 "image";
        15 "managed_string_alias";
        16 "link";
        17 "js_runtime_alias";
        18 "slot_content_id";
        19 "date";
        20 "keyframe_track_id";
        21 "keyframe_track_parameter_data";
        22 "easing";
        23 "timing";
        24 "vector";
        25 "color_array";
        26 "line";
        27 "circle";
        28 "rotation_3_d";
        29 "circle_point";
        30 "gradient";
        31 "color_point";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_variable_resolved_data_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "boolean";
        1 "float";
        2 "string";
        4 "color";
        5 "map";
        6 "symbol_id";
        7 "font_style";
        8 "text_data";
        9 "image";
        10 "link";
        11 "js_runtime_alias";
        12 "slot_content_id";
        13 "keyframe_track_id";
        14 "keyframe_track_parameter_data";
        15 "easing";
        16 "timing";
        17 "vector";
        18 "color_array";
        19 "line";
        20 "circle";
        21 "rotation_3_d";
        22 "circle_point";
        23 "gradient";
        24 "color_point";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_any_value_from_decoder;
    skip_fn skip_variable_any_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableAnyValue";
    definition "VariableAnyValue";
    capacity 30;
    fields [
        1 => "bool_value": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "text_value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "float_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "alias": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
        5 => "color_value": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        6 => "expression_value": false decode_sparse_expression_from_decoder; false false skip_expression_from_decoder;
        7 => "map_value": false decode_sparse_variable_map_from_decoder; false false skip_variable_map_from_decoder;
        8 => "symbol_id_value": false decode_sparse_symbol_id_from_decoder; false false skip_symbol_id_from_decoder;
        9 => "font_style_value": false decode_sparse_variable_font_style_from_decoder; false false skip_variable_font_style_from_decoder;
        10 => "text_data_value": false decode_sparse_text_data_from_decoder; false false skip_text_data_from_decoder;
        11 => "node_field_alias_value": false decode_sparse_node_field_alias_from_decoder; false false skip_node_field_alias_from_decoder;
        12 => "cms_alias_value": false decode_sparse_cms_alias_from_decoder; false false skip_cms_alias_from_decoder;
        13 => "prop_ref_value": false decode_sparse_prop_ref_value_from_decoder; false false skip_prop_ref_value_from_decoder;
        14 => "image_value": false decode_sparse_image_parameter_value_from_decoder; false false skip_image_parameter_value_from_decoder;
        15 => "managed_string_alias_value": false decode_sparse_managed_string_alias_from_decoder; false false skip_managed_string_alias_from_decoder;
        16 => "link_value": false decode_sparse_hyperlink_from_decoder; false false skip_hyperlink_from_decoder;
        17 => "js_runtime_alias_value": false decode_sparse_js_runtime_alias_from_decoder; false false skip_js_runtime_alias_from_decoder;
        18 => "slot_content_id_value": false decode_sparse_slot_content_id_from_decoder; false false skip_slot_content_id_from_decoder;
        19 => "keyframe_track_id_value": false decode_sparse_keyframe_track_id_from_decoder; false false skip_keyframe_track_id_from_decoder;
        20 => "keyframe_track_parameter_value": false decode_sparse_keyframe_track_parameter_value_from_decoder; false false skip_keyframe_track_parameter_value_from_decoder;
        21 => "easing_value": false decode_sparse_easing_data_from_decoder; false false skip_easing_data_from_decoder;
        22 => "vector_value": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        23 => "color_array_value": false decode_sparse_color_array_from_decoder; false false skip_color_array_from_decoder;
        24 => "line_value": false decode_sparse_line_from_decoder; false false skip_line_from_decoder;
        25 => "circle_value": false decode_sparse_circle_from_decoder; false false skip_circle_from_decoder;
        26 => "rotation3_d_value": false decode_sparse_rotation3_d_from_decoder; false false skip_rotation3_d_from_decoder;
        27 => "circle_point_value": false decode_sparse_circle_point_from_decoder; false false skip_circle_point_from_decoder;
        28 => "gradient_value": false decode_sparse_gradient_from_decoder; false false skip_gradient_from_decoder;
        29 => "color_point_value": false decode_sparse_color_point_from_decoder; false false skip_color_point_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_expression_function_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "addition";
        1 "subtraction";
        2 "resolve_variant";
        3 "multiply";
        4 "divide";
        5 "equals";
        6 "not_equal";
        7 "less_than";
        8 "less_than_or_equal";
        9 "greater_than";
        10 "greater_than_or_equal";
        11 "and";
        12 "or";
        13 "not";
        14 "stringify";
        15 "ternary";
        16 "var_mode_lookup";
        17 "negate";
        18 "is_truthy";
        19 "keyframe";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_expression_from_decoder;
    skip_fn skip_expression_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Expression";
    definition "Expression";
    capacity 3;
    fields [
        1 => "expression_function": false decode_sparse_expression_function_from_decoder; false false kiwi_skip_uint_value;
        2 => "expression_arguments": true decode_sparse_variable_data_from_decoder; true false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_map_value_from_decoder;
    skip_fn skip_variable_map_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableMapValue";
    definition "VariableMapValue";
    capacity 4;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "value": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "guid_key": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_map_from_decoder;
    skip_fn skip_variable_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableMap";
    definition "VariableMap";
    capacity 2;
    fields [
        1 => "values": true decode_sparse_variable_map_value_from_decoder; true false skip_variable_map_value_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_color_array_from_decoder;
    skip_fn skip_color_array_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ColorArray";
    definition "ColorArray";
    capacity 2;
    fields [
        1 => "colors": true decode_sparse_variable_data_from_decoder; true false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_font_style_from_decoder;
    skip_fn skip_variable_font_style_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableFontStyle";
    definition "VariableFontStyle";
    capacity 4;
    fields [
        1 => "as_string": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        2 => "as_float": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        3 => "as_variations": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_image_parameter_value_from_decoder;
    skip_fn skip_image_parameter_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ImageParameterValue";
    definition "ImageParameterValue";
    capacity 8;
    fields [
        1 => "image": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        2 => "image_thumbnail": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        3 => "alt_text": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "original_image_height": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        5 => "original_image_width": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        6 => "animated_image": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
        7 => "animation_frame": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_thumbnail_info_from_decoder;
    skip_fn skip_thumbnail_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ThumbnailInfo";
    definition "ThumbnailInfo";
    capacity 3;
    fields [
        1 => "node_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "thumbnail_version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_ai_canvas_prompt_from_decoder;
    skip_fn skip_ai_canvas_prompt_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AiCanvasPrompt";
    definition "AiCanvasPrompt";
    capacity 4;
    fields [
        1 => "user_prompt": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "author_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "parent_node_ids": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_field_alias_from_decoder;
    skip_fn skip_node_field_alias_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeFieldAlias";
    definition "NodeFieldAlias";
    capacity 4;
    fields [
        1 => "stable_path_to_node": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
        2 => "node_field": false decode_sparse_node_field_alias_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "index_or_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_node_field_alias_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "missing";
        1 "component_prop_assignments";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cms_alias_from_decoder;
    skip_fn skip_cms_alias_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CMSAlias";
    definition "CMSAlias";
    capacity 5;
    fields [
        1 => "collection_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "item_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "field_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "type": false decode_sparse_variable_data_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_js_runtime_alias_from_decoder;
    skip_fn skip_js_runtime_alias_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.JsRuntimeAlias";
    definition "JsRuntimeAlias";
    capacity 2;
    fields [
        1 => "lookup_key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_prop_ref_value_from_decoder;
    skip_fn skip_prop_ref_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PropRefValue";
    definition "PropRefValue";
    capacity 2;
    fields [
        1 => "def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_id_from_decoder;
    skip_fn skip_managed_string_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringId";
    definition "ManagedStringId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_placeholder_map_entry_from_decoder;
    skip_fn skip_managed_string_placeholder_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringPlaceholderMapEntry";
    definition "ManagedStringPlaceholderMapEntry";
    capacity 3;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slot_content_id_from_decoder;
    skip_fn skip_slot_content_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlotContentId";
    definition "SlotContentId";
    capacity 2;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_managed_string_alias_from_decoder;
    skip_fn skip_managed_string_alias_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManagedStringAlias";
    definition "ManagedStringAlias";
    capacity 3;
    fields [
        1 => "managed_string_id": false decode_sparse_managed_string_id_from_decoder; false false skip_managed_string_id_from_decoder;
        2 => "placeholder_values": true decode_sparse_managed_string_placeholder_map_entry_from_decoder; true false skip_managed_string_placeholder_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_track_id_from_decoder;
    skip_fn skip_keyframe_track_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeTrackId";
    definition "KeyframeTrackId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_animation_preset_id_from_decoder;
    skip_fn skip_animation_preset_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnimationPresetId";
    definition "AnimationPresetId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_tool_id_from_decoder;
    skip_fn skip_tool_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ToolId";
    definition "ToolId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_custom_effect_id_from_decoder;
    skip_fn skip_custom_effect_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CustomEffectId";
    definition "CustomEffectId";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "asset_ref": false decode_sparse_asset_ref_from_decoder; false false skip_asset_ref_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_trss_transform2_d_from_decoder;
    skip_fn skip_trss_transform2_d_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TRSSTransform2D";
    definition "TRSSTransform2D";
    capacity 5;
    fields [
        1 => "translation": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        2 => "rotation": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "scale": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        4 => "shear_x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_data_from_decoder;
    skip_fn skip_variable_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableData";
    definition "VariableData";
    capacity 4;
    fields [
        1 => "value": false decode_sparse_variable_any_value_from_decoder; false false skip_variable_any_value_from_decoder;
        2 => "data_type": false decode_sparse_variable_data_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "resolved_data_type": false decode_sparse_variable_resolved_data_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_set_mode_from_decoder;
    skip_fn skip_variable_set_mode_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableSetMode";
    definition "VariableSetMode";
    capacity 6;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "sort_position": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "parent_variable_set_id": false decode_sparse_variable_set_id_from_decoder; false false skip_variable_set_id_from_decoder;
        5 => "parent_mode_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_data_values_from_decoder;
    skip_fn skip_variable_data_values_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableDataValues";
    definition "VariableDataValues";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_variable_data_values_entry_from_decoder; true false skip_variable_data_values_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_data_values_entry_from_decoder;
    skip_fn skip_variable_data_values_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableDataValuesEntry";
    definition "VariableDataValuesEntry";
    capacity 3;
    fields [
        1 => "mode_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "variable_data": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_variable_scope_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "all_scopes";
        1 "text_content";
        2 "corner_radius";
        3 "width_height";
        4 "gap";
        5 "all_fills";
        6 "frame_fill";
        7 "shape_fill";
        8 "text_fill";
        9 "stroke";
        10 "stroke_float";
        11 "effect_float";
        12 "effect_color";
        13 "opacity";
        14 "font_style";
        15 "font_family";
        16 "font_size";
        17 "line_height";
        18 "letter_spacing";
        19 "paragraph_spacing";
        20 "paragraph_indent";
        21 "font_variations";
        22 "transform";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_any_value_from_decoder;
    skip_fn skip_keyframe_any_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeAnyValue";
    definition "KeyframeAnyValue";
    capacity 5;
    fields [
        1 => "float_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "color_value": false decode_sparse_color_from_decoder; false false skip_color_from_decoder;
        3 => "text_data_value": false decode_sparse_text_data_from_decoder; false false skip_text_data_from_decoder;
        4 => "vector_value": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_keyframe_value_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "float";
        1 "invalid";
        2 "color";
        3 "text_data";
        4 "vector";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_value_data_from_decoder;
    skip_fn skip_keyframe_value_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeValueData";
    definition "KeyframeValueData";
    capacity 3;
    fields [
        1 => "value": false decode_sparse_keyframe_any_value_from_decoder; false false skip_keyframe_any_value_from_decoder;
        2 => "value_type": false decode_sparse_keyframe_value_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_keyframe_track_parameter_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "invalid";
        1 "manual";
        2 "animation_preset";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_manual_keyframe_track_parameter_from_decoder;
    skip_fn skip_manual_keyframe_track_parameter_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ManualKeyframeTrackParameter";
    definition "ManualKeyframeTrackParameter";
    capacity 3;
    fields [
        1 => "keyframe_track_id": false decode_sparse_keyframe_track_id_from_decoder; false false skip_keyframe_track_id_from_decoder;
        2 => "timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_animation_preset_keyframe_track_parameter_from_decoder;
    skip_fn skip_animation_preset_keyframe_track_parameter_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnimationPresetKeyframeTrackParameter";
    definition "AnimationPresetKeyframeTrackParameter";
    capacity 4;
    fields [
        1 => "animation_preset_id": false decode_sparse_animation_preset_id_from_decoder; false false skip_animation_preset_id_from_decoder;
        2 => "keyframe_track_id": false decode_sparse_keyframe_track_id_from_decoder; false false skip_keyframe_track_id_from_decoder;
        3 => "timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_track_any_parameter_from_decoder;
    skip_fn skip_keyframe_track_any_parameter_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeTrackAnyParameter";
    definition "KeyframeTrackAnyParameter";
    capacity 4;
    fields [
        1 => "manual": false decode_sparse_manual_keyframe_track_parameter_from_decoder; false false skip_manual_keyframe_track_parameter_from_decoder;
        2 => "animation_preset": false decode_sparse_animation_preset_keyframe_track_parameter_from_decoder; false false skip_animation_preset_keyframe_track_parameter_from_decoder;
        3 => "animation_style_binding_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_track_parameter_from_decoder;
    skip_fn skip_keyframe_track_parameter_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeTrackParameter";
    definition "KeyframeTrackParameter";
    capacity 3;
    fields [
        1 => "value": false decode_sparse_keyframe_track_any_parameter_from_decoder; false false skip_keyframe_track_any_parameter_from_decoder;
        2 => "type": false decode_sparse_keyframe_track_parameter_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_keyframe_track_parameter_value_from_decoder;
    skip_fn skip_keyframe_track_parameter_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.KeyframeTrackParameterValue";
    definition "KeyframeTrackParameterValue";
    capacity 2;
    fields [
        1 => "parameters": true decode_sparse_keyframe_track_parameter_from_decoder; true false skip_keyframe_track_parameter_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_animation_presets_from_decoder;
    skip_fn skip_animation_presets_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnimationPresets";
    definition "AnimationPresets";
    capacity 2;
    fields [
        1 => "presets": true decode_sparse_animation_preset_data_from_decoder; true false skip_animation_preset_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_animation_preset_data_from_decoder;
    skip_fn skip_animation_preset_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AnimationPresetData";
    definition "AnimationPresetData";
    capacity 3;
    fields [
        1 => "animation_preset_id": false decode_sparse_animation_preset_id_from_decoder; false false skip_animation_preset_id_from_decoder;
        2 => "timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_style_animation_from_decoder;
    skip_fn skip_style_animation_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StyleAnimation";
    definition "StyleAnimation";
    capacity 2;
    fields [
        1 => "animation_preset_id": false decode_sparse_animation_preset_id_from_decoder; false false skip_animation_preset_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_style_id_for_animation_from_decoder;
    skip_fn skip_style_id_for_animation_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.StyleIdForAnimation";
    definition "StyleIdForAnimation";
    capacity 5;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "timeline_def_id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "animation_style_id": false decode_sparse_style_id_from_decoder; false false skip_style_id_from_decoder;
        4 => "timeline_offset": false kiwi_sparse_int64_value; false false kiwi_skip_int64_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_tools_from_decoder;
    skip_fn skip_tools_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.Tools";
    definition "Tools";
    capacity 2;
    fields [
        1 => "tools": true decode_sparse_tool_data_from_decoder; true false skip_tool_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_tool_data_from_decoder;
    skip_fn skip_tool_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ToolData";
    definition "ToolData";
    capacity 4;
    fields [
        1 => "tool_id": false decode_sparse_tool_id_from_decoder; false false skip_tool_id_from_decoder;
        2 => "backing_code_component_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
        3 => "component_prop_assignments": true decode_sparse_component_prop_assignment_from_decoder; true false skip_component_prop_assignment_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_custom_effects_from_decoder;
    skip_fn skip_custom_effects_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CustomEffects";
    definition "CustomEffects";
    capacity 2;
    fields [
        1 => "custom_effects": true decode_sparse_custom_effect_data_from_decoder; true false skip_custom_effect_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_custom_effect_data_from_decoder;
    skip_fn skip_custom_effect_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CustomEffectData";
    definition "CustomEffectData";
    capacity 2;
    fields [
        1 => "custom_effect_id": false decode_sparse_custom_effect_id_from_decoder; false false skip_custom_effect_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_spring_params_from_decoder;
    skip_fn skip_spring_params_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SpringParams";
    definition "SpringParams";
    capacity 4;
    fields [
        1 => "stiffness": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "damping": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "mass": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_easing_any_value_from_decoder;
    skip_fn skip_transition_easing_any_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionEasingAnyValue";
    definition "TransitionEasingAnyValue";
    capacity 3;
    fields [
        1 => "spring_easing": false decode_sparse_spring_params_from_decoder; false false skip_spring_params_from_decoder;
        2 => "bezier_easing": false decode_sparse_bezier_handles_from_decoder; false false skip_bezier_handles_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_easing_data_from_decoder;
    skip_fn skip_easing_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EasingData";
    definition "EasingData";
    capacity 3;
    fields [
        1 => "easing_type": false decode_sparse_easing_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "easing_value": false decode_sparse_transition_easing_any_value_from_decoder; false false skip_transition_easing_any_value_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_override_from_decoder;
    skip_fn skip_transition_override_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionOverride";
    definition "TransitionOverride";
    capacity 11;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "duration_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        4 => "delay": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "delay_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        6 => "easing": false decode_sparse_easing_data_from_decoder; false false skip_easing_data_from_decoder;
        7 => "easing_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        8 => "created_at_ms": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        9 => "interaction_i_ds": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        10 => "disabled": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_override_data_from_decoder;
    skip_fn skip_transition_override_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionOverrideData";
    definition "TransitionOverrideData";
    capacity 3;
    fields [
        1 => "all": true decode_sparse_transition_override_from_decoder; true false skip_transition_override_from_decoder;
        2 => "property_overrides": false decode_sparse_transition_override_prop_map_from_decoder; false false skip_transition_override_prop_map_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transition_override_prop_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "all";
        1 "opacity";
        2 "translation";
        3 "rotation";
        4 "scale";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_transition_override_binding_top_level_field_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "missing";
        1 "parameter_consumption_map";
        2 "effect_data";
        3 "fill_paint_data";
        4 "stroke_paint_data";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_override_binding_location_from_decoder;
    skip_fn skip_transition_override_binding_location_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionOverrideBindingLocation";
    definition "TransitionOverrideBindingLocation";
    capacity 5;
    fields [
        1 => "top_level_field": false decode_sparse_transition_override_binding_top_level_field_from_decoder; false false kiwi_skip_uint_value;
        2 => "parameter_field_value": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        3 => "index": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        4 => "effect_parametrized_field_value": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_keyframe_binding_effect_parametrized_field_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "missing";
        1 "offset_x";
        2 "offset_y";
        3 "radius";
        4 "spread";
        5 "color";
        6 "refraction_radius";
        7 "specular_angle";
        8 "specular_intensity";
        9 "chromatic_aberration";
        10 "splay";
        11 "refraction_intensity";
        12 "start_radius";
        13 "start_offset_x";
        14 "start_offset_y";
        15 "end_offset_x";
        16 "end_offset_y";
        17 "noise_size_x";
        18 "noise_size_y";
        19 "density";
        20 "effect_opacity";
        21 "secondary_color";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_contents_keyframe_binding_location_from_decoder;
    skip_fn skip_node_contents_keyframe_binding_location_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeContentsKeyframeBindingLocation";
    definition "NodeContentsKeyframeBindingLocation";
    capacity 5;
    fields [
        1 => "top_level_field": false decode_sparse_transition_override_binding_top_level_field_from_decoder; false false kiwi_skip_uint_value;
        2 => "parameter_field_value": false decode_sparse_variable_field_from_decoder; false false kiwi_skip_uint_value;
        3 => "index": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        4 => "effect_parametrized_field_value": false decode_sparse_keyframe_binding_effect_parametrized_field_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_override_prop_map_from_decoder;
    skip_fn skip_transition_override_prop_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionOverridePropMap";
    definition "TransitionOverridePropMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_transition_override_prop_map_entry_from_decoder; true false skip_transition_override_prop_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_transition_override_prop_map_entry_from_decoder;
    skip_fn skip_transition_override_prop_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.TransitionOverridePropMapEntry";
    definition "TransitionOverridePropMapEntry";
    capacity 5;
    fields [
        1 => "prop": false decode_sparse_transition_override_prop_from_decoder; false false kiwi_skip_uint_value;
        2 => "overrides": true decode_sparse_transition_override_from_decoder; true false skip_transition_override_from_decoder;
        3 => "binding_location": false decode_sparse_transition_override_binding_location_from_decoder; false false skip_transition_override_binding_location_from_decoder;
        4 => "node_contents_binding_location": false decode_sparse_node_contents_keyframe_binding_location_from_decoder; false false skip_node_contents_keyframe_binding_location_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_code_syntax_platform_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "web";
        1 "android";
        2 "i_os";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_optional_vector_from_decoder;
    skip_fn skip_optional_vector_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.OptionalVector";
    definition "OptionalVector";
    capacity 2;
    fields [
        1 => "value": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_html_tag_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "article";
        2 "section";
        3 "nav";
        4 "aside";
        5 "h1";
        6 "h2";
        7 "h3";
        8 "h4";
        9 "h5";
        10 "h6";
        11 "hgroup";
        12 "header";
        13 "footer";
        14 "address";
        15 "p";
        16 "hr";
        17 "pre";
        18 "blockquote";
        19 "ol";
        20 "ul";
        21 "menu";
        22 "li";
        23 "dl";
        24 "dt";
        25 "dd";
        26 "figure";
        27 "figcaption";
        28 "main";
        29 "div";
        30 "a";
        31 "em";
        32 "strong";
        33 "small";
        34 "s";
        35 "cite";
        36 "q";
        37 "dfn";
        38 "abbr";
        39 "ruby";
        40 "rt";
        41 "rp";
        42 "data";
        43 "time";
        44 "code";
        45 "var";
        46 "samp";
        47 "kbd";
        48 "sub";
        49 "sup";
        50 "i";
        51 "b";
        52 "u";
        53 "mark";
        54 "bdi";
        55 "bdo";
        56 "span";
        57 "br";
        58 "wbr";
        59 "picture";
        60 "source";
        61 "img";
        62 "form";
        63 "label";
        64 "input";
        65 "button";
        66 "select";
        67 "datalist";
        68 "optgroup";
        69 "option";
        70 "textarea";
        71 "output";
        72 "progress";
        73 "meter";
        74 "fieldset";
        75 "legend";
        76 "video";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_aria_role_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "auto";
        1 "button";
        2 "checkbox";
        3 "gridcell";
        4 "link";
        5 "menuitem";
        6 "menuitemcheckbox";
        7 "menuitemradio";
        8 "option";
        9 "progressbar";
        10 "radio";
        11 "scrollbar";
        12 "searchbox";
        13 "separator";
        14 "slider";
        15 "spinbutton";
        16 "switch";
        17 "tab";
        18 "tabpanel";
        19 "textbox";
        20 "treeitem";
        21 "combobox";
        22 "grid";
        23 "listbox";
        24 "menu";
        25 "menubar";
        26 "radiogroup";
        27 "tablist";
        28 "tree";
        29 "treegrid";
        30 "application";
        31 "article";
        32 "blockquote";
        33 "caption";
        34 "cell";
        35 "columnheader";
        36 "definition";
        37 "deletion";
        38 "directory";
        39 "document";
        40 "emphasis";
        41 "feed";
        42 "figure";
        43 "generic";
        44 "group";
        45 "heading";
        46 "img";
        47 "insertion";
        48 "list";
        49 "listitem";
        50 "math";
        51 "meter";
        52 "none";
        53 "note";
        54 "paragraph";
        55 "presentation";
        56 "row";
        57 "rowgroup";
        58 "rowheader";
        59 "strong";
        60 "subscript";
        61 "superscript";
        62 "table";
        63 "term";
        64 "time";
        65 "toolbar";
        66 "tooltip";
        67 "banner";
        68 "complementary";
        69 "contentinfo";
        70 "form";
        71 "main";
        72 "navigation";
        73 "region";
        74 "search";
        75 "alert";
        76 "log";
        77 "marquee";
        78 "status";
        79 "timer";
        80 "alertdialog";
        81 "dialog";
        82 "image";
        83 "heading_1";
        84 "heading_2";
        85 "heading_3";
        86 "heading_4";
        87 "heading_5";
        88 "heading_6";
        89 "header";
        90 "footer";
        91 "sidebar";
        92 "section";
        93 "maincontent";
        94 "table_cell";
        95 "widget";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_migration_status_from_decoder;
    skip_fn skip_migration_status_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MigrationStatus";
    definition "MigrationStatus";
    capacity 2;
    fields [
        1 => "dsd_cleanup": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_color_profile_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "srgb";
        1 "display_p3";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_document_color_profile_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "legacy";
        1 "srgb";
        2 "display_p3";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_child_reading_direction_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "left_to_right";
        2 "right_to_left";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_aria_attribute_any_value_from_decoder;
    skip_fn skip_aria_attribute_any_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ARIAAttributeAnyValue";
    definition "ARIAAttributeAnyValue";
    capacity 6;
    fields [
        1 => "bool_value": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        2 => "string_value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "float_value": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "int_value": false kiwi_sparse_int_value; false false kiwi_skip_int_value;
        5 => "string_array_value": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_aria_attribute_data_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "boolean";
        1 "string";
        2 "float";
        3 "int";
        4 "string_list";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_aria_attribute_data_from_decoder;
    skip_fn skip_aria_attribute_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ARIAAttributeData";
    definition "ARIAAttributeData";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_aria_attribute_data_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false decode_sparse_aria_attribute_any_value_from_decoder; false false skip_aria_attribute_any_value_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_aria_attributes_map_from_decoder;
    skip_fn skip_aria_attributes_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ARIAAttributesMap";
    definition "ARIAAttributesMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_aria_attributes_map_entry_from_decoder; true false skip_aria_attributes_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_aria_attributes_map_entry_from_decoder;
    skip_fn skip_aria_attributes_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ARIAAttributesMapEntry";
    definition "ARIAAttributesMapEntry";
    capacity 3;
    fields [
        1 => "attribute": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "value": false decode_sparse_aria_attribute_data_from_decoder; false false skip_aria_attribute_data_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_handoff_status_map_entry_from_decoder;
    skip_fn skip_handoff_status_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.HandoffStatusMapEntry";
    definition "HandoffStatusMapEntry";
    capacity 3;
    fields [
        1 => "guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "handoff_status": false decode_sparse_section_status_info_from_decoder; false false skip_section_status_info_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_handoff_status_map_from_decoder;
    skip_fn skip_handoff_status_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.HandoffStatusMap";
    definition "HandoffStatusMap";
    capacity 2;
    fields [
        1 => "entries": true decode_sparse_handoff_status_map_entry_from_decoder; true false skip_handoff_status_map_entry_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_edit_scope_info_from_decoder;
    skip_fn skip_edit_scope_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EditScopeInfo";
    definition "EditScopeInfo";
    capacity 3;
    fields [
        1 => "edit_scope_stacks": true decode_sparse_edit_scope_stack_from_decoder; true false skip_edit_scope_stack_from_decoder;
        2 => "snapshots": true decode_sparse_edit_scope_snapshot_from_decoder; true false skip_edit_scope_snapshot_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_edit_scope_snapshot_from_decoder;
    skip_fn skip_edit_scope_snapshot_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EditScopeSnapshot";
    definition "EditScopeSnapshot";
    capacity 3;
    fields [
        1 => "frames": true decode_sparse_edit_scope_stack_from_decoder; true false skip_edit_scope_stack_from_decoder;
        2 => "node_change_field_numbers": true kiwi_sparse_uint_value; true false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_edit_scope_stack_from_decoder;
    skip_fn skip_edit_scope_stack_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EditScopeStack";
    definition "EditScopeStack";
    capacity 2;
    fields [
        1 => "stack": true decode_sparse_edit_scope_from_decoder; true false skip_edit_scope_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_edit_scope_from_decoder;
    skip_fn skip_edit_scope_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.EditScope";
    definition "EditScope";
    capacity 4;
    fields [
        1 => "type": false decode_sparse_edit_scope_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "label": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "editor_type": false decode_sparse_editor_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_edit_scope_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "invalid";
        1 "test_setup";
        2 "user";
        3 "plugin";
        4 "system";
        5 "rest_api";
        6 "onboarding";
        7 "autosave";
        8 "ai";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_section_preset_state_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "inserted";
        1 "user_edited";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_emoji_image_set_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "apple";
        1 "noto";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_selection_region_focus_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "primary";
        2 "secondary";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_section_preset_info_from_decoder;
    skip_fn skip_section_preset_info_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SectionPresetInfo";
    definition "SectionPresetInfo";
    capacity 5;
    fields [
        1 => "shelf_id": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        2 => "template_id": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
        3 => "template_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "state": false decode_sparse_section_preset_state_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_clipboard_selection_region_from_decoder;
    skip_fn skip_clipboard_selection_region_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ClipboardSelectionRegion";
    definition "ClipboardSelectionRegion";
    capacity 6;
    fields [
        1 => "parent": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "nodes": true decode_sparse_guid_from_decoder; true false skip_guid_from_decoder;
        3 => "enclosing_frame_offset": false decode_sparse_vector_from_decoder; false false skip_vector_from_decoder;
        4 => "paste_is_partially_outside_enclosing_frame": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        5 => "focus_type": false decode_sparse_selection_region_focus_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_first_draft_kit_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "local";
        1 "library";
        2 "none";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_first_draft_kit_from_decoder;
    skip_fn skip_first_draft_kit_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FirstDraftKit";
    definition "FirstDraftKit";
    capacity 3;
    fields [
        1 => "key": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "type": false decode_sparse_first_draft_kit_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_first_draft_data_from_decoder;
    skip_fn skip_first_draft_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FirstDraftData";
    definition "FirstDraftData";
    capacity 3;
    fields [
        1 => "generation_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "kit": false decode_sparse_first_draft_kit_from_decoder; false false skip_first_draft_kit_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_first_draft_kit_element_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "building_block";
        2 "grouped_component";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_first_draft_kit_element_data_from_decoder;
    skip_fn skip_first_draft_kit_element_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FirstDraftKitElementData";
    definition "FirstDraftKitElementData";
    capacity 2;
    fields [
        1 => "type": false decode_sparse_first_draft_kit_element_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_platform_shape_property_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "fill";
        1 "stroke";
        2 "text";
        3 "stroke_color";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_platform_shape_behavior_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "shape";
        1 "container";
        2 "advanced_container";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_platform_shape_property_map_entry_from_decoder;
    skip_fn skip_platform_shape_property_map_entry_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PlatformShapePropertyMapEntry";
    definition "PlatformShapePropertyMapEntry";
    capacity 3;
    fields [
        1 => "property": false decode_sparse_platform_shape_property_from_decoder; false false kiwi_skip_uint_value;
        2 => "node_paths": true decode_sparse_guid_path_from_decoder; true false skip_guid_path_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_platform_shape_definition_from_decoder;
    skip_fn skip_platform_shape_definition_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PlatformShapeDefinition";
    definition "PlatformShapeDefinition";
    capacity 4;
    fields [
        1 => "property_map_entries": true decode_sparse_platform_shape_property_map_entry_from_decoder; true false skip_platform_shape_property_map_entry_from_decoder;
        2 => "behavior_type": false decode_sparse_platform_shape_behavior_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "thumbnail_node": false decode_sparse_guid_path_from_decoder; false false skip_guid_path_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_behaviors_from_decoder;
    skip_fn skip_node_behaviors_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeBehaviors";
    definition "NodeBehaviors";
    capacity 11;
    fields [
        1 => "link": false decode_sparse_link_behavior_from_decoder; false false skip_link_behavior_from_decoder;
        2 => "appear": false decode_sparse_appear_behavior_from_decoder; false false skip_appear_behavior_from_decoder;
        3 => "hover": false decode_sparse_hover_behavior_from_decoder; false false skip_hover_behavior_from_decoder;
        4 => "press": false decode_sparse_press_behavior_from_decoder; false false skip_press_behavior_from_decoder;
        5 => "focus": false decode_sparse_focus_behavior_from_decoder; false false skip_focus_behavior_from_decoder;
        6 => "scroll_parallax": false decode_sparse_scroll_parallax_behavior_from_decoder; false false skip_scroll_parallax_behavior_from_decoder;
        7 => "scroll_transform": false decode_sparse_scroll_transform_behavior_from_decoder; false false skip_scroll_transform_behavior_from_decoder;
        8 => "cursor": false decode_sparse_cursor_behavior_from_decoder; false false skip_cursor_behavior_from_decoder;
        9 => "marquee": false decode_sparse_marquee_behavior_from_decoder; false false skip_marquee_behavior_from_decoder;
        10 => "code": true decode_sparse_code_behavior_from_decoder; true false skip_code_behavior_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_behavior_transition_from_decoder;
    skip_fn skip_behavior_transition_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BehaviorTransition";
    definition "BehaviorTransition";
    capacity 7;
    fields [
        1 => "easing_type": false decode_sparse_easing_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "easing_function": true kiwi_sparse_float_value; true false kiwi_skip_float_value;
        3 => "transition_duration": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "delay": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        5 => "transition_duration_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        6 => "delay_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_appear_behavior_trigger_from_decoder;
    env env;
    decoder decoder;
    variants [
        1 "page_load";
        2 "this_layer_in_view";
        3 "other_layer_in_view";
        4 "scroll_direction";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_relative_direction_from_decoder;
    env env;
    decoder decoder;
    variants [
        1 "up";
        2 "down";
        3 "left";
        4 "right";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_appear_behavior_from_decoder;
    skip_fn skip_appear_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AppearBehavior";
    definition "AppearBehavior";
    capacity 11;
    fields [
        1 => "trigger": false decode_sparse_appear_behavior_trigger_from_decoder; false false kiwi_skip_uint_value;
        2 => "direction": false decode_sparse_relative_direction_from_decoder; false false kiwi_skip_uint_value;
        3 => "other_layer": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "enter_transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        5 => "enter_state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        6 => "exit_transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        7 => "exit_state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        8 => "plays_once": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        9 => "plays_once_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        10 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_hover_behavior_from_decoder;
    skip_fn skip_hover_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.HoverBehavior";
    definition "HoverBehavior";
    capacity 4;
    fields [
        1 => "transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        2 => "state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        3 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_press_behavior_from_decoder;
    skip_fn skip_press_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.PressBehavior";
    definition "PressBehavior";
    capacity 4;
    fields [
        1 => "transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        2 => "state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        3 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_focus_behavior_from_decoder;
    skip_fn skip_focus_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FocusBehavior";
    definition "FocusBehavior";
    capacity 4;
    fields [
        1 => "transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        2 => "state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        3 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scroll_parallax_behavior_from_decoder;
    skip_fn skip_scroll_parallax_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ScrollParallaxBehavior";
    definition "ScrollParallaxBehavior";
    capacity 6;
    fields [
        1 => "axis": false decode_sparse_scroll_direction_from_decoder; false false kiwi_skip_uint_value;
        2 => "speed": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "relative_to_page": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "speed_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        5 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_scroll_transform_behavior_trigger_from_decoder;
    env env;
    decoder decoder;
    variants [
        1 "page_height";
        2 "this_layer_in_view";
        3 "other_layer_in_view";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_scroll_transform_behavior_from_decoder;
    skip_fn skip_scroll_transform_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ScrollTransformBehavior";
    definition "ScrollTransformBehavior";
    capacity 10;
    fields [
        1 => "trigger": false decode_sparse_scroll_transform_behavior_trigger_from_decoder; false false kiwi_skip_uint_value;
        2 => "other_layer": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        3 => "transition": false decode_sparse_behavior_transition_from_decoder; false false skip_behavior_transition_from_decoder;
        4 => "from_state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        5 => "to_state": false decode_sparse_node_change_from_decoder; false false skip_node_change_from_decoder;
        6 => "plays_once": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        7 => "plays_once_var": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        8 => "plays_once_var2": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        9 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cursor_behavior_from_decoder;
    skip_fn skip_cursor_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CursorBehavior";
    definition "CursorBehavior";
    capacity 5;
    fields [
        1 => "hotspot_x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "hotspot_y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "cursor_guid": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_marquee_behavior_from_decoder;
    skip_fn skip_marquee_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.MarqueeBehavior";
    definition "MarqueeBehavior";
    capacity 8;
    fields [
        1 => "direction": false decode_sparse_relative_direction_from_decoder; false false kiwi_skip_uint_value;
        2 => "speed": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "should_loop_infinitely": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "speed_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        5 => "should_loop_infinitely_var": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        6 => "pause_on_hover": false decode_sparse_variable_data_from_decoder; false false skip_variable_data_from_decoder;
        7 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_code_behavior_from_decoder;
    skip_fn skip_code_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CodeBehavior";
    definition "CodeBehavior";
    capacity 4;
    fields [
        1 => "code_component_id": false decode_sparse_code_component_id_from_decoder; false false skip_code_component_id_from_decoder;
        2 => "component_prop_assignments": true decode_sparse_component_prop_assignment_from_decoder; true false skip_component_prop_assignment_from_decoder;
        3 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_client_rendered_metadata_from_decoder;
    skip_fn skip_client_rendered_metadata_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ClientRenderedMetadata";
    definition "ClientRenderedMetadata";
    capacity 5;
    fields [
        1 => "load_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "tracking_session_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "tracking_session_sequence_id": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        4 => "reconnect_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_link_behavior_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        1 "url";
        2 "page";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_link_behavior_from_decoder;
    skip_fn skip_link_behavior_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.LinkBehavior";
    definition "LinkBehavior";
    capacity 5;
    fields [
        1 => "type": false decode_sparse_link_behavior_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "url": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "page": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        4 => "open_in_new_window": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_variable_id_or_variable_override_id_from_decoder;
    skip_fn skip_variable_id_or_variable_override_id_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.VariableIdOrVariableOverrideId";
    definition "VariableIdOrVariableOverrideId";
    capacity 3;
    fields [
        1 => "variable_id": false decode_sparse_variable_id_from_decoder; false false skip_variable_id_from_decoder;
        2 => "variable_override_id": false decode_sparse_variable_override_id_from_decoder; false false skip_variable_override_id_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_slide_theme_data_from_decoder;
    skip_fn skip_slide_theme_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.SlideThemeData";
    definition "SlideThemeData";
    capacity 3;
    fields [
        1 => "theme_id": false decode_sparse_theme_id_from_decoder; false false skip_theme_id_from_decoder;
        2 => "version": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_slide_number_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "none";
        1 "slide";
        2 "section";
        3 "subsection";
        4 "total_within_deck";
        5 "total_within_section";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_node_chat_message_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "user_message";
        1 "assistant_message";
        2 "tool_message";
        3 "system_message";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_chat_message_from_decoder;
    skip_fn skip_node_chat_message_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChatMessage";
    definition "NodeChatMessage";
    capacity 9;
    fields [
        1 => "id": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "type": false decode_sparse_node_chat_message_type_from_decoder; false false kiwi_skip_uint_value;
        3 => "user_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        4 => "text_content": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "sent_at": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        6 => "tool_calls": true decode_sparse_node_chat_tool_call_from_decoder; true false skip_node_chat_tool_call_from_decoder;
        7 => "tool_results": true decode_sparse_node_chat_tool_result_from_decoder; true false skip_node_chat_tool_result_from_decoder;
        8 => "sent_at64": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_chat_tool_call_from_decoder;
    skip_fn skip_node_chat_tool_call_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChatToolCall";
    definition "NodeChatToolCall";
    capacity 4;
    fields [
        1 => "tool_call_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "tool_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "args_json": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_chat_tool_result_from_decoder;
    skip_fn skip_node_chat_tool_result_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChatToolResult";
    definition "NodeChatToolResult";
    capacity 4;
    fields [
        1 => "tool_call_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "tool_name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "result_json": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_chat_exchange_from_decoder;
    skip_fn skip_node_chat_exchange_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChatExchange";
    definition "NodeChatExchange";
    capacity 5;
    fields [
        1 => "node": false decode_sparse_guid_from_decoder; false false skip_guid_from_decoder;
        2 => "messages": true decode_sparse_node_chat_message_from_decoder; true false skip_node_chat_message_from_decoder;
        3 => "is_typing": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
        4 => "file_updates": true decode_sparse_file_update_from_decoder; true false skip_file_update_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_node_chat_compression_state_from_decoder;
    skip_fn skip_node_chat_compression_state_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.NodeChatCompressionState";
    definition "NodeChatCompressionState";
    capacity 3;
    fields [
        1 => "start_index": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "summary": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_file_update_from_decoder;
    skip_fn skip_file_update_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.FileUpdate";
    definition "FileUpdate";
    capacity 4;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "contents": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        3 => "is_deleted": false kiwi_sparse_bool_value; false false kiwi_skip_bool_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_ai_chat_content_part_from_decoder;
    skip_fn skip_ai_chat_content_part_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AIChatContentPart";
    definition "AIChatContentPart";
    capacity 3;
    fields [
        1 => "type": false decode_sparse_ai_chat_content_part_type_from_decoder; false false kiwi_skip_uint_value;
        2 => "value": false decode_sparse_ai_chat_content_part_any_value_from_decoder; false false skip_ai_chat_content_part_any_value_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_ai_chat_content_part_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "invalid";
        1 "text";
        2 "selected_node_ids";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_ai_chat_content_part_any_value_from_decoder;
    skip_fn skip_ai_chat_content_part_any_value_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AIChatContentPartAnyValue";
    definition "AIChatContentPartAnyValue";
    capacity 3;
    fields [
        1 => "text_value": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "selected_node_ids": true kiwi_sparse_string_value; true false kiwi_skip_string_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_ai_chat_message_role_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "user";
        1 "assistant";
        2 "tool";
        3 "system";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_ai_chat_message_from_decoder;
    skip_fn skip_ai_chat_message_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AIChatMessage";
    definition "AIChatMessage";
    capacity 6;
    fields [
        1 => "created_at_ms": false kiwi_sparse_uint_value; false false kiwi_skip_uint_value;
        2 => "role": false decode_sparse_ai_chat_message_role_from_decoder; false false kiwi_skip_uint_value;
        3 => "content": true decode_sparse_ai_chat_content_part_from_decoder; true false skip_ai_chat_content_part_from_decoder;
        4 => "client_id": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        5 => "created_at_ms64": false kiwi_sparse_uint64_value; false false kiwi_skip_uint64_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_ai_chat_thread_from_decoder;
    skip_fn skip_ai_chat_thread_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.AIChatThread";
    definition "AIChatThread";
    capacity 2;
    fields [
        1 => "messages": true decode_sparse_ai_chat_message_from_decoder; true false skip_ai_chat_message_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_cooper_template_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "custom";
        1 "twitter_post";
        2 "linkedin_post";
        3 "insta_post_square";
        4 "insta_post_portrait";
        5 "insta_story";
        6 "insta_ad";
        7 "facebook_post";
        8 "facebook_cover_photo";
        9 "facebook_event_cover";
        10 "facebook_ad_portrait";
        11 "facebook_ad_square";
        12 "pinterest_ad_pin";
        13 "twitter_banner";
        15 "linkedin_post_square";
        16 "linkedin_post_portrait";
        17 "linkedin_post_landscape";
        18 "linkedin_profile_banner";
        19 "linkedin_article_banner";
        20 "linkedin_ad_landscape";
        21 "linkedin_ad_square";
        22 "linkedin_ad_vertical";
        23 "youtube_thumbnail";
        24 "youtube_banner";
        25 "youtube_ad";
        26 "twitch_banner";
        27 "google_leaderboard_ad";
        28 "google_large_ad";
        29 "google_med_ad";
        30 "google_mobile_banner_ad";
        31 "google_skyscraper_ad";
        32 "card_horizontal";
        33 "card_vertical";
        34 "print_us_letter";
        35 "poster";
        36 "banner_standard";
        37 "banner_wide";
        38 "banner_ultrawide";
        39 "name_tag_portrait";
        40 "name_tag_landscape";
        41 "insta_reel_cover";
        42 "zoom_background";
        43 "tiktok_post";
        44 "insta_ad_portrait";
        45 "insta_post_tall_portrait";
        46 "twitter_post_square";
        47 "facebook_post_square";
        48 "facebook_post_portrait";
        49 "facebook_story";
        50 "google_square_ad";
        51 "google_small_square_ad";
        52 "google_narrow_skyscraper_ad";
        53 "google_half_page_ad";
        54 "google_large_leaderboard_ad";
        55 "google_billboard_ad";
        56 "google_banner_leaderboard_ad";
        57 "google_top_banner_ad";
        58 "google_mobile_leaderboard_banner_ad";
        59 "google_large_mobile_banner_ad";
        60 "google_mobile_interstitial_ad";
        61 "google_mobile_med_rectangle_ad";
        62 "pinterest_pin_standard";
        63 "pinterest_pin_square";
        64 "pinterest_ad_square";
        65 "print_a4";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_cooper_template_data_from_decoder;
    skip_fn skip_cooper_template_data_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.CooperTemplateData";
    definition "CooperTemplateData";
    capacity 2;
    fields [
        1 => "type": false decode_sparse_cooper_template_type_from_decoder; false false kiwi_skip_uint_value;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_image_import_map_from_decoder;
    skip_fn skip_image_import_map_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ImageImportMap";
    definition "ImageImportMap";
    capacity 2;
    fields [
        1 => "imports": true decode_sparse_image_import_from_decoder; true false skip_image_import_from_decoder;
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_image_import_from_decoder;
    skip_fn skip_image_import_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.ImageImport";
    definition "ImageImport";
    capacity 3;
    fields [
        1 => "name": false kiwi_sparse_string_value; false false kiwi_skip_string_value;
        2 => "image": false decode_sparse_image_from_decoder; false false skip_image_from_decoder;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_interpolation_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "hold";
        1 "bezier";
        2 "spring";
    ] }

kiwi_sparse_skip_message_descriptor_decoder! { 
    sparse_fn decode_sparse_bezier_handles_from_decoder;
    skip_fn skip_bezier_handles_from_decoder;
    env env;
    decoder decoder;
    module "Elixir.Figler.Schema.BezierHandles";
    definition "BezierHandles";
    capacity 5;
    fields [
        1 => "p1x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        2 => "p1y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        3 => "p2x": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
        4 => "p2y": false kiwi_sparse_float_value; false false kiwi_skip_float_value;
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_keyframe_operation_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "set";
        1 "scale";
        2 "offset";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_timeline_position_type_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "absolute";
        1 "relative";
    ] }

kiwi_sparse_enum_decoder! { 
    fn decode_sparse_playback_style_from_decoder;
    env env;
    decoder decoder;
    variants [
        0 "once";
        1 "loop";
        2 "boomerang";
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_guid_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_uint_value;
        false false kiwi_skip_uint_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_color_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_vector_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_rect_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_color_stop_from_decoder;
    decoder decoder;
    fields [
        false false skip_color_from_decoder;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_matrix_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_parent_index_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false kiwi_skip_string_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_number_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_uint_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_font_name_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_string_value;
        false false kiwi_skip_string_value;
        false false kiwi_skip_string_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_export_constraint_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_uint_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_guid_mapping_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false skip_guid_from_decoder;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_blob_from_decoder;
    decoder decoder;
    fields [
        false true kiwi_skip_bytes_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_filter_color_adjust_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_index_range_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_uint_value;
        false false kiwi_skip_uint_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_collaborative_text_op_id_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_uint_value;
        false false kiwi_skip_uint_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_matrix4f_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
        false false kiwi_skip_float_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_number_vector2_d_from_decoder;
    decoder decoder;
    fields [
        false false skip_number_from_decoder;
        false false skip_number_from_decoder;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_diagram_parent_index_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false kiwi_skip_string_value;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_click_from_decoder;
    decoder decoder;
    fields [
        false false kiwi_skip_uint_value;
        false false skip_vector_from_decoder;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_scroll_position_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false skip_vector_from_decoder;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_triggered_overlay_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false skip_guid_from_decoder;
        false false skip_guid_from_decoder;
    ] }

kiwi_skip_struct_decoder! { 
    fn skip_guid_and_encoded_offset_from_decoder;
    decoder decoder;
    fields [
        false false skip_guid_from_decoder;
        false false kiwi_skip_uint_value;
    ] }
#[derive(rustler::NifMap)]
pub struct SceneSummary {
    node_count: usize,
    parented_count: usize,
    root_count: usize,
    type_counts: Vec<(String, usize)>,
}
#[derive(Clone, Debug, rustler::NifMap)]
pub struct SceneSize {
    x: f64,
    y: f64,
}
#[derive(Clone, Debug, rustler::NifMap)]
pub struct SceneTransform {
    m00: f64,
    m01: f64,
    m02: f64,
    m10: f64,
    m11: f64,
    m12: f64,
}
#[derive(rustler::NifMap)]
pub struct SceneQueryNode {
    guid: String,
    node_type: String,
    name: Option<String>,
    parent_guid: Option<String>,
    position: Option<String>,
    size: Option<SceneSize>,
    transform: Option<SceneTransform>,
    visible: Option<bool>,
    locked: Option<bool>,
    opacity: Option<f32>,
    text: Option<String>,
    font_family: Option<String>,
    font_style: Option<String>,
    font_postscript: Option<String>,
    font_size: Option<f32>,
    text_style_guid: Option<String>,
    component_key: Option<String>,
    origin_component_key: Option<String>,
    fill_style_guid: Option<String>,
    stroke_style_guid: Option<String>,
    effect_style_guid: Option<String>,
    grid_style_guid: Option<String>,
    fill_count: Option<usize>,
    stroke_count: Option<usize>,
}
fn scene_node_type_name(value: u32) -> &'static str {
    match value {
        0 => "none",
        1 => "document",
        2 => "canvas",
        3 => "group",
        4 => "frame",
        5 => "boolean_operation",
        6 => "vector",
        7 => "star",
        8 => "line",
        9 => "ellipse",
        10 => "rectangle",
        11 => "regular_polygon",
        12 => "rounded_rectangle",
        13 => "text",
        14 => "slice",
        15 => "symbol",
        16 => "instance",
        17 => "sticky",
        18 => "shape_with_text",
        19 => "connector",
        20 => "code_block",
        21 => "widget",
        22 => "stamp",
        23 => "media",
        24 => "highlight",
        25 => "section",
        26 => "section_overlay",
        27 => "washi_tape",
        28 => "variable",
        29 => "table",
        30 => "table_cell",
        31 => "variable_set",
        32 => "slide",
        33 => "assisted_layout",
        34 => "interactive_slide_element",
        35 => "variable_override",
        36 => "module",
        37 => "slide_grid",
        38 => "slide_row",
        39 => "responsive_set",
        40 => "code_component",
        41 => "text_path",
        42 => "code_instance",
        43 => "code_library",
        44 => "code_file",
        45 => "code_layer",
        46 => "brush",
        47 => "managed_string",
        48 => "transform",
        49 => "cms_rich_text",
        50 => "repeater",
        51 => "jsx",
        52 => "embedded_prototype",
        53 => "react_fiber",
        54 => "responsive_node_set",
        55 => "webpage",
        56 => "keyframe",
        57 => "keyframe_track",
        58 => "animation_preset_instance",
        59 => "code_embed",
        60 => "binary_file",
        61 => "spec_block",
        62 => "tool_instance",
        63 => "custom_effect_instance",
        64 => "native_code_layer_instance",
        _ => "unknown",
    }
}
fn graph_focus_push_guid_ref(
    decoder: &mut Decoder<'_>,
    refs: &mut Option<Vec<GraphFocusGuid>>,
) -> NifResult<()> {
    graph_focus_push_ref(refs, graph_focus_read_guid(decoder)?);
    Ok(())
}
fn graph_focus_extend_symbol_refs(
    data: GraphFocusSymbolData,
    refs: &mut Option<Vec<GraphFocusGuid>>,
) -> NifResult<Option<GraphFocusGuid>> {
    let symbol_id = data.symbol_id;
    graph_focus_extend_refs(refs, data.refs);
    Ok(symbol_id)
}
fn graph_focus_extend_component_prop_assignments(
    decoder: &mut Decoder<'_>,
    refs: &mut Option<Vec<GraphFocusGuid>>,
) -> NifResult<()> {
    let remaining = decoder.read_var_uint()?;
    graph_focus_extend_component_prop_assignments_remaining(decoder, refs, remaining)
}
fn graph_focus_extend_component_prop_assignments_remaining(
    decoder: &mut Decoder<'_>,
    refs: &mut Option<Vec<GraphFocusGuid>>,
    remaining: u32,
) -> NifResult<()> {
    if remaining == 0 {
        Ok(())
    } else {
        let next = graph_focus_read_component_prop_assignment(decoder)?;
        graph_focus_extend_refs(refs, next);
        graph_focus_extend_component_prop_assignments_remaining(
            decoder,
            refs,
            remaining - 1,
        )
    }
}
fn graph_focus_extend_component_prop_value(
    decoder: &mut Decoder<'_>,
    refs: &mut Option<Vec<GraphFocusGuid>>,
) -> NifResult<()> {
    let next = graph_focus_read_component_prop_value(decoder)?;
    graph_focus_extend_refs(refs, next);
    Ok(())
}
#[derive(Clone, Copy, Eq, Hash, PartialEq)]
struct GraphFocusGuid {
    session_id: u32,
    local_id: u32,
}
struct GraphFocusMeta {
    guid: Option<GraphFocusGuid>,
    parent_guid: Option<GraphFocusGuid>,
    symbol_id: Option<GraphFocusGuid>,
    refs: Option<Vec<GraphFocusGuid>>,
    byte_start: usize,
    byte_end: usize,
}
struct GraphFocusSymbolData {
    symbol_id: Option<GraphFocusGuid>,
    refs: Option<Vec<GraphFocusGuid>>,
}
fn graph_focus_skip_symbol_data_field(
    decoder: &mut Decoder<'_>,
    field: u32,
) -> NifResult<()> {
    match field {
        1 => skip_guid_from_decoder(decoder)?,
        2 => kiwi_skip_repeated(decoder, skip_node_change_from_decoder)?,
        3 => kiwi_skip_float_value(decoder)?,
        field => {
            return Err(
                Error::Term(
                    Box::new(
                        format!("unknown field {} while indexing SymbolData", field),
                    ),
                ),
            );
        }
    }
    Ok(())
}
fn graph_focus_skip_component_prop_assignment_field(
    decoder: &mut Decoder<'_>,
    field: u32,
) -> NifResult<()> {
    match field {
        1 => skip_guid_from_decoder(decoder)?,
        2 => skip_component_prop_value_from_decoder(decoder)?,
        3 => skip_variable_data_from_decoder(decoder)?,
        4 => skip_derived_text_data_from_decoder(decoder)?,
        field => {
            return Err(
                Error::Term(
                    Box::new(
                        format!(
                            "unknown field {} while indexing ComponentPropAssignment",
                            field
                        ),
                    ),
                ),
            );
        }
    }
    Ok(())
}
fn graph_focus_skip_component_prop_value_field(
    decoder: &mut Decoder<'_>,
    field: u32,
) -> NifResult<()> {
    match field {
        1 => kiwi_skip_bool_value(decoder)?,
        2 => skip_text_data_from_decoder(decoder)?,
        3 => skip_guid_from_decoder(decoder)?,
        4 => kiwi_skip_float_value(decoder)?,
        5 => skip_easing_data_from_decoder(decoder)?,
        6 => skip_vector_from_decoder(decoder)?,
        7 => skip_line_from_decoder(decoder)?,
        8 => skip_circle_from_decoder(decoder)?,
        9 => skip_rotation3_d_from_decoder(decoder)?,
        10 => skip_circle_point_from_decoder(decoder)?,
        11 => skip_gradient_from_decoder(decoder)?,
        12 => skip_color_point_from_decoder(decoder)?,
        field => {
            return Err(
                Error::Term(
                    Box::new(
                        format!(
                            "unknown field {} while indexing ComponentPropValue", field
                        ),
                    ),
                ),
            );
        }
    }
    Ok(())
}
fn graph_focus_parse_guid(value: &str) -> Option<GraphFocusGuid> {
    let (session_id, local_id) = value.split_once(':')?;
    Some(GraphFocusGuid {
        session_id: session_id.parse().ok()?,
        local_id: local_id.parse().ok()?,
    })
}
fn graph_focus_read_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
    Ok(GraphFocusGuid {
        session_id: decoder.read_var_uint()?,
        local_id: decoder.read_var_uint()?,
    })
}
fn graph_focus_read_parent_guid(decoder: &mut Decoder<'_>) -> NifResult<GraphFocusGuid> {
    let guid = graph_focus_read_guid(decoder)?;
    decoder.skip_string()?;
    Ok(guid)
}
fn graph_focus_push_ref(refs: &mut Option<Vec<GraphFocusGuid>>, guid: GraphFocusGuid) {
    refs.get_or_insert_with(Vec::new).push(guid);
}
fn graph_focus_extend_refs(
    refs: &mut Option<Vec<GraphFocusGuid>>,
    next: Option<Vec<GraphFocusGuid>>,
) {
    if let Some(next) = next {
        refs.get_or_insert_with(Vec::new).extend(next);
    }
}
fn graph_focus_read_symbol_data(
    decoder: &mut Decoder<'_>,
) -> NifResult<GraphFocusSymbolData> {
    let mut symbol_id = None;
    let mut refs = None;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                symbol_id = Some(graph_focus_read_guid(decoder)?);
            }
            2 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    let meta = graph_focus_index_node_change(decoder)?;
                    graph_focus_extend_refs(&mut refs, meta.refs);
                }
            }
            field => graph_focus_skip_symbol_data_field(decoder, field)?,
        }
    }
    Ok(GraphFocusSymbolData {
        symbol_id,
        refs,
    })
}
fn graph_focus_read_component_prop_value(
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Vec<GraphFocusGuid>>> {
    let mut refs = None;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            3 => {
                graph_focus_push_guid_ref(decoder, &mut refs)?;
            }
            field => graph_focus_skip_component_prop_value_field(decoder, field)?,
        }
    }
    Ok(refs)
}
fn graph_focus_read_component_prop_assignment(
    decoder: &mut Decoder<'_>,
) -> NifResult<Option<Vec<GraphFocusGuid>>> {
    let mut refs = None;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            2 => {
                graph_focus_extend_component_prop_value(decoder, &mut refs)?;
            }
            field => graph_focus_skip_component_prop_assignment_field(decoder, field)?,
        }
    }
    Ok(refs)
}
fn graph_focus_index_node_change(
    decoder: &mut Decoder<'_>,
) -> NifResult<GraphFocusMeta> {
    let mut guid = None;
    let mut parent_guid = None;
    let mut symbol_id = None;
    let mut refs = None;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                guid = Some(graph_focus_read_guid(decoder)?);
            }
            3 => {
                parent_guid = Some(graph_focus_read_parent_guid(decoder)?);
            }
            113 => {
                let data = graph_focus_read_symbol_data(decoder)?;
                symbol_id = graph_focus_extend_symbol_refs(data, &mut refs)?;
            }
            143 => {
                graph_focus_push_guid_ref(decoder, &mut refs)?;
            }
            268 => {
                graph_focus_extend_component_prop_assignments(decoder, &mut refs)?;
            }
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }
    Ok(GraphFocusMeta {
        guid,
        parent_guid,
        symbol_id,
        refs,
        byte_start: 0,
        byte_end: 0,
    })
}
fn graph_focus_index_message(
    decoder: &mut Decoder<'_>,
) -> NifResult<Vec<GraphFocusMeta>> {
    let mut nodes = Vec::new();
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            4 => {
                let len = decoder.read_var_uint()? as usize;
                nodes.reserve(len);
                for _ in 0..len {
                    let byte_start = decoder.position();
                    let mut meta = graph_focus_index_node_change(decoder)?;
                    meta.byte_start = byte_start;
                    meta.byte_end = decoder.position();
                    nodes.push(meta);
                }
            }
            field => skip_fig_message_field(decoder, field)?,
        }
    }
    Ok(nodes)
}
fn graph_focus_collect_subtree(
    wanted: &mut std::collections::HashSet<GraphFocusGuid>,
    guid: GraphFocusGuid,
    by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
    children: &std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>>,
) {
    if !by_guid.contains_key(&guid) || !wanted.insert(guid) {
        return;
    }
    if let Some(child_guids) = children.get(&guid) {
        for child_guid in child_guids {
            graph_focus_collect_subtree(wanted, *child_guid, by_guid, children);
        }
    }
}
fn graph_focus_collect_ancestors(
    wanted: &mut std::collections::HashSet<GraphFocusGuid>,
    guid: GraphFocusGuid,
    metas: &[GraphFocusMeta],
    by_guid: &std::collections::HashMap<GraphFocusGuid, usize>,
) {
    let mut current = guid;
    while let Some(index) = by_guid.get(&current) {
        let Some(parent_guid) = metas[*index].parent_guid else {
            break;
        };
        wanted.insert(parent_guid);
        current = parent_guid;
    }
}
fn graph_focus_wanted(
    metas: &[GraphFocusMeta],
    focus: &[String],
) -> std::collections::HashSet<GraphFocusGuid> {
    let mut by_guid = std::collections::HashMap::new();
    let mut children: std::collections::HashMap<GraphFocusGuid, Vec<GraphFocusGuid>> = std::collections::HashMap::new();
    for (index, meta) in metas.iter().enumerate() {
        if let Some(guid) = meta.guid {
            by_guid.insert(guid, index);
            if let Some(parent_guid) = meta.parent_guid {
                children.entry(parent_guid).or_default().push(guid);
            }
        }
    }
    let mut wanted = std::collections::HashSet::new();
    for guid in focus.iter().filter_map(|value| graph_focus_parse_guid(value)) {
        graph_focus_collect_subtree(&mut wanted, guid, &by_guid, &children);
    }
    loop {
        let before = wanted.len();
        let current = wanted.iter().copied().collect::<Vec<_>>();
        for guid in current {
            if let Some(index) = by_guid.get(&guid) {
                if let Some(symbol_id) = metas[*index].symbol_id {
                    graph_focus_collect_subtree(
                        &mut wanted,
                        symbol_id,
                        &by_guid,
                        &children,
                    );
                }
                if let Some(refs) = &metas[*index].refs {
                    for ref_id in refs {
                        graph_focus_collect_subtree(
                            &mut wanted,
                            *ref_id,
                            &by_guid,
                            &children,
                        );
                    }
                }
            }
        }
        if wanted.len() == before {
            break;
        }
    }
    let current = wanted.iter().copied().collect::<Vec<_>>();
    for guid in current {
        graph_focus_collect_ancestors(&mut wanted, guid, metas, &by_guid);
    }
    wanted
}
fn graph_focus_sparse_message_from_slices<'a>(
    env: Env<'a>,
    bytes: &[u8],
    metas: &[GraphFocusMeta],
    wanted: &std::collections::HashSet<GraphFocusGuid>,
) -> NifResult<Term<'a>> {
    static NODE_CHANGES_ATOM: OnceLock<Atom> = OnceLock::new();
    let node_changes_atom = cached_atom(env, &NODE_CHANGES_ATOM, "node_changes");
    let mut node_changes = Vec::new();
    for meta in metas {
        let keep = meta.guid.map(|guid| wanted.contains(&guid)).unwrap_or(false);
        if keep {
            let mut decoder = Decoder::new(&bytes[meta.byte_start..meta.byte_end]);
            node_changes
                .push(decode_sparse_node_change_from_decoder(env, &mut decoder)?);
            decoder.finish()?;
        }
    }
    Term::map_from_term_arrays(
        env,
        &[node_changes_atom.encode(env)],
        &[node_changes.encode(env)],
    )
}
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
        name: Option<String>,
        parent_guid: Option<SceneGuid>,
        position: Option<String>,
        size: Option<SceneSize>,
        transform: Option<SceneTransform>,
        visible: Option<bool>,
        locked: Option<bool>,
        opacity: Option<f32>,
        text: Option<String>,
        font_family: Option<String>,
        font_style: Option<String>,
        font_postscript: Option<String>,
        font_size: Option<f32>,
        text_style_guid: Option<String>,
        component_key: Option<String>,
        origin_component_key: Option<String>,
        fill_style_guid: Option<String>,
        stroke_style_guid: Option<String>,
        effect_style_guid: Option<String>,
        grid_style_guid: Option<String>,
        fill_count: Option<usize>,
        stroke_count: Option<usize>,
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
    static GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static NODE_TYPE_ATOM: OnceLock<Atom> = OnceLock::new();
    static NAME_ATOM: OnceLock<Atom> = OnceLock::new();
    static PARENT_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static POSITION_ATOM: OnceLock<Atom> = OnceLock::new();
    static SIZE_ATOM: OnceLock<Atom> = OnceLock::new();
    static TRANSFORM_ATOM: OnceLock<Atom> = OnceLock::new();
    static VISIBLE_ATOM: OnceLock<Atom> = OnceLock::new();
    static LOCKED_ATOM: OnceLock<Atom> = OnceLock::new();
    static OPACITY_ATOM: OnceLock<Atom> = OnceLock::new();
    static TEXT_ATOM: OnceLock<Atom> = OnceLock::new();
    static FONT_FAMILY_ATOM: OnceLock<Atom> = OnceLock::new();
    static FONT_STYLE_ATOM: OnceLock<Atom> = OnceLock::new();
    static FONT_POSTSCRIPT_ATOM: OnceLock<Atom> = OnceLock::new();
    static FONT_SIZE_ATOM: OnceLock<Atom> = OnceLock::new();
    static TEXT_STYLE_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static COMPONENT_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
    static ORIGIN_COMPONENT_KEY_ATOM: OnceLock<Atom> = OnceLock::new();
    static FILL_STYLE_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static STROKE_STYLE_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static EFFECT_STYLE_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static GRID_STYLE_GUID_ATOM: OnceLock<Atom> = OnceLock::new();
    static FILL_COUNT_ATOM: OnceLock<Atom> = OnceLock::new();
    static STROKE_COUNT_ATOM: OnceLock<Atom> = OnceLock::new();
    impl SceneNodeRecord {
        fn attr(&self, index: usize) -> Option<(&'static str, String)> {
            scene_node_record_attr(self, index)
        }
        fn attr_count(&self) -> usize {
            scene_node_record_attr_count(self)
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
                .filter(|index| {
                    SceneGuid::parse(id)
                        .is_some_and(|guid| scene.nodes[*index].guid == guid)
                })
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
    fn scene_node_record_optional_attr_0(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.name.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("name", value.clone()))
                } else {
                    scene_node_record_optional_attr_1(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_1(record, index),
        }
    }
    fn scene_node_record_optional_attr_1(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.parent_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("parent_guid", value.to_string()))
                } else {
                    scene_node_record_optional_attr_2(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_2(record, index),
        }
    }
    fn scene_node_record_optional_attr_2(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.position.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("position", value.clone()))
                } else {
                    scene_node_record_optional_attr_3(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_3(record, index),
        }
    }
    fn scene_node_record_optional_attr_3(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.size.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("x", value.x.to_string()))
                } else {
                    scene_node_record_optional_attr_4(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_4(record, index),
        }
    }
    fn scene_node_record_optional_attr_4(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.size.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("y", value.y.to_string()))
                } else {
                    scene_node_record_optional_attr_5(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_5(record, index),
        }
    }
    fn scene_node_record_optional_attr_5(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.size.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("width", value.x.to_string()))
                } else {
                    scene_node_record_optional_attr_6(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_6(record, index),
        }
    }
    fn scene_node_record_optional_attr_6(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.size.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("height", value.y.to_string()))
                } else {
                    scene_node_record_optional_attr_7(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_7(record, index),
        }
    }
    fn scene_node_record_optional_attr_7(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.transform.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some((
                        "transform",
                        format!(
                            "{},{},{},{},{},{}", value.m00, value.m01, value.m02, value
                            .m10, value.m11, value.m12
                        ),
                    ))
                } else {
                    scene_node_record_optional_attr_8(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_8(record, index),
        }
    }
    fn scene_node_record_optional_attr_8(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.visible {
            Some(value) => {
                if index == 0 {
                    Some(("visible", value.to_string()))
                } else {
                    scene_node_record_optional_attr_9(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_9(record, index),
        }
    }
    fn scene_node_record_optional_attr_9(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.locked {
            Some(value) => {
                if index == 0 {
                    Some(("locked", value.to_string()))
                } else {
                    scene_node_record_optional_attr_10(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_10(record, index),
        }
    }
    fn scene_node_record_optional_attr_10(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.opacity {
            Some(value) => {
                if index == 0 {
                    Some(("opacity", value.to_string()))
                } else {
                    scene_node_record_optional_attr_11(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_11(record, index),
        }
    }
    fn scene_node_record_optional_attr_11(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.text.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("text", value.clone()))
                } else {
                    scene_node_record_optional_attr_12(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_12(record, index),
        }
    }
    fn scene_node_record_optional_attr_12(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.font_family.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("font_family", value.clone()))
                } else {
                    scene_node_record_optional_attr_13(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_13(record, index),
        }
    }
    fn scene_node_record_optional_attr_13(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.font_style.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("font_style", value.clone()))
                } else {
                    scene_node_record_optional_attr_14(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_14(record, index),
        }
    }
    fn scene_node_record_optional_attr_14(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.font_postscript.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("font_postscript", value.clone()))
                } else {
                    scene_node_record_optional_attr_15(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_15(record, index),
        }
    }
    fn scene_node_record_optional_attr_15(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.font_size {
            Some(value) => {
                if index == 0 {
                    Some(("font_size", value.to_string()))
                } else {
                    scene_node_record_optional_attr_16(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_16(record, index),
        }
    }
    fn scene_node_record_optional_attr_16(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.text_style_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("text_style_guid", value.clone()))
                } else {
                    scene_node_record_optional_attr_17(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_17(record, index),
        }
    }
    fn scene_node_record_optional_attr_17(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.component_key.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("component_key", value.clone()))
                } else {
                    scene_node_record_optional_attr_18(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_18(record, index),
        }
    }
    fn scene_node_record_optional_attr_18(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.origin_component_key.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("origin_component_key", value.clone()))
                } else {
                    scene_node_record_optional_attr_19(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_19(record, index),
        }
    }
    fn scene_node_record_optional_attr_19(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.fill_style_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("fill_style_guid", value.clone()))
                } else {
                    scene_node_record_optional_attr_20(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_20(record, index),
        }
    }
    fn scene_node_record_optional_attr_20(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.stroke_style_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("stroke_style_guid", value.clone()))
                } else {
                    scene_node_record_optional_attr_21(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_21(record, index),
        }
    }
    fn scene_node_record_optional_attr_21(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.effect_style_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("effect_style_guid", value.clone()))
                } else {
                    scene_node_record_optional_attr_22(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_22(record, index),
        }
    }
    fn scene_node_record_optional_attr_22(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.grid_style_guid.as_ref() {
            Some(value) => {
                if index == 0 {
                    Some(("grid_style_guid", value.clone()))
                } else {
                    scene_node_record_optional_attr_23(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_23(record, index),
        }
    }
    fn scene_node_record_optional_attr_23(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.fill_count {
            Some(value) => {
                if index == 0 {
                    Some(("fill_count", value.to_string()))
                } else {
                    scene_node_record_optional_attr_24(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_24(record, index),
        }
    }
    fn scene_node_record_optional_attr_24(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        match record.stroke_count {
            Some(value) => {
                if index == 0 {
                    Some(("stroke_count", value.to_string()))
                } else {
                    scene_node_record_optional_attr_25(record, index - 1)
                }
            }
            None => scene_node_record_optional_attr_25(record, index),
        }
    }
    fn scene_node_record_optional_attr_25(
        _record: &SceneNodeRecord,
        _index: usize,
    ) -> Option<(&'static str, String)> {
        None
    }
    fn scene_node_record_optional_attr_count_0(record: &SceneNodeRecord) -> usize {
        match record.name.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_1(record),
            None => scene_node_record_optional_attr_count_1(record),
        }
    }
    fn scene_node_record_optional_attr_count_1(record: &SceneNodeRecord) -> usize {
        match record.parent_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_2(record),
            None => scene_node_record_optional_attr_count_2(record),
        }
    }
    fn scene_node_record_optional_attr_count_2(record: &SceneNodeRecord) -> usize {
        match record.position.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_3(record),
            None => scene_node_record_optional_attr_count_3(record),
        }
    }
    fn scene_node_record_optional_attr_count_3(record: &SceneNodeRecord) -> usize {
        match record.size.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_4(record),
            None => scene_node_record_optional_attr_count_4(record),
        }
    }
    fn scene_node_record_optional_attr_count_4(record: &SceneNodeRecord) -> usize {
        match record.size.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_5(record),
            None => scene_node_record_optional_attr_count_5(record),
        }
    }
    fn scene_node_record_optional_attr_count_5(record: &SceneNodeRecord) -> usize {
        match record.size.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_6(record),
            None => scene_node_record_optional_attr_count_6(record),
        }
    }
    fn scene_node_record_optional_attr_count_6(record: &SceneNodeRecord) -> usize {
        match record.size.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_7(record),
            None => scene_node_record_optional_attr_count_7(record),
        }
    }
    fn scene_node_record_optional_attr_count_7(record: &SceneNodeRecord) -> usize {
        match record.transform.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_8(record),
            None => scene_node_record_optional_attr_count_8(record),
        }
    }
    fn scene_node_record_optional_attr_count_8(record: &SceneNodeRecord) -> usize {
        match record.visible {
            Some(_value) => 1 + scene_node_record_optional_attr_count_9(record),
            None => scene_node_record_optional_attr_count_9(record),
        }
    }
    fn scene_node_record_optional_attr_count_9(record: &SceneNodeRecord) -> usize {
        match record.locked {
            Some(_value) => 1 + scene_node_record_optional_attr_count_10(record),
            None => scene_node_record_optional_attr_count_10(record),
        }
    }
    fn scene_node_record_optional_attr_count_10(record: &SceneNodeRecord) -> usize {
        match record.opacity {
            Some(_value) => 1 + scene_node_record_optional_attr_count_11(record),
            None => scene_node_record_optional_attr_count_11(record),
        }
    }
    fn scene_node_record_optional_attr_count_11(record: &SceneNodeRecord) -> usize {
        match record.text.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_12(record),
            None => scene_node_record_optional_attr_count_12(record),
        }
    }
    fn scene_node_record_optional_attr_count_12(record: &SceneNodeRecord) -> usize {
        match record.font_family.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_13(record),
            None => scene_node_record_optional_attr_count_13(record),
        }
    }
    fn scene_node_record_optional_attr_count_13(record: &SceneNodeRecord) -> usize {
        match record.font_style.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_14(record),
            None => scene_node_record_optional_attr_count_14(record),
        }
    }
    fn scene_node_record_optional_attr_count_14(record: &SceneNodeRecord) -> usize {
        match record.font_postscript.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_15(record),
            None => scene_node_record_optional_attr_count_15(record),
        }
    }
    fn scene_node_record_optional_attr_count_15(record: &SceneNodeRecord) -> usize {
        match record.font_size {
            Some(_value) => 1 + scene_node_record_optional_attr_count_16(record),
            None => scene_node_record_optional_attr_count_16(record),
        }
    }
    fn scene_node_record_optional_attr_count_16(record: &SceneNodeRecord) -> usize {
        match record.text_style_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_17(record),
            None => scene_node_record_optional_attr_count_17(record),
        }
    }
    fn scene_node_record_optional_attr_count_17(record: &SceneNodeRecord) -> usize {
        match record.component_key.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_18(record),
            None => scene_node_record_optional_attr_count_18(record),
        }
    }
    fn scene_node_record_optional_attr_count_18(record: &SceneNodeRecord) -> usize {
        match record.origin_component_key.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_19(record),
            None => scene_node_record_optional_attr_count_19(record),
        }
    }
    fn scene_node_record_optional_attr_count_19(record: &SceneNodeRecord) -> usize {
        match record.fill_style_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_20(record),
            None => scene_node_record_optional_attr_count_20(record),
        }
    }
    fn scene_node_record_optional_attr_count_20(record: &SceneNodeRecord) -> usize {
        match record.stroke_style_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_21(record),
            None => scene_node_record_optional_attr_count_21(record),
        }
    }
    fn scene_node_record_optional_attr_count_21(record: &SceneNodeRecord) -> usize {
        match record.effect_style_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_22(record),
            None => scene_node_record_optional_attr_count_22(record),
        }
    }
    fn scene_node_record_optional_attr_count_22(record: &SceneNodeRecord) -> usize {
        match record.grid_style_guid.as_ref() {
            Some(_value) => 1 + scene_node_record_optional_attr_count_23(record),
            None => scene_node_record_optional_attr_count_23(record),
        }
    }
    fn scene_node_record_optional_attr_count_23(record: &SceneNodeRecord) -> usize {
        match record.fill_count {
            Some(_value) => 1 + scene_node_record_optional_attr_count_24(record),
            None => scene_node_record_optional_attr_count_24(record),
        }
    }
    fn scene_node_record_optional_attr_count_24(record: &SceneNodeRecord) -> usize {
        match record.stroke_count {
            Some(_value) => 1 + scene_node_record_optional_attr_count_25(record),
            None => scene_node_record_optional_attr_count_25(record),
        }
    }
    fn scene_node_record_optional_attr_count_25(_record: &SceneNodeRecord) -> usize {
        0
    }
    fn read_scene_float64_value(decoder: &mut Decoder<'_>) -> NifResult<f64> {
        Ok(decoder.read_var_float_value()? as f64)
    }
    #[allow(clippy::redundant_field_names)]
    fn read_scene_size_value(decoder: &mut Decoder<'_>) -> NifResult<SceneSize> {
        Ok(SceneSize {
            x: read_scene_float64_value(decoder)?,
            y: read_scene_float64_value(decoder)?,
        })
    }
    #[allow(clippy::redundant_field_names)]
    fn read_scene_transform_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<SceneTransform> {
        Ok(SceneTransform {
            m00: read_scene_float64_value(decoder)?,
            m01: read_scene_float64_value(decoder)?,
            m02: read_scene_float64_value(decoder)?,
            m10: read_scene_float64_value(decoder)?,
            m11: read_scene_float64_value(decoder)?,
            m12: read_scene_float64_value(decoder)?,
        })
    }
    fn read_scene_font_name_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<(Option<String>, Option<String>, Option<String>)> {
        let family = decoder.read_string_value()?;
        let style = decoder.read_string_value()?;
        let postscript = decoder.read_string_value()?;
        Ok((Some(family), Some(style), Some(postscript)))
    }
    fn scene_node_record_base_attr_count() -> usize {
        2
    }
    fn scene_node_record_attr(
        record: &SceneNodeRecord,
        index: usize,
    ) -> Option<(&'static str, String)> {
        if index == 0 {
            Some(("guid", record.guid.to_string()))
        } else {
            if index == 1 {
                Some(("type", record.node_type.to_string()))
            } else {
                scene_node_record_optional_attr_0(record, index - 2)
            }
        }
    }
    fn scene_node_record_attr_count(record: &SceneNodeRecord) -> usize {
        scene_node_record_base_attr_count()
            + scene_node_record_optional_attr_count_0(record)
    }
    fn scene_query_node(scene: &SceneIndex, node_index: usize) -> SceneQueryNode {
        let node = &scene.nodes[node_index];
        SceneQueryNode {
            guid: node.guid.to_string(),
            node_type: node.node_type.to_string(),
            name: node.name.clone(),
            parent_guid: node.parent_guid.map(|guid| guid.to_string()),
            position: node.position.clone(),
            size: node.size.clone(),
            transform: node.transform.clone(),
            visible: node.visible,
            locked: node.locked,
            opacity: node.opacity,
            text: node.text.clone(),
            font_family: node.font_family.clone(),
            font_style: node.font_style.clone(),
            font_postscript: node.font_postscript.clone(),
            font_size: node.font_size,
            text_style_guid: node.text_style_guid.clone(),
            component_key: node.component_key.clone(),
            origin_component_key: node.origin_component_key.clone(),
            fill_style_guid: node.fill_style_guid.clone(),
            stroke_style_guid: node.stroke_style_guid.clone(),
            effect_style_guid: node.effect_style_guid.clone(),
            grid_style_guid: node.grid_style_guid.clone(),
            fill_count: node.fill_count,
            stroke_count: node.stroke_count,
        }
    }
    fn scene_query_node_term<'a>(
        env: Env<'a>,
        scene: &SceneIndex,
        node_index: usize,
        fields: &[String],
    ) -> NifResult<Term<'a>> {
        let node = &scene.nodes[node_index];
        let mut keys = Vec::with_capacity(fields.len().max(2));
        let mut values = Vec::with_capacity(fields.len().max(2));
        keys.push(cached_atom(env, &GUID_ATOM, "guid").encode(env));
        values.push(node.guid.to_string().encode(env));
        keys.push(cached_atom(env, &NODE_TYPE_ATOM, "node_type").encode(env));
        values.push(node.node_type.encode(env));
        if wants_field(fields, "name") {
            keys.push(cached_atom(env, &NAME_ATOM, "name").encode(env));
            values.push(node.name.encode(env));
        }
        if wants_field(fields, "parent_guid") {
            keys.push(cached_atom(env, &PARENT_GUID_ATOM, "parent_guid").encode(env));
            values.push(node.parent_guid.map(|guid| guid.to_string()).encode(env));
        }
        if wants_field(fields, "position") {
            keys.push(cached_atom(env, &POSITION_ATOM, "position").encode(env));
            values.push(node.position.encode(env));
        }
        if wants_field(fields, "size") {
            keys.push(cached_atom(env, &SIZE_ATOM, "size").encode(env));
            values.push(node.size.encode(env));
        }
        if wants_field(fields, "transform") {
            keys.push(cached_atom(env, &TRANSFORM_ATOM, "transform").encode(env));
            values.push(node.transform.encode(env));
        }
        if wants_field(fields, "visible") {
            keys.push(cached_atom(env, &VISIBLE_ATOM, "visible").encode(env));
            values.push(node.visible.encode(env));
        }
        if wants_field(fields, "locked") {
            keys.push(cached_atom(env, &LOCKED_ATOM, "locked").encode(env));
            values.push(node.locked.encode(env));
        }
        if wants_field(fields, "opacity") {
            keys.push(cached_atom(env, &OPACITY_ATOM, "opacity").encode(env));
            values.push(node.opacity.encode(env));
        }
        if wants_field(fields, "text") {
            keys.push(cached_atom(env, &TEXT_ATOM, "text").encode(env));
            values.push(node.text.encode(env));
        }
        if wants_field(fields, "font_family") {
            keys.push(cached_atom(env, &FONT_FAMILY_ATOM, "font_family").encode(env));
            values.push(node.font_family.encode(env));
        }
        if wants_field(fields, "font_style") {
            keys.push(cached_atom(env, &FONT_STYLE_ATOM, "font_style").encode(env));
            values.push(node.font_style.encode(env));
        }
        if wants_field(fields, "font_postscript") {
            keys.push(
                cached_atom(env, &FONT_POSTSCRIPT_ATOM, "font_postscript").encode(env),
            );
            values.push(node.font_postscript.encode(env));
        }
        if wants_field(fields, "font_size") {
            keys.push(cached_atom(env, &FONT_SIZE_ATOM, "font_size").encode(env));
            values.push(node.font_size.encode(env));
        }
        if wants_field(fields, "text_style_guid") {
            keys.push(
                cached_atom(env, &TEXT_STYLE_GUID_ATOM, "text_style_guid").encode(env),
            );
            values.push(node.text_style_guid.encode(env));
        }
        if wants_field(fields, "component_key") {
            keys.push(
                cached_atom(env, &COMPONENT_KEY_ATOM, "component_key").encode(env),
            );
            values.push(node.component_key.encode(env));
        }
        if wants_field(fields, "origin_component_key") {
            keys.push(
                cached_atom(env, &ORIGIN_COMPONENT_KEY_ATOM, "origin_component_key")
                    .encode(env),
            );
            values.push(node.origin_component_key.encode(env));
        }
        if wants_field(fields, "fill_style_guid") {
            keys.push(
                cached_atom(env, &FILL_STYLE_GUID_ATOM, "fill_style_guid").encode(env),
            );
            values.push(node.fill_style_guid.encode(env));
        }
        if wants_field(fields, "stroke_style_guid") {
            keys.push(
                cached_atom(env, &STROKE_STYLE_GUID_ATOM, "stroke_style_guid")
                    .encode(env),
            );
            values.push(node.stroke_style_guid.encode(env));
        }
        if wants_field(fields, "effect_style_guid") {
            keys.push(
                cached_atom(env, &EFFECT_STYLE_GUID_ATOM, "effect_style_guid")
                    .encode(env),
            );
            values.push(node.effect_style_guid.encode(env));
        }
        if wants_field(fields, "grid_style_guid") {
            keys.push(
                cached_atom(env, &GRID_STYLE_GUID_ATOM, "grid_style_guid").encode(env),
            );
            values.push(node.grid_style_guid.encode(env));
        }
        if wants_field(fields, "fill_count") {
            keys.push(cached_atom(env, &FILL_COUNT_ATOM, "fill_count").encode(env));
            values.push(node.fill_count.encode(env));
        }
        if wants_field(fields, "stroke_count") {
            keys.push(cached_atom(env, &STROKE_COUNT_ATOM, "stroke_count").encode(env));
            values.push(node.stroke_count.encode(env));
        }
        Term::map_from_term_arrays(env, &keys, &values)
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
    fn read_scene_text_data_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<Option<String>> {
        let mut text = None;
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => text = Some(decoder.read_string_value()?),
                2 => kiwi_skip_repeated(decoder, kiwi_skip_uint_value)?,
                3 => kiwi_skip_repeated(decoder, skip_node_change_from_decoder)?,
                12 => kiwi_skip_repeated(decoder, skip_text_line_data_from_decoder)?,
                8 => kiwi_skip_uint_value(decoder)?,
                10 => kiwi_skip_repeated(decoder, skip_font_name_from_decoder)?,
                17 => kiwi_skip_float_value(decoder)?,
                4 => skip_vector_from_decoder(decoder)?,
                5 => kiwi_skip_repeated(decoder, skip_baseline_from_decoder)?,
                6 => kiwi_skip_repeated(decoder, skip_glyph_from_decoder)?,
                7 => kiwi_skip_repeated(decoder, skip_decoration_from_decoder)?,
                16 => kiwi_skip_repeated(decoder, skip_blockquote_from_decoder)?,
                9 => kiwi_skip_repeated(decoder, skip_font_meta_data_from_decoder)?,
                11 => kiwi_skip_repeated(decoder, skip_hyperlink_box_from_decoder)?,
                13 => kiwi_skip_int_value(decoder)?,
                14 => kiwi_skip_float_value(decoder)?,
                15 => kiwi_skip_repeated(decoder, kiwi_skip_float_value)?,
                18 => kiwi_skip_repeated(decoder, skip_mention_box_from_decoder)?,
                19 => {
                    kiwi_skip_repeated(
                        decoder,
                        skip_derived_text_line_data_from_decoder,
                    )?
                }
                field => {
                    return Err(
                        Error::Term(
                            Box::new(
                                format!(
                                    "unknown field {} while decoding scene text data", field
                                ),
                            ),
                        ),
                    );
                }
            }
        }
        Ok(text)
    }
    fn read_scene_style_id_value(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<Option<String>> {
        let mut guid = None;
        loop {
            match decoder.read_var_uint()? {
                0 => break,
                1 => guid = Some(read_guid_value(decoder)?.to_string()),
                2 => skip_asset_ref_from_decoder(decoder)?,
                field => {
                    return Err(
                        Error::Term(
                            Box::new(
                                format!(
                                    "unknown field {} while decoding scene style id", field
                                ),
                            ),
                        ),
                    );
                }
            }
        }
        Ok(guid)
    }
    fn wants_field(fields: &[String], field: &str) -> bool {
        fields.iter().any(|selected| selected == field)
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
        type_counts
            .sort_by(|left, right| {
                right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0))
            });
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
    fn evaluate_scene_xpath(
        index: Arc<SceneIndex>,
        xpath: &str,
    ) -> NifResult<Vec<usize>> {
        let root = SceneHandle::document(index);
        let mut cx = ();
        let expression = servo_xpath::parse::<
            SceneNamespaceResolver,
        >(&mut cx, xpath, None, false)
            .map_err(|error| Error::Term(
                Box::new(format!("invalid XPath: {:?}", error)),
            ))?;
        let value = servo_xpath::evaluate_parsed_xpath::<
            SceneDom,
        >(&mut cx, &expression, root)
            .map_err(|error| Error::Term(
                Box::new(format!("XPath evaluation failed: {:?}", error)),
            ))?;
        Ok(
            match value {
                Value::NodeSet(node_set) => {
                    node_set
                        .into_iter()
                        .filter_map(|handle| match handle.kind {
                            SceneHandleKind::Element(node_index) => Some(node_index),
                            SceneHandleKind::Attribute { owner, .. } => Some(owner),
                            SceneHandleKind::Document => None,
                        })
                        .collect()
                }
                _ => Vec::new(),
            },
        )
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
        match find_node_index(&index, &guid)
            .and_then(|node_index| index.nodes[node_index].parent)
        {
            Some(parent_index) => Ok(scene_query_node(&index, parent_index).encode(env)),
            None => Ok(None::<SceneQueryNode>.encode(env)),
        }
    }
    pub fn scene_index_roots_value(
        resource: ResourceArc<SceneIndexResource>,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        index
            .roots
            .iter()
            .copied()
            .map(|node_index| scene_query_node(&index, node_index))
            .collect()
    }
    pub fn scene_index_children_value(
        resource: ResourceArc<SceneIndexResource>,
        guid: String,
    ) -> Vec<SceneQueryNode> {
        let index = resource.index.clone();
        find_node_index(&index, &guid)
            .map(|node_index| {
                index
                    .nodes[node_index]
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
                let siblings = index
                    .nodes[node_index]
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
        scene_query_nodes_matching(
            &index,
            |node| { node.name.as_ref().is_some_and(|name| name.contains(&needle)) },
        )
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
                index
                    .nodes[*node_index]
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
        scene_query_nodes_matching(
            &index,
            |node| { node.text.as_ref().is_some_and(|text| text.contains(&needle)) },
        )
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
                index
                    .nodes[*node_index]
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
        let mut current = find_node_index(&index, &guid)
            .and_then(|node_index| index.nodes[node_index].parent);
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
                out.extend(
                    preorder
                        .into_iter()
                        .map(|index_node| scene_query_node(&index, index_node)),
                );
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
                4 => {
                    let len = decoder.read_var_uint()? as usize;
                    nodes.reserve(len);
                    for _ in 0..len {
                        nodes
                            .push(decode_scene_index_node_change_from_decoder(decoder)?);
                    }
                }
                field => super::skip_fig_message_field(decoder, field)?,
            }
        }
        Ok(())
    }
    fn decode_scene_index_node_change_from_decoder(
        decoder: &mut Decoder<'_>,
    ) -> NifResult<SceneNodeRecord> {
        let mut guid = None;
        let mut node_type: Option<&'static str> = None;
        let mut name = None;
        let mut parent_guid = None;
        let mut position = None;
        let mut size = None;
        let mut transform = None;
        let mut visible = None;
        let mut locked = None;
        let mut opacity = None;
        let mut text = None;
        let mut font_family = None;
        let mut font_style = None;
        let mut font_postscript = None;
        let mut font_size = None;
        let mut text_style_guid = None;
        let mut component_key = None;
        let mut origin_component_key = None;
        let mut fill_style_guid = None;
        let mut stroke_style_guid = None;
        let mut effect_style_guid = None;
        let mut grid_style_guid = None;
        let mut fill_count = None;
        let mut stroke_count = None;
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
                5 => {
                    name = Some(decoder.read_string_value()?);
                }
                11 => {
                    size = Some(read_scene_size_value(decoder)?);
                }
                12 => {
                    transform = Some(read_scene_transform_value(decoder)?);
                }
                6 => {
                    visible = Some(decoder.read_bool()?);
                }
                7 => {
                    locked = Some(decoder.read_bool()?);
                }
                8 => {
                    opacity = Some(decoder.read_var_float_value()?);
                }
                42 => {
                    text = read_scene_text_data_value(decoder)?;
                }
                41 => {
                    let font_name = read_scene_font_name_value(decoder)?;
                    font_family = font_name.0;
                    font_style = font_name.1;
                    font_postscript = font_name.2;
                }
                21 => {
                    font_size = Some(decoder.read_var_float_value()?);
                }
                334 => {
                    text_style_guid = read_scene_style_id_value(decoder)?;
                }
                216 => {
                    component_key = Some(decoder.read_string_value()?);
                }
                252 => {
                    origin_component_key = Some(decoder.read_string_value()?);
                }
                332 => {
                    fill_style_guid = read_scene_style_id_value(decoder)?;
                }
                333 => {
                    stroke_style_guid = read_scene_style_id_value(decoder)?;
                }
                335 => {
                    effect_style_guid = read_scene_style_id_value(decoder)?;
                }
                336 => {
                    grid_style_guid = read_scene_style_id_value(decoder)?;
                }
                38 => {
                    fill_count = read_scene_counted_array_value(
                        decoder,
                        skip_paint_from_decoder,
                    )?;
                }
                39 => {
                    stroke_count = read_scene_counted_array_value(
                        decoder,
                        skip_paint_from_decoder,
                    )?;
                }
                field => super::skip_fig_node_change_field(decoder, field)?,
            }
        }
        Ok(SceneNodeRecord {
            guid: guid.unwrap_or_default(),
            node_type: node_type.unwrap_or("unknown"),
            name,
            parent_guid,
            position,
            size,
            transform,
            visible,
            locked,
            opacity,
            text,
            font_family,
            font_style,
            font_postscript,
            font_size,
            text_style_guid,
            component_key,
            origin_component_key,
            fill_style_guid,
            stroke_style_guid,
            effect_style_guid,
            grid_style_guid,
            fill_count,
            stroke_count,
            parent: None,
            children: Vec::new(),
        })
    }
}
#[derive(Clone, Debug)]
pub struct FigSceneSkipField {
    pub id: u32,
    pub repeated: bool,
    pub bytes: bool,
    pub skip: KiwiSkipFn,
}
macro_rules! fig_scene_skip_field_decoder {
    (
        fn $name:ident; decoder $decoder:ident; field $field:ident; definition
        $definition_name:literal; skip_fields[$($field_id:literal =>
        $field_repeated:literal $field_bytes:literal $field_skip:ident;)*]
    ) => {
        fn $name ($decoder : & mut Decoder <'_ >, $field : u32) -> NifResult < () > {
        fig_scene_skip_field($decoder, $field, $definition_name, & [$(FigSceneSkipField {
        id : $field_id, repeated : $field_repeated, bytes : $field_bytes, skip :
        $field_skip },)*]) }
    };
}
fn fig_scene_skip_field(
    decoder: &mut Decoder<'_>,
    field_id: u32,
    _definition_name: &str,
    fields: &[FigSceneSkipField],
) -> NifResult<()> {
    match fields.binary_search_by_key(&field_id, |field| field.id) {
        Ok(index) => {
            let field = fields.get(index).unwrap();
            let kind = kiwi_skip_descriptor_kind(
                field.repeated,
                field.bytes,
                field.skip,
            );
            kiwi_skip_kind(decoder, &kind)?;
            Ok(())
        }
        Err(_index) => Err(rustler::Error::BadArg),
    }
}
fig_scene_skip_field_decoder! {
    fn skip_fig_message_field; decoder decoder; field field; definition "scene summary";
    skip_fields[1 => false false kiwi_skip_uint_value; 2 => false false
    kiwi_skip_uint_value; 3 => false false kiwi_skip_uint_value; 4 => true false
    skip_node_change_from_decoder; 5 => true false skip_user_change_from_decoder; 6 =>
    true false skip_blob_from_decoder; 7 => false false kiwi_skip_string_value; 8 =>
    false false kiwi_skip_uint_value; 9 => false false kiwi_skip_string_value; 10 =>
    false false kiwi_skip_uint_value; 11 => false false kiwi_skip_uint_value; 12 => false
    false kiwi_skip_int_value; 13 => false false skip_vector_from_decoder; 14 => false
    false kiwi_skip_string_value; 15 => false false kiwi_skip_string_value; 16 => true
    false skip_scene_graph_query_from_decoder; 17 => false false
    skip_node_changes_metadata_from_decoder; 18 => false false kiwi_skip_uint_value; 19
    => false false kiwi_skip_bool_value; 20 => false false skip_guid_from_decoder; 21 =>
    false false kiwi_skip_bool_value; 22 => true false skip_message_from_decoder; 23 =>
    true false skip_message_from_decoder; 24 => true false
    skip_client_broadcast_from_decoder; 25 => false false kiwi_skip_uint_value; 26 =>
    false false kiwi_skip_string_value; 27 => false false kiwi_skip_uint_value; 28 =>
    false false kiwi_skip_string_value; 29 => true false skip_guid_from_decoder; 30 =>
    false false kiwi_skip_uint_value; 31 => false false kiwi_skip_bool_value; 32 => false
    false skip_interactive_slide_element_change_from_decoder; 33 => true false
    skip_clipboard_selection_region_from_decoder; 34 => false false
    skip_encoded_offsets_index_from_decoder; 35 => false false kiwi_skip_bool_value; 36
    => false false skip_node_status_change_from_decoder; 37 => false false
    kiwi_skip_bool_value; 38 => false false kiwi_skip_uint64_value; 39 => true false
    skip_annotation_category_from_decoder; 40 => false false
    skip_client_rendered_metadata_from_decoder; 41 => false false kiwi_skip_uint_value;
    42 => false false kiwi_skip_string_value; 43 => false false
    skip_object_animation_list_from_decoder; 44 => false false
    skip_buzz_approval_change_from_decoder; 45 => false false kiwi_skip_uint_value;]
}
fig_scene_skip_field_decoder! {
    fn skip_fig_node_change_field; decoder decoder; field field; definition "scene node";
    skip_fields[1 => false false skip_guid_from_decoder; 2 => false false
    kiwi_skip_uint_value; 3 => false false skip_parent_index_from_decoder; 4 => false
    false kiwi_skip_uint_value; 5 => false false kiwi_skip_string_value; 6 => false false
    kiwi_skip_bool_value; 7 => false false kiwi_skip_bool_value; 8 => false false
    kiwi_skip_float_value; 9 => false false kiwi_skip_uint_value; 10 => false false
    kiwi_skip_uint_value; 11 => false false skip_vector_from_decoder; 12 => false false
    skip_matrix_from_decoder; 13 => true false kiwi_skip_float_value; 14 => false false
    kiwi_skip_bool_value; 15 => false false kiwi_skip_bool_value; 16 => false false
    kiwi_skip_bool_value; 17 => false false kiwi_skip_bool_value; 18 => false false
    kiwi_skip_bool_value; 19 => false false kiwi_skip_float_value; 20 => false false
    kiwi_skip_float_value; 21 => false false kiwi_skip_float_value; 22 => false false
    kiwi_skip_float_value; 23 => false false kiwi_skip_float_value; 24 => false false
    kiwi_skip_float_value; 25 => false false kiwi_skip_float_value; 26 => false false
    kiwi_skip_float_value; 27 => false false kiwi_skip_float_value; 28 => false false
    kiwi_skip_uint_value; 29 => false false kiwi_skip_uint_value; 30 => false false
    kiwi_skip_uint_value; 31 => false false kiwi_skip_uint_value; 32 => false false
    kiwi_skip_uint_value; 33 => false false kiwi_skip_uint_value; 34 => false false
    kiwi_skip_uint_value; 35 => false false kiwi_skip_uint_value; 36 => false false
    kiwi_skip_uint_value; 37 => false false kiwi_skip_uint_value; 38 => true false
    skip_paint_from_decoder; 39 => true false skip_paint_from_decoder; 40 => false false
    skip_number_from_decoder; 41 => false false skip_font_name_from_decoder; 42 => false
    false skip_text_data_from_decoder; 43 => true false skip_effect_from_decoder; 44 =>
    false false kiwi_skip_uint_value; 45 => true false skip_export_settings_from_decoder;
    46 => false false kiwi_skip_uint_value; 47 => true false
    skip_layout_grid_from_decoder; 48 => false false skip_vector_data_from_decoder; 49 =>
    false false kiwi_skip_uint_value; 50 => false false skip_color_from_decoder; 51 =>
    true false skip_path_from_decoder; 52 => true false skip_path_from_decoder; 53 =>
    false false kiwi_skip_uint_value; 54 => false false kiwi_skip_uint_value; 55 => false
    false kiwi_skip_uint_value; 56 => false false kiwi_skip_uint_value; 57 => false false
    kiwi_skip_uint_value; 58 => false false kiwi_skip_uint_value; 59 => false false
    kiwi_skip_uint_value; 60 => false false kiwi_skip_uint_value; 61 => false false
    kiwi_skip_uint_value; 62 => false false kiwi_skip_uint_value; 63 => false false
    kiwi_skip_uint_value; 64 => false false kiwi_skip_uint_value; 65 => false false
    kiwi_skip_uint_value; 66 => false false kiwi_skip_uint_value; 67 => false false
    kiwi_skip_uint_value; 68 => false false kiwi_skip_uint_value; 69 => false false
    kiwi_skip_uint_value; 70 => false false kiwi_skip_uint_value; 71 => false false
    kiwi_skip_uint_value; 72 => false false kiwi_skip_uint_value; 73 => false false
    kiwi_skip_uint_value; 74 => false false kiwi_skip_uint_value; 75 => false false
    kiwi_skip_uint_value; 76 => false false kiwi_skip_uint_value; 77 => false false
    kiwi_skip_uint_value; 78 => false false kiwi_skip_uint_value; 79 => false false
    kiwi_skip_uint_value; 80 => false false kiwi_skip_uint_value; 81 => false false
    kiwi_skip_uint_value; 82 => false false kiwi_skip_uint_value; 83 => false false
    kiwi_skip_uint_value; 84 => false false kiwi_skip_uint_value; 85 => false false
    kiwi_skip_uint_value; 86 => false false kiwi_skip_uint_value; 87 => false false
    kiwi_skip_uint_value; 88 => false false kiwi_skip_uint_value; 89 => false false
    kiwi_skip_uint_value; 90 => false false kiwi_skip_uint_value; 91 => false false
    kiwi_skip_uint_value; 92 => false false kiwi_skip_uint_value; 93 => false false
    kiwi_skip_uint_value; 94 => false false kiwi_skip_uint_value; 95 => false false
    kiwi_skip_uint_value; 96 => false false kiwi_skip_uint_value; 97 => false false
    kiwi_skip_uint_value; 98 => false false kiwi_skip_uint_value; 99 => false false
    kiwi_skip_uint_value; 100 => false false kiwi_skip_uint_value; 101 => false false
    kiwi_skip_uint_value; 102 => false false kiwi_skip_uint_value; 103 => false false
    kiwi_skip_uint_value; 104 => false false kiwi_skip_uint_value; 105 => false false
    kiwi_skip_uint_value; 106 => false false kiwi_skip_uint_value; 107 => false false
    kiwi_skip_float_value; 108 => false false kiwi_skip_uint_value; 109 => false false
    kiwi_skip_float_value; 110 => false false kiwi_skip_uint_value; 111 => false false
    skip_guid_path_from_decoder; 112 => false false kiwi_skip_uint_value; 113 => false
    false skip_symbol_data_from_decoder; 114 => false false kiwi_skip_uint_value; 115 =>
    false false kiwi_skip_bool_value; 116 => false false kiwi_skip_uint_value; 117 =>
    false false kiwi_skip_bool_value; 118 => false false kiwi_skip_uint_value; 119 =>
    false false kiwi_skip_bool_value; 120 => false false kiwi_skip_uint_value; 121 =>
    false false kiwi_skip_uint_value; 122 => false false
    skip_shared_symbol_reference_from_decoder; 123 => false false kiwi_skip_bool_value;
    124 => true false skip_guid_path_mapping_from_decoder; 125 => true false
    skip_node_change_from_decoder; 126 => false false kiwi_skip_string_value; 127 =>
    false false kiwi_skip_bool_value; 128 => false false kiwi_skip_bool_value; 129 =>
    false false kiwi_skip_bool_value; 130 => false false kiwi_skip_bool_value; 131 =>
    false false kiwi_skip_bool_value; 132 => false false kiwi_skip_bool_value; 133 =>
    false false kiwi_skip_uint_value; 134 => false false kiwi_skip_uint_value; 135 =>
    false false kiwi_skip_uint_value; 136 => false false kiwi_skip_uint_value; 137 =>
    false false kiwi_skip_uint_value; 138 => true false skip_guide_from_decoder; 139 =>
    false false skip_guid_from_decoder; 140 => false false skip_guid_from_decoder; 141 =>
    false false skip_color_from_decoder; 142 => false false kiwi_skip_bool_value; 143 =>
    false false skip_guid_from_decoder; 144 => false false kiwi_skip_string_value; 145 =>
    false false kiwi_skip_float_value; 146 => false false kiwi_skip_float_value; 147 =>
    false false kiwi_skip_float_value; 148 => false false kiwi_skip_float_value; 149 =>
    false false kiwi_skip_bool_value; 150 => false false kiwi_skip_bool_value; 151 =>
    false false kiwi_skip_bool_value; 152 => false false
    skip_shared_component_master_data_from_decoder; 153 => false false
    skip_transition_info_from_decoder; 154 => false false kiwi_skip_uint_value; 155 =>
    false false kiwi_skip_float_value; 156 => false false kiwi_skip_uint_value; 157 =>
    false false kiwi_skip_bool_value; 158 => false false skip_guid_from_decoder; 159 =>
    false false kiwi_skip_uint_value; 160 => false false kiwi_skip_float_value; 161 =>
    false false kiwi_skip_bool_value; 162 => false false skip_guid_from_decoder; 163 =>
    false false kiwi_skip_uint_value; 164 => true false
    skip_guid_path_mapping_from_decoder; 165 => false false skip_number_from_decoder; 166
    => false false skip_vector_from_decoder; 167 => false false skip_guid_from_decoder;
    168 => false false skip_guid_from_decoder; 169 => false false skip_guid_from_decoder;
    170 => false false skip_guid_from_decoder; 171 => false false kiwi_skip_string_value;
    172 => false false skip_shared_style_master_data_from_decoder; 173 => false false
    skip_shared_style_reference_from_decoder; 174 => false false kiwi_skip_bool_value;
    175 => false false kiwi_skip_bool_value; 176 => false false kiwi_skip_bool_value; 177
    => false false kiwi_skip_bool_value; 178 => false false kiwi_skip_uint_value; 179 =>
    false false skip_vector_from_decoder; 180 => false false kiwi_skip_string_value; 181
    => false false kiwi_skip_bool_value; 182 => false false kiwi_skip_uint_value; 183 =>
    false false kiwi_skip_string_value; 184 => false false
    skip_prototype_device_from_decoder; 185 => false false skip_guid_from_decoder; 186 =>
    false false kiwi_skip_uint_value; 187 => false false kiwi_skip_uint_value; 188 =>
    false false kiwi_skip_float_value; 189 => false false kiwi_skip_bool_value; 190 =>
    false false kiwi_skip_float_value; 191 => false false kiwi_skip_string_value; 192 =>
    false false kiwi_skip_bool_value; 193 => true false skip_paint_from_decoder; 194 =>
    false false skip_guid_from_decoder; 195 => false false skip_arc_data_from_decoder;
    196 => false false kiwi_skip_int_value; 197 => false false kiwi_skip_uint_value; 198
    => false false kiwi_skip_uint_value; 199 => false false skip_vector_from_decoder; 200
    => false false kiwi_skip_uint_value; 201 => false false
    skip_overlay_background_appearance_from_decoder; 202 => false false
    kiwi_skip_string_value; 203 => false false kiwi_skip_uint_value; 204 => true false
    skip_plugin_data_from_decoder; 205 => true false kiwi_skip_uint_value; 206 => true
    false kiwi_skip_uint_value; 207 => false false kiwi_skip_bool_value; 208 => false
    false kiwi_skip_uint_value; 209 => false false kiwi_skip_float_value; 210 => false
    false kiwi_skip_float_value; 211 => false false kiwi_skip_uint_value; 212 => false
    false kiwi_skip_uint_value; 213 => false false skip_guid_from_decoder; 214 => false
    false kiwi_skip_string_value; 215 => false false skip_guid_from_decoder; 216 => false
    false kiwi_skip_string_value; 217 => false false kiwi_skip_bool_value; 218 => false
    false kiwi_skip_string_value; 219 => true false
    skip_plugin_relaunch_data_from_decoder; 220 => false false kiwi_skip_bool_value; 221
    => false false kiwi_skip_uint_value; 222 => false false kiwi_skip_bool_value; 223 =>
    false false skip_hyperlink_from_decoder; 224 => false false
    skip_key_trigger_from_decoder; 225 => false false kiwi_skip_bool_value; 226 => true
    false skip_prototype_interaction_from_decoder; 227 => false false
    kiwi_skip_string_value; 228 => true false skip_guid_path_mapping_from_decoder; 229 =>
    false false kiwi_skip_uint_value; 230 => false false kiwi_skip_uint_value; 231 =>
    false false kiwi_skip_uint_value; 232 => false false kiwi_skip_float_value; 233 =>
    false false kiwi_skip_float_value; 234 => false false kiwi_skip_float_value; 235 =>
    true false skip_guid_from_decoder; 236 => false false kiwi_skip_uint_value; 237 =>
    true false skip_symbol_link_from_decoder; 238 => true false
    skip_state_group_property_value_order_from_decoder; 239 => false false
    skip_text_list_data_from_decoder; 240 => false false
    skip_node_generation_data_from_decoder; 241 => false false kiwi_skip_uint_value; 242
    => false false skip_connector_endpoint_from_decoder; 243 => false false
    skip_connector_endpoint_from_decoder; 244 => false false kiwi_skip_uint_value; 245 =>
    false false kiwi_skip_uint_value; 246 => false false kiwi_skip_uint_value; 247 =>
    false false kiwi_skip_float_value; 248 => true false
    skip_instance_override_stash_from_decoder; 249 => false false
    skip_prototype_starting_point_from_decoder; 250 => true false
    skip_instance_override_stash_v2_from_decoder; 251 => false false
    kiwi_skip_uint_value; 252 => false false kiwi_skip_string_value; 253 => true false
    skip_connector_control_point_from_decoder; 254 => false false
    skip_derived_immutable_frame_data_from_decoder; 255 => false false
    skip_connector_text_midpoint_from_decoder; 256 => false false
    skip_library_move_info_from_decoder; 257 => false false
    skip_internal_data_for_test_from_decoder; 258 => false false kiwi_skip_bool_value;
    259 => false false kiwi_skip_uint_value; 260 => true false
    skip_font_variation_from_decoder; 261 => false false kiwi_skip_bool_value; 262 =>
    false false skip_widget_metadata_from_decoder; 263 => true false
    kiwi_skip_uint_value; 264 => false false kiwi_skip_float_value; 265 => true false
    skip_widget_property_menu_item_from_decoder; 266 => true false
    skip_component_prop_def_from_decoder; 267 => true false
    skip_component_prop_ref_from_decoder; 268 => true false
    skip_component_prop_assignment_from_decoder; 269 => false false kiwi_skip_uint_value;
    270 => false false skip_embed_data_from_decoder; 271 => false false
    kiwi_skip_bool_value; 272 => false false skip_rich_media_data_from_decoder; 273 =>
    false false skip_multiplayer_map_from_decoder; 274 => false false
    kiwi_skip_uint_value; 275 => false false
    skip_widget_derived_subtree_cursor_from_decoder; 276 => false false
    skip_widget_pointer_from_decoder; 277 => false false
    skip_multiplayer_map_from_decoder; 278 => false false
    skip_link_preview_data_from_decoder; 279 => false false kiwi_skip_uint_value; 280 =>
    false false kiwi_skip_uint_value; 281 => true false
    skip_library_move_history_item_from_decoder; 282 => false false kiwi_skip_bool_value;
    283 => false false kiwi_skip_bool_value; 284 => false false kiwi_skip_bool_value; 285
    => false false kiwi_skip_uint_value; 286 => false false kiwi_skip_string_value; 287
    => false false kiwi_skip_bool_value; 288 => false false kiwi_skip_bool_value; 289 =>
    false false kiwi_skip_bool_value; 290 => false false kiwi_skip_bool_value; 291 =>
    false false skip_widget_hover_style_from_decoder; 292 => false false
    kiwi_skip_bool_value; 293 => false false kiwi_skip_bool_value; 294 => false false
    kiwi_skip_bool_value; 295 => false false kiwi_skip_float_value; 296 => false false
    kiwi_skip_float_value; 297 => false false kiwi_skip_float_value; 298 => false false
    kiwi_skip_float_value; 299 => false false kiwi_skip_bool_value; 300 => false false
    skip_video_playback_from_decoder; 301 => false false skip_stamp_data_from_decoder;
    302 => false false kiwi_skip_uint_value; 303 => false false kiwi_skip_uint_value; 304
    => false false kiwi_skip_string_value; 305 => false false kiwi_skip_bool_value; 306
    => false false skip_variable_data_from_decoder; 307 => false false
    skip_variable_data_map_from_decoder; 308 => false false
    skip_table_row_column_position_map_from_decoder; 309 => false false
    skip_table_row_column_position_map_from_decoder; 310 => false false
    skip_table_row_column_size_map_from_decoder; 311 => false false
    skip_table_row_column_size_map_from_decoder; 312 => true false
    skip_variable_set_mode_from_decoder; 313 => false false
    skip_variable_set_id_from_decoder; 314 => false false kiwi_skip_uint_value; 315 =>
    false false skip_variable_data_values_from_decoder; 316 => false false
    skip_variable_mode_by_set_map_from_decoder; 317 => false false kiwi_skip_uint_value;
    318 => false false kiwi_skip_string_value; 319 => false false kiwi_skip_string_value;
    320 => false false kiwi_skip_string_value; 321 => false false kiwi_skip_int_value;
    322 => false false kiwi_skip_uint_value; 323 => false false kiwi_skip_uint_value; 324
    => false false kiwi_skip_float_value; 325 => false false
    skip_optional_vector_from_decoder; 326 => false false
    skip_optional_vector_from_decoder; 327 => false false
    skip_agenda_position_map_from_decoder; 328 => false false
    skip_agenda_metadata_map_from_decoder; 329 => false false
    skip_migration_status_from_decoder; 330 => false false kiwi_skip_bool_value; 331 =>
    false false skip_edit_info_from_decoder; 332 => false false
    skip_style_id_from_decoder; 333 => false false skip_style_id_from_decoder; 334 =>
    false false skip_style_id_from_decoder; 335 => false false
    skip_style_id_from_decoder; 336 => false false skip_style_id_from_decoder; 337 =>
    false false kiwi_skip_bool_value; 338 => false false
    skip_multiplayer_field_version_from_decoder; 339 => false false kiwi_skip_bool_value;
    340 => false false skip_mention_from_decoder; 341 => false false
    kiwi_skip_uint_value; 342 => false false skip_symbol_id_from_decoder; 343 => false
    false kiwi_skip_uint_value; 344 => false false kiwi_skip_bool_value; 345 => false
    false skip_shared_style_master_data_from_decoder; 346 => false false
    kiwi_skip_uint_value; 347 => false false kiwi_skip_string_value; 348 => false false
    skip_shared_style_master_data_from_decoder; 349 => false false kiwi_skip_uint_value;
    350 => false false kiwi_skip_string_value; 351 => false false kiwi_skip_int_value;
    352 => false false kiwi_skip_uint_value; 353 => true false kiwi_skip_uint_value; 354
    => true false skip_developer_related_link_from_decoder; 355 => false false
    skip_section_status_info_from_decoder; 356 => false false kiwi_skip_string_value; 357
    => false false skip_aria_attributes_map_from_decoder; 358 => false false
    skip_code_syntax_map_from_decoder; 359 => false false
    skip_derived_text_data_from_decoder; 360 => false false kiwi_skip_bool_value; 361 =>
    false false skip_handoff_status_map_from_decoder; 362 => false false
    skip_guid_from_decoder; 363 => false false skip_guid_from_decoder; 364 => false false
    kiwi_skip_string_value; 365 => false false skip_edit_scope_info_from_decoder; 366 =>
    false false kiwi_skip_uint_value; 367 => false false
    skip_diagram_parent_index_from_decoder; 368 => false false kiwi_skip_uint_value; 369
    => true false skip_annotation_from_decoder; 370 => false false
    skip_section_preset_info_from_decoder; 371 => false false
    skip_multiplayer_map_from_decoder; 372 => false false
    skip_multiplayer_map_from_decoder; 373 => false false kiwi_skip_uint_value; 374 =>
    false false kiwi_skip_uint_value; 375 => false false kiwi_skip_uint_value; 376 =>
    false false kiwi_skip_bool_value; 377 => false false
    skip_variable_set_id_from_decoder; 378 => false false
    skip_variable_id_or_variable_override_id_from_decoder; 379 => false false
    skip_theme_id_from_decoder; 380 => false false kiwi_skip_bool_value; 381 => false
    false skip_slide_theme_data_from_decoder; 382 => false false kiwi_skip_uint_value;
    383 => false false skip_asset_id_map_from_decoder; 384 => true false
    skip_annotation_measurement_from_decoder; 385 => false false kiwi_skip_bool_value;
    386 => false false kiwi_skip_string_value; 387 => false false kiwi_skip_bool_value;
    388 => false false skip_paste_source_from_decoder; 389 => false false
    kiwi_skip_string_value; 390 => false false skip_slide_theme_map_from_decoder; 391 =>
    false false kiwi_skip_uint_value; 392 => false false kiwi_skip_string_value; 393 =>
    false false kiwi_skip_string_value; 394 => false false kiwi_skip_bool_value; 395 =>
    false false kiwi_skip_string_value; 396 => false false kiwi_skip_uint_value; 397 =>
    false false kiwi_skip_uint_value; 398 => false false skip_guid_from_decoder; 399 =>
    false false kiwi_skip_string_value; 400 => false false
    skip_responsive_set_settings_from_decoder; 401 => false false kiwi_skip_uint_value;
    402 => false false kiwi_skip_uint_value; 403 => false false kiwi_skip_bool_value; 404
    => false false skip_node_behaviors_from_decoder; 405 => true false
    kiwi_skip_uint_value; 406 => true false kiwi_skip_int_value; 407 => false false
    skip_first_draft_data_from_decoder; 408 => false false kiwi_skip_string_value; 409 =>
    false false skip_platform_shape_definition_from_decoder; 410 => false false
    kiwi_skip_bool_value; 411 => true false skip_paint_from_decoder; 412 => false false
    kiwi_skip_bool_value; 413 => false false skip_number_from_decoder; 414 => false false
    kiwi_skip_string_value; 415 => false false skip_number_from_decoder; 416 => false
    false kiwi_skip_uint_value; 417 => true false
    skip_responsive_text_style_variant_from_decoder; 418 => false false
    skip_first_draft_kit_element_data_from_decoder; 419 => false false
    skip_cms_selector_from_decoder; 420 => false false
    skip_cms_consumption_map_from_decoder; 421 => false false
    skip_cooper_revert_data_from_decoder; 422 => false false
    skip_hub_file_attribution_from_decoder; 423 => false false
    skip_optional_vector_from_decoder; 424 => false false skip_vector_from_decoder; 425
    => false false kiwi_skip_uint_value; 426 => true false
    skip_prototype_interaction_from_decoder; 427 => false false
    skip_code_library_id_from_decoder; 428 => false false skip_code_file_id_from_decoder;
    429 => false false skip_code_component_id_from_decoder; 430 => false false
    kiwi_skip_string_value; 431 => false false kiwi_skip_uint_value; 432 => false false
    skip_text_path_start_from_decoder; 433 => false false kiwi_skip_uint_value; 434 =>
    false false kiwi_skip_uint_value; 435 => false false
    skip_guid_position_map_from_decoder; 436 => false false
    skip_guid_position_map_from_decoder; 437 => false false kiwi_skip_float_value; 438 =>
    false false kiwi_skip_float_value; 439 => false false skip_guid_from_decoder; 440 =>
    false false skip_guid_from_decoder; 441 => false false kiwi_skip_uint_value; 442 =>
    false false kiwi_skip_uint_value; 443 => false false kiwi_skip_uint_value; 444 =>
    false false skip_collaborative_plain_text_from_decoder; 445 => false false
    skip_variable_data_map_from_decoder; 446 => false false skip_guid_from_decoder; 447
    => true false skip_variable_width_point_from_decoder; 448 => false false
    skip_dynamic_stroke_settings_from_decoder; 449 => false false
    skip_scatter_stroke_settings_from_decoder; 450 => false false
    skip_stretch_stroke_settings_from_decoder; 451 => true false
    skip_node_chat_message_from_decoder; 452 => false false kiwi_skip_uint_value; 453 =>
    false false skip_annotation_categories_from_decoder; 454 => false false
    skip_managed_string_data_from_decoder; 455 => true false
    skip_transform_modifier_from_decoder; 456 => false false kiwi_skip_string_value; 457
    => false false skip_guid_from_decoder; 458 => false false kiwi_skip_bool_value; 459
    => false false skip_code_snapshot_from_decoder; 460 => false false
    skip_cms_rich_text_style_map_from_decoder; 461 => false false
    skip_cooper_template_data_from_decoder; 462 => false false skip_guid_from_decoder;
    463 => false false kiwi_skip_bool_value; 464 => false false
    skip_variable_id_from_decoder; 465 => false false kiwi_skip_bool_value; 466 => false
    false skip_thumbnail_info_from_decoder; 467 => false false
    skip_imported_code_files_from_decoder; 468 => false false
    skip_canvas_node_id_from_decoder; 469 => false false kiwi_skip_bool_value; 470 =>
    false false kiwi_skip_bool_value; 471 => false false kiwi_skip_bool_value; 472 =>
    false false kiwi_skip_string_value; 473 => false false
    skip_image_import_map_from_decoder; 474 => false false
    skip_guid_grid_track_size_map_from_decoder; 475 => false false
    skip_guid_grid_track_size_map_from_decoder; 476 => false false kiwi_skip_uint_value;
    477 => false false kiwi_skip_uint_value; 478 => false false
    skip_code_behavior_data_from_decoder; 479 => true false
    skip_connector_control_point_from_decoder; 480 => false false kiwi_skip_uint_value;
    481 => false false skip_canvas_node_id_from_decoder; 482 => false false
    kiwi_skip_uint64_value; 483 => true false skip_variant_prop_spec_from_decoder; 484 =>
    false false kiwi_skip_string_value; 485 => false false
    skip_node_chat_compression_state_from_decoder; 486 => false false
    kiwi_skip_bool_value; 487 => false false kiwi_skip_bool_value; 488 => true false
    skip_matrix_from_decoder; 489 => false false skip_multiplayer_map_from_decoder; 490
    => false false kiwi_skip_bool_value; 491 => false false skip_jsx_data_from_decoder;
    492 => false false skip_derived_jsx_data_from_decoder; 493 => false false
    kiwi_skip_string_value; 494 => false false skip_ai_canvas_prompt_from_decoder; 495 =>
    false false kiwi_skip_bool_value; 496 => false false
    skip_ai_chat_thread_from_decoder; 497 => false false skip_number_from_decoder; 498 =>
    false false kiwi_skip_bool_value; 499 => false false
    skip_canvas_node_id_from_decoder; 500 => false false
    skip_derived_breakpoint_data_from_decoder; 501 => false false kiwi_skip_float_value;
    502 => false false kiwi_skip_string_value; 503 => false false kiwi_skip_uint_value;
    504 => false false kiwi_skip_string_value; 505 => false false kiwi_skip_uint_value;
    506 => false false kiwi_skip_int64_value; 507 => false false
    skip_keyframe_value_data_from_decoder; 508 => false false
    skip_bezier_handles_from_decoder; 509 => false false kiwi_skip_uint_value; 510 =>
    false false kiwi_skip_uint_value; 511 => false false skip_guid_from_decoder; 512 =>
    false false kiwi_skip_uint64_value; 513 => false false kiwi_skip_int64_value; 514 =>
    false false kiwi_skip_uint_value; 515 => true false kiwi_skip_string_value; 516 =>
    false false kiwi_skip_uint_value; 517 => false false
    skip_inherited_variables_data_from_decoder; 518 => false false
    kiwi_skip_string_value; 519 => false false kiwi_skip_uint_value; 520 => false false
    kiwi_skip_bool_value; 521 => false false skip_animation_presets_from_decoder; 522 =>
    false false kiwi_skip_bool_value; 523 => false false
    skip_trss_transform2_d_from_decoder; 524 => true false
    skip_used_make_library_from_decoder; 525 => true false
    skip_code_example_from_decoder; 526 => false false
    skip_transition_override_data_from_decoder; 527 => false false kiwi_skip_bool_value;
    528 => false false skip_buzz_approval_requests_from_decoder; 529 => false false
    skip_buzz_approval_node_status_info_from_decoder; 530 => false false
    kiwi_skip_bool_value; 531 => false false skip_prototype_device_from_decoder; 532 =>
    false false skip_code_embed_info_from_decoder; 533 => false false
    kiwi_skip_int_value; 534 => true false skip_collaborative_text_op_id_from_decoder;
    535 => false false skip_easing_data_from_decoder; 536 => false false
    kiwi_skip_string_value; 537 => false true kiwi_skip_bytes_value; 538 => false false
    skip_table_merged_cell_map_from_decoder; 539 => false false
    skip_symbol_id_from_decoder; 540 => false false
    skip_repeater_cms_override_data_from_decoder; 541 => false false
    skip_repeater_override_data_from_decoder; 542 => false false
    skip_optional_vector_from_decoder; 543 => false false kiwi_skip_bool_value; 544 =>
    false false kiwi_skip_bool_value; 545 => false false kiwi_skip_bool_value; 546 =>
    false false kiwi_skip_bool_value; 547 => false false kiwi_skip_string_value; 548 =>
    false false kiwi_skip_string_value; 549 => false false
    skip_repeater_symbol_override_data_from_decoder; 550 => false false
    kiwi_skip_bool_value; 551 => false false kiwi_skip_bool_value; 552 => false false
    skip_timeline_definitions_map_from_decoder; 553 => false false
    skip_timeline_assignments_map_from_decoder; 554 => false false kiwi_skip_float_value;
    555 => false false kiwi_skip_uint_value; 556 => false false kiwi_skip_bool_value; 557
    => false false skip_source_control_config_from_decoder; 558 => false false
    skip_code_source_info_from_decoder; 559 => false false kiwi_skip_uint_value; 560 =>
    false false skip_collaborative_plain_text_from_decoder; 561 => false false
    kiwi_skip_string_value; 562 => false false kiwi_skip_string_value; 563 => false false
    kiwi_skip_int_value; 564 => true false skip_path_from_decoder; 565 => false false
    kiwi_skip_bool_value; 566 => false false kiwi_skip_uint_value; 567 => false false
    kiwi_skip_bool_value; 568 => false false skip_tools_from_decoder; 569 => false false
    skip_custom_effects_from_decoder; 570 => false false skip_transform3d_from_decoder;
    571 => false false skip_stroke_data_from_decoder; 572 => false false
    skip_scene3d_from_decoder; 573 => false false skip_multiplayer_map_from_decoder; 574
    => false false kiwi_skip_uint_value; 575 => false false kiwi_skip_string_value; 576
    => false false kiwi_skip_int_value; 577 => false false kiwi_skip_int_value; 578 =>
    false false skip_table_row_column_size_map_from_decoder; 579 => false false
    skip_table_row_column_size_map_from_decoder; 580 => true false
    skip_style_animation_from_decoder; 581 => false false
    skip_partial_paste_annotation_from_decoder; 582 => true false
    skip_style_id_for_animation_from_decoder; 583 => false false
    skip_animation_preset_id_from_decoder; 584 => false false kiwi_skip_string_value; 585
    => false false kiwi_skip_int_value; 586 => false false
    skip_variable_data_from_decoder; 587 => false false
    skip_transform_origin_from_decoder; 588 => false false
    skip_custom_tool_artifact_ref_from_decoder; 589 => false false
    skip_code_snapshot_layers_from_decoder; 590 => false false kiwi_skip_string_value;]
}
fn decode_scene_message_from_decoder(
    decoder: &mut Decoder<'_>,
    node_count: &mut usize,
    parented_count: &mut usize,
    type_counts: &mut std::collections::HashMap<String, usize>,
) -> NifResult<()> {
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            4 => {
                let len = decoder.read_var_uint()? as usize;
                for _ in 0..len {
                    decode_scene_node_change_from_decoder(
                        decoder,
                        node_count,
                        parented_count,
                        type_counts,
                    )?;
                }
            }
            field => skip_fig_message_field(decoder, field)?,
        }
    }
    Ok(())
}
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
            }
            4 => {
                let value = decoder.read_var_uint()?;
                let name = scene_node_type_name(value).to_string();
                *type_counts.entry(name).or_insert(0) += 1;
            }
            field => skip_fig_node_change_field(decoder, field)?,
        }
    }
    Ok(())
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_sparse_message<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(value)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_graph_focused_sparse_message<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    focus: Vec<String>,
) -> NifResult<Term<'a>> {
    if focus.is_empty() {
        let mut decoder = Decoder::new(bytes.as_slice());
        let value = decode_sparse_message_from_decoder(env, &mut decoder)?;
        decoder.finish()?;
        return Ok(value);
    }
    let mut index_decoder = Decoder::new(bytes.as_slice());
    let metas = graph_focus_index_message(&mut index_decoder)?;
    index_decoder.finish()?;
    let wanted = graph_focus_wanted(&metas, &focus);
    let value = graph_focus_sparse_message_from_slices(
        env,
        bytes.as_slice(),
        &metas,
        &wanted,
    )?;
    Ok(value)
}
pub fn load(env: Env<'_>, _term: Term<'_>) -> bool {
    env.register::<scene_xpath_runtime::SceneIndexResource>().is_ok()
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_scene_summary<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let mut node_count: usize = 0;
    let mut parented_count: usize = 0;
    let mut type_counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
    decode_scene_message_from_decoder(
        &mut decoder,
        &mut node_count,
        &mut parented_count,
        &mut type_counts,
    )?;
    decoder.finish()?;
    let mut type_counts = type_counts.into_iter().collect::<Vec<_>>();
    type_counts
        .sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));
    Ok(
        SceneSummary {
            node_count,
            parented_count,
            root_count: node_count.saturating_sub(parented_count),
            type_counts,
        }
            .encode(env),
    )
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn build_scene_index(
    bytes: Binary<'_>,
) -> NifResult<rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>> {
    scene_xpath_runtime::build_scene_index_value(bytes)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn build_scene_index_with_summary(
    bytes: Binary<'_>,
) -> NifResult<
    (rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>, SceneSummary),
> {
    scene_xpath_runtime::build_scene_index_with_summary_value(bytes)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_xpath<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    xpath: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_value(env, bytes, xpath)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_xpath_fields<'a>(
    env: Env<'a>,
    bytes: Binary<'a>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_xpath_fields_value(env, bytes, xpath, fields)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_index<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_value(env, resource, xpath)
}
#[rustler::nif(schedule = "DirtyCpu")]
pub fn query_scene_index_fields<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    xpath: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::query_scene_index_fields_value(env, resource, xpath, fields)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_node<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::scene_index_node_value(env, resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_parent<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::scene_index_parent_value(env, resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_roots(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_roots_value(resource)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_children(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_children_value(resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_siblings(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_siblings_value(resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_by_type(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    node_type: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_by_type_value(resource, node_type)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_named(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    name: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_named_value(resource, name)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_name_contains(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    needle: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_name_contains_value(resource, needle)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_text_contains(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    needle: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_text_contains_value(resource, needle)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_ancestors(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_ancestors_value(resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_descendants(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    guid: String,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_descendants_value(resource, guid)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_by_type_fields<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    node_type: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::scene_index_by_type_fields_value(
        env,
        resource,
        node_type,
        fields,
    )
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_name_contains_fields<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    needle: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::scene_index_name_contains_fields_value(
        env,
        resource,
        needle,
        fields,
    )
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_text_contains_fields<'a>(
    env: Env<'a>,
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
    needle: String,
    fields: Vec<String>,
) -> NifResult<Term<'a>> {
    scene_xpath_runtime::scene_index_text_contains_fields_value(
        env,
        resource,
        needle,
        fields,
    )
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_components(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_components_value(resource)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_with_fills(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_with_fills_value(resource)
}
#[rustler::nif(schedule = "DirtyCpu")]
fn scene_index_with_strokes(
    resource: rustler::ResourceArc<scene_xpath_runtime::SceneIndexResource>,
) -> Vec<SceneQueryNode> {
    scene_xpath_runtime::scene_index_with_strokes_value(resource)
}
