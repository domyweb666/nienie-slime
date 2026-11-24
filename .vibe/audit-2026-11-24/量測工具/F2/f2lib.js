// 量皮用的工具（F2）。停掉 rAF，用固定 dt 1/60 推物理，每幀 draw() 之後立刻讀果凍皮那張 WebGL 畫布的 alpha
window.F2 = (() => {
  window.requestAnimationFrame = () => 0;
  const DT = 1 / 60;
  WALK.noSave = true; WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; IMPSV.noSave = true;
  try { sfxPlay = () => {}; } catch (e) {}
  const realRandom = Math.random;
  if (typeof SFX !== 'undefined' && SFX && SFX.frame && !SFX.__f2) { const f0 = SFX.frame; SFX.frame = (...a) => { const r = Math.random; Math.random = realRandom; try { return f0.apply(SFX, a); } finally { Math.random = r; } }; SFX.__f2 = 1; }
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const clampS = (x, y) => [Math.max(4, Math.min(innerWidth - 4, x)), Math.max(4, Math.min(innerHeight - 4, y))];
  function fresh(seed, over) {
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Math.random = seeded(seed);
    const s = SLIMES[SLIME];
    mat = { ...PRESETS[s.mat], seed: s.seed, ...s.p, ...viewOver(), intro: 0, introSwim: 0, ...(over || {}) };
    setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0;
    for (let i = 0; i < 90; i++) update(DT);
  }
  // 讀皮
  let W1 = W, H1 = H; const c2 = document.createElement('canvas'); c2.width = W1; c2.height = H1; const x2 = c2.getContext('2d', { willReadFrequently: true });
  const skin = new Uint8Array(W1 * H1), raw = new Uint8Array(W1 * H1);
  function readSkin() { x2.setTransform(1, 0, 0, 1, 0, 0); x2.clearRect(0, 0, W1, H1); x2.drawImage(JEL.c, 0, 0, W1, H1); const d = x2.getImageData(0, 0, W1, H1).data; for (let i = 0, j = 3; i < skin.length; i++, j += 4) skin[i] = d[j] > 127 ? 1 : 0; return skin; }
  function readRaw() { const d = JEL.m.getImageData(0, 0, W1, H1).data; for (let i = 0, j = 0; i < raw.length; i++, j += 4) raw[i] = d[j] > 127 ? 1 : 0; return raw; }
  // 連通塊：val=1 的塊數與各塊面積；val=0 的塊（不碰邊的＝洞）
  const lab = new Int32Array(W1 * H1), stack = new Int32Array(W1 * H1);
  function comps(m, val) { lab.fill(0); let n = 0; const out = []; const L = W1 * H1;
    for (let s = 0; s < L; s++) { if (m[s] !== val || lab[s]) continue; n++; let sp = 0, A = 0, edge = false, sx = 0, sy = 0; stack[sp++] = s; lab[s] = n;
      while (sp) { const p = stack[--sp]; A++; const x = p % W1, y = (p / W1) | 0; sx += x; sy += y; if (x === 0 || y === 0 || x === W1 - 1 || y === H1 - 1) edge = true;
        if (x > 0 && m[p - 1] === val && !lab[p - 1]) { lab[p - 1] = n; stack[sp++] = p - 1; } if (x < W1 - 1 && m[p + 1] === val && !lab[p + 1]) { lab[p + 1] = n; stack[sp++] = p + 1; }
        if (y > 0 && m[p - W1] === val && !lab[p - W1]) { lab[p - W1] = n; stack[sp++] = p - W1; } if (y < H1 - 1 && m[p + W1] === val && !lab[p + W1]) { lab[p + W1] = n; stack[sp++] = p + W1; } }
      out.push({ A, edge, x: sx / A, y: sy / A }); }
    return out; }
  const segInt = (ax, ay, bx, by, cx, cy, dx, dy) => { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; };
  function ringX(P) { const n = P.length; let c = 0; for (let i = 0; i < n; i++) { const a = P[i], b = P[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = P[j], q = P[(j + 1) % n]; if (segInt(a[0], a[1], b[0], b[1], p[0], p[1], q[0], q[1])) c++; } } return c; }
  function sharp(P) { const n = P.length; let m = 0, cnt = 0; for (let i = 0; i < n; i++) { const a = P[(i + n - 1) % n], b = P[i], c = P[(i + 1) % n], ux = b[0] - a[0], uy = b[1] - a[1], vx = c[0] - b[0], vy = c[1] - b[1], an = Math.abs(Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)) * 57.3; if (an > m) m = an; if (an > 75) cnt++; } return [m, cnt]; }
  const invN = () => { let n = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) n++; } return n; };
  // 一幀的量
  let prevSkin = null;
  function measure(o) { o = o || {}; draw(); readSkin(); readRaw(); const P = boundaryPts(); const r = {};
    const cs = comps(skin, 1).filter(c => c.A >= 6), cr = comps(raw, 1).filter(c => c.A >= 6), hs = comps(skin, 0).filter(c => !c.edge && c.A >= 4), hr = comps(raw, 0).filter(c => !c.edge && c.A >= 4);
    r.ns = cs.length; r.nr = cr.length; r.hs = hs.length; r.hr = hr.length; r.hsA = hs.reduce((a, c) => a + c.A, 0); r.hrA = hr.reduce((a, c) => a + c.A, 0);
    r.pieces = cs.map(c => c.A).sort((a, b) => b - a).slice(0, 4);
    let lost = 0, gain = 0, As = 0, Ar = 0; for (let i = 0; i < skin.length; i++) { if (skin[i]) As++; if (raw[i]) Ar++; if (raw[i] && !skin[i]) lost++; else if (skin[i] && !raw[i]) gain++; }
    r.As = As; r.Ar = Ar; r.lost = lost; r.gain = gain;
    let per = 0; for (let i = 0; i < P.length; i++) { const a = P[i], b = P[(i + 1) % P.length]; per += Math.hypot(a[0] - b[0], a[1] - b[1]); } r.per = per;
    if (prevSkin) { let x = 0; for (let i = 0; i < skin.length; i++) if (skin[i] !== prevSkin[i]) x++; r.dxor = x; r.disp = x / Math.max(1, per); }
    prevSkin = skin.slice();
    r.ringX = ringX(P); const sh = sharp(P); r.sharp = sh[0]; r.spk = sh[1]; r.inv = invN(); r.rem = REM.n; r.N = N; r.nb = bnd.length; r.cap = CAPG;
    // 眼睛：兩顆眼睛的橢圓邊 12 點，幾點不在皮裡
    if (EYE.pose) { const S = R * (mat.eyeSize || 1), js = .68, sxx = Math.max(.8, Math.min(1.3, Math.hypot(EYE.pose[2] - EYE.pose[0], EYE.pose[3] - EYE.pose[1]) / EYE.d0)), ew = S * .082 * js * Math.sqrt(sxx), eh = S * .118 * js; let out = 0, cOut = 0;
      const at = (x, y) => { const [sx, sy] = scr(x, y); const ix = Math.round(sx), iy = Math.round(sy); if (ix < 0 || iy < 0 || ix >= W1 || iy >= H1) return 0; return skin[iy * W1 + ix]; };
      for (const [ex, ey] of [[EYE.pose[0], EYE.pose[1]], [EYE.pose[2], EYE.pose[3]]]) { if (!at(ex, ey)) cOut++; for (let k = 0; k < 12; k++) { const a = k / 12 * Math.PI * 2; if (!at(ex + Math.cos(a) * ew, ey + Math.sin(a) * eh)) out++; } }
      r.eyeOut = out; r.eyeC = cOut; }
    return r; }
  const edgePt = (ux, uy) => { const c = globalC; let bi = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } } return bi; };
  return { DT, seeded, ev, scr, clampS, fresh, readSkin, readRaw, comps, measure, ringX, sharp, invN, edgePt, get skin() { return skin; }, get raw() { return raw; }, resetPrev() { prevSkin = null; }, W1, H1, c2 };
})();
;0
