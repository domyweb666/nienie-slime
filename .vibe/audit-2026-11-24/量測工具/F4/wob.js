(a) => { const F = window.__f4; F.setSeed(a.seed); if (a.slime != null) chooseSlime(a.slime, false, false); F.settle(5);
 const r = R * CAM.z, ev = F.ev; let b = 0, bd = -1e9; const ux = -.3, uy = -.95; for (const i of bnd) { const p = (X[i] - globalC.xc) * ux + (Y[i] - globalC.yc) * uy; if (p > bd) { bd = p; b = i; } }
 const [x, y] = F.scr(X[b] - ux * R * .25, Y[b] - uy * R * .25); ev('pointerdown', 1, x, y); F.step(4);
 for (let k = 1; k <= 30; k++) { ev('pointermove', 1, x - r * .3 * a.d * k / 30, y - r * a.d * k / 30); F.step(1); } F.step(10);
 ev('pointerup', 1, x, y - r * a.d); const out = []; const S = new Float64Array(N), T = new Float64Array(N);
 const rate = () => { // mean particle speed relative to the centroid, in R per second
   let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i] - S[i]; my += Y[i] - T[i]; } mx /= N; my /= N; let s = 0, m = 0; for (let i = 0; i < N; i++) { const v = Math.hypot(X[i] - S[i] - mx, Y[i] - T[i] - my); s += v * v; m = Math.max(m, v); } return [Math.sqrt(s / N) * 60 / R, m * 60 / R]; };
 for (let k = 0; k < 180; k++) { for (let i = 0; i < N; i++) { S[i] = X[i]; T[i] = Y[i]; } update(1 / 60); const q = rate(); out.push([+(k / 60).toFixed(2), +q[0].toFixed(3), +q[1].toFixed(2)]); }
 return out; }
