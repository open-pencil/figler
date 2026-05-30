use crate::runtime::Decoder;
use rustler::types::atom::Atom;
use rustler::{Binary, Encoder, Env, Error, NifResult, Term};
fn decode_axis_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "x")?.encode(env)),
        1 => Ok(Atom::from_str(env, "y")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_phase_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "created")?.encode(env)),
        1 => Ok(Atom::from_str(env, "removed")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_winding_rule_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "nonzero")?.encode(env)),
        1 => Ok(Atom::from_str(env, "odd")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "document")?.encode(env)),
        2 => Ok(Atom::from_str(env, "canvas")?.encode(env)),
        3 => Ok(Atom::from_str(env, "group")?.encode(env)),
        4 => Ok(Atom::from_str(env, "frame")?.encode(env)),
        5 => Ok(Atom::from_str(env, "boolean_operation")?.encode(env)),
        6 => Ok(Atom::from_str(env, "vector")?.encode(env)),
        7 => Ok(Atom::from_str(env, "star")?.encode(env)),
        8 => Ok(Atom::from_str(env, "line")?.encode(env)),
        9 => Ok(Atom::from_str(env, "ellipse")?.encode(env)),
        10 => Ok(Atom::from_str(env, "rectangle")?.encode(env)),
        11 => Ok(Atom::from_str(env, "regular_polygon")?.encode(env)),
        12 => Ok(Atom::from_str(env, "rounded_rectangle")?.encode(env)),
        13 => Ok(Atom::from_str(env, "text")?.encode(env)),
        14 => Ok(Atom::from_str(env, "slice")?.encode(env)),
        15 => Ok(Atom::from_str(env, "symbol")?.encode(env)),
        16 => Ok(Atom::from_str(env, "instance")?.encode(env)),
        17 => Ok(Atom::from_str(env, "sticky")?.encode(env)),
        18 => Ok(Atom::from_str(env, "shape_with_text")?.encode(env)),
        19 => Ok(Atom::from_str(env, "connector")?.encode(env)),
        20 => Ok(Atom::from_str(env, "code_block")?.encode(env)),
        21 => Ok(Atom::from_str(env, "widget")?.encode(env)),
        22 => Ok(Atom::from_str(env, "stamp")?.encode(env)),
        23 => Ok(Atom::from_str(env, "media")?.encode(env)),
        24 => Ok(Atom::from_str(env, "highlight")?.encode(env)),
        25 => Ok(Atom::from_str(env, "section")?.encode(env)),
        26 => Ok(Atom::from_str(env, "section_overlay")?.encode(env)),
        27 => Ok(Atom::from_str(env, "washi_tape")?.encode(env)),
        28 => Ok(Atom::from_str(env, "variable")?.encode(env)),
        29 => Ok(Atom::from_str(env, "table")?.encode(env)),
        30 => Ok(Atom::from_str(env, "table_cell")?.encode(env)),
        31 => Ok(Atom::from_str(env, "variable_set")?.encode(env)),
        32 => Ok(Atom::from_str(env, "slide")?.encode(env)),
        33 => Ok(Atom::from_str(env, "assisted_layout")?.encode(env)),
        34 => Ok(Atom::from_str(env, "interactive_slide_element")?.encode(env)),
        35 => Ok(Atom::from_str(env, "variable_override")?.encode(env)),
        36 => Ok(Atom::from_str(env, "module")?.encode(env)),
        37 => Ok(Atom::from_str(env, "slide_grid")?.encode(env)),
        38 => Ok(Atom::from_str(env, "slide_row")?.encode(env)),
        39 => Ok(Atom::from_str(env, "responsive_set")?.encode(env)),
        40 => Ok(Atom::from_str(env, "code_component")?.encode(env)),
        41 => Ok(Atom::from_str(env, "text_path")?.encode(env)),
        42 => Ok(Atom::from_str(env, "code_instance")?.encode(env)),
        43 => Ok(Atom::from_str(env, "code_library")?.encode(env)),
        44 => Ok(Atom::from_str(env, "code_file")?.encode(env)),
        45 => Ok(Atom::from_str(env, "code_layer")?.encode(env)),
        46 => Ok(Atom::from_str(env, "brush")?.encode(env)),
        47 => Ok(Atom::from_str(env, "managed_string")?.encode(env)),
        48 => Ok(Atom::from_str(env, "transform")?.encode(env)),
        49 => Ok(Atom::from_str(env, "cms_rich_text")?.encode(env)),
        50 => Ok(Atom::from_str(env, "repeater")?.encode(env)),
        51 => Ok(Atom::from_str(env, "jsx")?.encode(env)),
        52 => Ok(Atom::from_str(env, "embedded_prototype")?.encode(env)),
        53 => Ok(Atom::from_str(env, "react_fiber")?.encode(env)),
        54 => Ok(Atom::from_str(env, "responsive_node_set")?.encode(env)),
        55 => Ok(Atom::from_str(env, "webpage")?.encode(env)),
        56 => Ok(Atom::from_str(env, "keyframe")?.encode(env)),
        57 => Ok(Atom::from_str(env, "keyframe_track")?.encode(env)),
        58 => Ok(Atom::from_str(env, "animation_preset_instance")?.encode(env)),
        59 => Ok(Atom::from_str(env, "code_embed")?.encode(env)),
        60 => Ok(Atom::from_str(env, "binary_file")?.encode(env)),
        61 => Ok(Atom::from_str(env, "spec_block")?.encode(env)),
        62 => Ok(Atom::from_str(env, "tool_instance")?.encode(env)),
        63 => Ok(Atom::from_str(env, "custom_effect_instance")?.encode(env)),
        64 => Ok(Atom::from_str(env, "native_code_layer_instance")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_shape_with_text_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "square")?.encode(env)),
        1 => Ok(Atom::from_str(env, "ellipse")?.encode(env)),
        2 => Ok(Atom::from_str(env, "diamond")?.encode(env)),
        3 => Ok(Atom::from_str(env, "triangle_up")?.encode(env)),
        4 => Ok(Atom::from_str(env, "triangle_down")?.encode(env)),
        5 => Ok(Atom::from_str(env, "rounded_rectangle")?.encode(env)),
        6 => Ok(Atom::from_str(env, "parallelogram_right")?.encode(env)),
        7 => Ok(Atom::from_str(env, "parallelogram_left")?.encode(env)),
        8 => Ok(Atom::from_str(env, "eng_database")?.encode(env)),
        9 => Ok(Atom::from_str(env, "eng_queue")?.encode(env)),
        10 => Ok(Atom::from_str(env, "eng_file")?.encode(env)),
        11 => Ok(Atom::from_str(env, "eng_folder")?.encode(env)),
        12 => Ok(Atom::from_str(env, "trapezoid")?.encode(env)),
        13 => Ok(Atom::from_str(env, "predefined_process")?.encode(env)),
        14 => Ok(Atom::from_str(env, "shield")?.encode(env)),
        15 => Ok(Atom::from_str(env, "document_single")?.encode(env)),
        16 => Ok(Atom::from_str(env, "document_multiple")?.encode(env)),
        17 => Ok(Atom::from_str(env, "manual_input")?.encode(env)),
        18 => Ok(Atom::from_str(env, "hexagon")?.encode(env)),
        19 => Ok(Atom::from_str(env, "chevron")?.encode(env)),
        20 => Ok(Atom::from_str(env, "pentagon")?.encode(env)),
        21 => Ok(Atom::from_str(env, "octagon")?.encode(env)),
        22 => Ok(Atom::from_str(env, "star")?.encode(env)),
        23 => Ok(Atom::from_str(env, "plus")?.encode(env)),
        24 => Ok(Atom::from_str(env, "arrow_left")?.encode(env)),
        25 => Ok(Atom::from_str(env, "arrow_right")?.encode(env)),
        26 => Ok(Atom::from_str(env, "summing_junction")?.encode(env)),
        27 => Ok(Atom::from_str(env, "or")?.encode(env)),
        28 => Ok(Atom::from_str(env, "speech_bubble")?.encode(env)),
        29 => Ok(Atom::from_str(env, "internal_storage")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_blend_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "pass_through")?.encode(env)),
        1 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        2 => Ok(Atom::from_str(env, "darken")?.encode(env)),
        3 => Ok(Atom::from_str(env, "multiply")?.encode(env)),
        4 => Ok(Atom::from_str(env, "linear_burn")?.encode(env)),
        5 => Ok(Atom::from_str(env, "color_burn")?.encode(env)),
        6 => Ok(Atom::from_str(env, "lighten")?.encode(env)),
        7 => Ok(Atom::from_str(env, "screen")?.encode(env)),
        8 => Ok(Atom::from_str(env, "linear_dodge")?.encode(env)),
        9 => Ok(Atom::from_str(env, "color_dodge")?.encode(env)),
        10 => Ok(Atom::from_str(env, "overlay")?.encode(env)),
        11 => Ok(Atom::from_str(env, "soft_light")?.encode(env)),
        12 => Ok(Atom::from_str(env, "hard_light")?.encode(env)),
        13 => Ok(Atom::from_str(env, "difference")?.encode(env)),
        14 => Ok(Atom::from_str(env, "exclusion")?.encode(env)),
        15 => Ok(Atom::from_str(env, "hue")?.encode(env)),
        16 => Ok(Atom::from_str(env, "saturation")?.encode(env)),
        17 => Ok(Atom::from_str(env, "color")?.encode(env)),
        18 => Ok(Atom::from_str(env, "luminosity")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_paint_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "solid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "gradient_linear")?.encode(env)),
        2 => Ok(Atom::from_str(env, "gradient_radial")?.encode(env)),
        3 => Ok(Atom::from_str(env, "gradient_angular")?.encode(env)),
        4 => Ok(Atom::from_str(env, "gradient_diamond")?.encode(env)),
        5 => Ok(Atom::from_str(env, "image")?.encode(env)),
        6 => Ok(Atom::from_str(env, "emoji")?.encode(env)),
        7 => Ok(Atom::from_str(env, "video")?.encode(env)),
        8 => Ok(Atom::from_str(env, "pattern")?.encode(env)),
        9 => Ok(Atom::from_str(env, "noise")?.encode(env)),
        10 => Ok(Atom::from_str(env, "custom")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_image_scale_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "stretch")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fit")?.encode(env)),
        2 => Ok(Atom::from_str(env, "fill")?.encode(env)),
        3 => Ok(Atom::from_str(env, "tile")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_effect_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "inner_shadow")?.encode(env)),
        1 => Ok(Atom::from_str(env, "drop_shadow")?.encode(env)),
        2 => Ok(Atom::from_str(env, "foreground_blur")?.encode(env)),
        3 => Ok(Atom::from_str(env, "background_blur")?.encode(env)),
        4 => Ok(Atom::from_str(env, "repeat")?.encode(env)),
        5 => Ok(Atom::from_str(env, "symmetry")?.encode(env)),
        6 => Ok(Atom::from_str(env, "grain")?.encode(env)),
        7 => Ok(Atom::from_str(env, "noise")?.encode(env)),
        8 => Ok(Atom::from_str(env, "glass")?.encode(env)),
        9 => Ok(Atom::from_str(env, "custom")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_case_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "original")?.encode(env)),
        1 => Ok(Atom::from_str(env, "upper")?.encode(env)),
        2 => Ok(Atom::from_str(env, "lower")?.encode(env)),
        3 => Ok(Atom::from_str(env, "title")?.encode(env)),
        4 => Ok(Atom::from_str(env, "small_caps")?.encode(env)),
        5 => Ok(Atom::from_str(env, "small_caps_forced")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_decoration_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "underline")?.encode(env)),
        2 => Ok(Atom::from_str(env, "strikethrough")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_decoration_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "solid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "dotted")?.encode(env)),
        2 => Ok(Atom::from_str(env, "wavy")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_leading_trim_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "cap_height")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_number_units_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "raw")?.encode(env)),
        1 => Ok(Atom::from_str(env, "pixels")?.encode(env)),
        2 => Ok(Atom::from_str(env, "percent")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_constraint_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "min")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "max")?.encode(env)),
        3 => Ok(Atom::from_str(env, "stretch")?.encode(env)),
        4 => Ok(Atom::from_str(env, "scale")?.encode(env)),
        5 => Ok(Atom::from_str(env, "fixed_min")?.encode(env)),
        6 => Ok(Atom::from_str(env, "fixed_max")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stroke_align_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "center")?.encode(env)),
        1 => Ok(Atom::from_str(env, "inside")?.encode(env)),
        2 => Ok(Atom::from_str(env, "outside")?.encode(env)),
        3 => Ok(Atom::from_str(env, "offset")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stroke_cap_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "round")?.encode(env)),
        2 => Ok(Atom::from_str(env, "square")?.encode(env)),
        3 => Ok(Atom::from_str(env, "arrow_lines")?.encode(env)),
        4 => Ok(Atom::from_str(env, "arrow_equilateral")?.encode(env)),
        5 => Ok(Atom::from_str(env, "diamond_filled")?.encode(env)),
        6 => Ok(Atom::from_str(env, "triangle_filled")?.encode(env)),
        7 => Ok(Atom::from_str(env, "highlight")?.encode(env)),
        8 => Ok(Atom::from_str(env, "washi_tape_1")?.encode(env)),
        9 => Ok(Atom::from_str(env, "washi_tape_2")?.encode(env)),
        10 => Ok(Atom::from_str(env, "washi_tape_3")?.encode(env)),
        11 => Ok(Atom::from_str(env, "washi_tape_4")?.encode(env)),
        12 => Ok(Atom::from_str(env, "washi_tape_5")?.encode(env)),
        13 => Ok(Atom::from_str(env, "washi_tape_6")?.encode(env)),
        14 => Ok(Atom::from_str(env, "circle_filled")?.encode(env)),
        15 => Ok(Atom::from_str(env, "erd_zero_or_one")?.encode(env)),
        16 => Ok(Atom::from_str(env, "erd_exactly_one")?.encode(env)),
        17 => Ok(Atom::from_str(env, "erd_zero_or_more")?.encode(env)),
        18 => Ok(Atom::from_str(env, "erd_one_or_more")?.encode(env)),
        19 => Ok(Atom::from_str(env, "erd_one")?.encode(env)),
        20 => Ok(Atom::from_str(env, "erd_many")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stroke_join_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "miter")?.encode(env)),
        1 => Ok(Atom::from_str(env, "bevel")?.encode(env)),
        2 => Ok(Atom::from_str(env, "round")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_boolean_operation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "union")?.encode(env)),
        1 => Ok(Atom::from_str(env, "intersect")?.encode(env)),
        2 => Ok(Atom::from_str(env, "subtract")?.encode(env)),
        3 => Ok(Atom::from_str(env, "xor")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_align_horizontal_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "left")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "right")?.encode(env)),
        3 => Ok(Atom::from_str(env, "justified")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_align_vertical_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "top")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "bottom")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_vector_mirror_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "angle")?.encode(env)),
        2 => Ok(Atom::from_str(env, "angle_and_length")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_image_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "png")?.encode(env)),
        1 => Ok(Atom::from_str(env, "jpeg")?.encode(env)),
        2 => Ok(Atom::from_str(env, "svg")?.encode(env)),
        3 => Ok(Atom::from_str(env, "pdf")?.encode(env)),
        4 => Ok(Atom::from_str(env, "mp4")?.encode(env)),
        5 => Ok(Atom::from_str(env, "gif")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_export_constraint_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "content_scale")?.encode(env)),
        1 => Ok(Atom::from_str(env, "content_width")?.encode(env)),
        2 => Ok(Atom::from_str(env, "content_height")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_layout_grid_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "min")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "stretch")?.encode(env)),
        3 => Ok(Atom::from_str(env, "max")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_layout_grid_pattern_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "stripes")?.encode(env)),
        1 => Ok(Atom::from_str(env, "grid")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_auto_resize_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "width_and_height")?.encode(env)),
        2 => Ok(Atom::from_str(env, "height")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_truncation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "disabled")?.encode(env)),
        1 => Ok(Atom::from_str(env, "ending")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "horizontal")?.encode(env)),
        2 => Ok(Atom::from_str(env, "vertical")?.encode(env)),
        3 => Ok(Atom::from_str(env, "grid")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_align_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "min")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "max")?.encode(env)),
        3 => Ok(Atom::from_str(env, "baseline")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_counter_align_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "min")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "max")?.encode(env)),
        3 => Ok(Atom::from_str(env, "stretch")?.encode(env)),
        4 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        5 => Ok(Atom::from_str(env, "baseline")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_justify_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "min")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "max")?.encode(env)),
        3 => Ok(Atom::from_str(env, "space_evenly")?.encode(env)),
        4 => Ok(Atom::from_str(env, "space_between")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_grid_child_align_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        1 => Ok(Atom::from_str(env, "min")?.encode(env)),
        2 => Ok(Atom::from_str(env, "center")?.encode(env)),
        3 => Ok(Atom::from_str(env, "max")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_grid_auto_tracks_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "rows")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_size_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "fixed")?.encode(env)),
        1 => Ok(Atom::from_str(env, "resize_to_fit")?.encode(env)),
        2 => Ok(Atom::from_str(env, "resize_to_fit_with_implicit_size")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_positioning_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        1 => Ok(Atom::from_str(env, "absolute")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_wrap_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "no_wrap")?.encode(env)),
        1 => Ok(Atom::from_str(env, "wrap")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_stack_counter_align_content_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        1 => Ok(Atom::from_str(env, "space_between")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_connection_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "internal_node")?.encode(env)),
        2 => Ok(Atom::from_str(env, "url")?.encode(env)),
        3 => Ok(Atom::from_str(env, "back")?.encode(env)),
        4 => Ok(Atom::from_str(env, "close")?.encode(env)),
        5 => Ok(Atom::from_str(env, "set_variable")?.encode(env)),
        6 => Ok(Atom::from_str(env, "update_media_runtime")?.encode(env)),
        7 => Ok(Atom::from_str(env, "conditional")?.encode(env)),
        8 => Ok(Atom::from_str(env, "set_variable_mode")?.encode(env)),
        9 => Ok(Atom::from_str(env, "object_animation")?.encode(env)),
        10 => Ok(Atom::from_str(env, "update_animation_timeline_state")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_interaction_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "on_click")?.encode(env)),
        1 => Ok(Atom::from_str(env, "after_timeout")?.encode(env)),
        2 => Ok(Atom::from_str(env, "mouse_in")?.encode(env)),
        3 => Ok(Atom::from_str(env, "mouse_out")?.encode(env)),
        4 => Ok(Atom::from_str(env, "on_hover")?.encode(env)),
        5 => Ok(Atom::from_str(env, "mouse_down")?.encode(env)),
        6 => Ok(Atom::from_str(env, "mouse_up")?.encode(env)),
        7 => Ok(Atom::from_str(env, "on_press")?.encode(env)),
        8 => Ok(Atom::from_str(env, "none")?.encode(env)),
        9 => Ok(Atom::from_str(env, "drag")?.encode(env)),
        10 => Ok(Atom::from_str(env, "on_key_down")?.encode(env)),
        11 => Ok(Atom::from_str(env, "on_voice")?.encode(env)),
        12 => Ok(Atom::from_str(env, "on_media_hit")?.encode(env)),
        13 => Ok(Atom::from_str(env, "on_media_end")?.encode(env)),
        14 => Ok(Atom::from_str(env, "mouse_enter")?.encode(env)),
        15 => Ok(Atom::from_str(env, "mouse_leave")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_transition_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "instant_transition")?.encode(env)),
        1 => Ok(Atom::from_str(env, "dissolve")?.encode(env)),
        2 => Ok(Atom::from_str(env, "fade")?.encode(env)),
        3 => Ok(Atom::from_str(env, "slide_from_left")?.encode(env)),
        4 => Ok(Atom::from_str(env, "slide_from_right")?.encode(env)),
        5 => Ok(Atom::from_str(env, "slide_from_top")?.encode(env)),
        6 => Ok(Atom::from_str(env, "slide_from_bottom")?.encode(env)),
        7 => Ok(Atom::from_str(env, "push_from_left")?.encode(env)),
        8 => Ok(Atom::from_str(env, "push_from_right")?.encode(env)),
        9 => Ok(Atom::from_str(env, "push_from_top")?.encode(env)),
        10 => Ok(Atom::from_str(env, "push_from_bottom")?.encode(env)),
        11 => Ok(Atom::from_str(env, "move_from_left")?.encode(env)),
        12 => Ok(Atom::from_str(env, "move_from_right")?.encode(env)),
        13 => Ok(Atom::from_str(env, "move_from_top")?.encode(env)),
        14 => Ok(Atom::from_str(env, "move_from_bottom")?.encode(env)),
        15 => Ok(Atom::from_str(env, "slide_out_to_left")?.encode(env)),
        16 => Ok(Atom::from_str(env, "slide_out_to_right")?.encode(env)),
        17 => Ok(Atom::from_str(env, "slide_out_to_top")?.encode(env)),
        18 => Ok(Atom::from_str(env, "slide_out_to_bottom")?.encode(env)),
        19 => Ok(Atom::from_str(env, "move_out_to_left")?.encode(env)),
        20 => Ok(Atom::from_str(env, "move_out_to_right")?.encode(env)),
        21 => Ok(Atom::from_str(env, "move_out_to_top")?.encode(env)),
        22 => Ok(Atom::from_str(env, "move_out_to_bottom")?.encode(env)),
        23 => Ok(Atom::from_str(env, "magic_move")?.encode(env)),
        24 => Ok(Atom::from_str(env, "smart_animate")?.encode(env)),
        25 => Ok(Atom::from_str(env, "scroll_animate")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_easing_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "in_cubic")?.encode(env)),
        1 => Ok(Atom::from_str(env, "out_cubic")?.encode(env)),
        2 => Ok(Atom::from_str(env, "inout_cubic")?.encode(env)),
        3 => Ok(Atom::from_str(env, "linear")?.encode(env)),
        4 => Ok(Atom::from_str(env, "in_back_cubic")?.encode(env)),
        5 => Ok(Atom::from_str(env, "out_back_cubic")?.encode(env)),
        6 => Ok(Atom::from_str(env, "inout_back_cubic")?.encode(env)),
        7 => Ok(Atom::from_str(env, "custom_cubic")?.encode(env)),
        8 => Ok(Atom::from_str(env, "spring")?.encode(env)),
        9 => Ok(Atom::from_str(env, "gentle_spring")?.encode(env)),
        10 => Ok(Atom::from_str(env, "custom_spring")?.encode(env)),
        11 => Ok(Atom::from_str(env, "spring_preset_one")?.encode(env)),
        12 => Ok(Atom::from_str(env, "spring_preset_two")?.encode(env)),
        13 => Ok(Atom::from_str(env, "spring_preset_three")?.encode(env)),
        14 => Ok(Atom::from_str(env, "hold")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_scroll_direction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "horizontal")?.encode(env)),
        2 => Ok(Atom::from_str(env, "vertical")?.encode(env)),
        3 => Ok(Atom::from_str(env, "both")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_scroll_contracted_state_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "expanded")?.encode(env)),
        1 => Ok(Atom::from_str(env, "contracted")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_guid_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GUID")?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "session_id")?, value)?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "local_id")?, value)?;
    Ok(term)
}
fn decode_color_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Color")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "r")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "g")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "b")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "a")?, value)?;
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
fn decode_rect_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Rect")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "x")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "y")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "w")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "h")?, value)?;
    Ok(term)
}
fn decode_color_stop_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ColorStop")?;
    let value = decode_color_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "color")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "position")?, value)?;
    Ok(term)
}
fn decode_color_stop_var_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ColorStopVar")?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "color_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_var")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ColorStopVar",
                    field
                ))));
            }
        }
    }
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
fn decode_number_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Number")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "value")?, value)?;
    let value = decode_number_units_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "units")?, value)?;
    Ok(term)
}
fn decode_font_name_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FontName")?;
    let value = decoder.read_string()?;
    term = term.map_put(Atom::from_str(env, "family")?, value)?;
    let value = decoder.read_string()?;
    term = term.map_put(Atom::from_str(env, "style")?, value)?;
    let value = decoder.read_string()?;
    term = term.map_put(Atom::from_str(env, "postscript")?, value)?;
    Ok(term)
}
fn decode_font_variant_numeric_figure_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "lining")?.encode(env)),
        2 => Ok(Atom::from_str(env, "oldstyle")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_variant_numeric_spacing_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "proportional")?.encode(env)),
        2 => Ok(Atom::from_str(env, "tabular")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_variant_numeric_fraction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "diagonal")?.encode(env)),
        2 => Ok(Atom::from_str(env, "stacked")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_variant_caps_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "small")?.encode(env)),
        2 => Ok(Atom::from_str(env, "all_small")?.encode(env)),
        3 => Ok(Atom::from_str(env, "petite")?.encode(env)),
        4 => Ok(Atom::from_str(env, "all_petite")?.encode(env)),
        5 => Ok(Atom::from_str(env, "unicase")?.encode(env)),
        6 => Ok(Atom::from_str(env, "titling")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_variant_position_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "sub")?.encode(env)),
        2 => Ok(Atom::from_str(env, "super")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "italic")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_semantic_weight_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "bold")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_semantic_italic_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "italic")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_code_snapshot_state_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "initial")?.encode(env)),
        1 => Ok(Atom::from_str(env, "snapshotting")?.encode(env)),
        2 => Ok(Atom::from_str(env, "ok")?.encode(env)),
        3 => Ok(Atom::from_str(env, "snapshot_error")?.encode(env)),
        4 => Ok(Atom::from_str(env, "llm_in_progress")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_snapshot_capture_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "full")?.encode(env)),
        1 => Ok(Atom::from_str(env, "partial")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_code_source_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeSourceInfo")?;
    term = term.map_put(
        Atom::from_str(env, "origin_reference_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "origin_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "linked_snapshot_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "capture_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_blob_ref")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_element_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "origin_reference_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "origin_node_id")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "linked_snapshot_id")?, value)?;
            }
            4 => {
                let value = decode_snapshot_capture_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "capture_mode")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_blob_ref")?, value)?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_element_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeSourceInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_object_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "web_layer")?.encode(env)),
        1 => Ok(Atom::from_str(env, "web_interaction")?.encode(env)),
        2 => Ok(Atom::from_str(env, "native_layer")?.encode(env)),
        3 => Ok(Atom::from_str(env, "animation_preset")?.encode(env)),
        4 => Ok(Atom::from_str(env, "tool")?.encode(env)),
        5 => Ok(Atom::from_str(env, "custom_effect")?.encode(env)),
        6 => Ok(Atom::from_str(env, "plugin")?.encode(env)),
        7 => Ok(Atom::from_str(env, "web_layer_generic")?.encode(env)),
        8 => Ok(Atom::from_str(env, "custom_fill")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_custom_tool_artifact_ref_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CustomToolArtifactRef",
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_tool_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_tool_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "published_custom_tool_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "published_custom_tool_version_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_tool_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_tool_version")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "published_custom_tool_id")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(
                    Atom::from_str(env, "published_custom_tool_version_id")?,
                    value,
                )?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CustomToolArtifactRef",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_lock_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "all")?.encode(env)),
        2 => Ok(Atom::from_str(env, "background_only")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_open_type_feature_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "pcap")?.encode(env)),
        1 => Ok(Atom::from_str(env, "c2_pc")?.encode(env)),
        2 => Ok(Atom::from_str(env, "case")?.encode(env)),
        3 => Ok(Atom::from_str(env, "cpsp")?.encode(env)),
        4 => Ok(Atom::from_str(env, "titl")?.encode(env)),
        5 => Ok(Atom::from_str(env, "unic")?.encode(env)),
        6 => Ok(Atom::from_str(env, "zero")?.encode(env)),
        7 => Ok(Atom::from_str(env, "sinf")?.encode(env)),
        8 => Ok(Atom::from_str(env, "ordn")?.encode(env)),
        9 => Ok(Atom::from_str(env, "afrc")?.encode(env)),
        10 => Ok(Atom::from_str(env, "dnom")?.encode(env)),
        11 => Ok(Atom::from_str(env, "numr")?.encode(env)),
        12 => Ok(Atom::from_str(env, "liga")?.encode(env)),
        13 => Ok(Atom::from_str(env, "clig")?.encode(env)),
        14 => Ok(Atom::from_str(env, "dlig")?.encode(env)),
        15 => Ok(Atom::from_str(env, "hlig")?.encode(env)),
        16 => Ok(Atom::from_str(env, "rlig")?.encode(env)),
        17 => Ok(Atom::from_str(env, "aalt")?.encode(env)),
        18 => Ok(Atom::from_str(env, "calt")?.encode(env)),
        19 => Ok(Atom::from_str(env, "rclt")?.encode(env)),
        20 => Ok(Atom::from_str(env, "salt")?.encode(env)),
        21 => Ok(Atom::from_str(env, "rvrn")?.encode(env)),
        22 => Ok(Atom::from_str(env, "vert")?.encode(env)),
        23 => Ok(Atom::from_str(env, "swsh")?.encode(env)),
        24 => Ok(Atom::from_str(env, "cswh")?.encode(env)),
        25 => Ok(Atom::from_str(env, "nalt")?.encode(env)),
        26 => Ok(Atom::from_str(env, "ccmp")?.encode(env)),
        27 => Ok(Atom::from_str(env, "stch")?.encode(env)),
        28 => Ok(Atom::from_str(env, "hist")?.encode(env)),
        29 => Ok(Atom::from_str(env, "size")?.encode(env)),
        30 => Ok(Atom::from_str(env, "ornm")?.encode(env)),
        31 => Ok(Atom::from_str(env, "ital")?.encode(env)),
        32 => Ok(Atom::from_str(env, "rand")?.encode(env)),
        33 => Ok(Atom::from_str(env, "dtls")?.encode(env)),
        34 => Ok(Atom::from_str(env, "flac")?.encode(env)),
        35 => Ok(Atom::from_str(env, "mgrk")?.encode(env)),
        36 => Ok(Atom::from_str(env, "ssty")?.encode(env)),
        37 => Ok(Atom::from_str(env, "kern")?.encode(env)),
        38 => Ok(Atom::from_str(env, "fwid")?.encode(env)),
        39 => Ok(Atom::from_str(env, "hwid")?.encode(env)),
        40 => Ok(Atom::from_str(env, "halt")?.encode(env)),
        41 => Ok(Atom::from_str(env, "twid")?.encode(env)),
        42 => Ok(Atom::from_str(env, "qwid")?.encode(env)),
        43 => Ok(Atom::from_str(env, "pwid")?.encode(env)),
        44 => Ok(Atom::from_str(env, "just")?.encode(env)),
        45 => Ok(Atom::from_str(env, "lfbd")?.encode(env)),
        46 => Ok(Atom::from_str(env, "opbd")?.encode(env)),
        47 => Ok(Atom::from_str(env, "rtbd")?.encode(env)),
        48 => Ok(Atom::from_str(env, "palt")?.encode(env)),
        49 => Ok(Atom::from_str(env, "pkna")?.encode(env)),
        50 => Ok(Atom::from_str(env, "ltra")?.encode(env)),
        51 => Ok(Atom::from_str(env, "ltrm")?.encode(env)),
        52 => Ok(Atom::from_str(env, "rtla")?.encode(env)),
        53 => Ok(Atom::from_str(env, "rtlm")?.encode(env)),
        54 => Ok(Atom::from_str(env, "abrv")?.encode(env)),
        55 => Ok(Atom::from_str(env, "abvm")?.encode(env)),
        56 => Ok(Atom::from_str(env, "abvs")?.encode(env)),
        57 => Ok(Atom::from_str(env, "valt")?.encode(env)),
        58 => Ok(Atom::from_str(env, "vhal")?.encode(env)),
        59 => Ok(Atom::from_str(env, "blwf")?.encode(env)),
        60 => Ok(Atom::from_str(env, "blwm")?.encode(env)),
        61 => Ok(Atom::from_str(env, "blws")?.encode(env)),
        62 => Ok(Atom::from_str(env, "akhn")?.encode(env)),
        63 => Ok(Atom::from_str(env, "cjct")?.encode(env)),
        64 => Ok(Atom::from_str(env, "cfar")?.encode(env)),
        65 => Ok(Atom::from_str(env, "cpct")?.encode(env)),
        66 => Ok(Atom::from_str(env, "curs")?.encode(env)),
        67 => Ok(Atom::from_str(env, "dist")?.encode(env)),
        68 => Ok(Atom::from_str(env, "expt")?.encode(env)),
        69 => Ok(Atom::from_str(env, "falt")?.encode(env)),
        70 => Ok(Atom::from_str(env, "fina")?.encode(env)),
        71 => Ok(Atom::from_str(env, "fin2")?.encode(env)),
        72 => Ok(Atom::from_str(env, "fin3")?.encode(env)),
        73 => Ok(Atom::from_str(env, "half")?.encode(env)),
        74 => Ok(Atom::from_str(env, "haln")?.encode(env)),
        75 => Ok(Atom::from_str(env, "hkna")?.encode(env)),
        76 => Ok(Atom::from_str(env, "hngl")?.encode(env)),
        77 => Ok(Atom::from_str(env, "hojo")?.encode(env)),
        78 => Ok(Atom::from_str(env, "init")?.encode(env)),
        79 => Ok(Atom::from_str(env, "isol")?.encode(env)),
        80 => Ok(Atom::from_str(env, "jp78")?.encode(env)),
        81 => Ok(Atom::from_str(env, "jp83")?.encode(env)),
        82 => Ok(Atom::from_str(env, "jp90")?.encode(env)),
        83 => Ok(Atom::from_str(env, "jp04")?.encode(env)),
        84 => Ok(Atom::from_str(env, "ljmo")?.encode(env)),
        85 => Ok(Atom::from_str(env, "locl")?.encode(env)),
        86 => Ok(Atom::from_str(env, "mark")?.encode(env)),
        87 => Ok(Atom::from_str(env, "medi")?.encode(env)),
        88 => Ok(Atom::from_str(env, "med2")?.encode(env)),
        89 => Ok(Atom::from_str(env, "mkmk")?.encode(env)),
        90 => Ok(Atom::from_str(env, "nlck")?.encode(env)),
        91 => Ok(Atom::from_str(env, "nukt")?.encode(env)),
        92 => Ok(Atom::from_str(env, "pref")?.encode(env)),
        93 => Ok(Atom::from_str(env, "pres")?.encode(env)),
        94 => Ok(Atom::from_str(env, "vpal")?.encode(env)),
        95 => Ok(Atom::from_str(env, "pstf")?.encode(env)),
        96 => Ok(Atom::from_str(env, "psts")?.encode(env)),
        97 => Ok(Atom::from_str(env, "rkrf")?.encode(env)),
        98 => Ok(Atom::from_str(env, "rphf")?.encode(env)),
        99 => Ok(Atom::from_str(env, "ruby")?.encode(env)),
        100 => Ok(Atom::from_str(env, "smpl")?.encode(env)),
        101 => Ok(Atom::from_str(env, "tjmo")?.encode(env)),
        102 => Ok(Atom::from_str(env, "tnam")?.encode(env)),
        103 => Ok(Atom::from_str(env, "trad")?.encode(env)),
        104 => Ok(Atom::from_str(env, "vatu")?.encode(env)),
        105 => Ok(Atom::from_str(env, "vjmo")?.encode(env)),
        106 => Ok(Atom::from_str(env, "vkna")?.encode(env)),
        107 => Ok(Atom::from_str(env, "vkrn")?.encode(env)),
        108 => Ok(Atom::from_str(env, "vrtr")?.encode(env)),
        109 => Ok(Atom::from_str(env, "vrt2")?.encode(env)),
        110 => Ok(Atom::from_str(env, "ss01")?.encode(env)),
        111 => Ok(Atom::from_str(env, "ss02")?.encode(env)),
        112 => Ok(Atom::from_str(env, "ss03")?.encode(env)),
        113 => Ok(Atom::from_str(env, "ss04")?.encode(env)),
        114 => Ok(Atom::from_str(env, "ss05")?.encode(env)),
        115 => Ok(Atom::from_str(env, "ss06")?.encode(env)),
        116 => Ok(Atom::from_str(env, "ss07")?.encode(env)),
        117 => Ok(Atom::from_str(env, "ss08")?.encode(env)),
        118 => Ok(Atom::from_str(env, "ss09")?.encode(env)),
        119 => Ok(Atom::from_str(env, "ss10")?.encode(env)),
        120 => Ok(Atom::from_str(env, "ss11")?.encode(env)),
        121 => Ok(Atom::from_str(env, "ss12")?.encode(env)),
        122 => Ok(Atom::from_str(env, "ss13")?.encode(env)),
        123 => Ok(Atom::from_str(env, "ss14")?.encode(env)),
        124 => Ok(Atom::from_str(env, "ss15")?.encode(env)),
        125 => Ok(Atom::from_str(env, "ss16")?.encode(env)),
        126 => Ok(Atom::from_str(env, "ss17")?.encode(env)),
        127 => Ok(Atom::from_str(env, "ss18")?.encode(env)),
        128 => Ok(Atom::from_str(env, "ss19")?.encode(env)),
        129 => Ok(Atom::from_str(env, "ss20")?.encode(env)),
        130 => Ok(Atom::from_str(env, "cv01")?.encode(env)),
        131 => Ok(Atom::from_str(env, "cv02")?.encode(env)),
        132 => Ok(Atom::from_str(env, "cv03")?.encode(env)),
        133 => Ok(Atom::from_str(env, "cv04")?.encode(env)),
        134 => Ok(Atom::from_str(env, "cv05")?.encode(env)),
        135 => Ok(Atom::from_str(env, "cv06")?.encode(env)),
        136 => Ok(Atom::from_str(env, "cv07")?.encode(env)),
        137 => Ok(Atom::from_str(env, "cv08")?.encode(env)),
        138 => Ok(Atom::from_str(env, "cv09")?.encode(env)),
        139 => Ok(Atom::from_str(env, "cv10")?.encode(env)),
        140 => Ok(Atom::from_str(env, "cv11")?.encode(env)),
        141 => Ok(Atom::from_str(env, "cv12")?.encode(env)),
        142 => Ok(Atom::from_str(env, "cv13")?.encode(env)),
        143 => Ok(Atom::from_str(env, "cv14")?.encode(env)),
        144 => Ok(Atom::from_str(env, "cv15")?.encode(env)),
        145 => Ok(Atom::from_str(env, "cv16")?.encode(env)),
        146 => Ok(Atom::from_str(env, "cv17")?.encode(env)),
        147 => Ok(Atom::from_str(env, "cv18")?.encode(env)),
        148 => Ok(Atom::from_str(env, "cv19")?.encode(env)),
        149 => Ok(Atom::from_str(env, "cv20")?.encode(env)),
        150 => Ok(Atom::from_str(env, "cv21")?.encode(env)),
        151 => Ok(Atom::from_str(env, "cv22")?.encode(env)),
        152 => Ok(Atom::from_str(env, "cv23")?.encode(env)),
        153 => Ok(Atom::from_str(env, "cv24")?.encode(env)),
        154 => Ok(Atom::from_str(env, "cv25")?.encode(env)),
        155 => Ok(Atom::from_str(env, "cv26")?.encode(env)),
        156 => Ok(Atom::from_str(env, "cv27")?.encode(env)),
        157 => Ok(Atom::from_str(env, "cv28")?.encode(env)),
        158 => Ok(Atom::from_str(env, "cv29")?.encode(env)),
        159 => Ok(Atom::from_str(env, "cv30")?.encode(env)),
        160 => Ok(Atom::from_str(env, "cv31")?.encode(env)),
        161 => Ok(Atom::from_str(env, "cv32")?.encode(env)),
        162 => Ok(Atom::from_str(env, "cv33")?.encode(env)),
        163 => Ok(Atom::from_str(env, "cv34")?.encode(env)),
        164 => Ok(Atom::from_str(env, "cv35")?.encode(env)),
        165 => Ok(Atom::from_str(env, "cv36")?.encode(env)),
        166 => Ok(Atom::from_str(env, "cv37")?.encode(env)),
        167 => Ok(Atom::from_str(env, "cv38")?.encode(env)),
        168 => Ok(Atom::from_str(env, "cv39")?.encode(env)),
        169 => Ok(Atom::from_str(env, "cv40")?.encode(env)),
        170 => Ok(Atom::from_str(env, "cv41")?.encode(env)),
        171 => Ok(Atom::from_str(env, "cv42")?.encode(env)),
        172 => Ok(Atom::from_str(env, "cv43")?.encode(env)),
        173 => Ok(Atom::from_str(env, "cv44")?.encode(env)),
        174 => Ok(Atom::from_str(env, "cv45")?.encode(env)),
        175 => Ok(Atom::from_str(env, "cv46")?.encode(env)),
        176 => Ok(Atom::from_str(env, "cv47")?.encode(env)),
        177 => Ok(Atom::from_str(env, "cv48")?.encode(env)),
        178 => Ok(Atom::from_str(env, "cv49")?.encode(env)),
        179 => Ok(Atom::from_str(env, "cv50")?.encode(env)),
        180 => Ok(Atom::from_str(env, "cv51")?.encode(env)),
        181 => Ok(Atom::from_str(env, "cv52")?.encode(env)),
        182 => Ok(Atom::from_str(env, "cv53")?.encode(env)),
        183 => Ok(Atom::from_str(env, "cv54")?.encode(env)),
        184 => Ok(Atom::from_str(env, "cv55")?.encode(env)),
        185 => Ok(Atom::from_str(env, "cv56")?.encode(env)),
        186 => Ok(Atom::from_str(env, "cv57")?.encode(env)),
        187 => Ok(Atom::from_str(env, "cv58")?.encode(env)),
        188 => Ok(Atom::from_str(env, "cv59")?.encode(env)),
        189 => Ok(Atom::from_str(env, "cv60")?.encode(env)),
        190 => Ok(Atom::from_str(env, "cv61")?.encode(env)),
        191 => Ok(Atom::from_str(env, "cv62")?.encode(env)),
        192 => Ok(Atom::from_str(env, "cv63")?.encode(env)),
        193 => Ok(Atom::from_str(env, "cv64")?.encode(env)),
        194 => Ok(Atom::from_str(env, "cv65")?.encode(env)),
        195 => Ok(Atom::from_str(env, "cv66")?.encode(env)),
        196 => Ok(Atom::from_str(env, "cv67")?.encode(env)),
        197 => Ok(Atom::from_str(env, "cv68")?.encode(env)),
        198 => Ok(Atom::from_str(env, "cv69")?.encode(env)),
        199 => Ok(Atom::from_str(env, "cv70")?.encode(env)),
        200 => Ok(Atom::from_str(env, "cv71")?.encode(env)),
        201 => Ok(Atom::from_str(env, "cv72")?.encode(env)),
        202 => Ok(Atom::from_str(env, "cv73")?.encode(env)),
        203 => Ok(Atom::from_str(env, "cv74")?.encode(env)),
        204 => Ok(Atom::from_str(env, "cv75")?.encode(env)),
        205 => Ok(Atom::from_str(env, "cv76")?.encode(env)),
        206 => Ok(Atom::from_str(env, "cv77")?.encode(env)),
        207 => Ok(Atom::from_str(env, "cv78")?.encode(env)),
        208 => Ok(Atom::from_str(env, "cv79")?.encode(env)),
        209 => Ok(Atom::from_str(env, "cv80")?.encode(env)),
        210 => Ok(Atom::from_str(env, "cv81")?.encode(env)),
        211 => Ok(Atom::from_str(env, "cv82")?.encode(env)),
        212 => Ok(Atom::from_str(env, "cv83")?.encode(env)),
        213 => Ok(Atom::from_str(env, "cv84")?.encode(env)),
        214 => Ok(Atom::from_str(env, "cv85")?.encode(env)),
        215 => Ok(Atom::from_str(env, "cv86")?.encode(env)),
        216 => Ok(Atom::from_str(env, "cv87")?.encode(env)),
        217 => Ok(Atom::from_str(env, "cv88")?.encode(env)),
        218 => Ok(Atom::from_str(env, "cv89")?.encode(env)),
        219 => Ok(Atom::from_str(env, "cv90")?.encode(env)),
        220 => Ok(Atom::from_str(env, "cv91")?.encode(env)),
        221 => Ok(Atom::from_str(env, "cv92")?.encode(env)),
        222 => Ok(Atom::from_str(env, "cv93")?.encode(env)),
        223 => Ok(Atom::from_str(env, "cv94")?.encode(env)),
        224 => Ok(Atom::from_str(env, "cv95")?.encode(env)),
        225 => Ok(Atom::from_str(env, "cv96")?.encode(env)),
        226 => Ok(Atom::from_str(env, "cv97")?.encode(env)),
        227 => Ok(Atom::from_str(env, "cv98")?.encode(env)),
        228 => Ok(Atom::from_str(env, "cv99")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_export_constraint_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ExportConstraint",
    )?;
    let value = decode_export_constraint_type_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "type")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "value")?, value)?;
    Ok(term)
}
fn decode_guid_mapping_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GUIDMapping")?;
    let value = decode_guid_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "from")?, value)?;
    let value = decode_guid_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "to")?, value)?;
    Ok(term)
}
fn decode_image_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Image")?;
    term = term.map_put(Atom::from_str(env, "hash")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "data_blob")?,
        rustler::types::atom::nil(),
    )?;
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
fn decode_video_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Video")?;
    term = term.map_put(Atom::from_str(env, "hash")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "s3_url")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "hash")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "s3_url")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Video",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_paste_source_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PasteSource")?;
    term = term.map_put(
        Atom::from_str(env, "src_file")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "src_node")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "src_file")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "src_node")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PasteSource",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_filter_color_adjust_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.FilterColorAdjust",
    )?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "tint")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "shadows")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "highlights")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "detail")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "exposure")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "vignette")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "temperature")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "vibrance")?, value)?;
    Ok(term)
}
fn decode_paint_filter_message_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PaintFilterMessage",
    )?;
    term = term.map_put(Atom::from_str(env, "tint")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "shadows")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "highlights")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "detail")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "exposure")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vignette")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "temperature")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vibrance")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "contrast")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "brightness")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "tint")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "shadows")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "highlights")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "detail")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "exposure")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "vignette")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "temperature")?, value)?;
            }
            8 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "vibrance")?, value)?;
            }
            9 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "contrast")?, value)?;
            }
            10 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "brightness")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PaintFilterMessage",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_paint_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Paint")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "opacity")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "visible")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "blend_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "stops")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "transform")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "image")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "image_thumbnail")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animated_image")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_frame")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "image_scale_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "image_should_color_manage")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "scale")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "filter_color_adjust")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paint_filter")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "emoji_code_points")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "video")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "original_image_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "original_image_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "opacity_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "image_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stops_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumb_hash_base64")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumb_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "spacing")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "pattern_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "pattern_tile_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vertical_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "horizontal_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "alt_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "noise_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "density")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "noise_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_effect_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_assignments")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_paint_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "opacity")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "visible")?, value)?;
            }
            5 => {
                let value = decode_blend_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "blend_mode")?, value)?;
            }
            6 => {
                let value = decoder
                    .read_repeated(|decoder| decode_color_stop_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stops")?, value)?;
            }
            7 => {
                let value = decode_matrix_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transform")?, value)?;
            }
            8 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image")?, value)?;
            }
            9 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_thumbnail")?, value)?;
            }
            16 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animated_image")?, value)?;
            }
            17 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "animation_frame")?, value)?;
            }
            10 => {
                let value = decode_image_scale_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_scale_mode")?, value)?;
            }
            22 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "image_should_color_manage")?, value)?;
            }
            11 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotation")?, value)?;
            }
            12 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "scale")?, value)?;
            }
            13 => {
                let value = decode_filter_color_adjust_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "filter_color_adjust")?, value)?;
            }
            14 => {
                let value = decode_paint_filter_message_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "paint_filter")?, value)?;
            }
            15 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(Atom::from_str(env, "emoji_code_points")?, value)?;
            }
            18 => {
                let value = decode_video_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "video")?, value)?;
            }
            19 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "original_image_width")?, value)?;
            }
            20 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "original_image_height")?, value)?;
            }
            38 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "opacity_var")?, value)?;
            }
            21 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_var")?, value)?;
            }
            31 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_var")?, value)?;
            }
            23 => {
                let value = decoder
                    .read_repeated(|decoder| decode_color_stop_var_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stops_var")?, value)?;
            }
            24 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumb_hash_base64")?, value)?;
            }
            25 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "thumb_hash")?, value)?;
            }
            26 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "source_node_id")?, value)?;
            }
            27 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "spacing")?, value)?;
            }
            37 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "pattern_spacing")?, value)?;
            }
            28 => {
                let value = decode_pattern_tile_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "pattern_tile_type")?, value)?;
            }
            29 => {
                let value = decode_pattern_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vertical_alignment")?, value)?;
            }
            30 => {
                let value = decode_pattern_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "horizontal_alignment")?, value)?;
            }
            32 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            33 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "alt_text")?, value)?;
            }
            34 => {
                let value = decode_noise_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_type")?, value)?;
            }
            35 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "density")?, value)?;
            }
            36 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_size")?, value)?;
            }
            39 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_effect_id")?, value)?;
            }
            40 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_assignment_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_assignments")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Paint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_noise_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "multitone")?.encode(env)),
        1 => Ok(Atom::from_str(env, "monotone")?.encode(env)),
        2 => Ok(Atom::from_str(env, "duotone")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_pattern_tile_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "rectangular")?.encode(env)),
        1 => Ok(Atom::from_str(env, "horizontal_hexagonal")?.encode(env)),
        2 => Ok(Atom::from_str(env, "vertical_hexagonal")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_pattern_alignment_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "start")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "end")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_font_meta_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FontMetaData")?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "font_line_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_digest")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_weight")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_font_name_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "font_line_height")?, value)?;
            }
            3 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "font_digest")?, value)?;
            }
            4 => {
                let value = decode_font_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_style")?, value)?;
            }
            5 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "font_weight")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FontMetaData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_font_variation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FontVariation")?;
    term = term.map_put(
        Atom::from_str(env, "axis_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "axis_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "axis_tag")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "axis_name")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FontVariation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_text_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TextData")?;
    term = term.map_put(
        Atom::from_str(env, "characters")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "character_style_i_ds")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_override_table")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "lines")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "layout_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fallback_fonts")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_content_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "baselines")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "glyphs")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "decorations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "blockquotes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_meta_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hyperlink_boxes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "truncation_start_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "truncated_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "logical_index_to_character_offset_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mention_boxes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_lines")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "characters")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(Atom::from_str(env, "character_style_i_ds")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "style_override_table")?, value)?;
            }
            12 => {
                let value = decoder
                    .read_repeated(|decoder| decode_text_line_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "lines")?, value)?;
            }
            8 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "layout_version")?, value)?;
            }
            10 => {
                let value =
                    decoder.read_repeated(|decoder| decode_font_name_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "fallback_fonts")?, value)?;
            }
            17 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "min_content_height")?, value)?;
            }
            4 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "layout_size")?, value)?;
            }
            5 => {
                let value =
                    decoder.read_repeated(|decoder| decode_baseline_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "baselines")?, value)?;
            }
            6 => {
                let value =
                    decoder.read_repeated(|decoder| decode_glyph_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "glyphs")?, value)?;
            }
            7 => {
                let value = decoder
                    .read_repeated(|decoder| decode_decoration_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "decorations")?, value)?;
            }
            16 => {
                let value = decoder
                    .read_repeated(|decoder| decode_blockquote_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "blockquotes")?, value)?;
            }
            9 => {
                let value = decoder
                    .read_repeated(|decoder| decode_font_meta_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "font_meta_data")?, value)?;
            }
            11 => {
                let value = decoder
                    .read_repeated(|decoder| decode_hyperlink_box_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "hyperlink_boxes")?, value)?;
            }
            13 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "truncation_start_index")?, value)?;
            }
            14 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "truncated_height")?, value)?;
            }
            15 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(
                    Atom::from_str(env, "logical_index_to_character_offset_map")?,
                    value,
                )?;
            }
            18 => {
                let value = decoder
                    .read_repeated(|decoder| decode_mention_box_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "mention_boxes")?, value)?;
            }
            19 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_derived_text_line_data_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "derived_lines")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TextData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_derived_text_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DerivedTextData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "baselines")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "glyphs")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "decorations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "blockquotes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_meta_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hyperlink_boxes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "truncation_start_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "truncated_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "logical_index_to_character_offset_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mention_boxes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_lines")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "layout_size")?, value)?;
            }
            2 => {
                let value =
                    decoder.read_repeated(|decoder| decode_baseline_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "baselines")?, value)?;
            }
            3 => {
                let value =
                    decoder.read_repeated(|decoder| decode_glyph_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "glyphs")?, value)?;
            }
            4 => {
                let value = decoder
                    .read_repeated(|decoder| decode_decoration_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "decorations")?, value)?;
            }
            5 => {
                let value = decoder
                    .read_repeated(|decoder| decode_blockquote_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "blockquotes")?, value)?;
            }
            6 => {
                let value = decoder
                    .read_repeated(|decoder| decode_font_meta_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "font_meta_data")?, value)?;
            }
            7 => {
                let value = decoder
                    .read_repeated(|decoder| decode_hyperlink_box_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "hyperlink_boxes")?, value)?;
            }
            8 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "truncation_start_index")?, value)?;
            }
            9 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "truncated_height")?, value)?;
            }
            10 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(
                    Atom::from_str(env, "logical_index_to_character_offset_map")?,
                    value,
                )?;
            }
            11 => {
                let value = decoder
                    .read_repeated(|decoder| decode_mention_box_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "mention_boxes")?, value)?;
            }
            12 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_derived_text_line_data_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "derived_lines")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DerivedTextData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_hyperlink_box_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.HyperlinkBox")?;
    term = term.map_put(Atom::from_str(env, "bounds")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "cms_target")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "open_in_new_tab")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hyperlink_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_rect_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "bounds")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            5 => {
                let value = decode_cms_item_page_target_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_target")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "open_in_new_tab")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "hyperlink_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding HyperlinkBox",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_mention_box_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.MentionBox")?;
    term = term.map_put(Atom::from_str(env, "bounds")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "start_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_valid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mention_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_rect_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "bounds")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "start_index")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "end_index")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_valid")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "mention_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MentionBox",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_baseline_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Baseline")?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "width")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "line_y")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "line_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_ascent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ignore_leading_trim")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "first_character")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_character")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "width")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "line_y")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "line_height")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "line_ascent")?, value)?;
            }
            8 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "ignore_leading_trim")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "first_character")?, value)?;
            }
            6 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "end_character")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Baseline",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_glyph_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Glyph")?;
    term = term.map_put(
        Atom::from_str(env, "commands_blob")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "first_character")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "advance")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "emoji_code_points")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "emoji_image_set")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "commands_blob")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "font_size")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "first_character")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "advance")?, value)?;
            }
            7 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(Atom::from_str(env, "emoji_code_points")?, value)?;
            }
            8 => {
                let value = decode_emoji_image_set_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "emoji_image_set")?, value)?;
            }
            9 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotation")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Glyph",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_decoration_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Decoration")?;
    term = term.map_put(Atom::from_str(env, "rects")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_rect_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "rects")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Decoration",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_blockquote_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Blockquote")?;
    term = term.map_put(
        Atom::from_str(env, "vertical_bar")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "quote_mark_bounds")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_rect_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vertical_bar")?, value)?;
            }
            2 => {
                let value = decode_rect_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "quote_mark_bounds")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Blockquote",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_vector_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VectorData")?;
    term = term.map_put(
        Atom::from_str(env, "vector_network_blob")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "normalized_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_override_table")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "vector_network_blob")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "normalized_size")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "style_override_table")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VectorData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_text_path_start_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TextPathStart")?;
    term = term.map_put(Atom::from_str(env, "t_value")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "forward")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "t_value")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "forward")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TextPathStart",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_path_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GUIDPath")?;
    term = term.map_put(Atom::from_str(env, "guids")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "guids")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDPath",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_symbol_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SymbolData")?;
    term = term.map_put(
        Atom::from_str(env, "symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_overrides")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "uniform_scale_factor")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_id")?, value)?;
            }
            2 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "symbol_overrides")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "uniform_scale_factor")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SymbolData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_path_mapping_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GUIDPathMapping",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "path")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "path")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDPathMapping",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_derived_breakpoint_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DerivedBreakpointData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DerivedBreakpointData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_generation_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeGenerationData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "use_fine_grained_syncing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "diff_only_removals")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "use_fine_grained_syncing")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "diff_only_removals")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeGenerationData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_derived_immutable_frame_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DerivedImmutableFrameData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DerivedImmutableFrameData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_jsx_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.JsxData")?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding JsxData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_derived_jsx_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.DerivedJsxData")?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DerivedJsxData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_asset_id_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AssetIdMap")?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_asset_id_entry_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AssetIdMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_asset_id_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AssetIdEntry")?;
    term = term.map_put(
        Atom::from_str(env, "asset_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "asset_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "asset_key")?, value)?;
            }
            2 => {
                let value = decode_asset_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AssetIdEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_asset_ref_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AssetRef")?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AssetRef",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_asset_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AssetId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "state_group_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            3 => {
                let value = decode_state_group_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state_group_id")?, value)?;
            }
            4 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            5 => {
                let value = decode_symbol_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_id")?, value)?;
            }
            6 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_id")?, value)?;
            }
            7 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_set_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AssetId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_state_group_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.StateGroupId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StateGroupId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_style_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.StyleId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StyleId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_symbol_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SymbolId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SymbolId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VariableID")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableID",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_override_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableOverrideId",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableOverrideId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_set_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VariableSetID")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableSetID",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_theme_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ThemeID")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ThemeID",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_library_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeLibraryId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeLibraryId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_file_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeFileId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeFileId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_component_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CodeComponentId",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeComponentId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_canvas_node_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CanvasNodeId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "state_group_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_symbol_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_id")?, value)?;
            }
            3 => {
                let value = decode_state_group_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state_group_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CanvasNodeId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_index_range_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.IndexRange")?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "start_index")?, value)?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "end_index_exclusive")?, value)?;
    Ok(term)
}
fn decode_collaborative_text_op_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CollaborativeTextOpID",
    )?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "session_id")?, value)?;
    let value = decoder.read_var_uint()?;
    term = term.map_put(Atom::from_str(env, "counter_id")?, value)?;
    Ok(term)
}
fn decode_collaborative_text_op_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "insert")?.encode(env)),
        1 => Ok(Atom::from_str(env, "delete")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_collaborative_text_stripped_op_run_with_i_ds_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CollaborativeTextStrippedOpRunWithIDs",
    )?;
    term = term.map_put(
        Atom::from_str(env, "first_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "run_length")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rebased_on_op_ids")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_collaborative_text_op_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "first_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "run_length")?, value)?;
            }
            3 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_id_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "parent_ids")?, value)?;
            }
            4 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_id_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "rebased_on_op_ids")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CollaborativeTextStrippedOpRunWithIDs",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_collaborative_text_stripped_op_run_with_loc_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CollaborativeTextStrippedOpRunWithLoc",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "range")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "range_should_be_iterated_in_reverse")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "content_bytes_in_buffer")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rebased_range")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_collaborative_text_op_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_index_range_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "range")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "range_should_be_iterated_in_reverse")?,
                    value,
                )?;
            }
            4 => {
                let value = decode_index_range_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "content_bytes_in_buffer")?, value)?;
            }
            5 => {
                let value = decode_index_range_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rebased_range")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CollaborativeTextStrippedOpRunWithLoc",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_collaborative_text_op_run_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CollaborativeTextOpRun",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "parent_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "range")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "range_should_be_iterated_in_reverse")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "content")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "rebased_on_op_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rebased_range")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_collaborative_text_op_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_id_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "parent_ids")?, value)?;
            }
            3 => {
                let value = decode_collaborative_text_op_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            4 => {
                let value = decode_index_range_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "range")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "range_should_be_iterated_in_reverse")?,
                    value,
                )?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "content")?, value)?;
            }
            7 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_id_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "rebased_on_op_ids")?, value)?;
            }
            8 => {
                let value = decode_index_range_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rebased_range")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CollaborativeTextOpRun",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_collaborative_plain_text_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CollaborativePlainText",
    )?;
    term = term.map_put(
        Atom::from_str(env, "history_ops_with_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "history_ops_with_loc")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "history_string_content_buffer")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "changes_to_append")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_stripped_op_run_with_i_ds_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "history_ops_with_ids")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_stripped_op_run_with_loc_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "history_ops_with_loc")?, value)?;
            }
            3 => {
                let value = decoder.read_byte_array(env)?;
                term =
                    term.map_put(Atom::from_str(env, "history_string_content_buffer")?, value)?;
            }
            4 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_run_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "changes_to_append")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CollaborativePlainText",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_responsive_text_style_variant_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ResponsiveTextStyleVariant",
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "fields")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "variable_font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_line_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_letter_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_paragraph_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "min_width")?, value)?;
            }
            2 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "fields")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_font_size")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_line_height")?, value)?;
            }
            5 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_letter_spacing")?, value)?;
            }
            6 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_paragraph_spacing")?, value)?;
            }
            7 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ResponsiveTextStyleVariant",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_flapp_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "poll")?.encode(env)),
        1 => Ok(Atom::from_str(env, "embed")?.encode(env)),
        2 => Ok(Atom::from_str(env, "facepile")?.encode(env)),
        3 => Ok(Atom::from_str(env, "alignment")?.encode(env)),
        4 => Ok(Atom::from_str(env, "youtube")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_slide_theme_props_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SlideThemeProps",
    )?;
    term = term.map_put(
        Atom::from_str(env, "theme_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_style_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_text_color_manually_selected")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_border_color_manually_selected")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "subscribed_theme_ref")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "schema_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_generated_from_design")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "theme_version")?, value)?;
            }
            2 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_set_id")?, value)?;
            }
            3 => {
                let value =
                    decoder.read_repeated(|decoder| decode_style_id_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "text_style_ids")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "is_text_color_manually_selected")?,
                    value,
                )?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "is_border_color_manually_selected")?,
                    value,
                )?;
            }
            6 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "subscribed_theme_ref")?, value)?;
            }
            7 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "schema_version")?, value)?;
            }
            8 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_generated_from_design")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlideThemeProps",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slide_theme_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SlideThemeMap")?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_slide_theme_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlideThemeMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slide_theme_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SlideThemeMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "theme_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "theme_props")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_theme_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "theme_id")?, value)?;
            }
            2 => {
                let value = decode_slide_theme_props_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "theme_props")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlideThemeMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_shared_symbol_reference_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SharedSymbolReference",
    )?;
    term = term.map_put(
        Atom::from_str(env, "file_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "version_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "guid_path_mappings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "bytes")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "library_guid_to_subscribing_guid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "unflattening_mappings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_unflattened")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "file_key")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "version_hash")?, value)?;
            }
            4 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "guid_path_mappings")?, value)?;
            }
            5 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "bytes")?, value)?;
            }
            6 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_mapping_from_decoder(env, decoder))?;
                term = term.map_put(
                    Atom::from_str(env, "library_guid_to_subscribing_guid")?,
                    value,
                )?;
            }
            7 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "component_key")?, value)?;
            }
            8 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "unflattening_mappings")?, value)?;
            }
            9 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_unflattened")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SharedSymbolReference",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_shared_component_master_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SharedComponentMasterData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "publishing_guid_path_to_team_library_guid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_unflattened")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "component_key")?, value)?;
            }
            2 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(
                    Atom::from_str(env, "publishing_guid_path_to_team_library_guid")?,
                    value,
                )?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_unflattened")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SharedComponentMasterData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_instance_override_stash_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InstanceOverrideStash",
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_path_of_swapped_instance")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "override_path_of_swapped_instance")?,
                    value,
                )?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "component_key")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InstanceOverrideStash",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_instance_override_stash_v2_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InstanceOverrideStashV2",
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_path_of_swapped_instance")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "local_symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "override_path_of_swapped_instance")?,
                    value,
                )?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "local_symbol_id")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InstanceOverrideStashV2",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_imported_code_file_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ImportedCodeFileEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_file_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_code_file_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_file_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ImportedCodeFileEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_imported_code_files_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ImportedCodeFiles",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_imported_code_file_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ImportedCodeFiles",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_blur_op_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "normal")?.encode(env)),
        1 => Ok(Atom::from_str(env, "progressive")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_repeat_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "linear")?.encode(env)),
        1 => Ok(Atom::from_str(env, "radial")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_unit_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "pixels")?.encode(env)),
        1 => Ok(Atom::from_str(env, "relative")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_repeat_order_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "forward")?.encode(env)),
        1 => Ok(Atom::from_str(env, "reverse")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_effect_axis_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "x")?.encode(env)),
        1 => Ok(Atom::from_str(env, "y")?.encode(env)),
        2 => Ok(Atom::from_str(env, "x_and_y")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_effect_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Effect")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "radius")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "visible")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "blend_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "spread")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "show_shadow_behind_node")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "radius_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spread_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "x_var")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "y_var")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "count")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "repeat_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "unit_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "order")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "blur_op_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "secondary_color")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "noise_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "seed")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "clip_to_shape")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "density")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "noise_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "opacity")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "refraction_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "specular_angle")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "specular_intensity")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "bevel_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "chromatic_aberration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "reflection_distance")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "refraction_intensity")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "refraction_radius_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "specular_angle_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "specular_intensity_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "chromatic_aberration_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "splay_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "refraction_intensity_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_effect_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_assignments")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_radius_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_offset_x_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_offset_y_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_offset_x_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_offset_y_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "noise_size_x_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "noise_size_y_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "density_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "effect_opacity_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "secondary_color_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_effect_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            3 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "radius")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "visible")?, value)?;
            }
            6 => {
                let value = decode_blend_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "blend_mode")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "spread")?, value)?;
            }
            8 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "show_shadow_behind_node")?, value)?;
            }
            9 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "radius_var")?, value)?;
            }
            10 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_var")?, value)?;
            }
            11 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "spread_var")?, value)?;
            }
            12 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "x_var")?, value)?;
            }
            13 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "y_var")?, value)?;
            }
            14 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "count")?, value)?;
            }
            15 => {
                let value = decode_repeat_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "repeat_type")?, value)?;
            }
            16 => {
                let value = decode_effect_axis_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            17 => {
                let value = decode_unit_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit_type")?, value)?;
            }
            18 => {
                let value = decode_repeat_order_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "order")?, value)?;
            }
            19 => {
                let value = decode_blur_op_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "blur_op_type")?, value)?;
            }
            20 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "start_offset")?, value)?;
            }
            28 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "end_offset")?, value)?;
            }
            21 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "start_radius")?, value)?;
            }
            2 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            24 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "secondary_color")?, value)?;
            }
            22 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_size")?, value)?;
            }
            29 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "seed")?, value)?;
            }
            23 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "clip_to_shape")?, value)?;
            }
            25 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "density")?, value)?;
            }
            26 => {
                let value = decode_noise_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_type")?, value)?;
            }
            27 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "opacity")?, value)?;
            }
            30 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "refraction_radius")?, value)?;
            }
            31 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "specular_angle")?, value)?;
            }
            32 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "specular_intensity")?, value)?;
            }
            33 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "bevel_size")?, value)?;
            }
            34 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "chromatic_aberration")?, value)?;
            }
            35 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "reflection_distance")?, value)?;
            }
            36 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "refraction_intensity")?, value)?;
            }
            37 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "refraction_radius_var")?, value)?;
            }
            38 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "specular_angle_var")?, value)?;
            }
            39 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "specular_intensity_var")?, value)?;
            }
            40 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "chromatic_aberration_var")?, value)?;
            }
            41 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "splay_var")?, value)?;
            }
            42 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "refraction_intensity_var")?, value)?;
            }
            43 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_effect_id")?, value)?;
            }
            44 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_assignment_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_assignments")?, value)?;
            }
            45 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "start_radius_var")?, value)?;
            }
            46 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "start_offset_x_var")?, value)?;
            }
            47 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "start_offset_y_var")?, value)?;
            }
            48 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "end_offset_x_var")?, value)?;
            }
            49 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "end_offset_y_var")?, value)?;
            }
            50 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_size_x_var")?, value)?;
            }
            51 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "noise_size_y_var")?, value)?;
            }
            52 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "density_var")?, value)?;
            }
            53 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "effect_opacity_var")?, value)?;
            }
            54 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "secondary_color_var")?, value)?;
            }
            55 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Effect",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_modifier_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "repeat")?.encode(env)),
        1 => Ok(Atom::from_str(env, "symmetry")?.encode(env)),
        2 => Ok(Atom::from_str(env, "skew")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_transform_modifier_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransformModifier",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "visible")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "count")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "repeat_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "unit_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "order")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "skew_x")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "skew_y")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_transform_modifier_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "visible")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "count")?, value)?;
            }
            5 => {
                let value = decode_repeat_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "repeat_type")?, value)?;
            }
            6 => {
                let value = decode_effect_axis_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            7 => {
                let value = decode_unit_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit_type")?, value)?;
            }
            8 => {
                let value = decode_repeat_order_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "order")?, value)?;
            }
            9 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "skew_x")?, value)?;
            }
            10 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "skew_y")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransformModifier",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_schema_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fixed_order")?.encode(env)),
        2 => Ok(Atom::from_str(env, "freeform")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_matrix4f_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Matrix4f")?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m00")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m01")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m02")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m03")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m10")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m11")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m12")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m13")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m20")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m21")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m22")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m23")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m30")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m31")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m32")?, value)?;
    let value = decoder.read_var_float(env)?;
    term = term.map_put(Atom::from_str(env, "m33")?, value)?;
    Ok(term)
}
fn decode_fixed_order_transform3d_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.FixedOrderTransform3d",
    )?;
    term = term.map_put(
        Atom::from_str(env, "perspective")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "translate_z")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotate_x")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotate_y")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotate_z")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "perspective")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "translate_z")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotate_x")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotate_y")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotate_z")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FixedOrderTransform3d",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_fn_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "matrix_3_d")?.encode(env)),
        2 => Ok(Atom::from_str(env, "perspective")?.encode(env)),
        3 => Ok(Atom::from_str(env, "translate_z")?.encode(env)),
        4 => Ok(Atom::from_str(env, "rotate_x")?.encode(env)),
        5 => Ok(Atom::from_str(env, "rotate_y")?.encode(env)),
        6 => Ok(Atom::from_str(env, "rotate_z")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_transform_fn_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransformFnValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "matrix3d")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "perspective")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotate_angle")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "translate_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_matrix4f_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "matrix3d")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "perspective")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotate_angle")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "translate_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransformFnValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_fn_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TransformFn")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_transform_fn_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_transform_fn_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransformFn",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_schema_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransformSchemaValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "fixed_order_transform3d")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transform_functions")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_fixed_order_transform3d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "fixed_order_transform3d")?, value)?;
            }
            2 => {
                let value = decoder
                    .read_repeated(|decoder| decode_transform_fn_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "transform_functions")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransformSchemaValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform3d_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Transform3d")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "backface_hidden")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_transform_schema_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_transform_schema_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "backface_hidden")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Transform3d",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_number_vector2_d_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.NumberVector2D")?;
    let value = decode_number_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "x")?, value)?;
    let value = decode_number_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "y")?, value)?;
    Ok(term)
}
fn decode_scene3d_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Scene3d")?;
    term = term.map_put(
        Atom::from_str(env, "perspective")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "perspective_origin")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "preserve3d")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "perspective")?, value)?;
            }
            2 => {
                let value = decode_number_vector2_d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "perspective_origin")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "preserve3d")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Scene3d",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transform_origin_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransformOrigin",
    )?;
    term = term.map_put(Atom::from_str(env, "x")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "y")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "x")?, value)?;
            }
            2 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "y")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransformOrigin",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TransitionInfo")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "duration")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_transition_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "duration")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prototype_device_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "preset")?.encode(env)),
        2 => Ok(Atom::from_str(env, "custom")?.encode(env)),
        3 => Ok(Atom::from_str(env, "presentation")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_device_rotation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "ccw_90")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_prototype_device_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PrototypeDevice",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "size")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "preset_identifier")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_prototype_device_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "size")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "preset_identifier")?, value)?;
            }
            4 => {
                let value = decode_device_rotation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rotation")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeDevice",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_overlay_position_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "center")?.encode(env)),
        1 => Ok(Atom::from_str(env, "top_left")?.encode(env)),
        2 => Ok(Atom::from_str(env, "top_center")?.encode(env)),
        3 => Ok(Atom::from_str(env, "top_right")?.encode(env)),
        4 => Ok(Atom::from_str(env, "bottom_left")?.encode(env)),
        5 => Ok(Atom::from_str(env, "bottom_center")?.encode(env)),
        6 => Ok(Atom::from_str(env, "bottom_right")?.encode(env)),
        7 => Ok(Atom::from_str(env, "manual")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_overlay_background_interaction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "close_on_click_outside")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_overlay_background_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "solid_color")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_overlay_background_appearance_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.OverlayBackgroundAppearance",
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_color")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_overlay_background_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "background_type")?, value)?;
            }
            2 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "background_color")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding OverlayBackgroundAppearance",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_navigation_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "navigate")?.encode(env)),
        1 => Ok(Atom::from_str(env, "overlay")?.encode(env)),
        2 => Ok(Atom::from_str(env, "swap")?.encode(env)),
        3 => Ok(Atom::from_str(env, "swap_state")?.encode(env)),
        4 => Ok(Atom::from_str(env, "scroll_to")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_export_color_profile_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "document")?.encode(env)),
        1 => Ok(Atom::from_str(env, "srgb")?.encode(env)),
        2 => Ok(Atom::from_str(env, "display_p3_v4")?.encode(env)),
        3 => Ok(Atom::from_str(env, "cmyk")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_export_background_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "solid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "transparent")?.encode(env)),
        2 => Ok(Atom::from_str(env, "grid")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_export_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ExportSettings")?;
    term = term.map_put(Atom::from_str(env, "suffix")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "image_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "constraint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "svg_data_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "svg_id_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "svg_outline_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "contents_only")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "svg_force_stroke_masks")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "use_absolute_bounds")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_profile")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "quality")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "use_bicubic_sampler")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "frame_rate")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "loop_count")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_type")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "suffix")?, value)?;
            }
            2 => {
                let value = decode_image_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_type")?, value)?;
            }
            3 => {
                let value = decode_export_constraint_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "constraint")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "svg_data_name")?, value)?;
            }
            5 => {
                let value = decode_export_svgid_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "svg_id_mode")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "svg_outline_text")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "contents_only")?, value)?;
            }
            8 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "svg_force_stroke_masks")?, value)?;
            }
            9 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "use_absolute_bounds")?, value)?;
            }
            10 => {
                let value = decode_export_color_profile_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_profile")?, value)?;
            }
            11 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "quality")?, value)?;
            }
            12 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "use_bicubic_sampler")?, value)?;
            }
            13 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "frame_rate")?, value)?;
            }
            14 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "loop_count")?, value)?;
            }
            15 => {
                let value = decode_export_background_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "background_type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ExportSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_export_svgid_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "if_needed")?.encode(env)),
        1 => Ok(Atom::from_str(env, "always")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_layout_grid_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.LayoutGrid")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "visible")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "num_sections")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "section_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "gutter_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "pattern")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "num_sections_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "offset_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "section_size_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "gutter_size_var")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_layout_grid_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_axis_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "visible")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "num_sections")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "section_size")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "gutter_size")?, value)?;
            }
            8 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            9 => {
                let value = decode_layout_grid_pattern_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "pattern")?, value)?;
            }
            10 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "num_sections_var")?, value)?;
            }
            11 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "offset_var")?, value)?;
            }
            12 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "section_size_var")?, value)?;
            }
            13 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "gutter_size_var")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LayoutGrid",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guide_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Guide")?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_axis_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Guide",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_path_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Path")?;
    term = term.map_put(
        Atom::from_str(env, "winding_rule")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "commands_blob")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_winding_rule_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "winding_rule")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "commands_blob")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Path",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_style_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fill")?.encode(env)),
        2 => Ok(Atom::from_str(env, "stroke")?.encode(env)),
        3 => Ok(Atom::from_str(env, "text")?.encode(env)),
        4 => Ok(Atom::from_str(env, "effect")?.encode(env)),
        5 => Ok(Atom::from_str(env, "export")?.encode(env)),
        6 => Ok(Atom::from_str(env, "grid")?.encode(env)),
        7 => Ok(Atom::from_str(env, "animation")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_brush_orientation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "forward")?.encode(env)),
        1 => Ok(Atom::from_str(env, "reverse")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_brush_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "stretch")?.encode(env)),
        1 => Ok(Atom::from_str(env, "scatter")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_dynamic_stroke_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DynamicStrokeSettings",
    )?;
    term = term.map_put(
        Atom::from_str(env, "frequency")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "wiggle")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "smoothen")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "frequency")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "wiggle")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "smoothen")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DynamicStrokeSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_scatter_stroke_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ScatterStrokeSettings",
    )?;
    term = term.map_put(Atom::from_str(env, "gap")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "wiggle")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "angular_jitter")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "size_jitter")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "gap")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "wiggle")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "angular_jitter")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotation")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "size_jitter")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ScatterStrokeSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_stretch_stroke_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.StretchStrokeSettings",
    )?;
    term = term.map_put(
        Atom::from_str(env, "orientation")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_brush_orientation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "orientation")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StretchStrokeSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_stroke_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.StrokeData")?;
    term = term.map_put(Atom::from_str(env, "strokes")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_stroke_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "strokes")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StrokeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_stroke_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Stroke")?;
    term = term.map_put(
        Atom::from_str(env, "stroke_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_weight_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_paint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_stroke_fill")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_cap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_cap_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_join")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "miter_limit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "dash_pattern")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "path_trim")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "stroke_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stroke_weight")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_weight_var")?, value)?;
            }
            4 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stroke_paint")?, value)?;
            }
            5 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_stroke_fill")?, value)?;
            }
            6 => {
                let value = decode_stroke_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_align")?, value)?;
            }
            7 => {
                let value = decode_stroke_cap_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_cap")?, value)?;
            }
            8 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_cap_size")?, value)?;
            }
            9 => {
                let value = decode_stroke_join_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_join")?, value)?;
            }
            10 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "miter_limit")?, value)?;
            }
            11 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(Atom::from_str(env, "dash_pattern")?, value)?;
            }
            12 => {
                let value = decode_optional_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "path_trim")?, value)?;
            }
            13 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stroke_offset")?, value)?;
            }
            14 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Stroke",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_width_point_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableWidthPoint",
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "ascent")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "descent")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "segment_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "ascent")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "descent")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "segment_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableWidthPoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_shared_style_reference_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SharedStyleReference",
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "version_hash")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "style_key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "version_hash")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SharedStyleReference",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_shared_style_master_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SharedStyleMasterData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sort_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "file_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "style_key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "sort_position")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "file_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SharedStyleMasterData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_scroll_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "scrolls")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fixed_when_child_of_scrolling_frame")?.encode(env)),
        2 => Ok(Atom::from_str(env, "sticky_scrolls")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_arc_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ArcData")?;
    term = term.map_put(
        Atom::from_str(env, "starting_angle")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ending_angle")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inner_radius")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "starting_angle")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "ending_angle")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "inner_radius")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ArcData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_symbol_link_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SymbolLink")?;
    term = term.map_put(Atom::from_str(env, "uri")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "display_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "display_text")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "uri")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "display_name")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "display_text")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SymbolLink",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_plugin_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PluginData")?;
    term = term.map_put(
        Atom::from_str(env, "plugin_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "plugin_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PluginData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_plugin_relaunch_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PluginRelaunchData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "plugin_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "message")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "command")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_tool_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "plugin_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "message")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "command")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            5 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_tool_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PluginRelaunchData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_multiplayer_field_version_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.MultiplayerFieldVersion",
    )?;
    term = term.map_put(Atom::from_str(env, "counter")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "session_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "counter")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "session_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MultiplayerFieldVersion",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_connector_magnet_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        2 => Ok(Atom::from_str(env, "top")?.encode(env)),
        3 => Ok(Atom::from_str(env, "left")?.encode(env)),
        4 => Ok(Atom::from_str(env, "bottom")?.encode(env)),
        5 => Ok(Atom::from_str(env, "right")?.encode(env)),
        6 => Ok(Atom::from_str(env, "center")?.encode(env)),
        7 => Ok(Atom::from_str(env, "auto_horizontal")?.encode(env)),
        8 => Ok(Atom::from_str(env, "edge")?.encode(env)),
        9 => Ok(Atom::from_str(env, "absolute")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_connector_endpoint_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ConnectorEndpoint",
    )?;
    term = term.map_put(
        Atom::from_str(env, "endpoint_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "magnet")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "relative_position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "endpoint_node_id")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            3 => {
                let value = decode_connector_magnet_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "magnet")?, value)?;
            }
            4 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "relative_position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ConnectorEndpoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_connector_control_point_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ConnectorControlPoint",
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ConnectorControlPoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_connector_text_section_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "middle_to_start")?.encode(env)),
        1 => Ok(Atom::from_str(env, "middle_to_end")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_connector_off_axis_offset_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "above")?.encode(env)),
        2 => Ok(Atom::from_str(env, "below")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_connector_text_midpoint_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ConnectorTextMidpoint",
    )?;
    term = term.map_put(Atom::from_str(env, "section")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "off_axis_offset")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_connector_text_section_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "section")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            3 => {
                let value = decode_connector_off_axis_offset_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "off_axis_offset")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ConnectorTextMidpoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_connector_line_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "elbowed")?.encode(env)),
        1 => Ok(Atom::from_str(env, "straight")?.encode(env)),
        2 => Ok(Atom::from_str(env, "curved")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_connector_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "manual")?.encode(env)),
        1 => Ok(Atom::from_str(env, "diagram")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_annotation_property_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "fill")?.encode(env)),
        1 => Ok(Atom::from_str(env, "stroke")?.encode(env)),
        2 => Ok(Atom::from_str(env, "width")?.encode(env)),
        3 => Ok(Atom::from_str(env, "height")?.encode(env)),
        4 => Ok(Atom::from_str(env, "min_width")?.encode(env)),
        5 => Ok(Atom::from_str(env, "min_height")?.encode(env)),
        6 => Ok(Atom::from_str(env, "max_width")?.encode(env)),
        7 => Ok(Atom::from_str(env, "max_height")?.encode(env)),
        8 => Ok(Atom::from_str(env, "stroke_width")?.encode(env)),
        9 => Ok(Atom::from_str(env, "corner_radius")?.encode(env)),
        10 => Ok(Atom::from_str(env, "effect")?.encode(env)),
        11 => Ok(Atom::from_str(env, "text_style")?.encode(env)),
        12 => Ok(Atom::from_str(env, "text_align_horizontal")?.encode(env)),
        13 => Ok(Atom::from_str(env, "font_family")?.encode(env)),
        14 => Ok(Atom::from_str(env, "font_size")?.encode(env)),
        15 => Ok(Atom::from_str(env, "font_weight")?.encode(env)),
        16 => Ok(Atom::from_str(env, "line_height")?.encode(env)),
        17 => Ok(Atom::from_str(env, "letter_spacing")?.encode(env)),
        18 => Ok(Atom::from_str(env, "stack_spacing")?.encode(env)),
        19 => Ok(Atom::from_str(env, "stack_padding")?.encode(env)),
        20 => Ok(Atom::from_str(env, "stack_mode")?.encode(env)),
        21 => Ok(Atom::from_str(env, "stack_alignment")?.encode(env)),
        22 => Ok(Atom::from_str(env, "opacity")?.encode(env)),
        23 => Ok(Atom::from_str(env, "component")?.encode(env)),
        24 => Ok(Atom::from_str(env, "font_style")?.encode(env)),
        25 => Ok(Atom::from_str(env, "grid_row_gap")?.encode(env)),
        26 => Ok(Atom::from_str(env, "grid_column_gap")?.encode(env)),
        27 => Ok(Atom::from_str(env, "grid_row_count")?.encode(env)),
        28 => Ok(Atom::from_str(env, "grid_column_count")?.encode(env)),
        29 => Ok(Atom::from_str(env, "grid_row_anchor_index")?.encode(env)),
        30 => Ok(Atom::from_str(env, "grid_column_anchor_index")?.encode(env)),
        31 => Ok(Atom::from_str(env, "grid_row_span")?.encode(env)),
        32 => Ok(Atom::from_str(env, "grid_column_span")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_annotation_property_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnnotationProperty",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_annotation_property_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnnotationProperty",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_annotation_category_preset_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "accessibility")?.encode(env)),
        2 => Ok(Atom::from_str(env, "behavior")?.encode(env)),
        3 => Ok(Atom::from_str(env, "content")?.encode(env)),
        4 => Ok(Atom::from_str(env, "development")?.encode(env)),
        5 => Ok(Atom::from_str(env, "interaction")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_annotation_category_color_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "yellow")?.encode(env)),
        1 => Ok(Atom::from_str(env, "orange")?.encode(env)),
        2 => Ok(Atom::from_str(env, "red")?.encode(env)),
        3 => Ok(Atom::from_str(env, "pink")?.encode(env)),
        4 => Ok(Atom::from_str(env, "violet")?.encode(env)),
        5 => Ok(Atom::from_str(env, "blue")?.encode(env)),
        6 => Ok(Atom::from_str(env, "teal")?.encode(env)),
        7 => Ok(Atom::from_str(env, "green")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_annotation_category_custom_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnnotationCategoryCustom",
    )?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "custom_color")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "label")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_annotation_category_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            2 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_color")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "label")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnnotationCategoryCustom",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_annotation_category_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnnotationCategory",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "preset")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "custom")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_annotation_category_preset_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "preset")?, value)?;
            }
            3 => {
                let value = decode_annotation_category_custom_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnnotationCategory",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_annotation_categories_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnnotationCategories",
    )?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "items")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_annotation_category_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "items")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnnotationCategories",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_annotation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Annotation")?;
    term = term.map_put(Atom::from_str(env, "label")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "properties")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "label_v2")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "category_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "label")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_annotation_property_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "properties")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "label_v2")?, value)?;
            }
            4 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "category_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Annotation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_annotation_measurement_node_side_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "top")?.encode(env)),
        1 => Ok(Atom::from_str(env, "bottom")?.encode(env)),
        2 => Ok(Atom::from_str(env, "left")?.encode(env)),
        3 => Ok(Atom::from_str(env, "right")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_annotation_measurement_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnnotationMeasurement",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "from_node")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "to_node")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "from_node_side")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "to_same_side")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inner_offset_relative")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "outer_offset_fixed")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "to_node_stable_path")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "free_text")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "from_node")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "to_node")?, value)?;
            }
            4 => {
                let value = decode_annotation_measurement_node_side_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "from_node_side")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "to_same_side")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "inner_offset_relative")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "outer_offset_fixed")?, value)?;
            }
            8 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "to_node_stable_path")?, value)?;
            }
            9 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "free_text")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnnotationMeasurement",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_library_move_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.LibraryMoveInfo",
    )?;
    term = term.map_put(Atom::from_str(env, "old_key")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "paste_file_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "old_key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "paste_file_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LibraryMoveInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_library_move_history_item_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.LibraryMoveHistoryItem",
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_component_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "source_node_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_component_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LibraryMoveHistoryItem",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_developer_related_link_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DeveloperRelatedLink",
    )?;
    term = term.map_put(Atom::from_str(env, "node_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "file_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "link_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "link_url")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "node_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "file_key")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "link_name")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "link_url")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DeveloperRelatedLink",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_widget_pointer_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.WidgetPointer")?;
    term = term.map_put(Atom::from_str(env, "node_id")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetPointer",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EditInfo")?;
    term = term.map_put(
        Atom::from_str(env, "timestamp_iso8601")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "user_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "last_edited_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "created_at")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "timestamp_iso8601")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_id")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "last_edited_at")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "created_at")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EditInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_editor_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "design")?.encode(env)),
        1 => Ok(Atom::from_str(env, "whiteboard")?.encode(env)),
        2 => Ok(Atom::from_str(env, "slides")?.encode(env)),
        3 => Ok(Atom::from_str(env, "dev_handoff")?.encode(env)),
        4 => Ok(Atom::from_str(env, "sites")?.encode(env)),
        5 => Ok(Atom::from_str(env, "cooper")?.encode(env)),
        6 => Ok(Atom::from_str(env, "illustration")?.encode(env)),
        7 => Ok(Atom::from_str(env, "figmake")?.encode(env)),
        8 => Ok(Atom::from_str(env, "figspec")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_mask_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "alpha")?.encode(env)),
        1 => Ok(Atom::from_str(env, "outline")?.encode(env)),
        2 => Ok(Atom::from_str(env, "luminance")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_module_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "single_node")?.encode(env)),
        2 => Ok(Atom::from_str(env, "multi_node")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_section_status_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "build")?.encode(env)),
        2 => Ok(Atom::from_str(env, "completed")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_section_status_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SectionStatusInfo",
    )?;
    term = term.map_put(Atom::from_str(env, "status")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "last_update_unix_timestamp")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "user_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "prev_status")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_section_status_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "status")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "last_update_unix_timestamp")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_id")?, value)?;
            }
            5 => {
                let value = decode_section_status_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prev_status")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SectionStatusInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_buzz_approval_request_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.BuzzApprovalRequestInfo",
    )?;
    term = term.map_put(
        Atom::from_str(env, "request_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "requester_user_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "requested_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "reviewer_user_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "title")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "note")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "assets_in_request")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "request_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "requester_user_id")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "requested_at")?, value)?;
            }
            4 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "reviewer_user_ids")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "title")?, value)?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "note")?, value)?;
            }
            7 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "assets_in_request")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding BuzzApprovalRequestInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_buzz_approval_requests_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.BuzzApprovalRequests",
    )?;
    term = term.map_put(
        Atom::from_str(env, "requests")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_buzz_approval_request_info_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "requests")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding BuzzApprovalRequests",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_buzz_approval_node_status_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "in_review")?.encode(env)),
        2 => Ok(Atom::from_str(env, "approved")?.encode(env)),
        3 => Ok(Atom::from_str(env, "changes_requested")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_buzz_approval_node_status_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.BuzzApprovalNodeStatusInfo",
    )?;
    term = term.map_put(
        Atom::from_str(env, "current_status")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "was_previously_approved")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "approval_revoked_at_history")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_buzz_approval_node_status_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "current_status")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "was_previously_approved")?, value)?;
            }
            3 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(Atom::from_str(env, "approval_revoked_at_history")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding BuzzApprovalNodeStatusInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_embed_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeEmbedInfo")?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "src_url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "title")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_published_site")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "src_url")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "title")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumbnail_image_hash")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_published_site")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeEmbedInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_timing_display_unit_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "milliseconds")?.encode(env)),
        1 => Ok(Atom::from_str(env, "seconds")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_change_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.NodeChange")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "guid_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "phase")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "phase_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_index_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "type_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "name_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_publishable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "library_move_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "library_move_history")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "file_asset_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_fill_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_stroke_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_override_over_text_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "user_facing_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sort_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ojans_super_secret_node_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sev_moonlit_lily_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_soft_deleted_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_non_updateable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_style_master_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_style_reference")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_fill_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_stroke_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_text_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_export_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_effect_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_grid_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_fill_style_id_for_stroke")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_fill")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_stroke_fill")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_effect")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id_for_grid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_animations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherit_fill_style_id_for_background")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_state_group")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "state_group_property_value_orders")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "partial_paste_annotation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_symbol_reference")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_symbol_publishable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_symbol_mappings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_symbol_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shared_component_master_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "unflattening_mappings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "force_unflattening_mappings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "publish_file")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_library_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "publish_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "is_c2")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "published_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "origin_component_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_defs")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_refs")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variant_prop_specs")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_data_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_symbol_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "nested_instance_resize_enabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overridden_symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_assignments")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "props_are_bubbled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_stash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_stash_v2")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "guid_path")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "guid_path_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_level")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "module_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "is_slot")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_slot_content")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_size_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paragraph_indent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paragraph_indent_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paragraph_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paragraph_spacing_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_align_horizontal")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_align_horizontal_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_align_vertical")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_align_vertical_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_case")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_case_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_height_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_name_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_data_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_text_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_common_ligatures")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_contextual_ligatures")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_discretionary_ligatures")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_historical_ligatures")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_ordinal")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_slashed_zero")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_numeric_figure")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_numeric_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_numeric_fraction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_caps")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_variant_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "letter_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "leading_trim")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hanging_punctuation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hanging_list")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fallback_glyphs")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_lines")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "responsive_text_style_variants")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "section_status")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "section_status_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_user_layout_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_explicit_layout_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "toggled_on_ot_features")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "toggled_off_ot_features")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hyperlink")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "mention")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "font_variations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_bidi_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_truncation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "has_had_rtl_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "emoji_image_set")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_thumbnail_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "visible")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "visible_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "locked")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "locked_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "lock_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "opacity")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "opacity_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "blend_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "blend_mode_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "size")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "size_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transform")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transform_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "dash_pattern")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "dash_pattern_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "mask")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "mask_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation_origin")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mask_is_outline")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mask_is_outline_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mask_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_opacity")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_opacity_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "corner_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "corner_radius_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_weight_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_align_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_cap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_cap_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_cap_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_join")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_join_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fill_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fill_paints_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_paints_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "effects")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "effects_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_color")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_color_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fill_geometry")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fill_geometry_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_geometry")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_geometry_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "offset_fill_mask_geometry")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration_fill_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration_skip_ink")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_underline_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration_thickness")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_decoration_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transform_modifiers")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transform3d")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "scene3d")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "transform_origin")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_top_left_corner_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_top_right_corner_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_bottom_left_corner_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_bottom_right_corner_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_corner_radii_independent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rectangle_corner_tool_independent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "proportions_constrained")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_aspect_ratio")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "use_absolute_bounds")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_top_hidden")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_bottom_hidden")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_left_hidden")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_right_hidden")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "borders_take_space")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_top_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_bottom_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_left_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_right_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "border_stroke_weights_independent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "horizontal_constraint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "horizontal_constraint_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_mode_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_spacing_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_padding")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_padding_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_counter_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_justify")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_horizontal_padding")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_vertical_padding")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_primary_sizing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_primary_align_items")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_counter_align_items")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_child_primary_grow")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_padding_right")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_padding_bottom")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_child_align_self")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_positioning")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_reverse_z_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_wrap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_counter_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_counter_align_content")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sorted_moving_child_indices")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_layout_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_rows")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_columns")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_row_gap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_column_gap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_row_anchor")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_column_anchor")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_row_span")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_column_span")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_columns_sizing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_rows_sizing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_child_vertical_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_child_horizontal_align")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_auto_tracks")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "grid_reflow_enabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_snake_game_board")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prototype_start_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prototype_background_color")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_preserve_scroll")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connection_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connection_url")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prototype_device")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_timeout")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_maintained")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "destination_is_overlay")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_should_smart_animate")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prototype_interactions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "object_animations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prototype_starting_point")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plugin_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plugin_relaunch_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_start")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_end")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_line_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_start_cap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_end_cap")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_control_points")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_bezier_control_points")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_text_midpoint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connector_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "annotations")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "measurements")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "annotation_categories")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shape_with_text_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shape_user_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_stroke_paint_derived")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_immutable_frame_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_immutable_frame_data_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_generation_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "jsx_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_jsx_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stable_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_block_language")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_block_theme")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "link_preview_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "shape_truncates")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "section_contents_hidden")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "video_playback")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stamp_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "section_preset_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "platform_shape_definition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_synced_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_sync_cursor")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_derived_subtree_cursor")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_cached_ancestor")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_input_behavior")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_tooltip")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_hover_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_widget_stickable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "should_hide_cursors_on_widget_hover")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_metadata")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_events")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_property_menu_items")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_input_text_node_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "jsx_props")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "table_row_positions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "table_column_positions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "table_row_heights")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "table_column_widths")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "table_merged_cells")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interactive_slide_config_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interactive_slide_participant_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "flapp_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_embedded_prototype")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_speaker_notes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_skipped_slide")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "presentation_outlines")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "theme_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_theme_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_theme_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_template_file_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_number")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_number_separator")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "diagram_parent_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_root")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "diagram_layout_rule_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "diagram_parent_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "diagram_layout_paused")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_page_divider")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "internal_enum_for_test")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "internal_data_for_test")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "auto_rename")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "auto_rename_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_enabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "background_enabled_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_contents_only")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_contents_only_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "miter_limit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "miter_limit_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_tracking")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_tracking_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vertical_constraint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vertical_constraint_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_settings_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_auto_resize")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_auto_resize_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_grids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "layout_grids_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "frame_mask_disabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "frame_mask_disabled_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "resize_to_fit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "resize_to_fit_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "boolean_operation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "boolean_operation_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "handle_mirroring")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "handle_mirroring_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "count")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "count_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "star_inner_scale")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "star_inner_scale_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "arc_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_data_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_operation_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_path_start")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_background_disabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "guides")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "internal_only")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scroll_direction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "corner_smoothing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scroll_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "export_text_as_svg_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scroll_contracted_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "contracted_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "fixed_children_divider")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scroll_behavior")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_symbol_data_layout_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "navigation_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overlay_position_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overlay_relative_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overlay_background_interaction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overlay_background_appearance")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "override_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "container_supports_fill_stroke_and_corners")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stack_counter_sizing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "containers_support_fill_stroke_and_corners")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "key_trigger")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "voice_event_phrase")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ancestor_path_before_deletion")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_links")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_list_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "detach_optical_size_from_font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "list_spacing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "embed_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rich_media_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rendered_synced_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "simplify_instance_panels")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "accessible_html_tag")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "aria_role")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "aria_attributes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "accessible_label")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_decorative_image")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_consumption_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_mode_by_set_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_modes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_resolved_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_data_values")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_token_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timing_display_unit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_scopes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parameter_consumption_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_syntax")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "paste_source")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "page_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_brush_guid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_seed")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_width_points")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "dynamic_stroke_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scatter_stroke_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stretch_stroke_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scatter_brush_transforms")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "brush_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "path_trim")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "backing_variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overridden_variable_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "backing_variable_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_collection_extendable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "root_variable_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "inherited_variable_ids")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "handoff_status_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "agenda_position_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "agenda_metadata_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "migration_status")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_soft_deleted")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "edit_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_profile")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "detached_symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "child_reading_direction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "reading_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "document_color_profile")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "developer_related_links")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slide_active_theme_lib_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "edit_scope_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "semantic_weight")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "semantic_italic")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "are_slides_manually_indented")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_responsive_set")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "derived_breakpoint_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "default_responsive_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_primary_breakpoint")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "primary_responsive_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "multi_edit_glue_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "breakpoint_min_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_breakpoint_in_focus")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "responsive_set_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "behaviors")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_code")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_code_collaborative_text_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "collaborative_source_code")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "belongs_to_code_library_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "imported_code_files")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_file_canvas_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_entrypoint_code_file")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_or_state_group_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_or_state_group_version")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_code_library_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_code_library_keys")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "used_make_libraries")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "make_library_component_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "should_hide_preview_for_make_kit_creation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_make_kit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_preview_settings")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_examples")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "exported_from_code_file_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_export_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_component_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "backing_code_component_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_main_code_component")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_snapshot_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "chat_messages")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "chat_compression_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ai_chat_thread")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_chat_messages_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_snapshot")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_snapshot_layers")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_snapshot_invalidated_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_code_behavior")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "auto_fork_code")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "has_been_manually_renamed")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_created_from_design")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_created_from_design_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "image_imports")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_object_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_file_path")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_behavior_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_library_format")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_code_preview_playing_on_canvas")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_embed_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_embed_code_layer")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_source_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mime_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "blob_ref")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_selector")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_consumption_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_rich_text_style_map")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "repeater_symbol_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "repeater_cms_override_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "repeater_symbol_override_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "repeater_override_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ai_edited_node_change_field_numbers")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ai_edit_scope_label")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "first_draft_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "first_draft_kit_element_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cooper_revert_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cooper_template_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "buzz_approval_requests")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "buzz_approval_node_status_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hub_file_attribution")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "managed_string_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ai_canvas_prompt")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "backing_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "page_status")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "motion_transform")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_value_ref")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interpolation_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "bezier_handles")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_operation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_position_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "is_clip")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "clip_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "timeline_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_disabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "playback_style")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_definitions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_assignments")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_presets")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_ids_for_animation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "backing_animation_preset_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "tools")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "custom_effects")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_overrides")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "use_legacy_smart_animate")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_control_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_content")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_code_block_language")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_table_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_indent_level")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_table_row_heights")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_block_table_column_widths")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "spec_embed_url")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "placeholder")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "placeholder_client_lifecycle_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "placeholder_invalidate_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "disable_jit_dst")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_tool_artifact_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            53 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "guid_tag")?, value)?;
            }
            2 => {
                let value = decode_node_phase_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "phase")?, value)?;
            }
            54 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "phase_tag")?, value)?;
            }
            3 => {
                let value = decode_parent_index_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parent_index")?, value)?;
            }
            55 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "parent_index_tag")?, value)?;
            }
            4 => {
                let value = decode_node_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            56 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "type_tag")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            57 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "name_tag")?, value)?;
            }
            174 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_publishable")?, value)?;
            }
            318 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            256 => {
                let value = decode_library_move_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "library_move_info")?, value)?;
            }
            281 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_library_move_history_item_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "library_move_history")?, value)?;
            }
            319 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            383 => {
                let value = decode_asset_id_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "file_asset_ids")?, value)?;
            }
            49 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            101 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "style_id_tag")?, value)?;
            }
            157 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_fill_style")?, value)?;
            }
            161 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_stroke_style")?, value)?;
            }
            376 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_override_over_text_style")?, value)?;
            }
            163 => {
                let value = decode_style_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_type")?, value)?;
            }
            191 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "style_description")?, value)?;
            }
            171 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            399 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_facing_version")?, value)?;
            }
            320 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "sort_position")?, value)?;
            }
            345 => {
                let value = decode_shared_style_master_data_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "ojans_super_secret_node_field")?, value)?;
            }
            348 => {
                let value = decode_shared_style_master_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "sev_moonlit_lily_data")?, value)?;
            }
            176 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_soft_deleted_style")?, value)?;
            }
            177 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_non_updateable")?, value)?;
            }
            172 => {
                let value = decode_shared_style_master_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "shared_style_master_data")?, value)?;
            }
            173 => {
                let value = decode_shared_style_reference_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "shared_style_reference")?, value)?;
            }
            158 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_fill_style_id")?, value)?;
            }
            162 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_stroke_style_id")?, value)?;
            }
            167 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_text_style_id")?, value)?;
            }
            168 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_export_style_id")?, value)?;
            }
            169 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_effect_style_id")?, value)?;
            }
            170 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherit_grid_style_id")?, value)?;
            }
            185 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "inherit_fill_style_id_for_stroke")?,
                    value,
                )?;
            }
            332 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_fill")?, value)?;
            }
            333 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_stroke_fill")?, value)?;
            }
            334 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_text")?, value)?;
            }
            335 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_effect")?, value)?;
            }
            336 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_id_for_grid")?, value)?;
            }
            580 => {
                let value = decoder
                    .read_repeated(|decoder| decode_style_animation_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "style_animations")?, value)?;
            }
            193 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "background_paints")?, value)?;
            }
            194 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "inherit_fill_style_id_for_background")?,
                    value,
                )?;
            }
            225 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_state_group")?, value)?;
            }
            238 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_state_group_property_value_order_from_decoder(env, decoder)
                })?;
                term = term.map_put(
                    Atom::from_str(env, "state_group_property_value_orders")?,
                    value,
                )?;
            }
            581 => {
                let value = decode_partial_paste_annotation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "partial_paste_annotation")?, value)?;
            }
            122 => {
                let value = decode_shared_symbol_reference_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "shared_symbol_reference")?, value)?;
            }
            123 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_symbol_publishable")?, value)?;
            }
            124 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "shared_symbol_mappings")?, value)?;
            }
            126 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "shared_symbol_version")?, value)?;
            }
            152 => {
                let value = decode_shared_component_master_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "shared_component_master_data")?, value)?;
            }
            144 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "symbol_description")?, value)?;
            }
            164 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "unflattening_mappings")?, value)?;
            }
            228 => {
                let value = decoder
                    .read_repeated(|decoder| decode_guid_path_mapping_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "force_unflattening_mappings")?, value)?;
            }
            214 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "publish_file")?, value)?;
            }
            395 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_library_key")?, value)?;
            }
            215 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "publish_id")?, value)?;
            }
            216 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "component_key")?, value)?;
            }
            217 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_c2")?, value)?;
            }
            218 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "published_version")?, value)?;
            }
            252 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "origin_component_key")?, value)?;
            }
            266 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_def_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_defs")?, value)?;
            }
            267 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_ref_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_refs")?, value)?;
            }
            483 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variant_prop_spec_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "variant_prop_specs")?, value)?;
            }
            113 => {
                let value = decode_symbol_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_data")?, value)?;
            }
            114 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "symbol_data_tag")?, value)?;
            }
            125 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "derived_symbol_data")?, value)?;
            }
            394 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "nested_instance_resize_enabled")?,
                    value,
                )?;
            }
            143 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "overridden_symbol_id")?, value)?;
            }
            268 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_assignment_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_assignments")?, value)?;
            }
            305 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "props_are_bubbled")?, value)?;
            }
            248 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_instance_override_stash_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "override_stash")?, value)?;
            }
            250 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_instance_override_stash_v2_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "override_stash_v2")?, value)?;
            }
            111 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid_path")?, value)?;
            }
            112 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "guid_path_tag")?, value)?;
            }
            321 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "override_level")?, value)?;
            }
            382 => {
                let value = decode_module_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "module_type")?, value)?;
            }
            463 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_slot")?, value)?;
            }
            495 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_slot_content")?, value)?;
            }
            21 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "font_size")?, value)?;
            }
            73 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "font_size_tag")?, value)?;
            }
            22 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "paragraph_indent")?, value)?;
            }
            74 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "paragraph_indent_tag")?, value)?;
            }
            23 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "paragraph_spacing")?, value)?;
            }
            75 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "paragraph_spacing_tag")?, value)?;
            }
            32 => {
                let value = decode_text_align_horizontal_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_align_horizontal")?, value)?;
            }
            84 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_align_horizontal_tag")?, value)?;
            }
            33 => {
                let value = decode_text_align_vertical_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_align_vertical")?, value)?;
            }
            85 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_align_vertical_tag")?, value)?;
            }
            34 => {
                let value = decode_text_case_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_case")?, value)?;
            }
            86 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_case_tag")?, value)?;
            }
            35 => {
                let value = decode_text_decoration_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_decoration")?, value)?;
            }
            87 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_decoration_tag")?, value)?;
            }
            40 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "line_height")?, value)?;
            }
            92 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "line_height_tag")?, value)?;
            }
            41 => {
                let value = decode_font_name_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_name")?, value)?;
            }
            93 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "font_name_tag")?, value)?;
            }
            42 => {
                let value = decode_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_data")?, value)?;
            }
            94 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_data_tag")?, value)?;
            }
            359 => {
                let value = decode_derived_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "derived_text_data")?, value)?;
            }
            127 => {
                let value = decoder.read_bool()?;
                term =
                    term.map_put(Atom::from_str(env, "font_variant_common_ligatures")?, value)?;
            }
            128 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "font_variant_contextual_ligatures")?,
                    value,
                )?;
            }
            129 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "font_variant_discretionary_ligatures")?,
                    value,
                )?;
            }
            130 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "font_variant_historical_ligatures")?,
                    value,
                )?;
            }
            131 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "font_variant_ordinal")?, value)?;
            }
            132 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "font_variant_slashed_zero")?, value)?;
            }
            133 => {
                let value = decode_font_variant_numeric_figure_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_variant_numeric_figure")?, value)?;
            }
            134 => {
                let value = decode_font_variant_numeric_spacing_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_variant_numeric_spacing")?, value)?;
            }
            135 => {
                let value = decode_font_variant_numeric_fraction_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "font_variant_numeric_fraction")?, value)?;
            }
            136 => {
                let value = decode_font_variant_caps_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_variant_caps")?, value)?;
            }
            137 => {
                let value = decode_font_variant_position_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_variant_position")?, value)?;
            }
            165 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "letter_spacing")?, value)?;
            }
            202 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "font_version")?, value)?;
            }
            322 => {
                let value = decode_leading_trim_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "leading_trim")?, value)?;
            }
            337 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "hanging_punctuation")?, value)?;
            }
            339 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "hanging_list")?, value)?;
            }
            550 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "fallback_glyphs")?, value)?;
            }
            351 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "max_lines")?, value)?;
            }
            417 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_responsive_text_style_variant_from_decoder(env, decoder)
                })?;
                term = term.map_put(
                    Atom::from_str(env, "responsive_text_style_variants")?,
                    value,
                )?;
            }
            352 => {
                let value = decode_section_status_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "section_status")?, value)?;
            }
            355 => {
                let value = decode_section_status_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "section_status_info")?, value)?;
            }
            203 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_user_layout_version")?, value)?;
            }
            396 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_explicit_layout_version")?, value)?;
            }
            205 => {
                let value = decoder
                    .read_repeated(|decoder| decode_open_type_feature_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "toggled_on_ot_features")?, value)?;
            }
            206 => {
                let value = decoder
                    .read_repeated(|decoder| decode_open_type_feature_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "toggled_off_ot_features")?, value)?;
            }
            223 => {
                let value = decode_hyperlink_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "hyperlink")?, value)?;
            }
            340 => {
                let value = decode_mention_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mention")?, value)?;
            }
            260 => {
                let value = decoder
                    .read_repeated(|decoder| decode_font_variation_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "font_variations")?, value)?;
            }
            279 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_bidi_version")?, value)?;
            }
            280 => {
                let value = decode_text_truncation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_truncation")?, value)?;
            }
            292 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "has_had_rtl_text")?, value)?;
            }
            391 => {
                let value = decode_emoji_image_set_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "emoji_image_set")?, value)?;
            }
            392 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "slide_thumbnail_hash")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "visible")?, value)?;
            }
            58 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "visible_tag")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "locked")?, value)?;
            }
            59 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "locked_tag")?, value)?;
            }
            434 => {
                let value = decode_lock_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "lock_mode")?, value)?;
            }
            8 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "opacity")?, value)?;
            }
            60 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "opacity_tag")?, value)?;
            }
            9 => {
                let value = decode_blend_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "blend_mode")?, value)?;
            }
            61 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "blend_mode_tag")?, value)?;
            }
            11 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "size")?, value)?;
            }
            63 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "size_tag")?, value)?;
            }
            12 => {
                let value = decode_matrix_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transform")?, value)?;
            }
            64 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "transform_tag")?, value)?;
            }
            13 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(Atom::from_str(env, "dash_pattern")?, value)?;
            }
            65 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "dash_pattern_tag")?, value)?;
            }
            16 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "mask")?, value)?;
            }
            68 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "mask_tag")?, value)?;
            }
            424 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rotation_origin")?, value)?;
            }
            18 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "mask_is_outline")?, value)?;
            }
            70 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "mask_is_outline_tag")?, value)?;
            }
            317 => {
                let value = decode_mask_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mask_type")?, value)?;
            }
            19 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "background_opacity")?, value)?;
            }
            71 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "background_opacity_tag")?, value)?;
            }
            20 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "corner_radius")?, value)?;
            }
            72 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "corner_radius_tag")?, value)?;
            }
            26 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stroke_weight")?, value)?;
            }
            78 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_weight_tag")?, value)?;
            }
            29 => {
                let value = decode_stroke_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_align")?, value)?;
            }
            81 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_align_tag")?, value)?;
            }
            30 => {
                let value = decode_stroke_cap_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_cap")?, value)?;
            }
            82 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_cap_tag")?, value)?;
            }
            497 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_cap_size")?, value)?;
            }
            31 => {
                let value = decode_stroke_join_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_join")?, value)?;
            }
            83 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_join_tag")?, value)?;
            }
            38 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "fill_paints")?, value)?;
            }
            90 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "fill_paints_tag")?, value)?;
            }
            39 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stroke_paints")?, value)?;
            }
            91 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_paints_tag")?, value)?;
            }
            43 => {
                let value =
                    decoder.read_repeated(|decoder| decode_effect_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "effects")?, value)?;
            }
            95 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "effects_tag")?, value)?;
            }
            50 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "background_color")?, value)?;
            }
            102 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "background_color_tag")?, value)?;
            }
            51 => {
                let value =
                    decoder.read_repeated(|decoder| decode_path_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "fill_geometry")?, value)?;
            }
            103 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "fill_geometry_tag")?, value)?;
            }
            52 => {
                let value =
                    decoder.read_repeated(|decoder| decode_path_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stroke_geometry")?, value)?;
            }
            104 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stroke_geometry_tag")?, value)?;
            }
            564 => {
                let value =
                    decoder.read_repeated(|decoder| decode_path_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "offset_fill_mask_geometry")?, value)?;
            }
            411 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "text_decoration_fill_paints")?, value)?;
            }
            412 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "text_decoration_skip_ink")?, value)?;
            }
            413 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_underline_offset")?, value)?;
            }
            415 => {
                let value = decode_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_decoration_thickness")?, value)?;
            }
            416 => {
                let value = decode_text_decoration_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_decoration_style")?, value)?;
            }
            455 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_transform_modifier_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "transform_modifiers")?, value)?;
            }
            570 => {
                let value = decode_transform3d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transform3d")?, value)?;
            }
            571 => {
                let value = decode_stroke_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_data")?, value)?;
            }
            572 => {
                let value = decode_scene3d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scene3d")?, value)?;
            }
            587 => {
                let value = decode_transform_origin_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transform_origin")?, value)?;
            }
            145 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_top_left_corner_radius")?,
                    value,
                )?;
            }
            146 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_top_right_corner_radius")?,
                    value,
                )?;
            }
            147 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_bottom_left_corner_radius")?,
                    value,
                )?;
            }
            148 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_bottom_right_corner_radius")?,
                    value,
                )?;
            }
            149 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_corner_radii_independent")?,
                    value,
                )?;
            }
            150 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "rectangle_corner_tool_independent")?,
                    value,
                )?;
            }
            151 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "proportions_constrained")?, value)?;
            }
            423 => {
                let value = decode_optional_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_aspect_ratio")?, value)?;
            }
            258 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "use_absolute_bounds")?, value)?;
            }
            287 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "border_top_hidden")?, value)?;
            }
            288 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "border_bottom_hidden")?, value)?;
            }
            289 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "border_left_hidden")?, value)?;
            }
            290 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "border_right_hidden")?, value)?;
            }
            294 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "borders_take_space")?, value)?;
            }
            295 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "border_top_weight")?, value)?;
            }
            296 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "border_bottom_weight")?, value)?;
            }
            297 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "border_left_weight")?, value)?;
            }
            298 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "border_right_weight")?, value)?;
            }
            299 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "border_stroke_weights_independent")?,
                    value,
                )?;
            }
            28 => {
                let value = decode_constraint_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "horizontal_constraint")?, value)?;
            }
            80 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "horizontal_constraint_tag")?, value)?;
            }
            105 => {
                let value = decode_stack_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_mode")?, value)?;
            }
            106 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stack_mode_tag")?, value)?;
            }
            107 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_spacing")?, value)?;
            }
            108 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stack_spacing_tag")?, value)?;
            }
            109 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_padding")?, value)?;
            }
            110 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stack_padding_tag")?, value)?;
            }
            120 => {
                let value = decode_stack_counter_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_counter_align")?, value)?;
            }
            121 => {
                let value = decode_stack_justify_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_justify")?, value)?;
            }
            208 => {
                let value = decode_stack_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_align")?, value)?;
            }
            209 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_horizontal_padding")?, value)?;
            }
            210 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_vertical_padding")?, value)?;
            }
            211 => {
                let value = decode_stack_size_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_width")?, value)?;
            }
            212 => {
                let value = decode_stack_size_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_height")?, value)?;
            }
            229 => {
                let value = decode_stack_size_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_primary_sizing")?, value)?;
            }
            230 => {
                let value = decode_stack_justify_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_primary_align_items")?, value)?;
            }
            231 => {
                let value = decode_stack_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_counter_align_items")?, value)?;
            }
            232 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_child_primary_grow")?, value)?;
            }
            233 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_padding_right")?, value)?;
            }
            234 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_padding_bottom")?, value)?;
            }
            236 => {
                let value = decode_stack_counter_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_child_align_self")?, value)?;
            }
            269 => {
                let value = decode_stack_positioning_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_positioning")?, value)?;
            }
            271 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "stack_reverse_z_index")?, value)?;
            }
            323 => {
                let value = decode_stack_wrap_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_wrap")?, value)?;
            }
            324 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stack_counter_spacing")?, value)?;
            }
            325 => {
                let value = decode_optional_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "min_size")?, value)?;
            }
            326 => {
                let value = decode_optional_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "max_size")?, value)?;
            }
            343 => {
                let value = decode_stack_counter_align_content_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_counter_align_content")?, value)?;
            }
            406 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_int())?;
                term = term.map_put(Atom::from_str(env, "sorted_moving_child_indices")?, value)?;
            }
            574 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "stack_layout_version")?, value)?;
            }
            435 => {
                let value = decode_guid_position_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_rows")?, value)?;
            }
            436 => {
                let value = decode_guid_position_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_columns")?, value)?;
            }
            437 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "grid_row_gap")?, value)?;
            }
            438 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "grid_column_gap")?, value)?;
            }
            439 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_row_anchor")?, value)?;
            }
            440 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_column_anchor")?, value)?;
            }
            441 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "grid_row_span")?, value)?;
            }
            442 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "grid_column_span")?, value)?;
            }
            474 => {
                let value = decode_guid_grid_track_size_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_columns_sizing")?, value)?;
            }
            475 => {
                let value = decode_guid_grid_track_size_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_rows_sizing")?, value)?;
            }
            476 => {
                let value = decode_grid_child_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_child_vertical_align")?, value)?;
            }
            477 => {
                let value = decode_grid_child_align_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_child_horizontal_align")?, value)?;
            }
            555 => {
                let value = decode_grid_auto_tracks_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "grid_auto_tracks")?, value)?;
            }
            556 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "grid_reflow_enabled")?, value)?;
            }
            344 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_snake_game_board")?, value)?;
            }
            139 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_node_id")?, value)?;
            }
            140 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prototype_start_node_id")?, value)?;
            }
            141 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prototype_background_color")?, value)?;
            }
            153 => {
                let value = decode_transition_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_info")?, value)?;
            }
            154 => {
                let value = decode_transition_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_type")?, value)?;
            }
            155 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_duration")?, value)?;
            }
            156 => {
                let value = decode_easing_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_type")?, value)?;
            }
            181 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "transition_preserve_scroll")?, value)?;
            }
            182 => {
                let value = decode_connection_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connection_type")?, value)?;
            }
            183 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "connection_url")?, value)?;
            }
            184 => {
                let value = decode_prototype_device_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prototype_device")?, value)?;
            }
            187 => {
                let value = decode_interaction_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "interaction_type")?, value)?;
            }
            188 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_timeout")?, value)?;
            }
            189 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "interaction_maintained")?, value)?;
            }
            190 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "interaction_duration")?, value)?;
            }
            192 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "destination_is_overlay")?, value)?;
            }
            207 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "transition_should_smart_animate")?,
                    value,
                )?;
            }
            226 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_prototype_interaction_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "prototype_interactions")?, value)?;
            }
            426 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_prototype_interaction_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "object_animations")?, value)?;
            }
            249 => {
                let value = decode_prototype_starting_point_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prototype_starting_point")?, value)?;
            }
            204 => {
                let value = decoder
                    .read_repeated(|decoder| decode_plugin_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "plugin_data")?, value)?;
            }
            219 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_plugin_relaunch_data_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "plugin_relaunch_data")?, value)?;
            }
            242 => {
                let value = decode_connector_endpoint_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_start")?, value)?;
            }
            243 => {
                let value = decode_connector_endpoint_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_end")?, value)?;
            }
            244 => {
                let value = decode_connector_line_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_line_style")?, value)?;
            }
            245 => {
                let value = decode_stroke_cap_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_start_cap")?, value)?;
            }
            246 => {
                let value = decode_stroke_cap_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_end_cap")?, value)?;
            }
            253 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_connector_control_point_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "connector_control_points")?, value)?;
            }
            479 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_connector_control_point_from_decoder(env, decoder)
                })?;
                term = term.map_put(
                    Atom::from_str(env, "connector_bezier_control_points")?,
                    value,
                )?;
            }
            255 => {
                let value = decode_connector_text_midpoint_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_text_midpoint")?, value)?;
            }
            373 => {
                let value = decode_connector_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connector_type")?, value)?;
            }
            533 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "connector_version")?, value)?;
            }
            369 => {
                let value = decoder
                    .read_repeated(|decoder| decode_annotation_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "annotations")?, value)?;
            }
            384 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_annotation_measurement_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "measurements")?, value)?;
            }
            453 => {
                let value = decode_annotation_categories_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "annotation_categories")?, value)?;
            }
            241 => {
                let value = decode_shape_with_text_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "shape_with_text_type")?, value)?;
            }
            247 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "shape_user_height")?, value)?;
            }
            530 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_stroke_paint_derived")?, value)?;
            }
            254 => {
                let value = decode_derived_immutable_frame_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "derived_immutable_frame_data")?, value)?;
            }
            338 => {
                let value = decode_multiplayer_field_version_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "derived_immutable_frame_data_version")?,
                    value,
                )?;
            }
            240 => {
                let value = decode_node_generation_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_generation_data")?, value)?;
            }
            491 => {
                let value = decode_jsx_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "jsx_data")?, value)?;
            }
            492 => {
                let value = decode_derived_jsx_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "derived_jsx_data")?, value)?;
            }
            493 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "stable_key")?, value)?;
            }
            259 => {
                let value = decode_code_block_language_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_block_language")?, value)?;
            }
            433 => {
                let value = decode_code_block_theme_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_block_theme")?, value)?;
            }
            278 => {
                let value = decode_link_preview_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "link_preview_data")?, value)?;
            }
            282 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "shape_truncates")?, value)?;
            }
            283 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "section_contents_hidden")?, value)?;
            }
            300 => {
                let value = decode_video_playback_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "video_playback")?, value)?;
            }
            301 => {
                let value = decode_stamp_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stamp_data")?, value)?;
            }
            370 => {
                let value = decode_section_preset_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "section_preset_info")?, value)?;
            }
            409 => {
                let value = decode_platform_shape_definition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "platform_shape_definition")?, value)?;
            }
            273 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_synced_state")?, value)?;
            }
            274 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "widget_sync_cursor")?, value)?;
            }
            275 => {
                let value = decode_widget_derived_subtree_cursor_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "widget_derived_subtree_cursor")?, value)?;
            }
            276 => {
                let value = decode_widget_pointer_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_cached_ancestor")?, value)?;
            }
            285 => {
                let value = decode_widget_input_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_input_behavior")?, value)?;
            }
            286 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "widget_tooltip")?, value)?;
            }
            291 => {
                let value = decode_widget_hover_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_hover_style")?, value)?;
            }
            293 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_widget_stickable")?, value)?;
            }
            360 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "should_hide_cursors_on_widget_hover")?,
                    value,
                )?;
            }
            262 => {
                let value = decode_widget_metadata_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_metadata")?, value)?;
            }
            263 => {
                let value = decoder
                    .read_repeated(|decoder| decode_widget_event_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "widget_events")?, value)?;
            }
            265 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_widget_property_menu_item_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "widget_property_menu_items")?, value)?;
            }
            401 => {
                let value = decode_widget_input_text_node_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "widget_input_text_node_type")?, value)?;
            }
            489 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "jsx_props")?, value)?;
            }
            308 => {
                let value = decode_table_row_column_position_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "table_row_positions")?, value)?;
            }
            309 => {
                let value = decode_table_row_column_position_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "table_column_positions")?, value)?;
            }
            310 => {
                let value = decode_table_row_column_size_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "table_row_heights")?, value)?;
            }
            311 => {
                let value = decode_table_row_column_size_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "table_column_widths")?, value)?;
            }
            538 => {
                let value = decode_table_merged_cell_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "table_merged_cells")?, value)?;
            }
            371 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "interactive_slide_config_data")?, value)?;
            }
            372 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "interactive_slide_participant_data")?,
                    value,
                )?;
            }
            402 => {
                let value = decode_flapp_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "flapp_type")?, value)?;
            }
            486 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_embedded_prototype")?, value)?;
            }
            389 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "slide_speaker_notes")?, value)?;
            }
            410 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_skipped_slide")?, value)?;
            }
            573 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "presentation_outlines")?, value)?;
            }
            379 => {
                let value = decode_theme_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "theme_id")?, value)?;
            }
            381 => {
                let value = decode_slide_theme_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slide_theme_data")?, value)?;
            }
            390 => {
                let value = decode_slide_theme_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slide_theme_map")?, value)?;
            }
            393 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "slide_template_file_key")?, value)?;
            }
            443 => {
                let value = decode_slide_number_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slide_number")?, value)?;
            }
            456 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "slide_number_separator")?, value)?;
            }
            363 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "diagram_parent_id")?, value)?;
            }
            362 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "layout_root")?, value)?;
            }
            364 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "layout_position")?, value)?;
            }
            366 => {
                let value = decode_diagram_layout_rule_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "diagram_layout_rule_type")?, value)?;
            }
            367 => {
                let value = decode_diagram_parent_index_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "diagram_parent_index")?, value)?;
            }
            368 => {
                let value = decode_diagram_layout_paused_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "diagram_layout_paused")?, value)?;
            }
            380 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_page_divider")?, value)?;
            }
            251 => {
                let value = decode_internal_enum_for_test_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "internal_enum_for_test")?, value)?;
            }
            257 => {
                let value = decode_internal_data_for_test_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "internal_data_for_test")?, value)?;
            }
            14 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "auto_rename")?, value)?;
            }
            66 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "auto_rename_tag")?, value)?;
            }
            15 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "background_enabled")?, value)?;
            }
            67 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "background_enabled_tag")?, value)?;
            }
            17 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "export_contents_only")?, value)?;
            }
            69 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "export_contents_only_tag")?, value)?;
            }
            25 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "miter_limit")?, value)?;
            }
            77 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "miter_limit_tag")?, value)?;
            }
            27 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "text_tracking")?, value)?;
            }
            79 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_tracking_tag")?, value)?;
            }
            37 => {
                let value = decode_constraint_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vertical_constraint")?, value)?;
            }
            89 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "vertical_constraint_tag")?, value)?;
            }
            45 => {
                let value = decoder
                    .read_repeated(|decoder| decode_export_settings_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "export_settings")?, value)?;
            }
            97 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "export_settings_tag")?, value)?;
            }
            46 => {
                let value = decode_text_auto_resize_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_auto_resize")?, value)?;
            }
            98 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "text_auto_resize_tag")?, value)?;
            }
            47 => {
                let value = decoder
                    .read_repeated(|decoder| decode_layout_grid_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "layout_grids")?, value)?;
            }
            99 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "layout_grids_tag")?, value)?;
            }
            115 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "frame_mask_disabled")?, value)?;
            }
            116 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "frame_mask_disabled_tag")?, value)?;
            }
            117 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "resize_to_fit")?, value)?;
            }
            118 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "resize_to_fit_tag")?, value)?;
            }
            36 => {
                let value = decode_boolean_operation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "boolean_operation")?, value)?;
            }
            88 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "boolean_operation_tag")?, value)?;
            }
            44 => {
                let value = decode_vector_mirror_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "handle_mirroring")?, value)?;
            }
            96 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "handle_mirroring_tag")?, value)?;
            }
            10 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "count")?, value)?;
            }
            62 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "count_tag")?, value)?;
            }
            24 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "star_inner_scale")?, value)?;
            }
            76 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "star_inner_scale_tag")?, value)?;
            }
            195 => {
                let value = decode_arc_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "arc_data")?, value)?;
            }
            48 => {
                let value = decode_vector_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vector_data")?, value)?;
            }
            100 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "vector_data_tag")?, value)?;
            }
            425 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "vector_operation_version")?, value)?;
            }
            432 => {
                let value = decode_text_path_start_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_path_start")?, value)?;
            }
            119 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "export_background_disabled")?, value)?;
            }
            138 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guide_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "guides")?, value)?;
            }
            142 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "internal_only")?, value)?;
            }
            159 => {
                let value = decode_scroll_direction_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_direction")?, value)?;
            }
            160 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "corner_smoothing")?, value)?;
            }
            166 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_offset")?, value)?;
            }
            175 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "export_text_as_svg_text")?, value)?;
            }
            178 => {
                let value = decode_scroll_contracted_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_contracted_state")?, value)?;
            }
            179 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "contracted_size")?, value)?;
            }
            180 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "fixed_children_divider")?, value)?;
            }
            186 => {
                let value = decode_scroll_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_behavior")?, value)?;
            }
            196 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(
                    Atom::from_str(env, "derived_symbol_data_layout_version")?,
                    value,
                )?;
            }
            197 => {
                let value = decode_navigation_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "navigation_type")?, value)?;
            }
            198 => {
                let value = decode_overlay_position_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "overlay_position_type")?, value)?;
            }
            199 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "overlay_relative_position")?, value)?;
            }
            200 => {
                let value = decode_overlay_background_interaction_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "overlay_background_interaction")?,
                    value,
                )?;
            }
            201 => {
                let value = decode_overlay_background_appearance_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "overlay_background_appearance")?, value)?;
            }
            213 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "override_key")?, value)?;
            }
            220 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "container_supports_fill_stroke_and_corners")?,
                    value,
                )?;
            }
            221 => {
                let value = decode_stack_size_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stack_counter_sizing")?, value)?;
            }
            222 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "containers_support_fill_stroke_and_corners")?,
                    value,
                )?;
            }
            224 => {
                let value = decode_key_trigger_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "key_trigger")?, value)?;
            }
            227 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "voice_event_phrase")?, value)?;
            }
            235 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_from_decoder(env, decoder))?;
                term =
                    term.map_put(Atom::from_str(env, "ancestor_path_before_deletion")?, value)?;
            }
            237 => {
                let value = decoder
                    .read_repeated(|decoder| decode_symbol_link_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "symbol_links")?, value)?;
            }
            239 => {
                let value = decode_text_list_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_list_data")?, value)?;
            }
            261 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "detach_optical_size_from_font_size")?,
                    value,
                )?;
            }
            264 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "list_spacing")?, value)?;
            }
            270 => {
                let value = decode_embed_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "embed_data")?, value)?;
            }
            272 => {
                let value = decode_rich_media_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rich_media_data")?, value)?;
            }
            277 => {
                let value = decode_multiplayer_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rendered_synced_state")?, value)?;
            }
            284 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "simplify_instance_panels")?, value)?;
            }
            302 => {
                let value = decode_html_tag_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "accessible_html_tag")?, value)?;
            }
            303 => {
                let value = decode_aria_role_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "aria_role")?, value)?;
            }
            357 => {
                let value = decode_aria_attributes_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "aria_attributes")?, value)?;
            }
            304 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "accessible_label")?, value)?;
            }
            490 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_decorative_image")?, value)?;
            }
            306 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_data")?, value)?;
            }
            307 => {
                let value = decode_variable_data_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_consumption_map")?, value)?;
            }
            316 => {
                let value = decode_variable_mode_by_set_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_mode_by_set_map")?, value)?;
            }
            312 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variable_set_mode_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "variable_set_modes")?, value)?;
            }
            313 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_set_id")?, value)?;
            }
            314 => {
                let value = decode_variable_resolved_data_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_resolved_type")?, value)?;
            }
            315 => {
                let value = decode_variable_data_values_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_data_values")?, value)?;
            }
            350 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "variable_token_name")?, value)?;
            }
            566 => {
                let value = decode_variable_timing_display_unit_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timing_display_unit")?, value)?;
            }
            353 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variable_scope_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "variable_scopes")?, value)?;
            }
            445 => {
                let value = decode_variable_data_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parameter_consumption_map")?, value)?;
            }
            358 => {
                let value = decode_code_syntax_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_syntax")?, value)?;
            }
            388 => {
                let value = decode_paste_source_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "paste_source")?, value)?;
            }
            397 => {
                let value = decode_editor_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "page_type")?, value)?;
            }
            446 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stroke_brush_guid")?, value)?;
            }
            482 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "stroke_seed")?, value)?;
            }
            447 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_variable_width_point_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "variable_width_points")?, value)?;
            }
            448 => {
                let value = decode_dynamic_stroke_settings_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "dynamic_stroke_settings")?, value)?;
            }
            449 => {
                let value = decode_scatter_stroke_settings_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scatter_stroke_settings")?, value)?;
            }
            450 => {
                let value = decode_stretch_stroke_settings_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stretch_stroke_settings")?, value)?;
            }
            488 => {
                let value =
                    decoder.read_repeated(|decoder| decode_matrix_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "scatter_brush_transforms")?, value)?;
            }
            452 => {
                let value = decode_brush_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "brush_type")?, value)?;
            }
            542 => {
                let value = decode_optional_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "path_trim")?, value)?;
            }
            554 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stroke_offset")?, value)?;
            }
            377 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_variable_set_id")?, value)?;
            }
            464 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "overridden_variable_id")?, value)?;
            }
            378 => {
                let value = decode_variable_id_or_variable_override_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_variable_id")?, value)?;
            }
            385 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_collection_extendable")?, value)?;
            }
            386 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "root_variable_key")?, value)?;
            }
            517 => {
                let value = decode_inherited_variables_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "inherited_variable_ids")?, value)?;
            }
            361 => {
                let value = decode_handoff_status_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "handoff_status_map")?, value)?;
            }
            327 => {
                let value = decode_agenda_position_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "agenda_position_map")?, value)?;
            }
            328 => {
                let value = decode_agenda_metadata_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "agenda_metadata_map")?, value)?;
            }
            329 => {
                let value = decode_migration_status_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "migration_status")?, value)?;
            }
            330 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_soft_deleted")?, value)?;
            }
            331 => {
                let value = decode_edit_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "edit_info")?, value)?;
            }
            341 => {
                let value = decode_color_profile_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_profile")?, value)?;
            }
            342 => {
                let value = decode_symbol_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "detached_symbol_id")?, value)?;
            }
            346 => {
                let value = decode_child_reading_direction_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "child_reading_direction")?, value)?;
            }
            347 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "reading_index")?, value)?;
            }
            349 => {
                let value = decode_document_color_profile_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "document_color_profile")?, value)?;
            }
            354 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_developer_related_link_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "developer_related_links")?, value)?;
            }
            356 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "slide_active_theme_lib_key")?, value)?;
            }
            365 => {
                let value = decode_edit_scope_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "edit_scope_info")?, value)?;
            }
            374 => {
                let value = decode_semantic_weight_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "semantic_weight")?, value)?;
            }
            375 => {
                let value = decode_semantic_italic_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "semantic_italic")?, value)?;
            }
            403 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "are_slides_manually_indented")?, value)?;
            }
            387 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_responsive_set")?, value)?;
            }
            500 => {
                let value = decode_derived_breakpoint_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "derived_breakpoint_data")?, value)?;
            }
            398 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "default_responsive_set_id")?, value)?;
            }
            458 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_primary_breakpoint")?, value)?;
            }
            457 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "primary_responsive_node_id")?, value)?;
            }
            462 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "multi_edit_glue_id")?, value)?;
            }
            501 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "breakpoint_min_width")?, value)?;
            }
            522 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_breakpoint_in_focus")?, value)?;
            }
            400 => {
                let value = decode_responsive_set_settings_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "responsive_set_settings")?, value)?;
            }
            404 => {
                let value = decode_node_behaviors_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "behaviors")?, value)?;
            }
            414 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_code")?, value)?;
            }
            534 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_collaborative_text_op_id_from_decoder(env, decoder)
                })?;
                term = term.map_put(
                    Atom::from_str(env, "source_code_collaborative_text_version")?,
                    value,
                )?;
            }
            444 => {
                let value = decode_collaborative_plain_text_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "collaborative_source_code")?, value)?;
            }
            427 => {
                let value = decode_code_library_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "belongs_to_code_library_id")?, value)?;
            }
            467 => {
                let value = decode_imported_code_files_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "imported_code_files")?, value)?;
            }
            468 => {
                let value = decode_canvas_node_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_file_canvas_node_id")?, value)?;
            }
            498 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_entrypoint_code_file")?, value)?;
            }
            502 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "component_or_state_group_key")?, value)?;
            }
            503 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(
                    Atom::from_str(env, "component_or_state_group_version")?,
                    value,
                )?;
            }
            504 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "source_code_library_key")?, value)?;
            }
            515 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "source_code_library_keys")?, value)?;
            }
            524 => {
                let value = decoder
                    .read_repeated(|decoder| decode_used_make_library_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "used_make_libraries")?, value)?;
            }
            518 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "make_library_component_id")?, value)?;
            }
            520 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "should_hide_preview_for_make_kit_creation")?,
                    value,
                )?;
            }
            551 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_make_kit")?, value)?;
            }
            531 => {
                let value = decode_prototype_device_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_preview_settings")?, value)?;
            }
            525 => {
                let value = decoder
                    .read_repeated(|decoder| decode_code_example_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "code_examples")?, value)?;
            }
            428 => {
                let value = decode_code_file_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "exported_from_code_file_id")?, value)?;
            }
            430 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "code_export_name")?, value)?;
            }
            547 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "code_component_description")?, value)?;
            }
            429 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_code_component_id")?, value)?;
            }
            487 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_main_code_component")?, value)?;
            }
            431 => {
                let value = decode_code_snapshot_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_snapshot_state")?, value)?;
            }
            451 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_chat_message_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "chat_messages")?, value)?;
            }
            485 => {
                let value = decode_node_chat_compression_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "chat_compression_state")?, value)?;
            }
            496 => {
                let value = decode_ai_chat_thread_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "ai_chat_thread")?, value)?;
            }
            484 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "code_chat_messages_key")?, value)?;
            }
            459 => {
                let value = decode_code_snapshot_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_snapshot")?, value)?;
            }
            589 => {
                let value = decode_code_snapshot_layers_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_snapshot_layers")?, value)?;
            }
            480 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "code_snapshot_invalidated_at")?, value)?;
            }
            465 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_code_behavior")?, value)?;
            }
            469 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "auto_fork_code")?, value)?;
            }
            470 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "has_been_manually_renamed")?, value)?;
            }
            471 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "code_created_from_design")?, value)?;
            }
            481 => {
                let value = decode_canvas_node_id_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "code_created_from_design_node_id")?,
                    value,
                )?;
            }
            473 => {
                let value = decode_image_import_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_imports")?, value)?;
            }
            516 => {
                let value = decode_code_object_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_object_type")?, value)?;
            }
            472 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "code_file_path")?, value)?;
            }
            478 => {
                let value = decode_code_behavior_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_behavior_data")?, value)?;
            }
            519 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "code_library_format")?, value)?;
            }
            527 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "is_code_preview_playing_on_canvas")?,
                    value,
                )?;
            }
            532 => {
                let value = decode_code_embed_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_embed_info")?, value)?;
            }
            546 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_embed_code_layer")?, value)?;
            }
            558 => {
                let value = decode_code_source_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_source_info")?, value)?;
            }
            536 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "mime_type")?, value)?;
            }
            537 => {
                let value = decoder.read_byte_array(env)?;
                term = term.map_put(Atom::from_str(env, "blob_ref")?, value)?;
            }
            419 => {
                let value = decode_cms_selector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_selector")?, value)?;
            }
            420 => {
                let value = decode_cms_consumption_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_consumption_map")?, value)?;
            }
            460 => {
                let value = decode_cms_rich_text_style_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_rich_text_style_map")?, value)?;
            }
            539 => {
                let value = decode_symbol_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "repeater_symbol_id")?, value)?;
            }
            540 => {
                let value = decode_repeater_cms_override_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "repeater_cms_override_data")?, value)?;
            }
            549 => {
                let value = decode_repeater_symbol_override_data_from_decoder(env, decoder)?;
                term =
                    term.map_put(Atom::from_str(env, "repeater_symbol_override_data")?, value)?;
            }
            541 => {
                let value = decode_repeater_override_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "repeater_override_data")?, value)?;
            }
            405 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(
                    Atom::from_str(env, "ai_edited_node_change_field_numbers")?,
                    value,
                )?;
            }
            408 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "ai_edit_scope_label")?, value)?;
            }
            407 => {
                let value = decode_first_draft_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "first_draft_data")?, value)?;
            }
            418 => {
                let value = decode_first_draft_kit_element_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "first_draft_kit_element_data")?, value)?;
            }
            421 => {
                let value = decode_cooper_revert_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cooper_revert_data")?, value)?;
            }
            461 => {
                let value = decode_cooper_template_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cooper_template_data")?, value)?;
            }
            528 => {
                let value = decode_buzz_approval_requests_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "buzz_approval_requests")?, value)?;
            }
            529 => {
                let value = decode_buzz_approval_node_status_info_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "buzz_approval_node_status_info")?,
                    value,
                )?;
            }
            422 => {
                let value = decode_hub_file_attribution_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "hub_file_attribution")?, value)?;
            }
            454 => {
                let value = decode_managed_string_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "managed_string_data")?, value)?;
            }
            466 => {
                let value = decode_thumbnail_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "thumbnail_info")?, value)?;
            }
            494 => {
                let value = decode_ai_canvas_prompt_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "ai_canvas_prompt")?, value)?;
            }
            499 => {
                let value = decode_canvas_node_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_node_id")?, value)?;
            }
            548 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "page_status")?, value)?;
            }
            523 => {
                let value = decode_trss_transform2_d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "motion_transform")?, value)?;
            }
            506 => {
                let value = decoder.read_var_int64()?;
                term = term.map_put(Atom::from_str(env, "timeline_position")?, value)?;
            }
            507 => {
                let value = decode_keyframe_value_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_value")?, value)?;
            }
            586 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_value_ref")?, value)?;
            }
            505 => {
                let value = decode_interpolation_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "interpolation_type")?, value)?;
            }
            508 => {
                let value = decode_bezier_handles_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "bezier_handles")?, value)?;
            }
            535 => {
                let value = decode_easing_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_data")?, value)?;
            }
            509 => {
                let value = decode_keyframe_operation_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_operation")?, value)?;
            }
            510 => {
                let value = decode_timeline_position_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_position_type")?, value)?;
            }
            545 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_clip")?, value)?;
            }
            511 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "clip_id")?, value)?;
            }
            512 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "timeline_duration")?, value)?;
            }
            513 => {
                let value = decoder.read_var_int64()?;
                term = term.map_put(Atom::from_str(env, "timeline_offset")?, value)?;
            }
            543 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "timeline_disabled")?, value)?;
            }
            514 => {
                let value = decode_playback_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "playback_style")?, value)?;
            }
            552 => {
                let value = decode_timeline_definitions_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_definitions")?, value)?;
            }
            553 => {
                let value = decode_timeline_assignments_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_assignments")?, value)?;
            }
            521 => {
                let value = decode_animation_presets_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_presets")?, value)?;
            }
            582 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_style_id_for_animation_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "style_ids_for_animation")?, value)?;
            }
            583 => {
                let value = decode_animation_preset_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_animation_preset_id")?, value)?;
            }
            568 => {
                let value = decode_tools_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "tools")?, value)?;
            }
            569 => {
                let value = decode_custom_effects_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_effects")?, value)?;
            }
            526 => {
                let value = decode_transition_override_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_overrides")?, value)?;
            }
            544 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "use_legacy_smart_animate")?, value)?;
            }
            557 => {
                let value = decode_source_control_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "source_control_config")?, value)?;
            }
            559 => {
                let value = decode_spec_block_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "spec_block_type")?, value)?;
            }
            560 => {
                let value = decode_collaborative_plain_text_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "spec_block_content")?, value)?;
            }
            561 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "spec_code_block_language")?, value)?;
            }
            562 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "spec_block_table_alignment")?, value)?;
            }
            563 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "spec_block_indent_level")?, value)?;
            }
            575 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "spec_image_hash")?, value)?;
            }
            576 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "spec_width")?, value)?;
            }
            577 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "spec_height")?, value)?;
            }
            578 => {
                let value = decode_table_row_column_size_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "spec_block_table_row_heights")?, value)?;
            }
            579 => {
                let value = decode_table_row_column_size_map_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "spec_block_table_column_widths")?,
                    value,
                )?;
            }
            590 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "spec_embed_url")?, value)?;
            }
            565 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "placeholder")?, value)?;
            }
            584 => {
                let value = decoder.read_string()?;
                term = term.map_put(
                    Atom::from_str(env, "placeholder_client_lifecycle_id")?,
                    value,
                )?;
            }
            585 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "placeholder_invalidate_at")?, value)?;
            }
            567 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "disable_jit_dst")?, value)?;
            }
            588 => {
                let value = decode_custom_tool_artifact_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_tool_artifact_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeChange",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_git_repo_ref_provider_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "ugit")?.encode(env)),
        1 => Ok(Atom::from_str(env, "github")?.encode(env)),
        2 => Ok(Atom::from_str(env, "other")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_git_repo_ref_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GitRepoRef")?;
    term = term.map_put(
        Atom::from_str(env, "provider")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "git_repo")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "git_ref")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_git_repo_ref_provider_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "provider")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "git_repo")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "git_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GitRepoRef",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_source_control_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SourceControlConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "origin")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "upstream")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_git_repo_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "origin")?, value)?;
            }
            2 => {
                let value = decode_git_repo_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "upstream")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SourceControlConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_snapshot_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeSnapshot")?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "invalidated_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "paints")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "offset")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "layout_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "canvas_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "device_pixel_ratio")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            6 => {
                let value = decode_code_snapshot_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            7 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "invalidated_at")?, value)?;
            }
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "paints")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "offset")?, value)?;
            }
            3 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "layout_size")?, value)?;
            }
            5 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "canvas_size")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "device_pixel_ratio")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeSnapshot",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_output_layer_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CodeOutputLayer",
    )?;
    term = term.map_put(Atom::from_str(env, "node")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeOutputLayer",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_snapshot_layers_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CodeSnapshotLayers",
    )?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "invalidated_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "layers")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_code_snapshot_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "invalidated_at")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_code_output_layer_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "layers")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeSnapshotLayers",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_behavior_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CodeBehaviorData",
    )?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "icon")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "node_types")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "category")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "api_version")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "icon")?, value)?;
            }
            3 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "node_types")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "category")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "api_version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeBehaviorData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_example_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeExample")?;
    term = term.map_put(
        Atom::from_str(env, "example_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "code_export_name")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "example_name")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "code_export_name")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeExample",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_used_make_library_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.UsedMakeLibrary",
    )?;
    term = term.map_put(
        Atom::from_str(env, "make_library_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "make_library_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding UsedMakeLibrary",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cookie_banner_text_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CookieBannerText",
    )?;
    term = term.map_put(
        Atom::from_str(env, "banner_header")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "banner_disclaimer_explicit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "banner_disclaimer_implicit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "policy_label")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "accept_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "acknowledge_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "manage_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "reject_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "necessary_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "necessary_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "analytics_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "analytics_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "preferences_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "preferences_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "marketing_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "marketing_description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "save_label")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "trigger_label")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "banner_header")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "banner_disclaimer_explicit")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "banner_disclaimer_implicit")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "policy_label")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "accept_text")?, value)?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "acknowledge_text")?, value)?;
            }
            7 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "manage_text")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "reject_text")?, value)?;
            }
            9 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "necessary_text")?, value)?;
            }
            10 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "necessary_description")?, value)?;
            }
            11 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "analytics_text")?, value)?;
            }
            12 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "analytics_description")?, value)?;
            }
            13 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "preferences_text")?, value)?;
            }
            14 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "preferences_description")?, value)?;
            }
            15 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "marketing_text")?, value)?;
            }
            16 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "marketing_description")?, value)?;
            }
            17 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "save_label")?, value)?;
            }
            18 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "trigger_label")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CookieBannerText",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cookie_banner_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CookieBannerSettings",
    )?;
    term = term.map_put(Atom::from_str(env, "enabled")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "component_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "x_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "y_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "trigger_x_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "trigger_y_alignment")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "trigger_component_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "policy_url")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "text")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "policy_link")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "locale")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "enabled")?, value)?;
            }
            2 => {
                let value = decode_cookie_banner_component_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "component_type")?, value)?;
            }
            3 => {
                let value = decode_cookie_x_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "x_alignment")?, value)?;
            }
            4 => {
                let value = decode_cookie_y_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "y_alignment")?, value)?;
            }
            5 => {
                let value = decode_cookie_x_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger_x_alignment")?, value)?;
            }
            6 => {
                let value = decode_cookie_y_alignment_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger_y_alignment")?, value)?;
            }
            7 => {
                let value = decode_trigger_component_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger_component_type")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "policy_url")?, value)?;
            }
            9 => {
                let value = decode_cookie_banner_text_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text")?, value)?;
            }
            10 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "policy_link")?, value)?;
            }
            11 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "locale")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CookieBannerSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cookie_banner_component_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "banner")?.encode(env)),
        1 => Ok(Atom::from_str(env, "modal")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_trigger_component_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "banner")?.encode(env)),
        1 => Ok(Atom::from_str(env, "tag")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cookie_x_alignment_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "left")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "right")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cookie_y_alignment_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "top")?.encode(env)),
        1 => Ok(Atom::from_str(env, "center")?.encode(env)),
        2 => Ok(Atom::from_str(env, "bottom")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_responsive_set_settings_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ResponsiveSetSettings",
    )?;
    term = term.map_put(Atom::from_str(env, "title")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scaling_mode")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scaling_min_font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scaling_max_font_size")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scaling_min_layout_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scaling_max_layout_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "lang")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "favicon_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "social_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "google_analytics_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "block_search_indexing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_code_head_start")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_code_head_end")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_code_body_start")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_code_body_end")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "favicon_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "social_image_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "add_bypass_links")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "ignore_reduced_motion")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cookie_banner")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "title")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            3 => {
                let value = decode_responsive_scaling_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scaling_mode")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "scaling_min_font_size")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "scaling_max_font_size")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "scaling_min_layout_width")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "scaling_max_layout_width")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "lang")?, value)?;
            }
            9 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "favicon_hash")?, value)?;
            }
            10 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "social_image_hash")?, value)?;
            }
            11 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "google_analytics_id")?, value)?;
            }
            12 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "block_search_indexing")?, value)?;
            }
            13 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_code_head_start")?, value)?;
            }
            14 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_code_head_end")?, value)?;
            }
            15 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_code_body_start")?, value)?;
            }
            16 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "custom_code_body_end")?, value)?;
            }
            17 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "favicon_id")?, value)?;
            }
            18 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "social_image_id")?, value)?;
            }
            19 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "add_bypass_links")?, value)?;
            }
            20 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "ignore_reduced_motion")?, value)?;
            }
            21 => {
                let value = decode_cookie_banner_settings_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cookie_banner")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ResponsiveSetSettings",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_responsive_scaling_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "reflow")?.encode(env)),
        1 => Ok(Atom::from_str(env, "scale")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_selector_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CMSSelector")?;
    term = term.map_put(
        Atom::from_str(env, "cms_collection_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "filter_criteria")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "sorts")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "limit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "cms_collection_id")?, value)?;
            }
            2 => {
                let value = decode_cms_filter_critera_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "filter_criteria")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_cms_selector_sort_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "sorts")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "limit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSSelector",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_filter_critera_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSFilterCritera",
    )?;
    term = term.map_put(
        Atom::from_str(env, "match_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "filters")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_cms_filter_criteria_match_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "match_type")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_cms_selector_filter_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "filters")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSFilterCritera",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_filter_criteria_match_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "match_all")?.encode(env)),
        1 => Ok(Atom::from_str(env, "match_any")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_selector_filter_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSSelectorFilter",
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_field_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "op")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "comparison_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "cms_field_id")?, value)?;
            }
            2 => {
                let value = decode_cms_selector_filter_operator_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "op")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "comparison_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSSelectorFilter",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_selector_filter_operator_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "equals")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_selector_sort_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSSelectorSort",
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_field_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "order_by")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "cms_field_id")?, value)?;
            }
            2 => {
                let value = decode_cms_field_order_by_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "order_by")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSSelectorSort",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_field_order_by_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "ascending")?.encode(env)),
        1 => Ok(Atom::from_str(env, "descending")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_consumption_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSConsumptionMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_cms_consumption_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSConsumptionMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_consumption_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSConsumptionMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "consumption_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_field_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_cms_consumption_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "consumption_field")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "cms_field_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSConsumptionMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_consumption_field_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "missing")?.encode(env)),
        1 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_rich_text_style_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSRichTextStyleMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_cms_rich_text_style_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSRichTextStyleMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_rich_text_style_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSRichTextStyleEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_class")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_descriptor")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_cms_rich_text_style_class_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "style_class")?, value)?;
            }
            2 => {
                let value = decode_cms_rich_text_descriptor_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_descriptor")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSRichTextStyleEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_rich_text_style_class_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "heading1")?.encode(env)),
        1 => Ok(Atom::from_str(env, "heading2")?.encode(env)),
        2 => Ok(Atom::from_str(env, "heading3")?.encode(env)),
        3 => Ok(Atom::from_str(env, "heading4")?.encode(env)),
        4 => Ok(Atom::from_str(env, "heading5")?.encode(env)),
        5 => Ok(Atom::from_str(env, "heading6")?.encode(env)),
        6 => Ok(Atom::from_str(env, "paragraph")?.encode(env)),
        7 => Ok(Atom::from_str(env, "link")?.encode(env)),
        8 => Ok(Atom::from_str(env, "blockquote")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_rich_text_descriptor_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSRichTextDescriptor",
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_name_variants")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_style_id")?, value)?;
            }
            2 => {
                let value =
                    decoder.read_repeated(|decoder| decode_font_name_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "font_name_variants")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSRichTextDescriptor",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_repeater_cms_override_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.RepeaterCmsOverrideData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding RepeaterCmsOverrideData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_repeater_override_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.RepeaterOverrideData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_index_overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "parent_index_overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding RepeaterOverrideData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_repeater_symbol_override_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.RepeaterSymbolOverrideData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides_by_position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_repeater_position_overrides_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "overrides_by_position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding RepeaterSymbolOverrideData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_repeater_position_overrides_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.RepeaterPositionOverrides",
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_parent_index_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            2 => {
                let value = decoder
                    .read_repeated(|decoder| decode_node_change_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding RepeaterPositionOverrides",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_inherited_variables_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InheritedVariablesData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_ids")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_inherited_variable_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "variable_ids")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InheritedVariablesData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_inherited_variable_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InheritedVariableEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InheritedVariableEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_hub_file_attribution_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.HubFileAttribution",
    )?;
    term = term.map_put(
        Atom::from_str(env, "hub_file_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hub_file_name")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "hub_file_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "hub_file_name")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding HubFileAttribution",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringData",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "context")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "locale")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "content")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "content_schema")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "context")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "locale")?, value)?;
            }
            4 => {
                let value = decode_managed_string_node_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "content")?, value)?;
            }
            5 => {
                let value = decode_managed_string_content_schema_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "content_schema")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_content_schema_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "v0")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_managed_string_node_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "text")?.encode(env)),
        1 => Ok(Atom::from_str(env, "concatenate")?.encode(env)),
        2 => Ok(Atom::from_str(env, "plural")?.encode(env)),
        3 => Ok(Atom::from_str(env, "placeholder")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_managed_string_node_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringNode",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "text_node_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "concatenate_node_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plural_node_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "placeholder_node_data")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_managed_string_node_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_managed_string_text_node_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_node_data")?, value)?;
            }
            3 => {
                let value =
                    decode_managed_string_concatenate_ast_node_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "concatenate_node_data")?, value)?;
            }
            4 => {
                let value = decode_managed_string_plural_ast_node_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "plural_node_data")?, value)?;
            }
            5 => {
                let value =
                    decode_managed_string_placeholder_ast_node_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "placeholder_node_data")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringNode",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_text_node_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringTextNodeData",
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringTextNodeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_concatenate_ast_node_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringConcatenateAstNodeData",
    )?;
    term = term.map_put(Atom::from_str(env, "values")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_managed_string_node_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringConcatenateAstNodeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_plural_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "zero")?.encode(env)),
        1 => Ok(Atom::from_str(env, "one")?.encode(env)),
        2 => Ok(Atom::from_str(env, "two")?.encode(env)),
        3 => Ok(Atom::from_str(env, "few")?.encode(env)),
        4 => Ok(Atom::from_str(env, "many")?.encode(env)),
        5 => Ok(Atom::from_str(env, "other")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_managed_string_plural_ast_node_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringPluralAstNodeData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "identifier")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "conditions")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "identifier")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_managed_string_plural_type_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "conditions")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringPluralAstNodeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_plural_type_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringPluralTypeMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_managed_string_plural_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decode_managed_string_node_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringPluralTypeMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_format_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "text")?.encode(env)),
        1 => Ok(Atom::from_str(env, "date")?.encode(env)),
        2 => Ok(Atom::from_str(env, "time")?.encode(env)),
        3 => Ok(Atom::from_str(env, "number")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_managed_string_placeholder_ast_node_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringPlaceholderAstNodeData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "identifier")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "format_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "format_pattern")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "identifier")?, value)?;
            }
            2 => {
                let value = decode_managed_string_format_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "format_type")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "format_pattern")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringPlaceholderAstNodeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cooper_revert_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CooperRevertData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "original_values")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "original_values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CooperRevertData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_video_playback_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VideoPlayback")?;
    term = term.map_put(
        Atom::from_str(env, "autoplay")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_loop")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "muted")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "show_controls")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_time_ms")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "end_time_ms")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "autoplay")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "media_loop")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "muted")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "show_controls")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "start_time_ms")?, value)?;
            }
            6 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "end_time_ms")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VideoPlayback",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_media_action_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "play")?.encode(env)),
        1 => Ok(Atom::from_str(env, "pause")?.encode(env)),
        2 => Ok(Atom::from_str(env, "toggle_play_pause")?.encode(env)),
        3 => Ok(Atom::from_str(env, "mute")?.encode(env)),
        4 => Ok(Atom::from_str(env, "unmute")?.encode(env)),
        5 => Ok(Atom::from_str(env, "toggle_mute_unmute")?.encode(env)),
        6 => Ok(Atom::from_str(env, "skip_forward")?.encode(env)),
        7 => Ok(Atom::from_str(env, "skip_backward")?.encode(env)),
        8 => Ok(Atom::from_str(env, "skip_to")?.encode(env)),
        9 => Ok(Atom::from_str(env, "set_playback_rate")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_animation_timeline_action_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "play")?.encode(env)),
        1 => Ok(Atom::from_str(env, "pause")?.encode(env)),
        2 => Ok(Atom::from_str(env, "toggle_play_pause")?.encode(env)),
        3 => Ok(Atom::from_str(env, "set_playhead")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_hover_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.WidgetHoverStyle",
    )?;
    term = term.map_put(
        Atom::from_str(env, "fill_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stroke_paints")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "opacity")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "are_fill_paints_set")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "are_stroke_paints_set")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_opacity_set")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "fill_paints")?, value)?;
            }
            2 => {
                let value =
                    decoder.read_repeated(|decoder| decode_paint_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stroke_paints")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "opacity")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "are_fill_paints_set")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "are_stroke_paints_set")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_opacity_set")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetHoverStyle",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_widget_derived_subtree_cursor_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.WidgetDerivedSubtreeCursor",
    )?;
    term = term.map_put(
        Atom::from_str(env, "session_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "counter")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "session_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "counter")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetDerivedSubtreeCursor",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_multiplayer_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.MultiplayerMap")?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_multiplayer_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MultiplayerMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_multiplayer_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.MultiplayerMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MultiplayerMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableDataMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_variable_data_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableDataMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableDataMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_field")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "node_field")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_data")?, value)?;
            }
            3 => {
                let value = decode_variable_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_field")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableDataMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_field_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "missing")?.encode(env)),
        1 => Ok(Atom::from_str(env, "corner_radius")?.encode(env)),
        2 => Ok(Atom::from_str(env, "paragraph_spacing")?.encode(env)),
        3 => Ok(Atom::from_str(env, "paragraph_indent")?.encode(env)),
        4 => Ok(Atom::from_str(env, "stroke_weight")?.encode(env)),
        5 => Ok(Atom::from_str(env, "stack_spacing")?.encode(env)),
        6 => Ok(Atom::from_str(env, "stack_padding_left")?.encode(env)),
        7 => Ok(Atom::from_str(env, "stack_padding_top")?.encode(env)),
        8 => Ok(Atom::from_str(env, "stack_padding_right")?.encode(env)),
        9 => Ok(Atom::from_str(env, "stack_padding_bottom")?.encode(env)),
        10 => Ok(Atom::from_str(env, "visible")?.encode(env)),
        11 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        12 => Ok(Atom::from_str(env, "width")?.encode(env)),
        13 => Ok(Atom::from_str(env, "height")?.encode(env)),
        14 => Ok(Atom::from_str(env, "rectangle_top_left_corner_radius")?.encode(env)),
        15 => Ok(Atom::from_str(env, "rectangle_top_right_corner_radius")?.encode(env)),
        16 => Ok(Atom::from_str(env, "rectangle_bottom_left_corner_radius")?.encode(env)),
        17 => Ok(Atom::from_str(env, "rectangle_bottom_right_corner_radius")?.encode(env)),
        18 => Ok(Atom::from_str(env, "border_top_weight")?.encode(env)),
        19 => Ok(Atom::from_str(env, "border_bottom_weight")?.encode(env)),
        20 => Ok(Atom::from_str(env, "border_left_weight")?.encode(env)),
        21 => Ok(Atom::from_str(env, "border_right_weight")?.encode(env)),
        22 => Ok(Atom::from_str(env, "variant_properties")?.encode(env)),
        23 => Ok(Atom::from_str(env, "stack_counter_spacing")?.encode(env)),
        24 => Ok(Atom::from_str(env, "min_width")?.encode(env)),
        25 => Ok(Atom::from_str(env, "max_width")?.encode(env)),
        26 => Ok(Atom::from_str(env, "min_height")?.encode(env)),
        27 => Ok(Atom::from_str(env, "max_height")?.encode(env)),
        28 => Ok(Atom::from_str(env, "font_family")?.encode(env)),
        29 => Ok(Atom::from_str(env, "font_style")?.encode(env)),
        30 => Ok(Atom::from_str(env, "font_variations")?.encode(env)),
        31 => Ok(Atom::from_str(env, "opacity")?.encode(env)),
        32 => Ok(Atom::from_str(env, "font_size")?.encode(env)),
        34 => Ok(Atom::from_str(env, "letter_spacing")?.encode(env)),
        36 => Ok(Atom::from_str(env, "line_height")?.encode(env)),
        37 => Ok(Atom::from_str(env, "overridden_symbol_id")?.encode(env)),
        38 => Ok(Atom::from_str(env, "hyperlink")?.encode(env)),
        39 => Ok(Atom::from_str(env, "cms_serialized_rich_text_data")?.encode(env)),
        40 => Ok(Atom::from_str(env, "slot_content_id")?.encode(env)),
        41 => Ok(Atom::from_str(env, "grid_row_gap")?.encode(env)),
        42 => Ok(Atom::from_str(env, "grid_column_gap")?.encode(env)),
        43 => Ok(Atom::from_str(env, "x_position")?.encode(env)),
        44 => Ok(Atom::from_str(env, "y_position")?.encode(env)),
        45 => Ok(Atom::from_str(env, "rotation")?.encode(env)),
        46 => Ok(Atom::from_str(env, "motion_translation_x")?.encode(env)),
        47 => Ok(Atom::from_str(env, "motion_translation_y")?.encode(env)),
        48 => Ok(Atom::from_str(env, "motion_rotation")?.encode(env)),
        49 => Ok(Atom::from_str(env, "motion_scale_x")?.encode(env)),
        50 => Ok(Atom::from_str(env, "motion_scale_y")?.encode(env)),
        51 => Ok(Atom::from_str(env, "motion_shear")?.encode(env)),
        52 => Ok(Atom::from_str(env, "scroll_offset_x")?.encode(env)),
        53 => Ok(Atom::from_str(env, "scroll_offset_y")?.encode(env)),
        54 => Ok(Atom::from_str(env, "path_trim_start")?.encode(env)),
        55 => Ok(Atom::from_str(env, "path_trim_end")?.encode(env)),
        56 => Ok(Atom::from_str(env, "dissolve_progress")?.encode(env)),
        57 => Ok(Atom::from_str(env, "easing_data")?.encode(env)),
        58 => Ok(Atom::from_str(env, "media_current_time")?.encode(env)),
        59 => Ok(Atom::from_str(env, "transform_3_d_perspective")?.encode(env)),
        60 => Ok(Atom::from_str(env, "transform_3_d_translation_z")?.encode(env)),
        61 => Ok(Atom::from_str(env, "transform_3_d_rotation_x")?.encode(env)),
        62 => Ok(Atom::from_str(env, "transform_3_d_rotation_y")?.encode(env)),
        63 => Ok(Atom::from_str(env, "transform_3_d_rotation_z")?.encode(env)),
        64 => Ok(Atom::from_str(env, "polygon_count")?.encode(env)),
        65 => Ok(Atom::from_str(env, "arc_data_starting_angle")?.encode(env)),
        66 => Ok(Atom::from_str(env, "arc_data_ending_angle")?.encode(env)),
        67 => Ok(Atom::from_str(env, "arc_data_inner_radius")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_variable_mode_by_set_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableModeBySetMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_variable_mode_by_set_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableModeBySetMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_mode_by_set_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableModeBySetMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_mode_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_extension_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_set_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_mode_id")?, value)?;
            }
            3 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_set_extension_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableModeBySetMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_syntax_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeSyntaxMap")?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_code_syntax_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeSyntaxMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_syntax_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CodeSyntaxMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "platform")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_code_syntax_platform_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "platform")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeSyntaxMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_table_merged_cell_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableMergedCellMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_table_merged_cell_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableMergedCellMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_table_merged_cell_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableMergedCellMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "row_id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "col_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "row_span")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "col_span")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "row_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "col_id")?, value)?;
            }
            3 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "row_span")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "col_span")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableMergedCellMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_table_row_column_position_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableRowColumnPositionMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_table_row_column_position_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableRowColumnPositionMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_table_row_column_position_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableRowColumnPositionMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableRowColumnPositionMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_position_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GUIDPositionMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_guid_position_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDPositionMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_position_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GUIDPositionMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDPositionMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_grid_track_size_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GUIDGridTrackSizeMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_guid_grid_track_size_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDGridTrackSizeMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_guid_grid_track_size_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GUIDGridTrackSizeMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "track_size")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_grid_track_size_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "track_size")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GUIDGridTrackSizeMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_grid_track_size_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GridTrackSize")?;
    term = term.map_put(
        Atom::from_str(env, "min_sizing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_sizing")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_grid_track_sizing_function_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "min_sizing")?, value)?;
            }
            2 => {
                let value = decode_grid_track_sizing_function_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "max_sizing")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GridTrackSize",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_grid_track_sizing_function_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.GridTrackSizingFunction",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_grid_track_sizing_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GridTrackSizingFunction",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_grid_track_sizing_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "flex")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fixed")?.encode(env)),
        2 => Ok(Atom::from_str(env, "hug")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_table_row_column_size_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableRowColumnSizeMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_table_row_column_size_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableRowColumnSizeMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_table_row_column_size_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TableRowColumnSizeMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "size")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "size")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TableRowColumnSizeMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_position_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaPositionMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_agenda_position_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaPositionMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_position_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaPositionMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaPositionMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_item_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "node")?.encode(env)),
        1 => Ok(Atom::from_str(env, "block")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_agenda_metadata_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaMetadataMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_agenda_metadata_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaMetadataMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_metadata_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaMetadataMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "data")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_agenda_metadata_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "data")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaMetadataMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_metadata_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AgendaMetadata")?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "target_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timer_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vote_info")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "music_info")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            2 => {
                let value = decode_agenda_item_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_node_id")?, value)?;
            }
            4 => {
                let value = decode_agenda_timer_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timer_info")?, value)?;
            }
            5 => {
                let value = decode_agenda_vote_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vote_info")?, value)?;
            }
            6 => {
                let value = decode_agenda_music_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "music_info")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaMetadata",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_timer_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaTimerInfo",
    )?;
    term = term.map_put(
        Atom::from_str(env, "timer_length")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "timer_length")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaTimerInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_vote_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AgendaVoteInfo")?;
    term = term.map_put(
        Atom::from_str(env, "vote_count")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "vote_count")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaVoteInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_agenda_music_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AgendaMusicInfo",
    )?;
    term = term.map_put(Atom::from_str(env, "song_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "start_time_ms")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "song_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "start_time_ms")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AgendaMusicInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_diagram_layout_rule_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "tree")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_diagram_parent_index_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DiagramParentIndex",
    )?;
    let value = decode_guid_from_decoder(env, decoder)?;
    term = term.map_put(Atom::from_str(env, "guid")?, value)?;
    let value = decoder.read_string()?;
    term = term.map_put(Atom::from_str(env, "position")?, value)?;
    Ok(term)
}
fn decode_diagram_layout_paused_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "no")?.encode(env)),
        1 => Ok(Atom::from_str(env, "yes")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_component_prop_ref_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ComponentPropRef",
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "def_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "zombie_fallback_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_node_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "node_field")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "def_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "zombie_fallback_name")?, value)?;
            }
            4 => {
                let value = decode_component_prop_node_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "component_prop_node_field")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ComponentPropRef",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_component_prop_node_field_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "visible")?.encode(env)),
        1 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        2 => Ok(Atom::from_str(env, "overridden_symbol_id")?.encode(env)),
        3 => Ok(Atom::from_str(env, "inherit_fill_style_id")?.encode(env)),
        4 => Ok(Atom::from_str(env, "slot_content_id")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_component_prop_assignment_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ComponentPropAssignment",
    )?;
    term = term.map_put(Atom::from_str(env, "def_id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "var_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "legacy_derived_text_data")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "def_id")?, value)?;
            }
            2 => {
                let value = decode_component_prop_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "var_value")?, value)?;
            }
            4 => {
                let value = decode_derived_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "legacy_derived_text_data")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ComponentPropAssignment",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_component_prop_def_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ComponentPropDef",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "initial_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sort_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_prop_def_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "preferred_values")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "var_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parameter_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slot_prop_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_array_config")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            3 => {
                let value = decode_component_prop_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "initial_value")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "sort_position")?, value)?;
            }
            5 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parent_prop_def_id")?, value)?;
            }
            6 => {
                let value = decode_component_prop_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            8 => {
                let value = decode_component_prop_preferred_values_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "preferred_values")?, value)?;
            }
            9 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "var_value")?, value)?;
            }
            10 => {
                let value = decode_parameter_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parameter_config")?, value)?;
            }
            11 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            12 => {
                let value = decode_slot_prop_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slot_prop_config")?, value)?;
            }
            13 => {
                let value = decode_color_array_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_array_config")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ComponentPropDef",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_component_prop_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ComponentPropValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "bool_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "guid_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "float_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "circle_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation3_d_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "circle_point_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "gradient_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_point_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "bool_value")?, value)?;
            }
            2 => {
                let value = decode_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_value")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid_value")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "float_value")?, value)?;
            }
            5 => {
                let value = decode_easing_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_data")?, value)?;
            }
            6 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vector_value")?, value)?;
            }
            7 => {
                let value = decode_line_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "line_value")?, value)?;
            }
            8 => {
                let value = decode_circle_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "circle_value")?, value)?;
            }
            9 => {
                let value = decode_rotation3_d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rotation3_d_value")?, value)?;
            }
            10 => {
                let value = decode_circle_point_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "circle_point_value")?, value)?;
            }
            11 => {
                let value = decode_gradient_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "gradient_value")?, value)?;
            }
            12 => {
                let value = decode_color_point_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_point_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ComponentPropValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TimelineData")?;
    term = term.map_put(
        Atom::from_str(env, "duration_us")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "default_timeline")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "playback_style")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "duration_us")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "default_timeline")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parent_timeline_def_id")?, value)?;
            }
            4 => {
                let value = decode_playback_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "playback_style")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_definitions_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineDefinitionsMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_timeline_definitions_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineDefinitionsMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_definitions_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineDefinitionsMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "data")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_timeline_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "data")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineDefinitionsMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_assignment_key_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineAssignmentKey",
    )?;
    term = term.map_put(
        Atom::from_str(env, "assigned_timeline_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "containing_timeline_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "assigned_timeline_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "containing_timeline_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineAssignmentKey",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_binding_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineBindingData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "offset_us")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "disabled")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_int64()?;
                term = term.map_put(Atom::from_str(env, "offset_us")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "disabled")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineBindingData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_assignments_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineAssignmentsMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_timeline_assignments_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineAssignmentsMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_timeline_assignments_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TimelineAssignmentsMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_timeline_assignment_key_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decode_timeline_binding_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TimelineAssignmentsMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_component_prop_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "bool")?.encode(env)),
        1 => Ok(Atom::from_str(env, "text")?.encode(env)),
        2 => Ok(Atom::from_str(env, "color")?.encode(env)),
        3 => Ok(Atom::from_str(env, "instance_swap")?.encode(env)),
        4 => Ok(Atom::from_str(env, "variant")?.encode(env)),
        5 => Ok(Atom::from_str(env, "number")?.encode(env)),
        6 => Ok(Atom::from_str(env, "image")?.encode(env)),
        7 => Ok(Atom::from_str(env, "slot")?.encode(env)),
        8 => Ok(Atom::from_str(env, "easing")?.encode(env)),
        9 => Ok(Atom::from_str(env, "color_array")?.encode(env)),
        10 => Ok(Atom::from_str(env, "vector")?.encode(env)),
        11 => Ok(Atom::from_str(env, "line")?.encode(env)),
        12 => Ok(Atom::from_str(env, "circle")?.encode(env)),
        13 => Ok(Atom::from_str(env, "rotation_3_d")?.encode(env)),
        14 => Ok(Atom::from_str(env, "circle_point")?.encode(env)),
        15 => Ok(Atom::from_str(env, "gradient")?.encode(env)),
        16 => Ok(Atom::from_str(env, "color_point")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_component_prop_preferred_values_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ComponentPropPreferredValues",
    )?;
    term = term.map_put(
        Atom::from_str(env, "string_values")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "instance_swap_values")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "string_values")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_instance_swap_preferred_value_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "instance_swap_values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ComponentPropPreferredValues",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_parameter_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ParameterConfig",
    )?;
    term = term.map_put(
        Atom::from_str(env, "number_prop_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "control")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "slider_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "label")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "input_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "select_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "point_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "point_radius_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation3_d_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "circle_point_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_point_config")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "show_divider_above")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_number_prop_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "number_prop_config")?, value)?;
            }
            2 => {
                let value = decode_parameter_config_control_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "control")?, value)?;
            }
            3 => {
                let value = decode_slider_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slider_config")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "label")?, value)?;
            }
            5 => {
                let value = decode_input_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "input_config")?, value)?;
            }
            6 => {
                let value = decode_select_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "select_config")?, value)?;
            }
            7 => {
                let value = decode_point_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "point_config")?, value)?;
            }
            8 => {
                let value = decode_line_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "line_config")?, value)?;
            }
            9 => {
                let value = decode_point_radius_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "point_radius_config")?, value)?;
            }
            10 => {
                let value = decode_rotation3_d_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rotation3_d_config")?, value)?;
            }
            11 => {
                let value = decode_circle_point_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "circle_point_config")?, value)?;
            }
            12 => {
                let value = decode_color_point_config_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_point_config")?, value)?;
            }
            13 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "show_divider_above")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ParameterConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_parameter_config_control_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "default")?.encode(env)),
        1 => Ok(Atom::from_str(env, "slider")?.encode(env)),
        2 => Ok(Atom::from_str(env, "input")?.encode(env)),
        3 => Ok(Atom::from_str(env, "select")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_input_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.InputConfig")?;
    term = term.map_put(Atom::from_str(env, "unit")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "min")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "max")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "min")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "max")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InputConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slider_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SliderConfig")?;
    term = term.map_put(Atom::from_str(env, "min")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "max")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "step")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "unit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "min")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "max")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "step")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SliderConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_point_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "canvas_and_ui")?.encode(env)),
        1 => Ok(Atom::from_str(env, "canvas")?.encode(env)),
        2 => Ok(Atom::from_str(env, "ui")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_point_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PointConfig")?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "unit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            2 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PointConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_line_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Line")?;
    term = term.map_put(Atom::from_str(env, "a")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "b")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "a")?, value)?;
            }
            2 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "b")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Line",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_line_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.LineConfig")?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "unit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            2 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LineConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_circle_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Circle")?;
    term = term.map_put(Atom::from_str(env, "center")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "radius")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "center")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "radius")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Circle",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_point_radius_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PointRadiusConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "position_unit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "radius_unit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_radius")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            2 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position_unit")?, value)?;
            }
            3 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "radius_unit")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "min_radius")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "max_radius")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PointRadiusConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_rotation3_d_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Rotation3D")?;
    term = term.map_put(Atom::from_str(env, "x")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "y")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "z")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "translate_z")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "x")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "y")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "z")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "translate_z")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Rotation3D",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_rotation3_d_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.Rotation3DConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Rotation3DConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_circle_point_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CirclePoint")?;
    term = term.map_put(Atom::from_str(env, "center")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "radius")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "angle")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "center")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "radius")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "angle")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CirclePoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_circle_point_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CirclePointConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "position_unit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "radius_unit")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_radius")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_radius")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            2 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "position_unit")?, value)?;
            }
            3 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "radius_unit")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "min_radius")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "max_radius")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CirclePointConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_color_point_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ColorPoint")?;
    term = term.map_put(Atom::from_str(env, "point")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "point")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ColorPoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_color_point_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ColorPointConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "mode")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "unit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_point_mode_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode")?, value)?;
            }
            2 => {
                let value = decode_number_units_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "unit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ColorPointConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_gradient_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Gradient")?;
    term = term.map_put(Atom::from_str(env, "stops")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_gradient_stop_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stops")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Gradient",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_gradient_stop_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.GradientStop")?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "color")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding GradientStop",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_select_option_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SelectOption")?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "label")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "label")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SelectOption",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_select_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SelectConfig")?;
    term = term.map_put(Atom::from_str(env, "options")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_select_option_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "options")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SelectConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_color_array_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ColorArrayConfig",
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_length")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_length")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "min_length")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "max_length")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ColorArrayConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slot_prop_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SlotPropConfig")?;
    term = term.map_put(
        Atom::from_str(env, "stretch_child_on_insert")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "display_by_default")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "min_children")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "max_children")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "allow_preferred_values_only")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "stretch_child_on_insert")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "display_by_default")?, value)?;
            }
            3 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "min_children")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "max_children")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "allow_preferred_values_only")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlotPropConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_number_prop_config_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NumberPropConfig",
    )?;
    term = term.map_put(Atom::from_str(env, "control")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "min")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "max")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "step")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_parameter_config_control_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "control")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "min")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "max")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "step")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NumberPropConfig",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_instance_swap_preferred_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InstanceSwapPreferredValue",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_instance_swap_preferred_value_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InstanceSwapPreferredValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_instance_swap_preferred_value_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "component")?.encode(env)),
        1 => Ok(Atom::from_str(env, "state_group")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_event_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "mouse_down")?.encode(env)),
        1 => Ok(Atom::from_str(env, "click")?.encode(env)),
        2 => Ok(Atom::from_str(env, "text_edit_end")?.encode(env)),
        3 => Ok(Atom::from_str(env, "attached_stickables_changed")?.encode(env)),
        4 => Ok(Atom::from_str(env, "stuck_status_changed")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_input_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "wrap")?.encode(env)),
        1 => Ok(Atom::from_str(env, "truncate")?.encode(env)),
        2 => Ok(Atom::from_str(env, "multiline")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_metadata_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.WidgetMetadata")?;
    term = term.map_put(
        Atom::from_str(env, "plugin_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plugin_version_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "widget_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_resizable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_rotatable")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "plugin_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "plugin_version_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "widget_name")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_resizable")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_rotatable")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetMetadata",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_widget_property_menu_item_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "action")?.encode(env)),
        1 => Ok(Atom::from_str(env, "separator")?.encode(env)),
        2 => Ok(Atom::from_str(env, "color")?.encode(env)),
        3 => Ok(Atom::from_str(env, "dropdown")?.encode(env)),
        4 => Ok(Atom::from_str(env, "color_selector")?.encode(env)),
        5 => Ok(Atom::from_str(env, "toggle")?.encode(env)),
        6 => Ok(Atom::from_str(env, "link")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_property_menu_selector_option_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.WidgetPropertyMenuSelectorOption",
    )?;
    term = term.map_put(Atom::from_str(env, "option")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "tooltip")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "option")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tooltip")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetPropertyMenuSelectorOption",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_widget_input_text_node_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "widget_controlled")?.encode(env)),
        1 => Ok(Atom::from_str(env, "rich_text")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_widget_property_menu_item_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.WidgetPropertyMenuItem",
    )?;
    term = term.map_put(
        Atom::from_str(env, "property_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "tooltip")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "item_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "icon")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "options")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "selected_option")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_toggled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "href")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "allow_custom_color")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "property_name")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tooltip")?, value)?;
            }
            3 => {
                let value = decode_widget_property_menu_item_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "item_type")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "icon")?, value)?;
            }
            5 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_widget_property_menu_selector_option_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "options")?, value)?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "selected_option")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_toggled")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "href")?, value)?;
            }
            9 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "allow_custom_color")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding WidgetPropertyMenuItem",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_block_language_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "typescript")?.encode(env)),
        1 => Ok(Atom::from_str(env, "cpp")?.encode(env)),
        2 => Ok(Atom::from_str(env, "ruby")?.encode(env)),
        3 => Ok(Atom::from_str(env, "css")?.encode(env)),
        4 => Ok(Atom::from_str(env, "javascript")?.encode(env)),
        5 => Ok(Atom::from_str(env, "html")?.encode(env)),
        6 => Ok(Atom::from_str(env, "json")?.encode(env)),
        7 => Ok(Atom::from_str(env, "graphql")?.encode(env)),
        8 => Ok(Atom::from_str(env, "python")?.encode(env)),
        9 => Ok(Atom::from_str(env, "go")?.encode(env)),
        10 => Ok(Atom::from_str(env, "sql")?.encode(env)),
        11 => Ok(Atom::from_str(env, "swift")?.encode(env)),
        12 => Ok(Atom::from_str(env, "kotlin")?.encode(env)),
        13 => Ok(Atom::from_str(env, "rust")?.encode(env)),
        14 => Ok(Atom::from_str(env, "bash")?.encode(env)),
        15 => Ok(Atom::from_str(env, "plaintext")?.encode(env)),
        16 => Ok(Atom::from_str(env, "markdown")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_code_block_theme_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "figjam_dark")?.encode(env)),
        1 => Ok(Atom::from_str(env, "dracula")?.encode(env)),
        2 => Ok(Atom::from_str(env, "duotone_sea")?.encode(env)),
        3 => Ok(Atom::from_str(env, "duotone_space")?.encode(env)),
        4 => Ok(Atom::from_str(env, "duotone_earth")?.encode(env)),
        5 => Ok(Atom::from_str(env, "duotone_forest")?.encode(env)),
        6 => Ok(Atom::from_str(env, "duotone_light")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_spec_block_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "default")?.encode(env)),
        1 => Ok(Atom::from_str(env, "paragraph")?.encode(env)),
        2 => Ok(Atom::from_str(env, "heading_1")?.encode(env)),
        3 => Ok(Atom::from_str(env, "heading_2")?.encode(env)),
        4 => Ok(Atom::from_str(env, "heading_3")?.encode(env)),
        5 => Ok(Atom::from_str(env, "heading_4")?.encode(env)),
        6 => Ok(Atom::from_str(env, "heading_5")?.encode(env)),
        7 => Ok(Atom::from_str(env, "heading_6")?.encode(env)),
        8 => Ok(Atom::from_str(env, "code_block")?.encode(env)),
        9 => Ok(Atom::from_str(env, "block_quote")?.encode(env)),
        10 => Ok(Atom::from_str(env, "horizontal_rule")?.encode(env)),
        11 => Ok(Atom::from_str(env, "ordered_list_item")?.encode(env)),
        12 => Ok(Atom::from_str(env, "unordered_list_item")?.encode(env)),
        13 => Ok(Atom::from_str(env, "document")?.encode(env)),
        14 => Ok(Atom::from_str(env, "table")?.encode(env)),
        15 => Ok(Atom::from_str(env, "table_row")?.encode(env)),
        16 => Ok(Atom::from_str(env, "table_cell")?.encode(env)),
        17 => Ok(Atom::from_str(env, "todo_list_item_unchecked")?.encode(env)),
        18 => Ok(Atom::from_str(env, "todo_list_item_checked")?.encode(env)),
        19 => Ok(Atom::from_str(env, "image")?.encode(env)),
        20 => Ok(Atom::from_str(env, "embed")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_internal_enum_for_test_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        1 => Ok(Atom::from_str(env, "old")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_internal_data_for_test_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.InternalDataForTest",
    )?;
    term = term.map_put(
        Atom::from_str(env, "test_field_a")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "test_field_a")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding InternalDataForTest",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_state_group_property_value_order_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.StateGroupPropertyValueOrder",
    )?;
    term = term.map_put(
        Atom::from_str(env, "property")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "values")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "property")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StateGroupPropertyValueOrder",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_backfill_error_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "transient_retrying")?.encode(env)),
        2 => Ok(Atom::from_str(env, "permanently_failed")?.encode(env)),
        3 => Ok(Atom::from_str(env, "paste_failed")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_partial_paste_annotation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PartialPasteAnnotation",
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_partial")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "annotated_at")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "error_state")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_partial")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "annotated_at")?, value)?;
            }
            3 => {
                let value = decode_backfill_error_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "error_state")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PartialPasteAnnotation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variant_prop_spec_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariantPropSpec",
    )?;
    term = term.map_put(
        Atom::from_str(env, "prop_def_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prop_def_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariantPropSpec",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_text_list_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TextListData")?;
    term = term.map_put(Atom::from_str(env, "list_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "bullet_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "indentation_level")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_number")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "list_id")?, value)?;
            }
            2 => {
                let value = decode_bullet_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "bullet_type")?, value)?;
            }
            3 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "indentation_level")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "line_number")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TextListData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_bullet_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "ordered")?.encode(env)),
        1 => Ok(Atom::from_str(env, "unordered")?.encode(env)),
        2 => Ok(Atom::from_str(env, "indent")?.encode(env)),
        3 => Ok(Atom::from_str(env, "no_list")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_text_line_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.TextLineData")?;
    term = term.map_put(
        Atom::from_str(env, "line_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "indentation_level")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "source_directionality")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "directionality")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "directionality_intent")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "downgrade_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "consistency_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "list_start_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_first_line_of_list")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_line_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "line_type")?, value)?;
            }
            10 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "style_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "indentation_level")?, value)?;
            }
            9 => {
                let value = decode_source_directionality_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "source_directionality")?, value)?;
            }
            3 => {
                let value = decode_directionality_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "directionality")?, value)?;
            }
            4 => {
                let value = decode_directionality_intent_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "directionality_intent")?, value)?;
            }
            5 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "downgrade_style_id")?, value)?;
            }
            6 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "consistency_style_id")?, value)?;
            }
            7 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "list_start_offset")?, value)?;
            }
            8 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_first_line_of_list")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TextLineData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_derived_text_line_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.DerivedTextLineData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "directionality")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_directionality_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "directionality")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding DerivedTextLineData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_line_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "plain")?.encode(env)),
        1 => Ok(Atom::from_str(env, "ordered_list")?.encode(env)),
        2 => Ok(Atom::from_str(env, "unordered_list")?.encode(env)),
        3 => Ok(Atom::from_str(env, "blockquote")?.encode(env)),
        4 => Ok(Atom::from_str(env, "header")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_source_directionality_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        1 => Ok(Atom::from_str(env, "ltr")?.encode(env)),
        2 => Ok(Atom::from_str(env, "rtl")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_directionality_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "ltr")?.encode(env)),
        1 => Ok(Atom::from_str(env, "rtl")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_directionality_intent_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "implicit")?.encode(env)),
        1 => Ok(Atom::from_str(env, "explicit")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_prototype_interaction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PrototypeInteraction",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "event")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "actions")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "state_management_version")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_prototype_event_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "event")?, value)?;
            }
            3 => {
                let value = decoder
                    .read_repeated(|decoder| decode_prototype_action_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "actions")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            5 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "state_management_version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeInteraction",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prototype_event_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PrototypeEvent")?;
    term = term.map_put(
        Atom::from_str(env, "interaction_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_maintained")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "key_trigger")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "voice_event_phrase")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_timeout")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_hit_time")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_interaction_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "interaction_type")?, value)?;
            }
            2 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "interaction_maintained")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "interaction_duration")?, value)?;
            }
            4 => {
                let value = decode_key_trigger_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "key_trigger")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "voice_event_phrase")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_timeout")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "media_hit_time")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeEvent",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prototype_variable_target_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PrototypeVariableTarget",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "node_field_alias")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_node_field_alias_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_field_alias")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeVariableTarget",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_conditional_actions_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ConditionalActions",
    )?;
    term = term.map_put(Atom::from_str(env, "actions")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "condition")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_prototype_action_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "actions")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "condition")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ConditionalActions",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prototype_action_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PrototypeAction",
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_node_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_timeout")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_should_smart_animate")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connection_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "overlay_relative_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "navigation_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_preserve_scroll")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_function")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "extra_scroll_offset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_reset_scroll_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_reset_interactive_components")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_overrides_enabled")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "connection_url")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "open_url_in_new_tab")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "link_param")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_target")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_data")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_action")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_reset_video_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_skip_to_time")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_skip_by_amount")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "media_playback_rate")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "conditions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "conditional_actions")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_mode_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "target_variable_set_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_set_target_extension_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_target_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_phase")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "simple_link")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_timeline_action")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_skip_to_time")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_node_id")?, value)?;
            }
            2 => {
                let value = decode_transition_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_type")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_duration")?, value)?;
            }
            4 => {
                let value = decode_easing_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_type")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_timeout")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "transition_should_smart_animate")?,
                    value,
                )?;
            }
            7 => {
                let value = decode_connection_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "connection_type")?, value)?;
            }
            9 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "overlay_relative_position")?, value)?;
            }
            10 => {
                let value = decode_navigation_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "navigation_type")?, value)?;
            }
            11 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "transition_preserve_scroll")?, value)?;
            }
            12 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(Atom::from_str(env, "easing_function")?, value)?;
            }
            13 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "extra_scroll_offset")?, value)?;
            }
            25 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "transition_reset_scroll_position")?,
                    value,
                )?;
            }
            26 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "transition_reset_interactive_components")?,
                    value,
                )?;
            }
            42 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "transition_overrides_enabled")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "connection_url")?, value)?;
            }
            18 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "open_url_in_new_tab")?, value)?;
            }
            34 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "link_param")?, value)?;
            }
            35 => {
                let value = decode_cms_item_page_target_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_target")?, value)?;
            }
            14 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable_id")?, value)?;
            }
            15 => {
                let value = decode_variable_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable_value")?, value)?;
            }
            19 => {
                let value = decode_prototype_variable_target_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable")?, value)?;
            }
            20 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable_data")?, value)?;
            }
            16 => {
                let value = decode_media_action_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "media_action")?, value)?;
            }
            17 => {
                let value = decoder.read_bool()?;
                term = term.map_put(
                    Atom::from_str(env, "transition_reset_video_position")?,
                    value,
                )?;
            }
            21 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "media_skip_to_time")?, value)?;
            }
            22 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "media_skip_by_amount")?, value)?;
            }
            36 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "media_playback_rate")?, value)?;
            }
            23 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variable_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "conditions")?, value)?;
            }
            24 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_conditional_actions_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "conditional_actions")?, value)?;
            }
            27 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable_set_id")?, value)?;
            }
            28 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "target_variable_mode_id")?, value)?;
            }
            29 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "target_variable_set_key")?, value)?;
            }
            38 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "variable_set_target_extension_id")?,
                    value,
                )?;
            }
            30 => {
                let value = decode_animation_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_type")?, value)?;
            }
            31 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_target_id")?, value)?;
            }
            32 => {
                let value = decode_animation_phase_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_phase")?, value)?;
            }
            33 => {
                let value = decode_animation_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_state")?, value)?;
            }
            37 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "simple_link")?, value)?;
            }
            39 => {
                let value = decode_animation_timeline_action_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_timeline_action")?, value)?;
            }
            41 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_timeline_def_id")?, value)?;
            }
            40 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "animation_skip_to_time")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeAction",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_animation_phase_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "in")?.encode(env)),
        1 => Ok(Atom::from_str(env, "out")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_animation_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "fade")?.encode(env)),
        2 => Ok(Atom::from_str(env, "slide_from_left")?.encode(env)),
        3 => Ok(Atom::from_str(env, "slide_from_right")?.encode(env)),
        4 => Ok(Atom::from_str(env, "slide_from_top")?.encode(env)),
        5 => Ok(Atom::from_str(env, "slide_from_bottom")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_animation_state_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AnimationState")?;
    term = term.map_put(Atom::from_str(env, "opacity")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "transform")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "opacity")?, value)?;
            }
            2 => {
                let value = decode_matrix_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transform")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnimationState",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prototype_starting_point_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PrototypeStartingPoint",
    )?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "position")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "position")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PrototypeStartingPoint",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_trigger_device_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "keyboard")?.encode(env)),
        1 => Ok(Atom::from_str(env, "unknown_controller")?.encode(env)),
        2 => Ok(Atom::from_str(env, "xbox_one")?.encode(env)),
        3 => Ok(Atom::from_str(env, "ps4")?.encode(env)),
        4 => Ok(Atom::from_str(env, "switch_pro")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_key_trigger_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.KeyTrigger")?;
    term = term.map_put(
        Atom::from_str(env, "key_codes")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "trigger_device")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_int())?;
                term = term.map_put(Atom::from_str(env, "key_codes")?, value)?;
            }
            2 => {
                let value = decode_trigger_device_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger_device")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyTrigger",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_hyperlink_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Hyperlink")?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "cms_target")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "open_in_new_tab")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            4 => {
                let value = decode_cms_item_page_target_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_target")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "open_in_new_tab")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Hyperlink",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cms_item_page_target_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CMSItemPageTarget",
    )?;
    term = term.map_put(Atom::from_str(env, "node_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "cms_item_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "field_schema_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "cms_item_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "field_schema_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSItemPageTarget",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_mention_source_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "default")?.encode(env)),
        1 => Ok(Atom::from_str(env, "copy_duplicate")?.encode(env)),
        2 => Ok(Atom::from_str(env, "silent_insert")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_mention_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Mention")?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "mentioned_user_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mentioned_by_user_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "file_key")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "source")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "mentioned_user_id_int")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mentioned_by_user_id_int")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "mentioned_user_group_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "mentioned_user_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "mentioned_by_user_id")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "file_key")?, value)?;
            }
            5 => {
                let value = decode_mention_source_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "source")?, value)?;
            }
            6 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "mentioned_user_id_int")?, value)?;
            }
            7 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "mentioned_by_user_id_int")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "mentioned_user_group_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Mention",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_embed_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EmbedData")?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "src_url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "title")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_url")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "width")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "height")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "embed_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "favicon_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "provider")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "original_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "embed_version_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_published_site")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "src_url")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "title")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumbnail_url")?, value)?;
            }
            5 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "width")?, value)?;
            }
            6 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "height")?, value)?;
            }
            7 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "embed_type")?, value)?;
            }
            8 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumbnail_image_hash")?, value)?;
            }
            9 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "favicon_image_hash")?, value)?;
            }
            10 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "provider")?, value)?;
            }
            11 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "original_text")?, value)?;
            }
            12 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            13 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "embed_version_id")?, value)?;
            }
            14 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_published_site")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EmbedData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_stamp_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.StampData")?;
    term = term.map_put(Atom::from_str(env, "user_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "voting_session_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "stamped_by_user_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "voting_session_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "stamped_by_user_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StampData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_link_preview_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.LinkPreviewData",
    )?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "title")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "provider")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "description")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "favicon_image_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_image_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_image_height")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "title")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "provider")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "description")?, value)?;
            }
            5 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumbnail_image_hash")?, value)?;
            }
            6 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "favicon_image_hash")?, value)?;
            }
            7 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "thumbnail_image_width")?, value)?;
            }
            8 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "thumbnail_image_height")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LinkPreviewData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_rich_media_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "animated_image")?.encode(env)),
        1 => Ok(Atom::from_str(env, "video")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_rich_media_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.RichMediaData")?;
    term = term.map_put(
        Atom::from_str(env, "media_hash")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rich_media_type")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "media_hash")?, value)?;
            }
            2 => {
                let value = decode_rich_media_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rich_media_type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding RichMediaData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "boolean")?.encode(env)),
        1 => Ok(Atom::from_str(env, "float")?.encode(env)),
        2 => Ok(Atom::from_str(env, "string")?.encode(env)),
        3 => Ok(Atom::from_str(env, "alias")?.encode(env)),
        4 => Ok(Atom::from_str(env, "color")?.encode(env)),
        5 => Ok(Atom::from_str(env, "expression")?.encode(env)),
        6 => Ok(Atom::from_str(env, "map")?.encode(env)),
        7 => Ok(Atom::from_str(env, "symbol_id")?.encode(env)),
        8 => Ok(Atom::from_str(env, "font_style")?.encode(env)),
        9 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        10 => Ok(Atom::from_str(env, "invalid")?.encode(env)),
        11 => Ok(Atom::from_str(env, "node_field_alias")?.encode(env)),
        12 => Ok(Atom::from_str(env, "cms_alias")?.encode(env)),
        13 => Ok(Atom::from_str(env, "prop_ref")?.encode(env)),
        14 => Ok(Atom::from_str(env, "image")?.encode(env)),
        15 => Ok(Atom::from_str(env, "managed_string_alias")?.encode(env)),
        16 => Ok(Atom::from_str(env, "link")?.encode(env)),
        17 => Ok(Atom::from_str(env, "js_runtime_alias")?.encode(env)),
        18 => Ok(Atom::from_str(env, "slot_content_id")?.encode(env)),
        19 => Ok(Atom::from_str(env, "date")?.encode(env)),
        20 => Ok(Atom::from_str(env, "keyframe_track_id")?.encode(env)),
        21 => Ok(Atom::from_str(env, "keyframe_track_parameter_data")?.encode(env)),
        22 => Ok(Atom::from_str(env, "easing")?.encode(env)),
        23 => Ok(Atom::from_str(env, "timing")?.encode(env)),
        24 => Ok(Atom::from_str(env, "vector")?.encode(env)),
        25 => Ok(Atom::from_str(env, "color_array")?.encode(env)),
        26 => Ok(Atom::from_str(env, "line")?.encode(env)),
        27 => Ok(Atom::from_str(env, "circle")?.encode(env)),
        28 => Ok(Atom::from_str(env, "rotation_3_d")?.encode(env)),
        29 => Ok(Atom::from_str(env, "circle_point")?.encode(env)),
        30 => Ok(Atom::from_str(env, "gradient")?.encode(env)),
        31 => Ok(Atom::from_str(env, "color_point")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_variable_resolved_data_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "boolean")?.encode(env)),
        1 => Ok(Atom::from_str(env, "float")?.encode(env)),
        2 => Ok(Atom::from_str(env, "string")?.encode(env)),
        4 => Ok(Atom::from_str(env, "color")?.encode(env)),
        5 => Ok(Atom::from_str(env, "map")?.encode(env)),
        6 => Ok(Atom::from_str(env, "symbol_id")?.encode(env)),
        7 => Ok(Atom::from_str(env, "font_style")?.encode(env)),
        8 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        9 => Ok(Atom::from_str(env, "image")?.encode(env)),
        10 => Ok(Atom::from_str(env, "link")?.encode(env)),
        11 => Ok(Atom::from_str(env, "js_runtime_alias")?.encode(env)),
        12 => Ok(Atom::from_str(env, "slot_content_id")?.encode(env)),
        13 => Ok(Atom::from_str(env, "keyframe_track_id")?.encode(env)),
        14 => Ok(Atom::from_str(env, "keyframe_track_parameter_data")?.encode(env)),
        15 => Ok(Atom::from_str(env, "easing")?.encode(env)),
        16 => Ok(Atom::from_str(env, "timing")?.encode(env)),
        17 => Ok(Atom::from_str(env, "vector")?.encode(env)),
        18 => Ok(Atom::from_str(env, "color_array")?.encode(env)),
        19 => Ok(Atom::from_str(env, "line")?.encode(env)),
        20 => Ok(Atom::from_str(env, "circle")?.encode(env)),
        21 => Ok(Atom::from_str(env, "rotation_3_d")?.encode(env)),
        22 => Ok(Atom::from_str(env, "circle_point")?.encode(env)),
        23 => Ok(Atom::from_str(env, "gradient")?.encode(env)),
        24 => Ok(Atom::from_str(env, "color_point")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_variable_any_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableAnyValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "bool_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "float_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "alias")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "color_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "expression_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "map_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "symbol_id_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "font_style_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_data_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_field_alias_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cms_alias_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "prop_ref_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "image_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "managed_string_alias_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "link_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "js_runtime_alias_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "slot_content_id_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_track_id_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_track_parameter_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_array_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "line_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "circle_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation3_d_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "circle_point_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "gradient_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_point_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "bool_value")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "text_value")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "float_value")?, value)?;
            }
            4 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "alias")?, value)?;
            }
            5 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_value")?, value)?;
            }
            6 => {
                let value = decode_expression_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "expression_value")?, value)?;
            }
            7 => {
                let value = decode_variable_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "map_value")?, value)?;
            }
            8 => {
                let value = decode_symbol_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "symbol_id_value")?, value)?;
            }
            9 => {
                let value = decode_variable_font_style_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "font_style_value")?, value)?;
            }
            10 => {
                let value = decode_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_data_value")?, value)?;
            }
            11 => {
                let value = decode_node_field_alias_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_field_alias_value")?, value)?;
            }
            12 => {
                let value = decode_cms_alias_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cms_alias_value")?, value)?;
            }
            13 => {
                let value = decode_prop_ref_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prop_ref_value")?, value)?;
            }
            14 => {
                let value = decode_image_parameter_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_value")?, value)?;
            }
            15 => {
                let value = decode_managed_string_alias_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "managed_string_alias_value")?, value)?;
            }
            16 => {
                let value = decode_hyperlink_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "link_value")?, value)?;
            }
            17 => {
                let value = decode_js_runtime_alias_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "js_runtime_alias_value")?, value)?;
            }
            18 => {
                let value = decode_slot_content_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "slot_content_id_value")?, value)?;
            }
            19 => {
                let value = decode_keyframe_track_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_track_id_value")?, value)?;
            }
            20 => {
                let value = decode_keyframe_track_parameter_value_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "keyframe_track_parameter_value")?,
                    value,
                )?;
            }
            21 => {
                let value = decode_easing_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_value")?, value)?;
            }
            22 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vector_value")?, value)?;
            }
            23 => {
                let value = decode_color_array_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_array_value")?, value)?;
            }
            24 => {
                let value = decode_line_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "line_value")?, value)?;
            }
            25 => {
                let value = decode_circle_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "circle_value")?, value)?;
            }
            26 => {
                let value = decode_rotation3_d_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "rotation3_d_value")?, value)?;
            }
            27 => {
                let value = decode_circle_point_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "circle_point_value")?, value)?;
            }
            28 => {
                let value = decode_gradient_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "gradient_value")?, value)?;
            }
            29 => {
                let value = decode_color_point_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_point_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableAnyValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_expression_function_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "addition")?.encode(env)),
        1 => Ok(Atom::from_str(env, "subtraction")?.encode(env)),
        2 => Ok(Atom::from_str(env, "resolve_variant")?.encode(env)),
        3 => Ok(Atom::from_str(env, "multiply")?.encode(env)),
        4 => Ok(Atom::from_str(env, "divide")?.encode(env)),
        5 => Ok(Atom::from_str(env, "equals")?.encode(env)),
        6 => Ok(Atom::from_str(env, "not_equal")?.encode(env)),
        7 => Ok(Atom::from_str(env, "less_than")?.encode(env)),
        8 => Ok(Atom::from_str(env, "less_than_or_equal")?.encode(env)),
        9 => Ok(Atom::from_str(env, "greater_than")?.encode(env)),
        10 => Ok(Atom::from_str(env, "greater_than_or_equal")?.encode(env)),
        11 => Ok(Atom::from_str(env, "and")?.encode(env)),
        12 => Ok(Atom::from_str(env, "or")?.encode(env)),
        13 => Ok(Atom::from_str(env, "not")?.encode(env)),
        14 => Ok(Atom::from_str(env, "stringify")?.encode(env)),
        15 => Ok(Atom::from_str(env, "ternary")?.encode(env)),
        16 => Ok(Atom::from_str(env, "var_mode_lookup")?.encode(env)),
        17 => Ok(Atom::from_str(env, "negate")?.encode(env)),
        18 => Ok(Atom::from_str(env, "is_truthy")?.encode(env)),
        19 => Ok(Atom::from_str(env, "keyframe")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_expression_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Expression")?;
    term = term.map_put(
        Atom::from_str(env, "expression_function")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "expression_arguments")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_expression_function_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "expression_function")?, value)?;
            }
            2 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variable_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "expression_arguments")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Expression",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_map_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableMapValue",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "guid_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableMapValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VariableMap")?;
    term = term.map_put(Atom::from_str(env, "values")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_variable_map_value_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_color_array_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ColorArray")?;
    term = term.map_put(Atom::from_str(env, "colors")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_variable_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "colors")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ColorArray",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_font_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableFontStyle",
    )?;
    term = term.map_put(
        Atom::from_str(env, "as_string")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "as_float")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "as_variations")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "as_string")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "as_float")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "as_variations")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableFontStyle",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_image_parameter_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ImageParameterValue",
    )?;
    term = term.map_put(Atom::from_str(env, "image")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "image_thumbnail")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animated_image")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "alt_text")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "original_image_height")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "original_image_width")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_frame")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image")?, value)?;
            }
            2 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image_thumbnail")?, value)?;
            }
            6 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animated_image")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "alt_text")?, value)?;
            }
            4 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "original_image_height")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "original_image_width")?, value)?;
            }
            7 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "animation_frame")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ImageParameterValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_thumbnail_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ThumbnailInfo")?;
    term = term.map_put(Atom::from_str(env, "node_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_version")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "thumbnail_version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ThumbnailInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_ai_canvas_prompt_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AiCanvasPrompt")?;
    term = term.map_put(
        Atom::from_str(env, "user_prompt")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "author_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_node_ids")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_prompt")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "author_id")?, value)?;
            }
            3 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "parent_node_ids")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AiCanvasPrompt",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_field_alias_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.NodeFieldAlias")?;
    term = term.map_put(
        Atom::from_str(env, "stable_path_to_node")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "index_or_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "stable_path_to_node")?, value)?;
            }
            2 => {
                let value = decode_node_field_alias_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "node_field")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "index_or_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeFieldAlias",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_field_alias_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "missing")?.encode(env)),
        1 => Ok(Atom::from_str(env, "component_prop_assignments")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cms_alias_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CMSAlias")?;
    term = term.map_put(
        Atom::from_str(env, "collection_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "item_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "field_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "collection_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "item_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "field_id")?, value)?;
            }
            4 => {
                let value = decode_variable_data_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CMSAlias",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_js_runtime_alias_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.JsRuntimeAlias")?;
    term = term.map_put(
        Atom::from_str(env, "lookup_key")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "lookup_key")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding JsRuntimeAlias",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_prop_ref_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PropRefValue")?;
    term = term.map_put(Atom::from_str(env, "def_id")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "def_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PropRefValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringId",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_placeholder_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringPlaceholderMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringPlaceholderMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slot_content_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SlotContentId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlotContentId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_managed_string_alias_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManagedStringAlias",
    )?;
    term = term.map_put(
        Atom::from_str(env, "managed_string_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "placeholder_values")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_managed_string_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "managed_string_id")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_managed_string_placeholder_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "placeholder_values")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManagedStringAlias",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_track_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeTrackId",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeTrackId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_animation_preset_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnimationPresetId",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnimationPresetId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_tool_id_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ToolId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ToolId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_custom_effect_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CustomEffectId")?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "asset_ref")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_asset_ref_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "asset_ref")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CustomEffectId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_trss_transform2_d_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TRSSTransform2D",
    )?;
    term = term.map_put(
        Atom::from_str(env, "translation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "rotation")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "scale")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "shear_x")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "translation")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "rotation")?, value)?;
            }
            3 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scale")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "shear_x")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TRSSTransform2D",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.VariableData")?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "data_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "resolved_data_type")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            2 => {
                let value = decode_variable_data_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "data_type")?, value)?;
            }
            3 => {
                let value = decode_variable_resolved_data_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "resolved_data_type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_set_mode_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableSetMode",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "sort_position")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_variable_set_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parent_mode_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "sort_position")?, value)?;
            }
            4 => {
                let value = decode_variable_set_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parent_variable_set_id")?, value)?;
            }
            5 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parent_mode_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableSetMode",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_values_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableDataValues",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_variable_data_values_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableDataValues",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_data_values_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableDataValuesEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "mode_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "variable_data")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "mode_id")?, value)?;
            }
            2 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_data")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableDataValuesEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_scope_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "all_scopes")?.encode(env)),
        1 => Ok(Atom::from_str(env, "text_content")?.encode(env)),
        2 => Ok(Atom::from_str(env, "corner_radius")?.encode(env)),
        3 => Ok(Atom::from_str(env, "width_height")?.encode(env)),
        4 => Ok(Atom::from_str(env, "gap")?.encode(env)),
        5 => Ok(Atom::from_str(env, "all_fills")?.encode(env)),
        6 => Ok(Atom::from_str(env, "frame_fill")?.encode(env)),
        7 => Ok(Atom::from_str(env, "shape_fill")?.encode(env)),
        8 => Ok(Atom::from_str(env, "text_fill")?.encode(env)),
        9 => Ok(Atom::from_str(env, "stroke")?.encode(env)),
        10 => Ok(Atom::from_str(env, "stroke_float")?.encode(env)),
        11 => Ok(Atom::from_str(env, "effect_float")?.encode(env)),
        12 => Ok(Atom::from_str(env, "effect_color")?.encode(env)),
        13 => Ok(Atom::from_str(env, "opacity")?.encode(env)),
        14 => Ok(Atom::from_str(env, "font_style")?.encode(env)),
        15 => Ok(Atom::from_str(env, "font_family")?.encode(env)),
        16 => Ok(Atom::from_str(env, "font_size")?.encode(env)),
        17 => Ok(Atom::from_str(env, "line_height")?.encode(env)),
        18 => Ok(Atom::from_str(env, "letter_spacing")?.encode(env)),
        19 => Ok(Atom::from_str(env, "paragraph_spacing")?.encode(env)),
        20 => Ok(Atom::from_str(env, "paragraph_indent")?.encode(env)),
        21 => Ok(Atom::from_str(env, "font_variations")?.encode(env)),
        22 => Ok(Atom::from_str(env, "transform")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_keyframe_any_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeAnyValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "float_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "color_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_data_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "vector_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "float_value")?, value)?;
            }
            2 => {
                let value = decode_color_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "color_value")?, value)?;
            }
            3 => {
                let value = decode_text_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "text_data_value")?, value)?;
            }
            4 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "vector_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeAnyValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_value_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "float")?.encode(env)),
        1 => Ok(Atom::from_str(env, "invalid")?.encode(env)),
        2 => Ok(Atom::from_str(env, "color")?.encode(env)),
        3 => Ok(Atom::from_str(env, "text_data")?.encode(env)),
        4 => Ok(Atom::from_str(env, "vector")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_keyframe_value_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeValueData",
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "value_type")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_keyframe_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            2 => {
                let value = decode_keyframe_value_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value_type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeValueData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_track_parameter_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "invalid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "manual")?.encode(env)),
        2 => Ok(Atom::from_str(env, "animation_preset")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_manual_keyframe_track_parameter_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ManualKeyframeTrackParameter",
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_track_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_keyframe_track_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_track_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_def_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ManualKeyframeTrackParameter",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_animation_preset_keyframe_track_parameter_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnimationPresetKeyframeTrackParameter",
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_preset_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "keyframe_track_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_animation_preset_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_preset_id")?, value)?;
            }
            2 => {
                let value = decode_keyframe_track_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "keyframe_track_id")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_def_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnimationPresetKeyframeTrackParameter",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_track_any_parameter_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeTrackAnyParameter",
    )?;
    term = term.map_put(Atom::from_str(env, "manual")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "animation_preset")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_style_binding_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_manual_keyframe_track_parameter_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "manual")?, value)?;
            }
            2 => {
                let value =
                    decode_animation_preset_keyframe_track_parameter_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_preset")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_style_binding_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeTrackAnyParameter",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_track_parameter_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeTrackParameter",
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_keyframe_track_any_parameter_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            2 => {
                let value = decode_keyframe_track_parameter_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeTrackParameter",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_track_parameter_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.KeyframeTrackParameterValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "parameters")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_keyframe_track_parameter_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "parameters")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding KeyframeTrackParameterValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_animation_presets_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnimationPresets",
    )?;
    term = term.map_put(Atom::from_str(env, "presets")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_animation_preset_data_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "presets")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnimationPresets",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_animation_preset_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AnimationPresetData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_preset_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_animation_preset_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_preset_id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_def_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AnimationPresetData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_style_animation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.StyleAnimation")?;
    term = term.map_put(
        Atom::from_str(env, "animation_preset_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_animation_preset_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_preset_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StyleAnimation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_style_id_for_animation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.StyleIdForAnimation",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "timeline_def_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "animation_style_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "timeline_offset")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "timeline_def_id")?, value)?;
            }
            3 => {
                let value = decode_style_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "animation_style_id")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int64()?;
                term = term.map_put(Atom::from_str(env, "timeline_offset")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding StyleIdForAnimation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_tools_from_decoder<'a>(env: Env<'a>, decoder: &mut Decoder<'_>) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.Tools")?;
    term = term.map_put(Atom::from_str(env, "tools")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decoder.read_repeated(|decoder| decode_tool_data_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "tools")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding Tools",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_tool_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ToolData")?;
    term = term.map_put(Atom::from_str(env, "tool_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "backing_code_component_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_assignments")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_tool_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "tool_id")?, value)?;
            }
            2 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "backing_code_component_id")?, value)?;
            }
            3 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_assignment_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_assignments")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ToolData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_custom_effects_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CustomEffects")?;
    term = term.map_put(
        Atom::from_str(env, "custom_effects")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_custom_effect_data_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "custom_effects")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CustomEffects",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_custom_effect_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CustomEffectData",
    )?;
    term = term.map_put(
        Atom::from_str(env, "custom_effect_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_custom_effect_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "custom_effect_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CustomEffectData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_spring_params_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SpringParams")?;
    term = term.map_put(
        Atom::from_str(env, "stiffness")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "damping")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "mass")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "stiffness")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "damping")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "mass")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SpringParams",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_easing_any_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionEasingAnyValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "spring_easing")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "bezier_easing")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_spring_params_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "spring_easing")?, value)?;
            }
            2 => {
                let value = decode_bezier_handles_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "bezier_easing")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionEasingAnyValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_easing_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EasingData")?;
    term = term.map_put(
        Atom::from_str(env, "easing_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_easing_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_type")?, value)?;
            }
            2 => {
                let value = decode_transition_easing_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EasingData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_override_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionOverride",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "duration_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "delay")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "delay_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "easing")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "easing_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "created_at_ms")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "interaction_i_ds")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "disabled")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "duration")?, value)?;
            }
            3 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "duration_var")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "delay")?, value)?;
            }
            5 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "delay_var")?, value)?;
            }
            6 => {
                let value = decode_easing_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing")?, value)?;
            }
            7 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_var")?, value)?;
            }
            8 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "created_at_ms")?, value)?;
            }
            9 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "interaction_i_ds")?, value)?;
            }
            10 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "disabled")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionOverride",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_override_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionOverrideData",
    )?;
    term = term.map_put(Atom::from_str(env, "all")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "property_overrides")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_transition_override_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "all")?, value)?;
            }
            2 => {
                let value = decode_transition_override_prop_map_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "property_overrides")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionOverrideData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_override_prop_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "all")?.encode(env)),
        1 => Ok(Atom::from_str(env, "opacity")?.encode(env)),
        2 => Ok(Atom::from_str(env, "translation")?.encode(env)),
        3 => Ok(Atom::from_str(env, "rotation")?.encode(env)),
        4 => Ok(Atom::from_str(env, "scale")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_transition_override_binding_top_level_field_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "missing")?.encode(env)),
        1 => Ok(Atom::from_str(env, "parameter_consumption_map")?.encode(env)),
        2 => Ok(Atom::from_str(env, "effect_data")?.encode(env)),
        3 => Ok(Atom::from_str(env, "fill_paint_data")?.encode(env)),
        4 => Ok(Atom::from_str(env, "stroke_paint_data")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_transition_override_binding_location_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionOverrideBindingLocation",
    )?;
    term = term.map_put(
        Atom::from_str(env, "top_level_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parameter_field_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "index")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "effect_parametrized_field_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decode_transition_override_binding_top_level_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "top_level_field")?, value)?;
            }
            2 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "parameter_field_value")?, value)?;
            }
            3 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "index")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(
                    Atom::from_str(env, "effect_parametrized_field_value")?,
                    value,
                )?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionOverrideBindingLocation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_binding_effect_parametrized_field_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "missing")?.encode(env)),
        1 => Ok(Atom::from_str(env, "offset_x")?.encode(env)),
        2 => Ok(Atom::from_str(env, "offset_y")?.encode(env)),
        3 => Ok(Atom::from_str(env, "radius")?.encode(env)),
        4 => Ok(Atom::from_str(env, "spread")?.encode(env)),
        5 => Ok(Atom::from_str(env, "color")?.encode(env)),
        6 => Ok(Atom::from_str(env, "refraction_radius")?.encode(env)),
        7 => Ok(Atom::from_str(env, "specular_angle")?.encode(env)),
        8 => Ok(Atom::from_str(env, "specular_intensity")?.encode(env)),
        9 => Ok(Atom::from_str(env, "chromatic_aberration")?.encode(env)),
        10 => Ok(Atom::from_str(env, "splay")?.encode(env)),
        11 => Ok(Atom::from_str(env, "refraction_intensity")?.encode(env)),
        12 => Ok(Atom::from_str(env, "start_radius")?.encode(env)),
        13 => Ok(Atom::from_str(env, "start_offset_x")?.encode(env)),
        14 => Ok(Atom::from_str(env, "start_offset_y")?.encode(env)),
        15 => Ok(Atom::from_str(env, "end_offset_x")?.encode(env)),
        16 => Ok(Atom::from_str(env, "end_offset_y")?.encode(env)),
        17 => Ok(Atom::from_str(env, "noise_size_x")?.encode(env)),
        18 => Ok(Atom::from_str(env, "noise_size_y")?.encode(env)),
        19 => Ok(Atom::from_str(env, "density")?.encode(env)),
        20 => Ok(Atom::from_str(env, "effect_opacity")?.encode(env)),
        21 => Ok(Atom::from_str(env, "secondary_color")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_contents_keyframe_binding_location_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeContentsKeyframeBindingLocation",
    )?;
    term = term.map_put(
        Atom::from_str(env, "top_level_field")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "parameter_field_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "index")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "effect_parametrized_field_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value =
                    decode_transition_override_binding_top_level_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "top_level_field")?, value)?;
            }
            2 => {
                let value = decode_variable_field_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "parameter_field_value")?, value)?;
            }
            3 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "index")?, value)?;
            }
            4 => {
                let value =
                    decode_keyframe_binding_effect_parametrized_field_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "effect_parametrized_field_value")?,
                    value,
                )?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeContentsKeyframeBindingLocation",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_override_prop_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionOverridePropMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_transition_override_prop_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionOverridePropMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_transition_override_prop_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.TransitionOverridePropMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "prop")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "overrides")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "binding_location")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_contents_binding_location")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_transition_override_prop_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "prop")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_transition_override_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "overrides")?, value)?;
            }
            3 => {
                let value = decode_transition_override_binding_location_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "binding_location")?, value)?;
            }
            4 => {
                let value =
                    decode_node_contents_keyframe_binding_location_from_decoder(env, decoder)?;
                term = term.map_put(
                    Atom::from_str(env, "node_contents_binding_location")?,
                    value,
                )?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding TransitionOverridePropMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_syntax_platform_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "web")?.encode(env)),
        1 => Ok(Atom::from_str(env, "android")?.encode(env)),
        2 => Ok(Atom::from_str(env, "i_os")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_optional_vector_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.OptionalVector")?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_vector_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding OptionalVector",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_html_tag_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        1 => Ok(Atom::from_str(env, "article")?.encode(env)),
        2 => Ok(Atom::from_str(env, "section")?.encode(env)),
        3 => Ok(Atom::from_str(env, "nav")?.encode(env)),
        4 => Ok(Atom::from_str(env, "aside")?.encode(env)),
        5 => Ok(Atom::from_str(env, "h1")?.encode(env)),
        6 => Ok(Atom::from_str(env, "h2")?.encode(env)),
        7 => Ok(Atom::from_str(env, "h3")?.encode(env)),
        8 => Ok(Atom::from_str(env, "h4")?.encode(env)),
        9 => Ok(Atom::from_str(env, "h5")?.encode(env)),
        10 => Ok(Atom::from_str(env, "h6")?.encode(env)),
        11 => Ok(Atom::from_str(env, "hgroup")?.encode(env)),
        12 => Ok(Atom::from_str(env, "header")?.encode(env)),
        13 => Ok(Atom::from_str(env, "footer")?.encode(env)),
        14 => Ok(Atom::from_str(env, "address")?.encode(env)),
        15 => Ok(Atom::from_str(env, "p")?.encode(env)),
        16 => Ok(Atom::from_str(env, "hr")?.encode(env)),
        17 => Ok(Atom::from_str(env, "pre")?.encode(env)),
        18 => Ok(Atom::from_str(env, "blockquote")?.encode(env)),
        19 => Ok(Atom::from_str(env, "ol")?.encode(env)),
        20 => Ok(Atom::from_str(env, "ul")?.encode(env)),
        21 => Ok(Atom::from_str(env, "menu")?.encode(env)),
        22 => Ok(Atom::from_str(env, "li")?.encode(env)),
        23 => Ok(Atom::from_str(env, "dl")?.encode(env)),
        24 => Ok(Atom::from_str(env, "dt")?.encode(env)),
        25 => Ok(Atom::from_str(env, "dd")?.encode(env)),
        26 => Ok(Atom::from_str(env, "figure")?.encode(env)),
        27 => Ok(Atom::from_str(env, "figcaption")?.encode(env)),
        28 => Ok(Atom::from_str(env, "main")?.encode(env)),
        29 => Ok(Atom::from_str(env, "div")?.encode(env)),
        30 => Ok(Atom::from_str(env, "a")?.encode(env)),
        31 => Ok(Atom::from_str(env, "em")?.encode(env)),
        32 => Ok(Atom::from_str(env, "strong")?.encode(env)),
        33 => Ok(Atom::from_str(env, "small")?.encode(env)),
        34 => Ok(Atom::from_str(env, "s")?.encode(env)),
        35 => Ok(Atom::from_str(env, "cite")?.encode(env)),
        36 => Ok(Atom::from_str(env, "q")?.encode(env)),
        37 => Ok(Atom::from_str(env, "dfn")?.encode(env)),
        38 => Ok(Atom::from_str(env, "abbr")?.encode(env)),
        39 => Ok(Atom::from_str(env, "ruby")?.encode(env)),
        40 => Ok(Atom::from_str(env, "rt")?.encode(env)),
        41 => Ok(Atom::from_str(env, "rp")?.encode(env)),
        42 => Ok(Atom::from_str(env, "data")?.encode(env)),
        43 => Ok(Atom::from_str(env, "time")?.encode(env)),
        44 => Ok(Atom::from_str(env, "code")?.encode(env)),
        45 => Ok(Atom::from_str(env, "var")?.encode(env)),
        46 => Ok(Atom::from_str(env, "samp")?.encode(env)),
        47 => Ok(Atom::from_str(env, "kbd")?.encode(env)),
        48 => Ok(Atom::from_str(env, "sub")?.encode(env)),
        49 => Ok(Atom::from_str(env, "sup")?.encode(env)),
        50 => Ok(Atom::from_str(env, "i")?.encode(env)),
        51 => Ok(Atom::from_str(env, "b")?.encode(env)),
        52 => Ok(Atom::from_str(env, "u")?.encode(env)),
        53 => Ok(Atom::from_str(env, "mark")?.encode(env)),
        54 => Ok(Atom::from_str(env, "bdi")?.encode(env)),
        55 => Ok(Atom::from_str(env, "bdo")?.encode(env)),
        56 => Ok(Atom::from_str(env, "span")?.encode(env)),
        57 => Ok(Atom::from_str(env, "br")?.encode(env)),
        58 => Ok(Atom::from_str(env, "wbr")?.encode(env)),
        59 => Ok(Atom::from_str(env, "picture")?.encode(env)),
        60 => Ok(Atom::from_str(env, "source")?.encode(env)),
        61 => Ok(Atom::from_str(env, "img")?.encode(env)),
        62 => Ok(Atom::from_str(env, "form")?.encode(env)),
        63 => Ok(Atom::from_str(env, "label")?.encode(env)),
        64 => Ok(Atom::from_str(env, "input")?.encode(env)),
        65 => Ok(Atom::from_str(env, "button")?.encode(env)),
        66 => Ok(Atom::from_str(env, "select")?.encode(env)),
        67 => Ok(Atom::from_str(env, "datalist")?.encode(env)),
        68 => Ok(Atom::from_str(env, "optgroup")?.encode(env)),
        69 => Ok(Atom::from_str(env, "option")?.encode(env)),
        70 => Ok(Atom::from_str(env, "textarea")?.encode(env)),
        71 => Ok(Atom::from_str(env, "output")?.encode(env)),
        72 => Ok(Atom::from_str(env, "progress")?.encode(env)),
        73 => Ok(Atom::from_str(env, "meter")?.encode(env)),
        74 => Ok(Atom::from_str(env, "fieldset")?.encode(env)),
        75 => Ok(Atom::from_str(env, "legend")?.encode(env)),
        76 => Ok(Atom::from_str(env, "video")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_aria_role_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "auto")?.encode(env)),
        52 => Ok(Atom::from_str(env, "none")?.encode(env)),
        30 => Ok(Atom::from_str(env, "application")?.encode(env)),
        67 => Ok(Atom::from_str(env, "banner")?.encode(env)),
        68 => Ok(Atom::from_str(env, "complementary")?.encode(env)),
        69 => Ok(Atom::from_str(env, "contentinfo")?.encode(env)),
        70 => Ok(Atom::from_str(env, "form")?.encode(env)),
        71 => Ok(Atom::from_str(env, "main")?.encode(env)),
        72 => Ok(Atom::from_str(env, "navigation")?.encode(env)),
        73 => Ok(Atom::from_str(env, "region")?.encode(env)),
        74 => Ok(Atom::from_str(env, "search")?.encode(env)),
        13 => Ok(Atom::from_str(env, "separator")?.encode(env)),
        31 => Ok(Atom::from_str(env, "article")?.encode(env)),
        35 => Ok(Atom::from_str(env, "columnheader")?.encode(env)),
        36 => Ok(Atom::from_str(env, "definition")?.encode(env)),
        38 => Ok(Atom::from_str(env, "directory")?.encode(env)),
        39 => Ok(Atom::from_str(env, "document")?.encode(env)),
        44 => Ok(Atom::from_str(env, "group")?.encode(env)),
        45 => Ok(Atom::from_str(env, "heading")?.encode(env)),
        46 => Ok(Atom::from_str(env, "img")?.encode(env)),
        48 => Ok(Atom::from_str(env, "list")?.encode(env)),
        49 => Ok(Atom::from_str(env, "listitem")?.encode(env)),
        50 => Ok(Atom::from_str(env, "math")?.encode(env)),
        53 => Ok(Atom::from_str(env, "note")?.encode(env)),
        55 => Ok(Atom::from_str(env, "presentation")?.encode(env)),
        56 => Ok(Atom::from_str(env, "row")?.encode(env)),
        57 => Ok(Atom::from_str(env, "rowgroup")?.encode(env)),
        58 => Ok(Atom::from_str(env, "rowheader")?.encode(env)),
        62 => Ok(Atom::from_str(env, "table")?.encode(env)),
        65 => Ok(Atom::from_str(env, "toolbar")?.encode(env)),
        1 => Ok(Atom::from_str(env, "button")?.encode(env)),
        2 => Ok(Atom::from_str(env, "checkbox")?.encode(env)),
        3 => Ok(Atom::from_str(env, "gridcell")?.encode(env)),
        4 => Ok(Atom::from_str(env, "link")?.encode(env)),
        5 => Ok(Atom::from_str(env, "menuitem")?.encode(env)),
        6 => Ok(Atom::from_str(env, "menuitemcheckbox")?.encode(env)),
        7 => Ok(Atom::from_str(env, "menuitemradio")?.encode(env)),
        8 => Ok(Atom::from_str(env, "option")?.encode(env)),
        9 => Ok(Atom::from_str(env, "progressbar")?.encode(env)),
        10 => Ok(Atom::from_str(env, "radio")?.encode(env)),
        11 => Ok(Atom::from_str(env, "scrollbar")?.encode(env)),
        14 => Ok(Atom::from_str(env, "slider")?.encode(env)),
        15 => Ok(Atom::from_str(env, "spinbutton")?.encode(env)),
        17 => Ok(Atom::from_str(env, "tab")?.encode(env)),
        18 => Ok(Atom::from_str(env, "tabpanel")?.encode(env)),
        19 => Ok(Atom::from_str(env, "textbox")?.encode(env)),
        20 => Ok(Atom::from_str(env, "treeitem")?.encode(env)),
        21 => Ok(Atom::from_str(env, "combobox")?.encode(env)),
        22 => Ok(Atom::from_str(env, "grid")?.encode(env)),
        23 => Ok(Atom::from_str(env, "listbox")?.encode(env)),
        24 => Ok(Atom::from_str(env, "menu")?.encode(env)),
        25 => Ok(Atom::from_str(env, "menubar")?.encode(env)),
        26 => Ok(Atom::from_str(env, "radiogroup")?.encode(env)),
        27 => Ok(Atom::from_str(env, "tablist")?.encode(env)),
        28 => Ok(Atom::from_str(env, "tree")?.encode(env)),
        29 => Ok(Atom::from_str(env, "treegrid")?.encode(env)),
        66 => Ok(Atom::from_str(env, "tooltip")?.encode(env)),
        75 => Ok(Atom::from_str(env, "alert")?.encode(env)),
        76 => Ok(Atom::from_str(env, "log")?.encode(env)),
        77 => Ok(Atom::from_str(env, "marquee")?.encode(env)),
        78 => Ok(Atom::from_str(env, "status")?.encode(env)),
        79 => Ok(Atom::from_str(env, "timer")?.encode(env)),
        80 => Ok(Atom::from_str(env, "alertdialog")?.encode(env)),
        81 => Ok(Atom::from_str(env, "dialog")?.encode(env)),
        12 => Ok(Atom::from_str(env, "searchbox")?.encode(env)),
        16 => Ok(Atom::from_str(env, "switch")?.encode(env)),
        32 => Ok(Atom::from_str(env, "blockquote")?.encode(env)),
        33 => Ok(Atom::from_str(env, "caption")?.encode(env)),
        34 => Ok(Atom::from_str(env, "cell")?.encode(env)),
        37 => Ok(Atom::from_str(env, "deletion")?.encode(env)),
        40 => Ok(Atom::from_str(env, "emphasis")?.encode(env)),
        41 => Ok(Atom::from_str(env, "feed")?.encode(env)),
        42 => Ok(Atom::from_str(env, "figure")?.encode(env)),
        43 => Ok(Atom::from_str(env, "generic")?.encode(env)),
        47 => Ok(Atom::from_str(env, "insertion")?.encode(env)),
        51 => Ok(Atom::from_str(env, "meter")?.encode(env)),
        54 => Ok(Atom::from_str(env, "paragraph")?.encode(env)),
        59 => Ok(Atom::from_str(env, "strong")?.encode(env)),
        60 => Ok(Atom::from_str(env, "subscript")?.encode(env)),
        61 => Ok(Atom::from_str(env, "superscript")?.encode(env)),
        63 => Ok(Atom::from_str(env, "term")?.encode(env)),
        64 => Ok(Atom::from_str(env, "time")?.encode(env)),
        82 => Ok(Atom::from_str(env, "image")?.encode(env)),
        83 => Ok(Atom::from_str(env, "heading_1")?.encode(env)),
        84 => Ok(Atom::from_str(env, "heading_2")?.encode(env)),
        85 => Ok(Atom::from_str(env, "heading_3")?.encode(env)),
        86 => Ok(Atom::from_str(env, "heading_4")?.encode(env)),
        87 => Ok(Atom::from_str(env, "heading_5")?.encode(env)),
        88 => Ok(Atom::from_str(env, "heading_6")?.encode(env)),
        89 => Ok(Atom::from_str(env, "header")?.encode(env)),
        90 => Ok(Atom::from_str(env, "footer")?.encode(env)),
        91 => Ok(Atom::from_str(env, "sidebar")?.encode(env)),
        92 => Ok(Atom::from_str(env, "section")?.encode(env)),
        93 => Ok(Atom::from_str(env, "maincontent")?.encode(env)),
        94 => Ok(Atom::from_str(env, "table_cell")?.encode(env)),
        95 => Ok(Atom::from_str(env, "widget")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_migration_status_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.MigrationStatus",
    )?;
    term = term.map_put(
        Atom::from_str(env, "dsd_cleanup")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "dsd_cleanup")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MigrationStatus",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_color_profile_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "srgb")?.encode(env)),
        1 => Ok(Atom::from_str(env, "display_p3")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_document_color_profile_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "legacy")?.encode(env)),
        1 => Ok(Atom::from_str(env, "srgb")?.encode(env)),
        2 => Ok(Atom::from_str(env, "display_p3")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_child_reading_direction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "left_to_right")?.encode(env)),
        2 => Ok(Atom::from_str(env, "right_to_left")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_aria_attribute_any_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ARIAAttributeAnyValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "bool_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "string_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "float_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "int_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "string_array_value")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "bool_value")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "string_value")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "float_value")?, value)?;
            }
            4 => {
                let value = decoder.read_var_int()?;
                term = term.map_put(Atom::from_str(env, "int_value")?, value)?;
            }
            5 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "string_array_value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ARIAAttributeAnyValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_aria_attribute_data_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "boolean")?.encode(env)),
        1 => Ok(Atom::from_str(env, "string")?.encode(env)),
        2 => Ok(Atom::from_str(env, "float")?.encode(env)),
        3 => Ok(Atom::from_str(env, "int")?.encode(env)),
        4 => Ok(Atom::from_str(env, "string_list")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_aria_attribute_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ARIAAttributeData",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_aria_attribute_data_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_aria_attribute_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ARIAAttributeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_aria_attributes_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ARIAAttributesMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_aria_attributes_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ARIAAttributesMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_aria_attributes_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ARIAAttributesMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "attribute")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "attribute")?, value)?;
            }
            2 => {
                let value = decode_aria_attribute_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ARIAAttributesMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_handoff_status_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.HandoffStatusMapEntry",
    )?;
    term = term.map_put(Atom::from_str(env, "guid")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "handoff_status")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "guid")?, value)?;
            }
            2 => {
                let value = decode_section_status_info_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "handoff_status")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding HandoffStatusMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_handoff_status_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.HandoffStatusMap",
    )?;
    term = term.map_put(Atom::from_str(env, "entries")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_handoff_status_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "entries")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding HandoffStatusMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_scope_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EditScopeInfo")?;
    term = term.map_put(
        Atom::from_str(env, "edit_scope_stacks")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "snapshots")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_edit_scope_stack_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "edit_scope_stacks")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_edit_scope_snapshot_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "snapshots")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EditScopeInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_scope_snapshot_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.EditScopeSnapshot",
    )?;
    term = term.map_put(Atom::from_str(env, "frames")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "node_change_field_numbers")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_edit_scope_stack_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "frames")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_uint())?;
                term = term.map_put(Atom::from_str(env, "node_change_field_numbers")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EditScopeSnapshot",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_scope_stack_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EditScopeStack")?;
    term = term.map_put(Atom::from_str(env, "stack")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_edit_scope_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "stack")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EditScopeStack",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_scope_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.EditScope")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "label")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "editor_type")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_edit_scope_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "label")?, value)?;
            }
            3 => {
                let value = decode_editor_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "editor_type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding EditScope",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_edit_scope_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "invalid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "test_setup")?.encode(env)),
        2 => Ok(Atom::from_str(env, "user")?.encode(env)),
        3 => Ok(Atom::from_str(env, "plugin")?.encode(env)),
        4 => Ok(Atom::from_str(env, "system")?.encode(env)),
        5 => Ok(Atom::from_str(env, "rest_api")?.encode(env)),
        6 => Ok(Atom::from_str(env, "onboarding")?.encode(env)),
        7 => Ok(Atom::from_str(env, "autosave")?.encode(env)),
        8 => Ok(Atom::from_str(env, "ai")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_section_preset_state_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "inserted")?.encode(env)),
        1 => Ok(Atom::from_str(env, "user_edited")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_emoji_image_set_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "apple")?.encode(env)),
        1 => Ok(Atom::from_str(env, "noto")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_section_preset_info_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.SectionPresetInfo",
    )?;
    term = term.map_put(
        Atom::from_str(env, "shelf_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "template_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "template_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "shelf_id")?, value)?;
            }
            2 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "template_id")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "template_name")?, value)?;
            }
            4 => {
                let value = decode_section_preset_state_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SectionPresetInfo",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_first_draft_kit_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "local")?.encode(env)),
        1 => Ok(Atom::from_str(env, "library")?.encode(env)),
        2 => Ok(Atom::from_str(env, "none")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_first_draft_kit_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FirstDraftKit")?;
    term = term.map_put(Atom::from_str(env, "key")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "key")?, value)?;
            }
            2 => {
                let value = decode_first_draft_kit_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FirstDraftKit",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_first_draft_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FirstDraftData")?;
    term = term.map_put(
        Atom::from_str(env, "generation_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "kit")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "generation_id")?, value)?;
            }
            2 => {
                let value = decode_first_draft_kit_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "kit")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FirstDraftData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_first_draft_kit_element_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "building_block")?.encode(env)),
        2 => Ok(Atom::from_str(env, "grouped_component")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_first_draft_kit_element_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.FirstDraftKitElementData",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_first_draft_kit_element_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FirstDraftKitElementData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_platform_shape_property_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "fill")?.encode(env)),
        1 => Ok(Atom::from_str(env, "stroke")?.encode(env)),
        2 => Ok(Atom::from_str(env, "text")?.encode(env)),
        3 => Ok(Atom::from_str(env, "stroke_color")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_platform_shape_behavior_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "shape")?.encode(env)),
        1 => Ok(Atom::from_str(env, "container")?.encode(env)),
        2 => Ok(Atom::from_str(env, "advanced_container")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_platform_shape_property_map_entry_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PlatformShapePropertyMapEntry",
    )?;
    term = term.map_put(
        Atom::from_str(env, "property")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "node_paths")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_platform_shape_property_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "property")?, value)?;
            }
            2 => {
                let value =
                    decoder.read_repeated(|decoder| decode_guid_path_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "node_paths")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PlatformShapePropertyMapEntry",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_platform_shape_definition_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.PlatformShapeDefinition",
    )?;
    term = term.map_put(
        Atom::from_str(env, "property_map_entries")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "behavior_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "thumbnail_node")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_platform_shape_property_map_entry_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "property_map_entries")?, value)?;
            }
            2 => {
                let value = decode_platform_shape_behavior_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "behavior_type")?, value)?;
            }
            3 => {
                let value = decode_guid_path_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "thumbnail_node")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PlatformShapeDefinition",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_behaviors_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.NodeBehaviors")?;
    term = term.map_put(Atom::from_str(env, "link")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "appear")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "hover")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "press")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "focus")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "scroll_parallax")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "scroll_transform")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "cursor")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "marquee")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "code")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_link_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "link")?, value)?;
            }
            2 => {
                let value = decode_appear_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "appear")?, value)?;
            }
            3 => {
                let value = decode_hover_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "hover")?, value)?;
            }
            4 => {
                let value = decode_press_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "press")?, value)?;
            }
            5 => {
                let value = decode_focus_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "focus")?, value)?;
            }
            6 => {
                let value = decode_scroll_parallax_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_parallax")?, value)?;
            }
            7 => {
                let value = decode_scroll_transform_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "scroll_transform")?, value)?;
            }
            8 => {
                let value = decode_cursor_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cursor")?, value)?;
            }
            9 => {
                let value = decode_marquee_behavior_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "marquee")?, value)?;
            }
            10 => {
                let value = decoder
                    .read_repeated(|decoder| decode_code_behavior_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "code")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeBehaviors",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_behavior_transition_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.BehaviorTransition",
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_type")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "easing_function")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition_duration")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "delay")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "transition_duration_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "delay_var")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_easing_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "easing_type")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| decoder.read_var_float(env))?;
                term = term.map_put(Atom::from_str(env, "easing_function")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "transition_duration")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "delay")?, value)?;
            }
            5 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition_duration_var")?, value)?;
            }
            6 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "delay_var")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding BehaviorTransition",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_appear_behavior_trigger_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        1 => Ok(Atom::from_str(env, "page_load")?.encode(env)),
        2 => Ok(Atom::from_str(env, "this_layer_in_view")?.encode(env)),
        3 => Ok(Atom::from_str(env, "other_layer_in_view")?.encode(env)),
        4 => Ok(Atom::from_str(env, "scroll_direction")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_relative_direction_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        1 => Ok(Atom::from_str(env, "up")?.encode(env)),
        2 => Ok(Atom::from_str(env, "down")?.encode(env)),
        3 => Ok(Atom::from_str(env, "left")?.encode(env)),
        4 => Ok(Atom::from_str(env, "right")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_appear_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AppearBehavior")?;
    term = term.map_put(Atom::from_str(env, "trigger")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "direction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "other_layer")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "enter_transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "enter_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "exit_transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "exit_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plays_once")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plays_once_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_appear_behavior_trigger_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger")?, value)?;
            }
            2 => {
                let value = decode_relative_direction_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "direction")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "other_layer")?, value)?;
            }
            4 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "enter_transition")?, value)?;
            }
            5 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "enter_state")?, value)?;
            }
            6 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "exit_transition")?, value)?;
            }
            7 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "exit_state")?, value)?;
            }
            8 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "plays_once")?, value)?;
            }
            9 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "plays_once_var")?, value)?;
            }
            10 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AppearBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_hover_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.HoverBehavior")?;
    term = term.map_put(
        Atom::from_str(env, "transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition")?, value)?;
            }
            2 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding HoverBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_press_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.PressBehavior")?;
    term = term.map_put(
        Atom::from_str(env, "transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition")?, value)?;
            }
            2 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding PressBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_focus_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.FocusBehavior")?;
    term = term.map_put(
        Atom::from_str(env, "transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "state")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition")?, value)?;
            }
            2 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "state")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding FocusBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_scroll_parallax_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ScrollParallaxBehavior",
    )?;
    term = term.map_put(Atom::from_str(env, "axis")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "speed")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "relative_to_page")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "speed_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_scroll_direction_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "axis")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "speed")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "relative_to_page")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "speed_var")?, value)?;
            }
            5 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ScrollParallaxBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_scroll_transform_behavior_trigger_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        1 => Ok(Atom::from_str(env, "page_height")?.encode(env)),
        2 => Ok(Atom::from_str(env, "this_layer_in_view")?.encode(env)),
        3 => Ok(Atom::from_str(env, "other_layer_in_view")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_scroll_transform_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.ScrollTransformBehavior",
    )?;
    term = term.map_put(Atom::from_str(env, "trigger")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "other_layer")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "transition")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "from_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "to_state")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plays_once")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plays_once_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "plays_once_var2")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_scroll_transform_behavior_trigger_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "trigger")?, value)?;
            }
            2 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "other_layer")?, value)?;
            }
            3 => {
                let value = decode_behavior_transition_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "transition")?, value)?;
            }
            4 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "from_state")?, value)?;
            }
            5 => {
                let value = decode_node_change_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "to_state")?, value)?;
            }
            6 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "plays_once")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "plays_once_var")?, value)?;
            }
            8 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "plays_once_var2")?, value)?;
            }
            9 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ScrollTransformBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cursor_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CursorBehavior")?;
    term = term.map_put(
        Atom::from_str(env, "hotspot_x")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "hotspot_y")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "cursor_guid")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "hotspot_x")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "hotspot_y")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "cursor_guid")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CursorBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_marquee_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.MarqueeBehavior",
    )?;
    term = term.map_put(
        Atom::from_str(env, "direction")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "speed")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "should_loop_infinitely")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "speed_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "should_loop_infinitely_var")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "pause_on_hover")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_relative_direction_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "direction")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "speed")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "should_loop_infinitely")?, value)?;
            }
            4 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "speed_var")?, value)?;
            }
            5 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "should_loop_infinitely_var")?, value)?;
            }
            6 => {
                let value = decode_variable_data_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "pause_on_hover")?, value)?;
            }
            7 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding MarqueeBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_code_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.CodeBehavior")?;
    term = term.map_put(
        Atom::from_str(env, "code_component_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "component_prop_assignments")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "is_deleted")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_code_component_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "code_component_id")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_component_prop_assignment_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "component_prop_assignments")?, value)?;
            }
            3 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "is_deleted")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CodeBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_link_behavior_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        1 => Ok(Atom::from_str(env, "url")?.encode(env)),
        2 => Ok(Atom::from_str(env, "page")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_link_behavior_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.LinkBehavior")?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "url")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "page")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "open_in_new_window")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_link_behavior_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "url")?, value)?;
            }
            3 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "page")?, value)?;
            }
            4 => {
                let value = decoder.read_bool()?;
                term = term.map_put(Atom::from_str(env, "open_in_new_window")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding LinkBehavior",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_variable_id_or_variable_override_id_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.VariableIdOrVariableOverrideId",
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "variable_override_id")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_variable_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_id")?, value)?;
            }
            2 => {
                let value = decode_variable_override_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "variable_override_id")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding VariableIdOrVariableOverrideId",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slide_theme_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.SlideThemeData")?;
    term = term.map_put(
        Atom::from_str(env, "theme_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "version")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_theme_id_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "theme_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "version")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding SlideThemeData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_slide_number_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "none")?.encode(env)),
        1 => Ok(Atom::from_str(env, "slide")?.encode(env)),
        2 => Ok(Atom::from_str(env, "section")?.encode(env)),
        3 => Ok(Atom::from_str(env, "subsection")?.encode(env)),
        4 => Ok(Atom::from_str(env, "total_within_deck")?.encode(env)),
        5 => Ok(Atom::from_str(env, "total_within_section")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_chat_message_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "user_message")?.encode(env)),
        1 => Ok(Atom::from_str(env, "assistant_message")?.encode(env)),
        2 => Ok(Atom::from_str(env, "tool_message")?.encode(env)),
        3 => Ok(Atom::from_str(env, "system_message")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_node_chat_message_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeChatMessage",
    )?;
    term = term.map_put(Atom::from_str(env, "id")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "user_id")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "text_content")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "sent_at")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "tool_calls")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "tool_results")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "sent_at64")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_guid_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "id")?, value)?;
            }
            2 => {
                let value = decode_node_chat_message_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "user_id")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "text_content")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "sent_at")?, value)?;
            }
            6 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_node_chat_tool_call_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "tool_calls")?, value)?;
            }
            7 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_node_chat_tool_result_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "tool_results")?, value)?;
            }
            8 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "sent_at64")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeChatMessage",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_chat_tool_call_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeChatToolCall",
    )?;
    term = term.map_put(
        Atom::from_str(env, "tool_call_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "tool_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "args_json")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tool_call_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tool_name")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "args_json")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeChatToolCall",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_chat_tool_result_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeChatToolResult",
    )?;
    term = term.map_put(
        Atom::from_str(env, "tool_call_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "tool_name")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "result_json")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tool_call_id")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "tool_name")?, value)?;
            }
            3 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "result_json")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeChatToolResult",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_node_chat_compression_state_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.NodeChatCompressionState",
    )?;
    term = term.map_put(
        Atom::from_str(env, "start_index")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "summary")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "start_index")?, value)?;
            }
            2 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "summary")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding NodeChatCompressionState",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_ai_chat_content_part_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AIChatContentPart",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "value")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_ai_chat_content_part_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            2 => {
                let value = decode_ai_chat_content_part_any_value_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "value")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AIChatContentPart",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_ai_chat_content_part_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "invalid")?.encode(env)),
        1 => Ok(Atom::from_str(env, "text")?.encode(env)),
        2 => Ok(Atom::from_str(env, "selected_node_ids")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_ai_chat_content_part_any_value_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.AIChatContentPartAnyValue",
    )?;
    term = term.map_put(
        Atom::from_str(env, "text_value")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "selected_node_ids")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "text_value")?, value)?;
            }
            2 => {
                let value = decoder.read_repeated(|decoder| decoder.read_string())?;
                term = term.map_put(Atom::from_str(env, "selected_node_ids")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AIChatContentPartAnyValue",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_ai_chat_message_role_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "user")?.encode(env)),
        1 => Ok(Atom::from_str(env, "assistant")?.encode(env)),
        2 => Ok(Atom::from_str(env, "tool")?.encode(env)),
        3 => Ok(Atom::from_str(env, "system")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_ai_chat_message_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AIChatMessage")?;
    term = term.map_put(
        Atom::from_str(env, "created_at_ms")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(Atom::from_str(env, "role")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "content")?, rustler::types::atom::nil())?;
    term = term.map_put(
        Atom::from_str(env, "client_id")?,
        rustler::types::atom::nil(),
    )?;
    term = term.map_put(
        Atom::from_str(env, "created_at_ms64")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_uint()?;
                term = term.map_put(Atom::from_str(env, "created_at_ms")?, value)?;
            }
            2 => {
                let value = decode_ai_chat_message_role_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "role")?, value)?;
            }
            3 => {
                let value = decoder.read_repeated(|decoder| {
                    decode_ai_chat_content_part_from_decoder(env, decoder)
                })?;
                term = term.map_put(Atom::from_str(env, "content")?, value)?;
            }
            4 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "client_id")?, value)?;
            }
            5 => {
                let value = decoder.read_var_uint64()?;
                term = term.map_put(Atom::from_str(env, "created_at_ms64")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AIChatMessage",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_ai_chat_thread_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.AIChatThread")?;
    term = term.map_put(
        Atom::from_str(env, "messages")?,
        rustler::types::atom::nil(),
    )?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_ai_chat_message_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "messages")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding AIChatThread",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_cooper_template_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "custom")?.encode(env)),
        1 => Ok(Atom::from_str(env, "twitter_post")?.encode(env)),
        2 => Ok(Atom::from_str(env, "linkedin_post")?.encode(env)),
        3 => Ok(Atom::from_str(env, "insta_post_square")?.encode(env)),
        4 => Ok(Atom::from_str(env, "insta_post_portrait")?.encode(env)),
        5 => Ok(Atom::from_str(env, "insta_story")?.encode(env)),
        6 => Ok(Atom::from_str(env, "insta_ad")?.encode(env)),
        7 => Ok(Atom::from_str(env, "facebook_post")?.encode(env)),
        8 => Ok(Atom::from_str(env, "facebook_cover_photo")?.encode(env)),
        9 => Ok(Atom::from_str(env, "facebook_event_cover")?.encode(env)),
        10 => Ok(Atom::from_str(env, "facebook_ad_portrait")?.encode(env)),
        11 => Ok(Atom::from_str(env, "facebook_ad_square")?.encode(env)),
        12 => Ok(Atom::from_str(env, "pinterest_ad_pin")?.encode(env)),
        13 => Ok(Atom::from_str(env, "twitter_banner")?.encode(env)),
        15 => Ok(Atom::from_str(env, "linkedin_post_square")?.encode(env)),
        16 => Ok(Atom::from_str(env, "linkedin_post_portrait")?.encode(env)),
        17 => Ok(Atom::from_str(env, "linkedin_post_landscape")?.encode(env)),
        18 => Ok(Atom::from_str(env, "linkedin_profile_banner")?.encode(env)),
        19 => Ok(Atom::from_str(env, "linkedin_article_banner")?.encode(env)),
        20 => Ok(Atom::from_str(env, "linkedin_ad_landscape")?.encode(env)),
        21 => Ok(Atom::from_str(env, "linkedin_ad_square")?.encode(env)),
        22 => Ok(Atom::from_str(env, "linkedin_ad_vertical")?.encode(env)),
        23 => Ok(Atom::from_str(env, "youtube_thumbnail")?.encode(env)),
        24 => Ok(Atom::from_str(env, "youtube_banner")?.encode(env)),
        25 => Ok(Atom::from_str(env, "youtube_ad")?.encode(env)),
        26 => Ok(Atom::from_str(env, "twitch_banner")?.encode(env)),
        27 => Ok(Atom::from_str(env, "google_leaderboard_ad")?.encode(env)),
        28 => Ok(Atom::from_str(env, "google_large_ad")?.encode(env)),
        29 => Ok(Atom::from_str(env, "google_med_ad")?.encode(env)),
        30 => Ok(Atom::from_str(env, "google_mobile_banner_ad")?.encode(env)),
        31 => Ok(Atom::from_str(env, "google_skyscraper_ad")?.encode(env)),
        32 => Ok(Atom::from_str(env, "card_horizontal")?.encode(env)),
        33 => Ok(Atom::from_str(env, "card_vertical")?.encode(env)),
        34 => Ok(Atom::from_str(env, "print_us_letter")?.encode(env)),
        35 => Ok(Atom::from_str(env, "poster")?.encode(env)),
        36 => Ok(Atom::from_str(env, "banner_standard")?.encode(env)),
        37 => Ok(Atom::from_str(env, "banner_wide")?.encode(env)),
        38 => Ok(Atom::from_str(env, "banner_ultrawide")?.encode(env)),
        39 => Ok(Atom::from_str(env, "name_tag_portrait")?.encode(env)),
        40 => Ok(Atom::from_str(env, "name_tag_landscape")?.encode(env)),
        41 => Ok(Atom::from_str(env, "insta_reel_cover")?.encode(env)),
        42 => Ok(Atom::from_str(env, "zoom_background")?.encode(env)),
        43 => Ok(Atom::from_str(env, "tiktok_post")?.encode(env)),
        44 => Ok(Atom::from_str(env, "insta_ad_portrait")?.encode(env)),
        45 => Ok(Atom::from_str(env, "insta_post_tall_portrait")?.encode(env)),
        46 => Ok(Atom::from_str(env, "twitter_post_square")?.encode(env)),
        47 => Ok(Atom::from_str(env, "facebook_post_square")?.encode(env)),
        48 => Ok(Atom::from_str(env, "facebook_post_portrait")?.encode(env)),
        49 => Ok(Atom::from_str(env, "facebook_story")?.encode(env)),
        50 => Ok(Atom::from_str(env, "google_square_ad")?.encode(env)),
        51 => Ok(Atom::from_str(env, "google_small_square_ad")?.encode(env)),
        52 => Ok(Atom::from_str(env, "google_narrow_skyscraper_ad")?.encode(env)),
        53 => Ok(Atom::from_str(env, "google_half_page_ad")?.encode(env)),
        54 => Ok(Atom::from_str(env, "google_large_leaderboard_ad")?.encode(env)),
        55 => Ok(Atom::from_str(env, "google_billboard_ad")?.encode(env)),
        56 => Ok(Atom::from_str(env, "google_banner_leaderboard_ad")?.encode(env)),
        57 => Ok(Atom::from_str(env, "google_top_banner_ad")?.encode(env)),
        58 => Ok(Atom::from_str(env, "google_mobile_leaderboard_banner_ad")?.encode(env)),
        59 => Ok(Atom::from_str(env, "google_large_mobile_banner_ad")?.encode(env)),
        60 => Ok(Atom::from_str(env, "google_mobile_interstitial_ad")?.encode(env)),
        61 => Ok(Atom::from_str(env, "google_mobile_med_rectangle_ad")?.encode(env)),
        62 => Ok(Atom::from_str(env, "pinterest_pin_standard")?.encode(env)),
        63 => Ok(Atom::from_str(env, "pinterest_pin_square")?.encode(env)),
        64 => Ok(Atom::from_str(env, "pinterest_ad_square")?.encode(env)),
        65 => Ok(Atom::from_str(env, "print_a4")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_cooper_template_data_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term = rustler::types::elixir_struct::make_ex_struct(
        env,
        "Elixir.FigKiwi.Schema.CooperTemplateData",
    )?;
    term = term.map_put(Atom::from_str(env, "type")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decode_cooper_template_type_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "type")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding CooperTemplateData",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_image_import_map_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ImageImportMap")?;
    term = term.map_put(Atom::from_str(env, "imports")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder
                    .read_repeated(|decoder| decode_image_import_from_decoder(env, decoder))?;
                term = term.map_put(Atom::from_str(env, "imports")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ImageImportMap",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_image_import_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.ImageImport")?;
    term = term.map_put(Atom::from_str(env, "name")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "image")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_string()?;
                term = term.map_put(Atom::from_str(env, "name")?, value)?;
            }
            2 => {
                let value = decode_image_from_decoder(env, decoder)?;
                term = term.map_put(Atom::from_str(env, "image")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding ImageImport",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_interpolation_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "hold")?.encode(env)),
        1 => Ok(Atom::from_str(env, "bezier")?.encode(env)),
        2 => Ok(Atom::from_str(env, "spring")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_bezier_handles_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    let mut term =
        rustler::types::elixir_struct::make_ex_struct(env, "Elixir.FigKiwi.Schema.BezierHandles")?;
    term = term.map_put(Atom::from_str(env, "p1x")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "p1y")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "p2x")?, rustler::types::atom::nil())?;
    term = term.map_put(Atom::from_str(env, "p2y")?, rustler::types::atom::nil())?;
    loop {
        match decoder.read_var_uint()? {
            0 => break,
            1 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "p1x")?, value)?;
            }
            2 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "p1y")?, value)?;
            }
            3 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "p2x")?, value)?;
            }
            4 => {
                let value = decoder.read_var_float(env)?;
                term = term.map_put(Atom::from_str(env, "p2y")?, value)?;
            }
            field => {
                return Err(Error::Term(Box::new(format!(
                    "unknown field {} while decoding BezierHandles",
                    field
                ))));
            }
        }
    }
    Ok(term)
}
fn decode_keyframe_operation_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "set")?.encode(env)),
        1 => Ok(Atom::from_str(env, "scale")?.encode(env)),
        2 => Ok(Atom::from_str(env, "offset")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_timeline_position_type_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "absolute")?.encode(env)),
        1 => Ok(Atom::from_str(env, "relative")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
}
fn decode_playback_style_from_decoder<'a>(
    env: Env<'a>,
    decoder: &mut Decoder<'_>,
) -> NifResult<Term<'a>> {
    match decoder.read_var_uint()? {
        0 => Ok(Atom::from_str(env, "once")?.encode(env)),
        1 => Ok(Atom::from_str(env, "loop")?.encode(env)),
        2 => Ok(Atom::from_str(env, "boomerang")?.encode(env)),
        value => Ok((value as i64).encode(env)),
    }
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
#[rustler::nif(schedule = "DirtyCpu")]
pub fn decode_node_change<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
    let mut decoder = Decoder::new(bytes.as_slice());
    let term = decode_node_change_from_decoder(env, &mut decoder)?;
    decoder.finish()?;
    Ok(term)
}
