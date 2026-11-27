// 補點那一格：同一個物理狀態，remesh 前後各畫一次，量純粹由補點造成的外框變化；順便量眼睛、珍珠、餡、紫斑、凹痕的瞬移
window.REMLOG = [];
(() => {
  const rm0 = remesh;
  const ctr = L => { if (!L.length) return null; let x = 0, y = 0; for (const i of L) { x += X[i]; y += Y[i]; } x /= L.length; y /= L.length; let s = 0; for (const i of L) s += Math.hypot(X[i] - x, Y[i] - y); return [x, y, s / L.length]; };
  remesh = function (back) {
    draw(); F2.readSkin(); const A = F2.skin.slice(); eyePose(0); const e0 = EYE.pose.slice(), P0 = boundaryPts(); const N0 = N, nb0 = bnd.length;
    const f = FX(); if (f.core && CORE.n !== N) { CORE.n = N; CORE.list = fxInner(.4, .44, 22); }
    const c0 = f.core ? ctr(CORE.list) : null, p0 = f.pearls ? PEARL.list.map(p => [p.x, p.y, X[p.i], Y[p.i]]) : null, s0 = f.purple ? STAIN.map(s => [X[s.i], Y[s.i], s.k]) : null, d0 = DENTS.length ? DENTS.map(d => d.d) : [];
    const r = rm0(back); if (!r) return r;
    draw(); F2.readSkin(); const B = F2.skin; let x = 0; for (let i = 0; i < A.length; i++) if (A[i] !== B[i]) x++;
    eyePose(0); const e1 = EYE.pose; let per = 0; for (let i = 0; i < P0.length; i++) { const a = P0[i], b = P0[(i + 1) % P0.length]; per += Math.hypot(a[0] - b[0], a[1] - b[1]); }
    // 外框點最大位移：新外框點到舊外框折線的距離
    const P1 = boundaryPts(); let md = 0; for (const q of P1) { const d = Math.abs(sdRing(P0, q[0], q[1])); if (d > md) md = d; }
    const o = { f: t, back: back ? 1 : 0, xor: x, disp: x / per, maxd: md, eye: Math.max(Math.hypot(e1[0] - e0[0], e1[1] - e0[1]), Math.hypot(e1[2] - e0[2], e1[3] - e0[3])), N0, N1: N, nb0, nb1: bnd.length, dents: d0.length, dentMax: d0.length ? Math.max(...d0) : 0 };
    if (c0) { if (CORE.n !== N) { CORE.n = N; CORE.list = fxInner(.4, .44, 22); } const c1 = ctr(CORE.list); o.core = Math.hypot(c1[0] - c0[0], c1[1] - c0[1]) / R; o.spread = [c0[2] / R, c1[2] / R]; }
    if (p0) { const q0 = PEARL.list.map(p => [p.x, p.y]); fxStep(1e-6); const q1 = PEARL.list.map(p => [p.x, p.y]); o.pearl = p0.map((p, k) => q1[k] ? Math.hypot(q1[k][0] - p[0], q1[k][1] - p[1]) / R : 9); }
    if (s0) o.stain = s0.map((s, k) => STAIN[k] && STAIN[k].i < N ? Math.hypot(X[STAIN[k].i] - s[0], Y[STAIN[k].i] - s[1]) / R : 9);
    REMLOG.push(o); return r; };
})();
0
