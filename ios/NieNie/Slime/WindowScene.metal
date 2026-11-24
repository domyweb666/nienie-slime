#include <metal_stdlib>
using namespace metal;

// v2.59 窗景: the layers outside the window, one quad each, and the dashes of the waterfall as capsules (WindowScene.swift).
// Everything is premultiplied. All float4, so the Swift side hands over a plain array of SIMD4<Float>.

struct WinOut { float4 pos [[position]]; float2 uv; float2 q; };
struct WinU {
    float4 v[4];   // the corners: clip-space x, y; then the clip circle's own coordinates (quads) or along, across the dash (dashes)
    float4 k;      // quads: alpha, the circle's radius (0 = none). dashes: alpha, half the width, length, 1 = round ends
    float4 c;      // dashes: the colour
};

vertex WinOut winVertex(uint vid [[vertex_id]], constant WinU& u [[buffer(0)]]) {
    float4 p = u.v[vid];
    WinOut o;
    o.pos = float4(p.xy, 0.0, 1.0);
    o.uv = float2(float(vid & 1u), float(vid >> 1));
    o.q = p.zw;
    return o;
}

fragment float4 winQuad(WinOut in [[stage_in]], texture2d<float> t [[texture(0)]], sampler sm [[sampler(0)]], constant WinU& u [[buffer(0)]]) {
    float4 c = t.sample(sm, in.uv, bias(-0.5));
    float d = length(in.q);
    float cut = clamp(0.5 - (d - u.k.y) / max(fwidth(d), 1e-5), 0.0, 1.0);
    float a = u.k.y > 0.0 ? u.k.x * cut : u.k.x;
    return c * a;
}

fragment float4 winDash(WinOut in [[stage_in]], constant WinU& u [[buffer(0)]]) {
    float x = in.q.x, y = in.q.y;
    float capsule = length(float2(x - clamp(x, 0.0, u.k.z), y)) - u.k.y;
    float box = max(abs(y) - u.k.y, max(-x, x - u.k.z));
    float d = u.k.w > 0.5 ? capsule : box;
    float w = max(max(fwidth(x), fwidth(y)), 1e-5);
    float a = clamp(0.5 - d / w, 0.0, 1.0) * u.k.x * u.c.a;
    return float4(u.c.rgb * a, a);
}
