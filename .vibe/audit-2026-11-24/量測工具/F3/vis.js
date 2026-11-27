async (cfg) => {
  window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 120));
  sfxPlay = () => {}; if (SFX) SFX.frame = () => {};
  const DT = 1 / 120;
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  WALK.noSave = true; IMPSV.noSave = true; VIEW.bg = 'day';
  const BASE = { ...PRESETS[cfg.mat || 'clay'], limbs: 0, tentSlip: 0, tentBump: 0, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, life2: 0, brain: 0, emo: 0, decoReal: 0, life: 0, wriggle: 0, morph: 0, pods: 0, jelly: 0, drift: 0, wander: 0, remeshCalm: 0 };
  const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65 + sd * 1000); mat = { ...BASE, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 9e9; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; for (let i = 0; i < 720; i++) update(DT); };
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const snapB = () => bnd.map(i => scr(X[i], Y[i]));
  const out = []; fresh({}, 0); fresh({}, 0);
  for (const job of cfg.jobs) {
    const run = (touch) => {
      fresh(job.over || {}, job.sd || 0);
      const c = globalC; let wx = c.xc + (job.ox || 0) * R, wy = c.yc + (job.oy || 0) * R;
      if (job.edge) { const [ux, uy] = job.dir; let bi = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } } wx = X[bi] - ux * R * .3; wy = Y[bi] - uy * R * .3; }
      const [sx, sy] = scr(wx, wy); const fr = []; const b0 = snapB();
      let mem0 = null, p0 = null, f = null;
      if (touch) { ev('pointerdown', 1, sx, sy); f = fingers.get(1); }
      let ex = sx, ey = sy;
      for (let k = 1; k <= job.n; k++) {
        if (touch && job.v && k > job.wait) { ex = sx + job.dir[0] * job.v * DT * (k - job.wait); ey = sy + job.dir[1] * job.v * DT * (k - job.wait); ev('pointermove', 1, ex, ey); }
        update(DT);
        let patch = null;
        if (touch && f && f.mem.length) { let px = 0, py = 0, w = 0; const n0 = job._n0 || (job._n0 = f.mem.length); for (let q = 0; q < Math.min(n0, f.mem.length); q++) { const m = f.mem[q]; px += X[m[0]] * m[3]; py += Y[m[0]] * m[3]; w += m[3]; } px /= w; py /= w; if (!p0) p0 = null; patch = scr(px, py); }
        fr.push({ b: snapB(), ex, ey, patch, mode: f ? f.mode : null, st: f ? f.stretch : 0, fx: f ? scr(f.fx, f.fy) : null, dent: DENTS.length ? DENTS[0].d : 0, eye: (typeof EYE !== 'undefined' && EYE.lx != null) ? null : null, N });
      }
      job._n0 = null;
      return { fr, sx, sy, b0 };
    };
    const A = run(false), B = run(true); let drift = 0; for (let i = 0; i < A.b0.length; i++) drift = Math.max(drift, Math.hypot(A.b0[i][0] - A.fr[job.n - 1].b[i][0], A.b0[i][1] - A.fr[job.n - 1].b[i][1]));
    const rows = [];
    for (let k = 0; k < job.n; k++) {
      const a = B.b0, b = B.fr[k].b; let mx = 0, mv = 0, cnt = 0;
      if (a.length === b.length) for (let i = 0; i < a.length; i++) { const d = Math.hypot(a[i][0] - b[i][0], a[i][1] - b[i][1]); if (d > mx) mx = d; const df = Math.hypot(b[i][0] - B.fr[k].ex, b[i][1] - B.fr[k].ey); if (df > cfg.occ && d > mv) mv = d; if (d > 2) cnt++; }
      rows.push([+mx.toFixed(2), +mv.toFixed(2), +(cnt / a.length).toFixed(3), B.fr[k].patch ? [+B.fr[k].patch[0].toFixed(2), +B.fr[k].patch[1].toFixed(2)] : null, +B.fr[k].ex.toFixed(1), +B.fr[k].ey.toFixed(1), B.fr[k].mode, +B.fr[k].st.toFixed(3), +B.fr[k].dent.toFixed(3), B.fr[k].N]);
    }
    out.push({ name: job.name, drift: +drift.toFixed(3), R: +R.toFixed(1), sx: B.sx, sy: B.sy, rows });
  }
  return out;
}
