#include <metal_stdlib>
using namespace metal;

// v2.28 果凍皮 / v2.31 皮 A 清透 (多米 11-07): the body as a lit, see-through jelly. Port of the web's WebGL2 shaders (index.html, jelInit):
// a mask of the body, a small and a large gaussian blur of it (edge thickness and inner shading), then one lighting pass.
// The web's texture space has y up; here uv.y runs down, so the slope's y and the edge gradient's y are flipped where they are
// computed and every constant stays as on the web.

struct VOut { float4 pos [[position]]; float2 uv; };

vertex VOut jelVertex(uint vid [[vertex_id]]) {
    float2 p = float2(vid == 1 ? 3.0 : -1.0, vid == 2 ? 3.0 : -1.0);
    VOut o;
    o.pos = float4(p, 0.0, 1.0);
    o.uv = float2(p.x * 0.5 + 0.5, 1.0 - (p.y * 0.5 + 0.5));
    return o;
}

struct BlurU { float2 d; float s; float pad; };

fragment float4 jelBlur(VOut in [[stage_in]], texture2d<float> t [[texture(0)]], sampler sm [[sampler(0)]], constant BlurU& u [[buffer(0)]]) {
    float sum = 0.0, w = 0.0;
    int N = int(ceil(u.s * 2.6));
    for (int i = -N; i <= N; i++) {
        float g = exp(-0.5 * float(i * i) / (u.s * u.s));
        sum += t.sample(sm, in.uv + u.d * float(i)).r * g;
        w += g;
    }
    return float4(sum / w, 0.0, 0.0, 1.0);
}

// all float4 so the Swift side can hand over a plain array of SIMD4<Float>
struct LightU {
    float4 resRpxN;      // res.x, res.y, rpx, nD
    float4 uD[6];        // dents: x, y (pixels, y down), radius, depth
    float4 cEdge, cCore, cLine, cGlow;
    float4 k0;           // aEdge, aCore, amb, dif
    float4 k1;           // glow, line, nk, shin
    float4 k2;           // s0, s1, spec, sheen
    float4 k3;           // arc
};

static float H1(float2 uv, texture2d<float> B1, sampler sm, constant LightU& u) {
    float h = 0.45 * smoothstep(0.0, 1.0, B1.sample(sm, uv).r);
    float2 px = uv * u.resRpxN.xy;
    int nD = int(u.resRpxN.w);
    for (int i = 0; i < nD; i++) {
        float2 q = (px - u.uD[i].xy) / u.uD[i].z;
        h -= u.uD[i].w * 0.24 * exp(-dot(q, q) * 1.6);
    }
    return h;
}

fragment float4 jelLight(VOut in [[stage_in]], texture2d<float> M [[texture(0)]], texture2d<float> B1 [[texture(1)]], texture2d<float> B2 [[texture(2)]],
                         sampler sm [[sampler(0)]], constant LightU& u [[buffer(0)]]) {
    float2 v = in.uv, res = u.resRpxN.xy;
    float rpx = u.resRpxN.z;
    float aEdge = u.k0.x, aCore = u.k0.y, amb = u.k0.z, dif = u.k0.w;
    float glow = u.k1.x, line = u.k1.y, nk = u.k1.z, shin = u.k1.w;
    float s0 = u.k2.x, s1 = u.k2.y, spec = u.k2.z, sheen = u.k2.w, arc = u.k3.x;
    float m = M.sample(sm, v).r, cov = smoothstep(0.18, 0.82, m);
    if (cov <= 0.0) return float4(0.0);
    float2 e = 2.0 / res, E = 8.0 / res;
    float gx = (H1(v + float2(e.x, 0.0), B1, sm, u) - H1(v - float2(e.x, 0.0), B1, sm, u)) / 4.0
             + 0.55 * (B2.sample(sm, v + float2(E.x, 0.0)).r - B2.sample(sm, v - float2(E.x, 0.0)).r) / 16.0;
    float gyDown = (H1(v + float2(0.0, e.y), B1, sm, u) - H1(v - float2(0.0, e.y), B1, sm, u)) / 4.0
                 + 0.55 * (B2.sample(sm, v + float2(0.0, E.y)).r - B2.sample(sm, v - float2(0.0, E.y)).r) / 16.0;
    float gy = -gyDown;   // the web's y ran up
    float3 n = normalize(float3(-gx * rpx * nk, -gy * rpx * nk, 1.0));
    float3 L = normalize(float3(-0.5, 0.72, 0.9)), Hv = normalize(L + float3(0.0, 0.0, 1.0));
    float b1 = B1.sample(sm, v).r, b2 = B2.sample(sm, v).r, thick = smoothstep(0.08, 0.8, b2), fres = pow(1.0 - n.z, 2.0);
    float3 col = mix(u.cEdge.rgb, u.cCore.rgb, thick);
    col *= amb + dif * clamp(dot(n, L), 0.0, 1.0);
    float tr = clamp(dot(n.xy, normalize(float2(0.35, -0.94))), 0.0, 1.0);
    col += u.cGlow.rgb * smoothstep(0.0, 0.7, tr) * (0.25 + 0.75 * fres) * glow;
    float a = mix(aEdge, aCore, thick);
    float4 c = float4(col * a, a);
    c = mix(c, float4(u.cLine.rgb, 1.0), (1.0 - smoothstep(0.5, 0.66, b1)) * line);
    float nh = max(dot(n, Hv), 0.0);
    c.rgb += float3(pow(nh, shin * 0.22) * sheen * (1.0 - thick * 0.4)) * c.a;
    c = mix(c, float4(1.0), smoothstep(s0, s1, pow(nh, shin)) * spec);
    // the bright arc: along the contour just inside the outline, only the part facing the light; it follows a pull or a squash, thin places lose it
    float2 g2 = float2(B1.sample(sm, v + float2(e.x, 0.0)).r - B1.sample(sm, v - float2(e.x, 0.0)).r,
                       -(B1.sample(sm, v + float2(0.0, e.y)).r - B1.sample(sm, v - float2(0.0, e.y)).r));
    float gl2 = length(g2);
    if (gl2 > 1e-5 && arc > 0.0) {
        float wd = 0.05 * smoothstep(0.70, 0.97, dot(-g2 / gl2, normalize(float2(-0.62, 0.78))));
        if (wd > 0.002) c = mix(c, float4(1.0), (1.0 - smoothstep(wd * 0.55, wd, abs(b1 - 0.90))) * arc);
    }
    return c * cov;
}
