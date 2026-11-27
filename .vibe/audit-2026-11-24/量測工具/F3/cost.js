async (cfg) => {
  window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 120));
  sfxPlay = () => {}; if (SFX) SFX.frame = () => {};
  const DT = 1 / 120;
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  WALK.noSave = true; IMPSV.noSave = true; VIEW.bg = 'day';
  const BASE = { ...PRESETS.clay, limbs: 0, tentSlip: 0, tentBump: 0, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0 };
  const fresh = () => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65); mat = { ...BASE }; setup(); t = 0; lastTouch = -10; for (let i = 0; i < 480; i++) update(DT); };
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const out = []; fresh(); fresh();
  const time = n => { const a = []; for (let i = 0; i < n; i++) { const p = performance.now(); update(DT); a.push(performance.now() - p); } a.sort((x, y) => x - y); return [+(a.reduce((s, x) => s + x, 0) / n).toFixed(3), +a[Math.floor(n * .95)].toFixed(3)]; };
  out.push(['靜止', N, ...time(240)]);
  const c = globalC; let bi = 0, bd = 1e9; for (const i of bnd) { if (Y[i] < bd) { bd = Y[i]; bi = i; } }
  const [sx, sy] = scr(X[bi], Y[bi] + R * .3); ev('pointerdown', 1, sx, sy);
  out.push(['按住', N, ...time(120)]);
  let ey = sy; const target = [2, 4];
  let go = 0; for (const tg of [1, 2, 3, 4]) { while (go < tg * R) { go += 300 * DT; ey = sy - go; ev('pointermove', 1, sx, Math.max(6, ey)); update(DT); } const a = time(60); out.push(['拉 ' + tg + 'R 停住', N, ...a, +(([...fingers.values()][0] || {}).stretch || 0).toFixed(2)]); }
  ev('pointerup', 1, sx, ey);
  out.push(['放手後', N, ...time(120)]);
  return out;
}
