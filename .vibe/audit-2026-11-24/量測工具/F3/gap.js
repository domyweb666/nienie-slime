async (cfg) => {
  window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 120));
  const evl = []; sfxPlay = (k, g, r) => { evl.push([+t.toFixed(4), k, +(+g).toFixed(3)]); }; if (SFX) SFX.frame = () => {};
  const DT = 1 / 120;
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  WALK.noSave = true; IMPSV.noSave = true; VIEW.bg = 'day';
  const BASE = { ...PRESETS.clay, limbs: 0, tentSlip: 0, tentBump: 0, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, decoReal: 0, remeshCalm: 0 };
  const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65 + sd * 1000); mat = { ...BASE, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 9e9; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; for (let i = 0; i < 720; i++) update(DT); evl.length = 0; };
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const wld = (sx, sy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(sx - q.left - v.x) / CAM.z + CAM.x, (sy - q.top - v.y) / CAM.z + CAM.y]; };
  const out = []; fresh({}, 0);
  for (const job of cfg.jobs) {
    fresh({ ...(cfg.over || {}), ...(job.over || {}) }, job.sd || 0);
    const c = globalC; let wx = c.xc + (job.ox || 0) * R, wy = c.yc + (job.oy || 0) * R;
    if (job.edge) { const [ux, uy] = job.dir; let bi = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } } wx = X[bi] - ux * R * .3; wy = Y[bi] - uy * R * .3; }
    const [sx, sy] = scr(wx, wy); const t0 = t; ev('pointerdown', 1, sx, sy); const f = fingers.get(1); const rows = []; let ex = sx, ey = sy, go = 0;
    for (let k = 1; k <= job.n; k++) {
      let mv = false;
      if (k > job.wait && job.v && !(job.stop && go >= job.stop)) { const ds = job.v * DT; go += ds;
        if (job.circle) { const a = go / job.circle; ex = sx + job.circle * Math.sin(a); ey = sy + job.circle * (1 - Math.cos(a)); }
        else { ex = sx + job.dir[0] * go; ey = sy + job.dir[1] * go; }
        mv = true; ev('pointermove', 1, ex, ey); }
      update(DT);
      let raw = 0; if (f.mem.length && f.mode === 'grab') { let px = 0, py = 0, w = 0; for (const m of f.mem) { px += (X[m[0]] - m[1]) * m[3]; py += (Y[m[0]] - m[2]) * m[3]; w += m[3]; } raw = Math.hypot(px / w - f.x, py / w - f.y) / R; }
      rows.push([+(t - t0).toFixed(4), +ex.toFixed(2), +ey.toFixed(2), f.mode, +(f.stretch || 0).toFixed(4), +CAPGAP.toFixed(4), +raw.toFixed(4), +RATE.s.toFixed(3), +(f.still || 0)]);
    }
    const te = t - t0; ev('pointerup', 1, ex, ey);
    out.push({ name: job.name, R, rows, evl: evl.map(e => [+(e[0] - t0).toFixed(4), e[1], e[2]]), te });
  }
  return out;
}
