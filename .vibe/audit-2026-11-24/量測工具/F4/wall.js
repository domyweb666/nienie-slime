(a) => { const F = window.__f4; F.setSeed(a.seed); if (a.slime != null) { chooseSlime(a.slime, false, false); } F.settle(a.settle || 6);
 const r = R * CAM.z, ev = F.ev; let gx = globalC.xc, gy = globalC.yc; if (a.grab === 'bottom') gy = SILL.g.fl - R * .3; if (a.grab === 'side') gx += R * .6;
 const [x, y] = F.scr(gx, gy); F.start(); ev('pointerdown', 1, x, y); F.step(8);
 const tx = a.side === 'r' ? 386 : 7, ty = y - r * a.up; const n = Math.round(a.T * 60);
 for (let k = 1; k <= n; k++) { const u = k / n, e = u * u * (3 - 2 * u); ev('pointermove', 1, x + (tx - x) * e, y + (ty - y) * e); F.step(1); }
 F.step(Math.round(a.hold * 60));
 let x1 = -1e9, y1 = -1e9; for (const i of bnd) { x1 = Math.max(x1, X[i]); y1 = Math.max(y1, Y[i]); }
 const st = [...fingers.values()][0] ? [...fingers.values()][0].stretch : -1, strain = MOOD.strainMax;
 ev('pointerup', 1, tx, ty); F.step(30); const c05 = CLING.on, n05 = CLING.n; F.step(150); const c3 = CLING.on;
 F.stop(); return { c05, n05, c3, x1: +x1.toFixed(0), gap: +((SILL.g.fl - y1) / R).toFixed(2), st: +st.toFixed(2), strain: +strain.toFixed(2), esc: F.log.filter(e => e[1] === 'st:esc').length > 0 }; }
