async (cfg) => {
  window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 120));
  sfxPlay = () => {}; if (SFX) SFX.frame = () => {};
  const DT = 1 / 120;
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  WALK.noSave = true; IMPSV.noSave = true; VIEW.bg = 'day';
  const BASE = { ...PRESETS.clay, limbs: 0, tentSlip: 0, tentBump: 0, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, life2: 0, emo: 0, brain: 0, decoReal: 0, life: 0, wriggle: 0, morph: 0, pods: 0, jelly: 0, drift: 0, wander: 0 };
  const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65); mat = { ...BASE, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 9e9; for (let i = 0; i < 480; i++) update(DT); };
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const out = []; fresh({});
  for (const lag of [.22, 0]) { fresh({ lag });
    // 手指按在牠左邊空白處（距中心 1.6R），停 1 秒，再以 600 點/秒移到右邊
    const c = globalC, [x0, y0] = scr(c.xc - 1.6 * R, c.yc), [x1] = scr(c.xc + 1.6 * R, c.yc); ev('pointerdown', 1, x0, y0 - 1.2 * R); for (let i = 0; i < 120; i++) update(DT);
    const f = fingers.get(1), rows = []; let x = x0; for (let k = 0; k < 120; k++) { x = Math.min(x1, x + 600 * DT); ev('pointermove', 1, x, y0 - 1.2 * R); update(DT); rows.push([+(k * DT * 1000).toFixed(0), +x.toFixed(0), +EYE.gx.toFixed(3), f.mode]); }
    out.push({ lag, rows, reach: Math.round((x1 - x0) / 600 * 1000) }); ev('pointerup', 1, x, y0); }
  return out;
}
