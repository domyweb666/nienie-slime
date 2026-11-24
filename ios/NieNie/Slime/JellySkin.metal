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

// v2.61 A1 網格聯集的皮 (web: JELX.mode 9, jelMeshInit's VM FM VC FC): the mask drawn from the body's own triangles instead of its outline. Every triangle writes 1,
// the capsules (the keep-alive line where it is thin) their own soft edge, all blended with max, so neither the winding nor the order matters.
// Points are screen points, y down; u.xy = 2 / the mask's size.
struct MeshOut { float4 pos [[position]]; };

vertex MeshOut jelMeshVertex(uint vid [[vertex_id]], const device float2* p [[buffer(0)]], constant float4& u [[buffer(1)]]) {
    MeshOut o;
    o.pos = float4(p[vid].x * u.x - 1.0, 1.0 - p[vid].y * u.y, 0.0, 1.0);
    return o;
}

fragment float4 jelMeshFragment(MeshOut in [[stage_in]]) {
    return float4(1.0);
}

struct CapIn { float4 ab; float4 r; };   // the two ends; the radius in r.x (Swift: SkinMesh.Cap)
struct CapOut { float4 pos [[position]]; float2 q; float4 sg [[flat]]; float rd [[flat]]; };

vertex CapOut jelCapVertex(uint vid [[vertex_id]], uint iid [[instance_id]], const device CapIn* c [[buffer(0)]], constant float4& u [[buffer(1)]]) {
    float2 p = float2(float(vid & 1u), float(vid >> 1) * 2.0 - 1.0);   // a strip of four: (0,-1) (1,-1) (0,1) (1,1)
    float4 ab = c[iid].ab;
    float r = c[iid].r.x;
    float2 a = ab.xy, b = ab.zw, d = b - a;
    float L = length(d);
    float2 along = L > 1e-5 ? d / L : float2(1.0, 0.0);
    float2 n = float2(-along.y, along.x);
    float2 q = mix(a, b, p.x) + along * (p.x * 2.0 - 1.0) * (r + 1.0) + n * p.y * (r + 1.0);
    CapOut o;
    o.pos = float4(q.x * u.x - 1.0, 1.0 - q.y * u.y, 0.0, 1.0);
    o.q = q;
    o.sg = ab;
    o.rd = r;
    return o;
}

fragment float4 jelCapFragment(CapOut in [[stage_in]]) {
    float2 a = in.sg.xy, ba = in.sg.zw - a, pa = in.q - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return float4(clamp(in.rd + 0.5 - length(pa - ba * h), 0.0, 1.0));
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
    float4 k3;           // arc, rnd (v2.47: threshold on the small blur for the outline, 0 = the mask), wet (v2.47)
    float4 k4;           // v2.49: water (0 = the v2.48 skin), refr (how far the background bends, in radii), absorb (how much the thick part takes its colour); v2.51 w: opaque
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

fragment float4 jelLight(VOut in [[stage_in]], texture2d<float> M [[texture(0)]], texture2d<float> B1 [[texture(1)]], texture2d<float> B2 [[texture(2)]], texture2d<float> BG [[texture(3)]],
                         sampler sm [[sampler(0)]], constant LightU& u [[buffer(0)]]) {
    float2 v = in.uv, res = u.resRpxN.xy;
    float rpx = u.resRpxN.z;
    float aEdge = u.k0.x, aCore = u.k0.y, amb = u.k0.z, dif = u.k0.w;
    float glow = u.k1.x, line = u.k1.y, nk = u.k1.z, shin = u.k1.w;
    float s0 = u.k2.x, s1 = u.k2.y, spec = u.k2.z, sheen = u.k2.w, arc = u.k3.x, rnd = u.k3.y, wet = u.k3.z;
    // v2.47 rnd: the outline from the blurred mask, so sharp corners and thin spikes round off and concave corners join like water
    float m = M.sample(sm, v).r, cov = rnd > 0.0 ? smoothstep(rnd - 0.05, rnd + 0.05, B1.sample(sm, v).r) : smoothstep(0.18, 0.82, m);
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
    // v2.49 看得出是水 (多米 11-16: it should read as made of water, 95% water): what is behind it shows through, bent (most at the edge, like looking
    // through a drop); thin places are almost colourless, only the thick part takes its colour; a band of light gathers inside the far edge; the rim reflects the sky
    float water = u.k4.x;
    if (water > 0.0) {
        float2 ro = float2(-n.x, n.y) * rpx * u.k4.y / res * (0.3 + 0.7 * thick);   // n's y runs up, the texture's down
        float3 bg = BG.sample(sm, v + ro).rgb;
        float3 T = mix(float3(1.0), u.cCore.rgb, clamp(thick * u.k4.z + 0.05, 0.0, 1.0));
        float3 w = bg * T + u.cGlow.rgb * smoothstep(0.15, 0.8, tr) * (0.2 + 0.8 * fres) * glow * 0.5;
        w = mix(w, col, clamp(smoothstep(0.03, 0.35, thick) * u.k4.w, 0.0, 1.0));   // v2.51: the thick part hides what is behind it
        w *= 1.0 - 0.16 * smoothstep(0.2, 0.55, fres) * (1.0 - smoothstep(0.55, 0.9, fres));
        w = mix(w, float3(0.95, 0.98, 1.0), fres * 0.3);
        c = mix(c, float4(w, 1.0), water);
    }
    c = mix(c, float4(u.cLine.rgb, 1.0), (1.0 - smoothstep(0.5, 0.66, b1)) * line);
    float nh = max(dot(n, Hv), 0.0);
    c.rgb += float3(pow(nh, shin * 0.22) * sheen * (1.0 - thick * 0.4)) * c.a;
    c = mix(c, float4(1.0), smoothstep(s0, s1, pow(nh, shin)) * spec);
    // v2.47 水潤: a second small highlight beside the main one, a rim of light along the edge
    if (wet > 0.0) {
        float3 H2 = normalize(normalize(float3(-0.26, 0.46, 0.9)) + float3(0.0, 0.0, 1.0));
        c = mix(c, float4(1.0), smoothstep(0.5, 0.8, pow(max(dot(n, H2), 0.0), shin * 2.2)) * 0.75 * wet);
        c.rgb += float3(fres * 0.30 * wet * (1.0 - 0.6 * water)) * c.a;
    }
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
