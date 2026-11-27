// 亂捏（手勢照 fuzz.js）＋每幀量皮。CFG={seeds,over,every,stopAt,set(史萊姆編號)}；stopAt=[seed,frame] 時跑到那一幀就停，給截圖用
window.FZS = async (CFG) => {
  const { seeds, over, every = 2, stopAt = null } = CFG, out = [], DT = F2.DT, ev = F2.ev, scr = F2.scr, clampS = F2.clampS;
  for (const seed of seeds) {
    F2.fresh(seed, over); F2.resetPrev();
    const rnd = F2.seeded(seed * 2654435761 % 4294967296); Math.random = F2.seeded(seed);
    const rows = []; let fr = 0, stopped = false, lastRem = REM.n, lastN = N;
    const step = (ph) => { if (stopped) return; if (CFG.pre) CFG.pre(fr); const pn = N; update(DT); fr++; if (stopAt && stopAt[1] === fr) { stopped = true; return; }
      if (!stopAt) { const remeshed = REM.n !== lastRem || N !== lastN; lastRem = REM.n; lastN = N; if (fr % every === 0 || remeshed) { const m = F2.measure(); m.f = fr; m.ph = ph; m.rm = remeshed ? 1 : 0; rows.push(m); } } };
    const pick = () => { const a = rnd() * 6.283, rr = Math.sqrt(rnd()) * .95, c = globalC; let bi = 0, bd = 1e9; const tx = c.xc + Math.cos(a) * R * rr, ty = c.yc + Math.sin(a) * R * rr; for (let i = 0; i < N; i++) { const d = (X[i] - tx) ** 2 + (Y[i] - ty) ** 2; if (d < bd) { bd = d; bi = i; } } return scr(X[bi], Y[bi]); };
    const drag = (id, x0, y0, x1, y1, n, ph) => { for (let s = 1; s <= n; s++) { const [x, y] = clampS(x0 + (x1 - x0) * s / n, y0 + (y1 - y0) * s / n); if (!stopped) ev('pointermove', id, x, y); step(ph); } return clampS(x1, y1); };
    const up = (id, x, y) => { if (!stopped) ev('pointerup', id, x, y); };
    const ng = 5 + Math.floor(rnd() * 4);
    for (let g = 0; g < ng && !stopped; g++) {
      const kind = Math.floor(rnd() * 6), a = rnd() * 6.283, dist = (.5 + rnd() * 3.5) * R, n = 4 + Math.floor(rnd() * 36), hd = Math.floor(rnd() * 100);
      const [sx, sy] = pick();
      if (kind === 0 || kind === 1) { ev('pointerdown', 1, sx, sy); for (let i = 0; i < 4; i++) step('d'); const [ex, ey] = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n, 'pull'); for (let i = 0; i < hd; i++) step('hold'); up(1, ex, ey); }
      else if (kind === 2) { const [tx, ty] = pick(); ev('pointerdown', 1, sx, sy); ev('pointerdown', 2, tx, ty); for (let i = 0; i < 4; i++) step('d');
        const ex = sx + Math.cos(a) * dist * .6, ey = sy + Math.sin(a) * dist * .6, fx = tx - Math.cos(a) * dist * .6, fy = ty - Math.sin(a) * dist * .6; let e1 = [sx, sy], e2 = [tx, ty];
        for (let s = 1; s <= n; s++) { e1 = clampS(sx + (ex - sx) * s / n, sy + (ey - sy) * s / n); e2 = clampS(tx + (fx - tx) * s / n, ty + (fy - ty) * s / n); if (!stopped) { ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); } step('two'); }
        for (let i = 0; i < hd; i++) step('hold'); up(1, e1[0], e1[1]); for (let i = 0; i < 6; i++) step('rel'); up(2, e2[0], e2[1]); }
      else if (kind === 3) { ev('pointerdown', 1, sx, sy); step('d'); let px = sx, py = sy; for (let k = 0; k < 6; k++) { const sg = k % 2 ? -1 : 1, bx = sx + Math.cos(a) * dist * .5 * sg + (rnd() - .5) * R * .6, by = sy + Math.sin(a) * dist * .5 * sg + (rnd() - .5) * R * .6; [px, py] = drag(1, px, py, bx, by, 5 + Math.floor(rnd() * 8), 'scrub'); } up(1, px, py); }
      else if (kind === 4) { ev('pointerdown', 1, sx, sy); step('d'); const rr = dist * .4, turns = 40 + Math.floor(rnd() * 60); let p = [sx, sy]; for (let k = 1; k <= turns; k++) { const th = a + k * .35; p = clampS(sx + Math.cos(th) * rr - Math.cos(a) * rr, sy + Math.sin(th) * rr - Math.sin(a) * rr); if (!stopped) ev('pointermove', 1, p[0], p[1]); step('stir'); } for (let i = 0; i < hd / 2; i++) step('hold'); up(1, p[0], p[1]); }
      else { ev('pointerdown', 1, sx, sy); for (let i = 0; i < 3; i++) step('d'); let p = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n, 'zig'); for (let i = 0; i < hd / 3; i++) step('hold'); const b = a + 1.6 + rnd() * 3; p = drag(1, p[0], p[1], sx + Math.cos(b) * dist, sy + Math.sin(b) * dist, 6 + Math.floor(rnd() * 20), 'zig'); for (let i = 0; i < hd; i++) step('hold'); up(1, p[0], p[1]); }
      const rest = 10 + Math.floor(rnd() * 80); for (let i = 0; i < rest && !stopped; i++) step('rel');
    }
    for (let i = 0; i < 120 && !stopped; i++) step('end');
    out.push({ seed, rows, frames: fr });
    if (stopped) break;
    await new Promise(r => setTimeout(r, 0));
  }
  return out;
};
// 拉很長：六次連拉（照 p4.js），拉得比亂捏遠
window.P4S = async (CFG) => {
  const { seeds, over, every = 2, stopAt = null } = CFG, out = [], DT = F2.DT, ev = F2.ev, scr = F2.scr;
  for (const sd of seeds) {
    F2.fresh(61, over); F2.resetPrev(); const rows = []; let fr = 0, stopped = false, lastRem = REM.n, lastN = N;
    const step = (ph) => { if (stopped) return; update(DT); fr++; if (stopAt && stopAt[1] === fr) { stopped = true; return; } if (!stopAt) { const remeshed = REM.n !== lastRem || N !== lastN; lastRem = REM.n; lastN = N; if (fr % every === 0 || remeshed) { const m = F2.measure(); m.f = fr; m.ph = ph; m.rm = remeshed ? 1 : 0; rows.push(m); } } };
    const rr = F2.seeded(sd * 7919), PP = Array.from({ length: 6 }, () => [rr(), rr(), rr(), rr(), 10 + Math.floor(rr() * 20), 20 + Math.floor(rr() * 70)]);
    for (const [a1, a2, a3, a4, nm, hh] of PP) { if (stopped) break; const bi = bnd[Math.floor(a1 * bnd.length) % bnd.length], c = globalC, k = .15 + .3 * a2, [sx, sy] = scr(X[bi] + (c.xc - X[bi]) * k, Y[bi] + (c.yc - Y[bi]) * k), ex = 10 + a3 * (innerWidth - 20), ey = 60 + a4 * innerHeight * .5; ev('pointerdown', 1, sx, sy); for (let i = 0; i < 4; i++) step('d'); for (let s = 1; s <= nm; s++) { if (!stopped) ev('pointermove', 1, sx + (ex - sx) * s / nm, sy + (ey - sy) * s / nm); step('pull'); } for (let i = 0; i < hh; i++) step('hold'); if (!stopped) ev('pointerup', 1, ex, ey); for (let i = 0; i < 25; i++) step('rel'); }
    for (let i = 0; i < 120 && !stopped; i++) step('end');
    out.push({ seed: sd, rows, frames: fr }); if (stopped) break; await new Promise(r => setTimeout(r, 0));
  }
  return out;
};
// 兩指：各抓一邊往兩頭拉到螢幕邊（左右／上下／斜），按住，放手
window.TWO = async (CFG) => {
  const { seeds, over, every = 2, stopAt = null } = CFG, out = [], DT = F2.DT, ev = F2.ev, scr = F2.scr, clampS = F2.clampS;
  for (const sd of seeds) {
    F2.fresh(sd, over); F2.resetPrev(); const rows = []; let fr = 0, stopped = false, lastRem = REM.n, lastN = N;
    const step = (ph) => { if (stopped) return; update(DT); fr++; if (stopAt && stopAt[1] === fr) { stopped = true; return; } if (!stopAt) { const remeshed = REM.n !== lastRem || N !== lastN; lastRem = REM.n; lastN = N; if (fr % every === 0 || remeshed) { const m = F2.measure(); m.f = fr; m.ph = ph; m.rm = remeshed ? 1 : 0; rows.push(m); } } };
    const rr = F2.seeded(sd * 104729), a = rr() * Math.PI, ux = Math.cos(a), uy = Math.sin(a), n = 8 + Math.floor(rr() * 50), far = (1.5 + rr() * 3) * R, c = globalC;
    const b1 = F2.edgePt(ux, uy), b2 = F2.edgePt(-ux, -uy), k = .2 + .3 * rr(), [s1x, s1y] = scr(X[b1] + (c.xc - X[b1]) * k, Y[b1] + (c.yc - Y[b1]) * k), [s2x, s2y] = scr(X[b2] + (c.xc - X[b2]) * k, Y[b2] + (c.yc - Y[b2]) * k);
    ev('pointerdown', 1, s1x, s1y); ev('pointerdown', 2, s2x, s2y); for (let i = 0; i < 4; i++) step('d');
    // 先一起往上提到畫面中間，不然下面那指會被窗台擋住
    const lift = -H * .25; let e1 = [s1x, s1y], e2 = [s2x, s2y];
    for (let s = 1; s <= 20; s++) { e1 = clampS(s1x, s1y + lift * s / 20); e2 = clampS(s2x, s2y + lift * s / 20); if (!stopped) { ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); } step('lift'); }
    const o1 = e1.slice(), o2 = e2.slice();
    for (let s = 1; s <= n; s++) { e1 = clampS(o1[0] + ux * far * s / n, o1[1] + uy * far * s / n); e2 = clampS(o2[0] - ux * far * s / n, o2[1] - uy * far * s / n); if (!stopped) { ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); } step('two'); }
    for (let i = 0; i < 60; i++) step('hold');
    if (!stopped) ev('pointerup', 1, e1[0], e1[1]); for (let i = 0; i < 10; i++) step('rel'); if (!stopped) ev('pointerup', 2, e2[0], e2[1]); for (let i = 0; i < 120 && !stopped; i++) step('end');
    out.push({ seed: sd, rows, frames: fr }); if (stopped) break; await new Promise(r => setTimeout(r, 0));
  }
  return out;
};
;0
