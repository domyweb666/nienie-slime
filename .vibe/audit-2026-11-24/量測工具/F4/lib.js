// F4 gesture probe: deterministic stepping, hook sounds and the pet's state
window.__f4 = (() => {
  window.requestAnimationFrame = () => 0;
  const DT = 1 / 60;
  let seedv = 12345;
  const rnd = () => { seedv = (seedv + 0x6D2B79F5) >>> 0; let z = seedv; z = Math.imul(z ^ (z >>> 15), z | 1); z ^= z + Math.imul(z ^ (z >>> 7), z | 61); return ((z ^ (z >>> 14)) >>> 0) / 4294967296; };
  Math.random = rnd;
  IMPSV.noSave = true; WALK.noSave = true;
  const log = []; let T0 = 0, cont = [], on = false, last = {};
  const rec = (k, ...a) => { if (on) log.push([+(t - T0).toFixed(3), k, ...a.map(x => typeof x === 'number' ? +x.toFixed(3) : x)]); };
  sfxPlay = (k, g = 1, r = 1) => { rec('snd:' + k, g, r); };
  if (SFX) {
    SFX.fx = (k, g, r, d) => rec('snd:fx.' + k, g, r || 1, d || 0);
    SFX.frame = (dt, st) => { if (on) cont.push([+(t - T0).toFixed(3), +st.rub.toFixed(3), +st.stretch.toFixed(3), st.grabbing ? 1 : 0]); };
  }
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  let px = null, py = null;
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const snap = () => { px = X.slice(0, N); py = Y.slice(0, N); };
  const maxd = () => { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(X[i] - px[i], Y[i] - py[i])); return m; };
  let eyeMin = 9;
  const st = () => {
    const now = { eye: EYE.mode, esc: ESC.on ? 1 : 0, slp: SLP.on ? 1 : 0, life: LIFE.st, gait: GAIT.on ? 1 : 0, purr: PURR > .3 ? 1 : 0, strain: MOOD.strain > .4 ? 1 : 0, tickle: (typeof tickOn === 'function' && tickOn()) ? 1 : 0, flinch: (FLN.amp > .02 && t - FLN.t0 >= 0 && t - FLN.t0 < .3) ? 1 : 0, cling: CLING.on ? 1 : 0, air: SILL.air ? 1 : 0, esq: t < EYE.sqU ? 1 : 0 };
    for (const k in now) if (last[k] !== now[k]) { if (last[k] !== undefined) rec('st:' + k, String(last[k]) + '>' + String(now[k])); last[k] = now[k]; }
  };
  const step = (n = 1) => { for (let i = 0; i < n; i++) { update(DT); st(); eyeMin = Math.min(eyeMin, EYE.openD); } };
  const settle = (sec = 14) => { for (let i = 0; i < sec * 60; i++) update(DT); st(); };
  const start = () => { on = true; T0 = t; log.length = 0; cont = []; last = {}; st(); snap(); eyeMin = 9; };
  const stop = () => { on = false; };
  return { DT, ev, step, settle, start, stop, log, scr, snap, maxd, get cont() { return cont }, rec, st, rnd, get eyeMin() { return eyeMin }, setSeed(s) { seedv = s }, get T0() { return T0 } };
})();
