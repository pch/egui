struct VertexOutput {
    @builtin(position) position: vec4<f32>,
};

var<private> positions: array<vec2f, 3> = array<vec2f, 3>(
    vec2f(-1.0, -3.0),
    vec2f(-1.0, 1.0),
    vec2f(3.0, 1.0)
);

// meant to be called with 3 vertex indices: 0, 1, 2
// draws one large triangle over the clip space like this:
// (the asterisks represent the clip space bounds)
//-1,1           1,1
// ---------------------------------
// |              *              .
// |              *           .
// |              *        .
// |              *      .
// |              *    .
// |              * .
// |***************
// |            . 1,-1
// |          .
// |       .
// |     .
// |   .
// |.
@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var result: VertexOutput;
    result.position = vec4f(positions[vertex_index], 0.0, 1.0);
    return result;
}

@group(0)
@binding(0)
var r_color: texture_2d<f32>;

@fragment
fn fs_main(vertex: VertexOutput) -> @location(0) vec4<f32> {
    return textureLoad(r_color, vec2i(vertex.position.xy), 0);
}

// Linear from gamma-encoded sRGB, extended: values above 1 stay above 1, and
// negative values are mirrored, as extended sRGB defines them.
fn linear_from_extended_srgb(c: vec3<f32>) -> vec3<f32> {
    let a = abs(c);
    let lower = a / 12.92;
    let higher = pow((a + 0.055) / 1.055, vec3<f32>(2.4));
    return sign(c) * select(higher, lower, a <= vec3<f32>(0.04045));
}

// Where black and SDR white land on the linear surface; see `LinearOutput`.
struct LinearOutput {
    white: f32,
    black: f32,
    _padding: vec2<f32>,
};

@group(0)
@binding(1)
var<uniform> r_output: LinearOutput;

@fragment
fn fs_main_linear(vertex: VertexOutput) -> @location(0) vec4<f32> {
    let c = textureLoad(r_color, vec2i(vertex.position.xy), 0);
    let linear = linear_from_extended_srgb(c.rgb);
    return vec4<f32>(r_output.black + linear * (r_output.white - r_output.black), c.a);
}
