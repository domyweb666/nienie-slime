// 同一個物理狀態，用不同遮罩各畫一次、各量一次（配對比較），並留最糟畫面
window.F2PAIR = (() => {
  const caps = {}, K = 3;   // 每一類留最糟 K 張
  const jpg = () => { const k = document.createElement('canvas'); k.width = 393; k.height = 852; k.getContext('2d').drawImage(cv, 0, 0, 393, 852); return k.toDataURL('image/jpeg', .85); };
  function diag() { const W1 = F2.W1, H1 = F2.H1, k = document.createElement('canvas'); k.width = W1; k.height = H1; const g = k.getContext('2d');
    const im = g.createImageData(W1, H1); for (let i = 0; i < W1 * H1; i++) { const r = F2.raw[i], s = F2.skin[i]; let c = [255, 255, 255]; if (r && s) c = [205, 205, 210]; else if (r && !s) c = [255, 90, 70]; else if (!r && s) c = [90, 160, 255]; im.data[4 * i] = c[0]; im.data[4 * i + 1] = c[1]; im.data[4 * i + 2] = c[2]; im.data[4 * i + 3] = 255; } g.putImageData(im, 0, 0);
    const S = (x, y) => F2.scr(x, y);
    for (let q = 0; q < TRI.length; q += 3) { const a = TRI[q], b = TRI[q + 1], c = TRI[q + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[q / 3]) { const A = S(X[a], Y[a]), B = S(X[b], Y[b]), C = S(X[c], Y[c]); g.fillStyle = 'rgba(255,200,0,.45)'; g.beginPath(); g.moveTo(A[0], A[1]); g.lineTo(B[0], B[1]); g.lineTo(C[0], C[1]); g.fill(); } }
    g.lineWidth = .9; g.strokeStyle = '#0a0'; g.beginPath(); bnd.forEach((i, n) => { const a = S(X[i], Y[i]); n ? g.lineTo(a[0], a[1]) : g.moveTo(a[0], a[1]); }); g.closePath(); g.stroke();
    for (const f of fingers.values()) { g.strokeStyle = '#f0f'; g.lineWidth = 2; g.beginPath(); g.arc(f.sx, f.sy, 8, 0, 7); g.stroke(); }
    return k.toDataURL('image/jpeg', .85); }
  function offer(cat, score, info, modes) { if (!(score > 0)) return; const L = caps[cat] = caps[cat] || []; const key = info.seed + '/' + info.g; const same = L.find(o => o.key === key); if (same && same.score >= score) return; if (!same && L.length >= K && L[L.length - 1].score >= score) return;
    const imgs = {}; SKM.mode = 0; draw(); F2.readSkin(); F2.readRaw(); imgs.m0 = jpg(); imgs.d0 = diag(); for (const md of modes) if (md) { SKM.mode = md; draw(); imgs['m' + md] = jpg(); } SKM.mode = 0;
    const o = { key, score, info, imgs }; if (same) L[L.indexOf(same)] = o; else L.push(o); L.sort((a, b) => b.score - a.score); if (L.length > K) L.length = K; }
  return { caps, offer, jpg, diag };
})();
// 手勢產生器：把 fuzz、連拉、兩指包成同一個介面，每一幀呼叫 tick(ph,g)
window.GEST = {
  FZS: (seed, step, alive) => { const ev = F2.ev, scr = F2.scr, clampS = F2.clampS, rnd = F2.seeded(seed * 2654435761 % 4294967296); Math.random = F2.seeded(seed);
    const pick = () => { const a = rnd() * 6.283, rr = Math.sqrt(rnd()) * .95, c = globalC; let bi = 0, bd = 1e9; const tx = c.xc + Math.cos(a) * R * rr, ty = c.yc + Math.sin(a) * R * rr; for (let i = 0; i < N; i++) { const d = (X[i] - tx) ** 2 + (Y[i] - ty) ** 2; if (d < bd) { bd = d; bi = i; } } return scr(X[bi], Y[bi]); };
    const drag = (id, x0, y0, x1, y1, n, ph, g) => { for (let s = 1; s <= n; s++) { const [x, y] = clampS(x0 + (x1 - x0) * s / n, y0 + (y1 - y0) * s / n); ev('pointermove', id, x, y); step(ph, g); } return clampS(x1, y1); };
    const ng = 5 + Math.floor(rnd() * 4);
    for (let g = 0; g < ng; g++) { const kind = Math.floor(rnd() * 6), a = rnd() * 6.283, dist = (.5 + rnd() * 3.5) * R, n = 4 + Math.floor(rnd() * 36), hd = Math.floor(rnd() * 100); const [sx, sy] = pick();
      if (kind < 2) { ev('pointerdown', 1, sx, sy); for (let i = 0; i < 4; i++) step('d', g); const [ex, ey] = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n, 'pull', g); for (let i = 0; i < hd; i++) step('hold', g); ev('pointerup', 1, ex, ey); }
      else if (kind === 2) { const [tx, ty] = pick(); ev('pointerdown', 1, sx, sy); ev('pointerdown', 2, tx, ty); for (let i = 0; i < 4; i++) step('d', g); const ex = sx + Math.cos(a) * dist * .6, ey = sy + Math.sin(a) * dist * .6, fx = tx - Math.cos(a) * dist * .6, fy = ty - Math.sin(a) * dist * .6; let e1 = [sx, sy], e2 = [tx, ty]; for (let s = 1; s <= n; s++) { e1 = clampS(sx + (ex - sx) * s / n, sy + (ey - sy) * s / n); e2 = clampS(tx + (fx - tx) * s / n, ty + (fy - ty) * s / n); ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); step('two', g); } for (let i = 0; i < hd; i++) step('hold2', g); ev('pointerup', 1, e1[0], e1[1]); for (let i = 0; i < 6; i++) step('rel', g); ev('pointerup', 2, e2[0], e2[1]); }
      else if (kind === 3) { ev('pointerdown', 1, sx, sy); step('d', g); let px = sx, py = sy; for (let k = 0; k < 6; k++) { const sg = k % 2 ? -1 : 1, bx = sx + Math.cos(a) * dist * .5 * sg + (rnd() - .5) * R * .6, by = sy + Math.sin(a) * dist * .5 * sg + (rnd() - .5) * R * .6; [px, py] = drag(1, px, py, bx, by, 5 + Math.floor(rnd() * 8), 'scrub', g); } ev('pointerup', 1, px, py); }
      else if (kind === 4) { ev('pointerdown', 1, sx, sy); step('d', g); const rr = dist * .4, turns = 40 + Math.floor(rnd() * 60); let p = [sx, sy]; for (let k = 1; k <= turns; k++) { const th = a + k * .35; p = clampS(sx + Math.cos(th) * rr - Math.cos(a) * rr, sy + Math.sin(th) * rr - Math.sin(a) * rr); ev('pointermove', 1, p[0], p[1]); step('stir', g); } for (let i = 0; i < hd / 2; i++) step('hold', g); ev('pointerup', 1, p[0], p[1]); }
      else { ev('pointerdown', 1, sx, sy); for (let i = 0; i < 3; i++) step('d', g); let p = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n, 'zig', g); for (let i = 0; i < hd / 3; i++) step('hold', g); const b = a + 1.6 + rnd() * 3; p = drag(1, p[0], p[1], sx + Math.cos(b) * dist, sy + Math.sin(b) * dist, 6 + Math.floor(rnd() * 20), 'zig', g); for (let i = 0; i < hd; i++) step('hold', g); ev('pointerup', 1, p[0], p[1]); }
      const rest = 10 + Math.floor(rnd() * 80); for (let i = 0; i < rest; i++) step('rel', g); }
    for (let i = 0; i < 120; i++) step('end', 99); },
  P4S: (sd, step) => { const ev = F2.ev, scr = F2.scr, rr = F2.seeded(sd * 7919), PP = Array.from({ length: 6 }, () => [rr(), rr(), rr(), rr(), 10 + Math.floor(rr() * 20), 20 + Math.floor(rr() * 70)]);
    PP.forEach(([a1, a2, a3, a4, nm, hh], g) => { const bi = bnd[Math.floor(a1 * bnd.length) % bnd.length], c = globalC, k = .15 + .3 * a2, [sx, sy] = scr(X[bi] + (c.xc - X[bi]) * k, Y[bi] + (c.yc - Y[bi]) * k), ex = 10 + a3 * (innerWidth - 20), ey = 60 + a4 * innerHeight * .5; ev('pointerdown', 1, sx, sy); for (let i = 0; i < 4; i++) step('d', g); for (let s = 1; s <= nm; s++) { ev('pointermove', 1, sx + (ex - sx) * s / nm, sy + (ey - sy) * s / nm); step('pull', g); } for (let i = 0; i < hh; i++) step('hold', g); ev('pointerup', 1, ex, ey); for (let i = 0; i < 25; i++) step('rel', g); });
    for (let i = 0; i < 120; i++) step('end', 99); },
  TWO: (sd, step) => { const ev = F2.ev, scr = F2.scr, clampS = F2.clampS, rr = F2.seeded(sd * 104729), a = rr() * Math.PI, ux = Math.cos(a), uy = Math.sin(a), n = 8 + Math.floor(rr() * 50), far = (1.5 + rr() * 3) * R, c = globalC;
    const b1 = F2.edgePt(ux, uy), b2 = F2.edgePt(-ux, -uy), k = .2 + .3 * rr(), [s1x, s1y] = scr(X[b1] + (c.xc - X[b1]) * k, Y[b1] + (c.yc - Y[b1]) * k), [s2x, s2y] = scr(X[b2] + (c.xc - X[b2]) * k, Y[b2] + (c.yc - Y[b2]) * k);
    ev('pointerdown', 1, s1x, s1y); ev('pointerdown', 2, s2x, s2y); for (let i = 0; i < 4; i++) step('d', 0); const lift = -H * .25; let e1, e2; for (let s = 1; s <= 20; s++) { e1 = clampS(s1x, s1y + lift * s / 20); e2 = clampS(s2x, s2y + lift * s / 20); ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); step('lift', 0); }
    const o1 = e1.slice(), o2 = e2.slice(); for (let s = 1; s <= n; s++) { e1 = clampS(o1[0] + ux * far * s / n, o1[1] + uy * far * s / n); e2 = clampS(o2[0] - ux * far * s / n, o2[1] - uy * far * s / n); ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); step('two', 0); }
    for (let i = 0; i < 60; i++) step('hold2', 0); ev('pointerup', 1, e1[0], e1[1]); for (let i = 0; i < 10; i++) step('rel', 0); ev('pointerup', 2, e2[0], e2[1]); for (let i = 0; i < 120; i++) step('end', 99); },
  // 正常玩：單指從邊緣或中間慢慢拉 1 到 3R、停、放、揉（多米平常的玩法），不是暴力
  CALM: (sd, step) => { const ev = F2.ev, scr = F2.scr, clampS = F2.clampS, rr = F2.seeded(sd * 15485863);
    for (let g = 0; g < 5; g++) { const a = -Math.PI * rr(), ux = Math.cos(a), uy = Math.sin(a), bi = F2.edgePt(ux, uy), c = globalC, k = .1 + .5 * rr(), [sx, sy] = scr(X[bi] + (c.xc - X[bi]) * k, Y[bi] + (c.yc - Y[bi]) * k), dist = (.8 + 2.2 * rr()) * R, n = 30 + Math.floor(rr() * 60), hh = 20 + Math.floor(rr() * 60);
      ev('pointerdown', 1, sx, sy); for (let i = 0; i < 6; i++) step('d', g); let e = [sx, sy]; for (let s = 1; s <= n; s++) { e = clampS(sx + ux * dist * s / n, sy + uy * dist * s / n); ev('pointermove', 1, e[0], e[1]); step('pull', g); } for (let i = 0; i < hh; i++) step('hold', g); ev('pointerup', 1, e[0], e[1]); for (let i = 0; i < 50; i++) step('rel', g); }
    for (let i = 0; i < 120; i++) step('end', 99); },
};
window.RUNP = async ({ fn, seeds, over, every = 3, modes = [0, 1, 2], slime = null }) => { const out = [];
  if (slime != null) chooseSlime(slime, false, false);
  for (const seed of seeds) { F2.fresh(fn === 'P4S' ? 61 : seed, over); let fr = 0, lastRem = REM.n, lastN = N; const rows = []; const prev = {};
    const step = (ph, g) => { update(F2.DT); fr++; const rm = REM.n !== lastRem || N !== lastN; lastRem = REM.n; lastN = N; if (fr % every && !rm) return; const row = { f: fr, ph, g, rm: rm ? 1 : 0 };
      for (const md of modes) { SKM.mode = md; const m = F2.measure(); delete m.dxor; delete m.disp;
        const sk = F2.skin; if (prev[md] && prev[md].f === fr - 1 || prev[md]) { let x = 0; const p = prev[md].s; for (let i = 0; i < sk.length; i++) if (sk[i] !== p[i]) x++; m.dxor = x; m.df = fr - prev[md].f; } prev[md] = { f: fr, s: sk.slice() };
        row['m' + md] = md === 0 ? m : { ns: m.ns, hs: m.hs, hsA: m.hsA, pieces: m.pieces, As: m.As, Ar: m.Ar, lost: m.lost, gain: m.gain, eyeOut: m.eyeOut, eyeC: m.eyeC, dxor: m.dxor, df: m.df }; }
      SKM.mode = 0; rows.push(row); const m0 = row.m0, info = { fn, seed, f: fr, ph, g, pieces: m0.pieces, hsA: m0.hsA, ringX: m0.ringX, inv: m0.inv, eyeOut: m0.eyeOut, lost: +(100 * m0.lost / m0.Ar).toFixed(1) };
      if (m0.pieces.length > 1) F2PAIR.offer(m0.nr > 1 ? 'broken8' : 'brokenRound', m0.pieces[1], info, modes); if (m0.hsA > 0) F2PAIR.offer('hole', m0.hsA, info, modes); if (m0.eyeOut > 0) F2PAIR.offer('eye', m0.eyeOut + 3 * m0.eyeC, info, modes); if (m0.lost / m0.Ar > .03) F2PAIR.offer('lost', m0.lost / m0.Ar, info, modes);
      if (row.m9 && row.m9.As / Math.max(1, m0.As) > 1.08) F2PAIR.offer('fat', row.m9.As / m0.As - 1, info, modes);
      for (const md of modes) if (md) { const q = row['m' + md]; if (q.pieces.length > 1) F2PAIR.offer('still' + md, q.pieces[1], { ...info, pm: q.pieces }, modes); if (q.hsA > 0) F2PAIR.offer('hole' + md, q.hsA, { ...info, hm: q.hsA }, modes); } };
    GEST[fn](seed, step); out.push({ seed, frames: fr, rows }); for (const id of [...fingers.keys()]) F2.ev('pointerup', id, 0, 0); await new Promise(r => setTimeout(r, 0)); }
  return { out, caps: F2PAIR.caps }; };
0
