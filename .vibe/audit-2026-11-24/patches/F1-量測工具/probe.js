/* F1 破皮量測：注入到真正的頁面（?all=1 或預設），不改任何專案檔。 */
(() => {
  const PB = window.PB = {}; const DT = 1 / 60;
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const clampS = (x, y) => [Math.max(4, Math.min(W - 4, x)), Math.max(4, Math.min(H - 4, y))];
  PB.scr = scr; PB.ev = ev;
  PB.init = async () => {
    window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 150));
    PB.real = Math.random;
    if (typeof SFX !== 'undefined' && SFX && SFX.frame) { const f0 = SFX.frame; SFX.frame = (...a) => { const r = Math.random; Math.random = PB.real; try { return f0.apply(SFX, a); } finally { Math.random = r; } }; }
    try { sfxPlay = () => {}; } catch (e) {}
    WALK.noSave = true; WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; IMPSV.noSave = true;
    PB.MAT0 = { ...mat }; draw();
    return { N, nb: bnd.length, R, h, W, H, SLIME, name: SLIMES[SLIME].name, curMat, bg: VIEW.bg, skin: VIEW.skin, fail: JEL.fail, float: JEL.float };
  };
  PB.slime = i => { if (i !== SLIME) { chooseSlime(i, false, false); } PB.MAT0 = { ...mat }; return SLIMES[SLIME].name; };
  PB.over = null;
  const FG = new Map();   // 真的手指（螢幕）
  PB.fresh = (seed, x0) => {
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FG.clear();
    Math.random = seeded(seed); mat = { ...PB.MAT0, ...(PB.over || {}) };
    setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0;
    if (x0 != null) { const dx = x0 - CX; for (let i = 0; i < N; i++) { X[i] += dx; PX[i] += dx; } HOMEX += dx; }
    for (let i = 0; i < 120; i++) update(DT);
    VIS.prev = null; VIS.disp = 0;
  };
  /* ---------- 物理量測 ---------- */
  const segInt = (ax, ay, bx, by, cx, cy, dx, dy) => { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; };
  function crossN(P) { const n = P.length; let c = 0; for (let i = 0; i < n; i++) { const a = P[i], b = P[(i + 1) % n], x0 = Math.min(a[0], b[0]), x1 = Math.max(a[0], b[0]), y0 = Math.min(a[1], b[1]), y1 = Math.max(a[1], b[1]); for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = P[j], q = P[(j + 1) % n]; if (Math.max(p[0], q[0]) < x0 || Math.min(p[0], q[0]) > x1 || Math.max(p[1], q[1]) < y0 || Math.min(p[1], q[1]) > y1) continue; if (segInt(a[0], a[1], b[0], b[1], p[0], p[1], q[0], q[1])) c++; } } return c; }
  function flips(AX, AY) { const T = TRI; let n = 0; for (let k = 0, m = T.length; k < m; k += 3) { const a = T[k], b = T[k + 1], c = T[k + 2]; if (.5 * ((AX[b] - AX[a]) * (AY[c] - AY[a]) - (AY[b] - AY[a]) * (AX[c] - AX[a])) < -.02 * TRA[k / 3]) n++; } return n; }
  // 內角 < 30 度（相鄰兩段轉超過 150 度）的個數；最小內角
  function sharp(P) { const n = P.length; let mn = 180, c = 0; for (let i = 0; i < n; i++) { const a = P[(i + n - 1) % n], b = P[i], d = P[(i + 1) % n], ux = b[0] - a[0], uy = b[1] - a[1], vx = d[0] - b[0], vy = d[1] - b[1], an = 180 - Math.abs(Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)) * 57.2958; if (an < mn) mn = an; if (an < 30) c++; } return [mn, c]; }
  function pip(P, x, y) { let c = false; const n = P.length; for (let i = 0, j = n - 1; i < n; j = i++) { const ax = P[i][0], ay = P[i][1], bx = P[j][0], by = P[j][1]; if ((ay > y) !== (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax) c = !c; } return c; }
  // 最細的脖子（R）：外框上兩點離很近、沿外框離很遠、兩邊都還有 0.5% 以上的面積、中點在身體裡
  function neck(P) { const n = P.length, s = new Float64Array(n + 1), c = new Float64Array(n + 1); for (let k = 0; k < n; k++) { const a = P[k], b = P[(k + 1) % n]; s[k + 1] = s[k] + Math.hypot(b[0] - a[0], b[1] - a[1]); c[k + 1] = c[k] + a[0] * b[1] - b[0] * a[1]; } const per = s[n], A = c[n] / 2; let best = .25 * R, at = null;
    for (let i = 0; i < n; i++) for (let j = i + 3; j < n; j++) { const la = s[j] - s[i], mn = Math.min(la, per - la); if (mn < .3 * R) continue; const dx = P[j][0] - P[i][0], dy = P[j][1] - P[i][1], d = Math.hypot(dx, dy); if (d >= best || d > mn * .4) continue; const a1 = (c[j] - c[i] + P[j][0] * P[i][1] - P[i][0] * P[j][1]) / 2, fr = Math.min(Math.abs(a1), Math.abs(A - a1)) / Math.abs(A); if (fr < .005) continue; const mx = (P[i][0] + P[j][0]) / 2, my = (P[i][1] + P[j][1]) / 2; if (!pip(P, mx, my)) continue; best = d; at = [mx, my, fr]; }
    return at ? [best / R, at[0], at[1], at[2]] : [.25, 0, 0, 0]; }
  /* ---------- 畫出來的身體 ---------- */
  const VIS = { w: 0, h: 0, buf: null, m: null, prev: null, disp: 0, lab: null, st: null, dt: null };
  PB.VIS = VIS;
  function grabMask() { draw(); const gl = JEL.gl, w = JEL.h2.w, hh = JEL.h2.h; if (VIS.w !== w || VIS.h !== hh) { VIS.w = w; VIS.h = hh; VIS.buf = new Float32Array(w * hh * 4); VIS.lab = new Int32Array(w * hh); VIS.st = new Int32Array(w * hh); }
    gl.bindFramebuffer(gl.FRAMEBUFFER, JEL.h2.f); gl.readPixels(0, 0, w, hh, gl.RGBA, gl.FLOAT, VIS.buf); gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    const m = new Uint8Array(w * hh), B = new Float32Array(w * hh), rn = mat.round > 0 && !LAB.off.round; for (let y = 0; y < hh; y++) for (let x = 0; x < w; x++) { const v = VIS.buf[((hh - 1 - y) * w + x) * 4]; B[y * w + x] = v; m[y * w + x] = v > .46 ? 1 : 0; }
    if (!rn) { const r = rawMask(boundaryPts()); m.set(r); }
    VIS.B = B; return m; }
  // 用外框填色（nonzero，跟畫布 fill 一樣），半解析度
  function rawMask(P) { const w = VIS.w, hh = VIS.h, m = new Uint8Array(w * hh), sx = w / W, sy = hh / H, Q = [];
    { const n = P.length; for (let i = 0; i < n; i++) { const p0 = P[(i + n - 1) % n], p1 = P[i], p2 = P[(i + 1) % n], p3 = P[(i + 2) % n]; for (let s = 0; s < 4; s++) { const u = s / 4, mu = 1 - u, c1x = p1[0] + (p2[0] - p0[0]) / 6, c1y = p1[1] + (p2[1] - p0[1]) / 6, c2x = p2[0] - (p3[0] - p1[0]) / 6, c2y = p2[1] - (p3[1] - p1[1]) / 6, b0 = mu * mu * mu, b1 = 3 * mu * mu * u, b2 = 3 * mu * u * u, b3 = u * u * u, q = scr(b0 * p1[0] + b1 * c1x + b2 * c2x + b3 * p2[0], b0 * p1[1] + b1 * c1y + b2 * c2y + b3 * p2[1]); Q.push(q[0] * sx, q[1] * sy); } } }
    const n = Q.length / 2; for (let y = 0; y < hh; y++) { const yc = y + .5, xs = []; for (let i = 0; i < n; i++) { const j = (i + 1) % n, ay = Q[2 * i + 1], by = Q[2 * j + 1]; if ((ay > yc) === (by > yc)) continue; const f = (yc - ay) / (by - ay); xs.push([Q[2 * i] + (Q[2 * j] - Q[2 * i]) * f, by > ay ? 1 : -1]); } if (!xs.length) continue; xs.sort((a, b) => a[0] - b[0]); let wn = 0; for (let k = 0; k < xs.length - 1; k++) { wn += xs[k][1]; if (wn === 0) continue; const x0 = Math.max(0, Math.ceil(xs[k][0] - .5)), x1 = Math.min(w - 1, Math.floor(xs[k + 1][0] - .5)); for (let x = x0; x <= x1; x++) m[y * w + x] = 1; } }
    return m; }
  // 連通元件（前景 8 連通、背景 4 連通）
  function comps(m) { const w = VIS.w, hh = VIS.h, lab = VIS.lab, st = VIS.st; lab.fill(0); const px2 = (W / w) * (H / hh) / (R * R), out = [], holes = []; let id = 0;
    for (let s = 0; s < m.length; s++) { if (!m[s] || lab[s]) continue; id++; let top = 0, c = 0, sx = 0, sy = 0, eb = 0; st[top++] = s; lab[s] = id; while (top) { const p = st[--top], x = p % w, y = (p / w) | 0; c++; sx += x; sy += y; if (x === 0 || y === 0 || x === w - 1 || y === hh - 1) eb = 1; for (let oy = -1; oy <= 1; oy++) for (let ox = -1; ox <= 1; ox++) { if (!ox && !oy) continue; const X1 = x + ox, Y1 = y + oy; if (X1 < 0 || Y1 < 0 || X1 >= w || Y1 >= hh) continue; const q = Y1 * w + X1; if (m[q] && !lab[q]) { lab[q] = id; st[top++] = q; } } } out.push({ a: c * px2, x: sx / c, y: sy / c, id, eb }); }
    let hid = -1; for (let s = 0; s < m.length; s++) { if (m[s] || lab[s]) continue; let top = 0, c = 0, sx = 0, sy = 0, edge = false; st[top++] = s; lab[s] = hid; while (top) { const p = st[--top], x = p % w, y = (p / w) | 0; c++; sx += x; sy += y; if (x === 0 || y === 0 || x === w - 1 || y === hh - 1) edge = true; if (x > 0 && !m[p - 1] && !lab[p - 1]) { lab[p - 1] = hid; st[top++] = p - 1; } if (x < w - 1 && !m[p + 1] && !lab[p + 1]) { lab[p + 1] = hid; st[top++] = p + 1; } if (y > 0 && !m[p - w] && !lab[p - w]) { lab[p - w] = hid; st[top++] = p - w; } if (y < hh - 1 && !m[p + w] && !lab[p + w]) { lab[p + w] = hid; st[top++] = p + w; } } if (!edge) holes.push({ a: c * px2, x: sx / c, y: sy / c, id: hid }); hid--; }
    out.sort((a, b) => b.a - a.a); holes.sort((a, b) => b.a - a.a); return { out, holes }; }
  // 距離變換（到前景的距離，半解析度格）
  function dist(m) { const w = VIS.w, hh = VIS.h, d = new Float32Array(w * hh); for (let i = 0; i < d.length; i++) d[i] = m[i] ? 0 : 1e6; const D = 1.4142; for (let y = 0; y < hh; y++) for (let x = 0; x < w; x++) { const i = y * w + x; let v = d[i]; if (v === 0) continue; if (x > 0) v = Math.min(v, d[i - 1] + 1); if (y > 0) { v = Math.min(v, d[i - w] + 1); if (x > 0) v = Math.min(v, d[i - w - 1] + D); if (x < w - 1) v = Math.min(v, d[i - w + 1] + D); } d[i] = v; }
    for (let y = hh - 1; y >= 0; y--) for (let x = w - 1; x >= 0; x--) { const i = y * w + x; let v = d[i]; if (v === 0) continue; if (x < w - 1) v = Math.min(v, d[i + 1] + 1); if (y < hh - 1) { v = Math.min(v, d[i + w] + 1); if (x < w - 1) v = Math.min(v, d[i + w + 1] + D); if (x > 0) v = Math.min(v, d[i + w - 1] + D); } d[i] = v; } return d; }
  PB.CMIN = .004; PB.HMIN = .002; PB.POP = .12;
  /* ---------- 一格 ---------- */
  let xrun = 0, eyeP = null, M = null, ph = '', frame = 0, vx = null, vy = null, still = 0, prevR = -1, lastMax = 0, jl = [];
  const blank = () => ({ fr: 0, xMax: 0, xFr: 0, xdMax: 0, xdFr: 0, flMax: 0, flFr: 0, qfMax: 0, shMin: 180, shN: 0, shFr: 0, neck: .25, neckFr: 0, neckAt: 0, jSum: 0, jN: 0, jMax: 0, lagMax: 0, lagEnd: 0, gapMax: 0, gapEnd: 0, nan: 0, msSum: 0, msMax: 0, remN: 0, remMs: 0, vN: 0, cMax: 1, cFr: 0, hMax: 0, hFr: 0, popMax: 0, popN: 0, eyeFr: 0, erMax: 0, erFr: 0, rawC: 0, rawH: 0, len: 0, len0: 0, len1: 0, off: 0, offFr: 0, vmax: 0, xRun: 0, xEnd: 0, flEnd: 0, shEnd: 0, nkEnd: .25, cEnd: 1, eyeJ: 0, eyeJN: 0, offC: 0, va: 9, vaAt: 0, alt3: 0, alt2: 0, alt1: 0, altH2: 0, flick: 0, flickN: 0, str: 0 });
  PB.begin = (id, label, seed, info) => { M = { id, label, seed, info: info || null, ph: {}, ev: [], snaps: {}, jl: null, rem: [] }; frame = 0; vx = vy = null; still = 0; prevR = REM.n; lastMax = 0; jl = []; xrun = 0; eyeP = null; prevR2 = REM.n; lastRem = -99; VIS.prev = null; VIS.disp = 0; EVT.cur = null; };
  const EVT = { cur: null };
  function shot(type, sev, text, over) { const o = M.snaps[type]; if (o && o.sev >= sev * .8) return; const k = document.createElement('canvas'); k.width = 393; k.height = 852; const c = k.getContext('2d'); c.drawImage(cv, 0, 0, 393, 852);
    if (over && over.prev) { const w = VIS.w, hh = VIS.h, m = over.prev; c.fillStyle = 'rgba(255,0,0,.9)'; for (let y = 1; y < hh - 1; y++) for (let x = 1; x < w - 1; x++) { const i = y * w + x; if (m[i] && (!m[i - 1] || !m[i + 1] || !m[i - w] || !m[i + w])) c.fillRect(x * W / w, y * H / hh, 1.4, 1.4); } }
    for (const f of FG.values()) { c.beginPath(); c.arc(f.x, f.y, 17, 0, 6.283); c.lineWidth = 2.5; c.strokeStyle = 'rgba(20,20,20,.85)'; c.stroke(); }
    M.snaps[type] = { sev, text, fr: frame, ph, img: k.toDataURL('image/jpeg', .82) }; }
  PB.snapOn = true;
  function vis() {
    const P = boundaryPts(), m = grabMask(), q = M.ph[ph]; q.vN++;
    const { out, holes } = comps(m), big0 = out.filter(o => o.a >= PB.CMIN), hb = holes.filter(o => o.a >= PB.HMIN); let big = big0, eb1 = null; { big = []; for (const o of big0) { if (o.eb) { if (!eb1) { eb1 = o; big.push(o); } } else big.push(o); } } if (big0.length > 1 && big.length < 2) q.offC++; q.cEnd = big.length;
    const raw = rawMask(P); let er = 0; const dm = dist(m); for (let i = 0; i < raw.length; i++) if (raw[i] && dm[i] > 3) er++; er *= (W / VIS.w) * (H / VIS.h) / (R * R);
    if (big0.length > 1 || hb.length || PB.altAll) { const cnt = th => { const mm = new Uint8Array(m.length); for (let i = 0; i < m.length; i++) mm[i] = m[i] || (raw[i] && VIS.B[i] > th) ? 1 : 0; const c2 = comps(mm); let e1 = 0, n = 0; for (const o of c2.out) { if (o.a < PB.CMIN) continue; if (o.eb) { if (!e1) { e1 = 1; n++; } } else n++; } return [n, c2.holes.filter(o => o.a >= PB.HMIN).length]; }; const a3 = cnt(.3), a2 = cnt(.2), a1 = cnt(.1); if (a3[0] > 1) q.alt3++; if (a2[0] > 1) q.alt2++; if (a1[0] > 1) q.alt1++; if (a2[1]) q.altH2++; }
    { let va = 0; for (const o of out) va += o.a; if (va < q.va) { q.va = va; q.vaAt = frame; if (va < 1 && PB.snapOn) shot('gone', 10 - va, '畫面上只剩 ' + va.toFixed(2) + 'R²(平常2.9)', { prev: VIS.prev }); } }
    if (er > q.erMax) q.erMax = er; if (er > .01) q.erFr++;
    // 突變：跟上一次讀（2 格前）比
    let pop = 0, pd = 0, pl = 0; if (VIS.prev) { const dp = dist(VIS.prev), pm = VIS.prev; let xo = 0, cont = 0; const w = VIS.w; for (let i = 0; i < m.length; i++) { if (m[i] !== pm[i]) { xo++; if (pm[i]) { if (dm[i] > pl) pl = dm[i]; } else if (dp[i] > pd) pd = dp[i]; } if (m[i] && (!m[i - 1] || !m[i + 1] || !m[i - w] || !m[i + w])) cont++; } const jump = Math.max(pd, pl) * 2; pop = (jump - VIS.disp - 4) / R; if (still > 40 && ph === 'hold') { q.flick += xo * 2 / Math.max(1, cont); q.flickN++; } }
    if (pop > q.popMax) q.popMax = pop;
    if (big.length > q.cMax) q.cMax = big.length; if (hb.length > q.hMax) q.hMax = hb.length;
    let type = null, sev = 0, txt = '';
    if (big.length > 1) { q.cFr++; type = 'split'; sev = big[1].a; txt = '裂成' + big.length + '塊(第二塊' + big[1].a.toFixed(2) + 'R²)'; }
    if (hb.length) { q.hFr++; if (!type) { type = 'hole'; sev = hb[0].a; txt = '破洞' + hb.length + '個(' + hb[0].a.toFixed(3) + 'R²)'; } else if (PB.snapOn) shot('hole', hb[0].a, '破洞(' + hb[0].a.toFixed(3) + 'R²)'); }
    if (pop > PB.POP) { q.popN++; if (PB.snapOn) shot('pop', pop, '一格突變 ' + pop.toFixed(2) + 'R', { prev: VIS.prev }); M.ev.push({ ty: 'pop', fr: frame, ph, v: +pop.toFixed(2), rem: REM.n !== prevR2 || frame - lastRem <= 2 ? 1 : 0, how: pl > pd ? 'lost' : 'new' }); if (M.ev.length > 60) M.ev.length = 60; }
    let rc = null; if (type) { rc = comps(raw); const rb = rc.out.filter(o => o.a >= PB.CMIN).length, rh = rc.holes.filter(o => o.a >= PB.HMIN).length; q.rawC = Math.max(q.rawC, rb); q.rawH = Math.max(q.rawH, rh);
      if (PB.snapOn) shot(type, sev, txt);
      const e = EVT.cur; if (e && e.ty === type && frame - e.f1 <= 4) { e.f1 = frame; if (sev > e.sev) { e.sev = +sev.toFixed(3); e.rb = rb; e.rh = rh; e.nk = lastNeck; e.x = lastX; e.fl = lastFl; e.er = +er.toFixed(3); e.len = lastLen; } } else { EVT.cur = { ty: type, ph, f0: frame, f1: frame, sev: +sev.toFixed(3), rb, rh, nk: lastNeck, x: lastX, fl: lastFl, er: +er.toFixed(3), len: lastLen }; M.ev.push(EVT.cur); if (M.ev.length > 60) M.ev.length = 60; } }
    // 眼睛在不在畫出來的身體上
    if (EYE.pose) { let off = 0; for (const [ex, ey] of [[EYE.pose[0], EYE.pose[1]], [EYE.pose[2], EYE.pose[3]]]) { const s = scr(ex, ey), gx = Math.round(s[0] * VIS.w / W), gy = Math.round(s[1] * VIS.h / H); if (gx < 0 || gy < 0 || gx >= VIS.w || gy >= VIS.h || !m[gy * VIS.w + gx]) off++; } if (off) q.eyeFr++; }
    // 看得到的身體離手指多遠
    let gap = 0; for (const f of FG.values()) { const gx = Math.max(0, Math.min(VIS.w - 1, Math.round(f.x * VIS.w / W))), gy = Math.max(0, Math.min(VIS.h - 1, Math.round(f.y * VIS.h / H))); gap = Math.max(gap, dm[gy * VIS.w + gx] * 2 / R); } if (gap > q.gapMax) q.gapMax = gap; q.gapEnd = gap;
    VIS.prev = m; VIS.disp = 0; prevR2 = REM.n; VIS.last = { out, holes, er, pop };
  }
  let lastNeck = .25, lastX = 0, lastFl = 0, lastLen = 0, prevR2 = 0, lastRem = -99, lastQ = 1, remPend = null; PB.deep = true;
  PB.step = (phase, readVis) => {
    ph = phase; const q = M.ph[ph] || (M.ph[ph] = blank()); const n0 = N, x0 = Float64Array.from(X), y0 = Float64Array.from(Y), r0 = REM.n, rl0 = REM.last;
    const p0 = performance.now(); update(DT); const ms = performance.now() - p0; q.fr++; frame++; q.msSum += ms; if (ms > q.msMax) q.msMax = ms;
    const rem = N !== n0 || REM.n !== r0 || REM.last !== rl0; if (rem) { q.remN++; if (REM.ms > q.remMs) q.remMs = REM.ms; lastRem = frame; M.rem.push([frame, ph, n0, N, r0, REM.n, +REM.ms.toFixed(1), lastFl, lastX, +lastQ.toFixed(1)]); remPend = M.rem[M.rem.length - 1]; }
    let bad = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bad++; if (bad) q.nan += bad;
    const P = bnd.map(i => [X[i], Y[i]]), D = boundaryPts(), xr = crossN(P), xd = xr ? crossN(D) : 0, fl = flips(X, Y), qf = flips(QX, QY); if (xr) q.xFr++; if (xr > q.xMax) q.xMax = xr; if (xd) q.xdFr++; if (xd > q.xdMax) q.xdMax = xd; if (fl) q.flFr++; if (fl > q.flMax) q.flMax = fl; if (qf > q.qfMax) q.qfMax = qf;
    const sh = sharp(P); if (sh[0] < q.shMin) q.shMin = sh[0]; if (sh[1]) q.shFr++; if (sh[1] > q.shN) q.shN = sh[1];
    const nk = neck(D); if (nk[0] < q.neck) { q.neck = nk[0]; q.neckAt = frame; } if (nk[0] < .1) q.neckFr++; if (remPend) { remPend.push(fl, xr, +QSTR.toFixed(1)); remPend = null; } lastNeck = +nk[0].toFixed(3); lastX = xr; lastFl = fl; lastQ = QSTR;
    { let a = 1e9, b = -1e9, c = 1e9, d = -1e9; for (const p of P) { a = Math.min(a, p[0]); b = Math.max(b, p[0]); c = Math.min(c, p[1]); d = Math.max(d, p[1]); } lastLen = +(Math.hypot(b - a, d - c) / R).toFixed(2); if (lastLen > q.len) q.len = lastLen; }
    if (q.fr === 30) q.len0 = lastLen; q.len1 = lastLen; { let o = 0; for (let i = 0; i < N; i++) { const s = X[i], u = Y[i]; if (s < -2 || s > W + 2 || u < -2 || u > H + 2) o++; } o /= N; if (o > q.off) q.off = o; if (o > .3) q.offFr++; }
    xrun = xr ? xrun + 1 : 0; if (xrun > q.xRun) q.xRun = xrun; q.xEnd = xr; q.flEnd = fl; q.shEnd = sh[1]; q.nkEnd = nk[0];
    // 跳動：扣掉整團平移後，每顆速度一格變多少（點）
    if (rem || N !== n0) { vx = vy = null; VIS.disp += lastMax; } else { let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N; const nx = new Float64Array(N), ny = new Float64Array(N); let j = 0, dmx = 0; for (let i = 0; i < N; i++) { nx[i] = X[i] - x0[i] - ax; ny[i] = Y[i] - y0[i] - ay; if (vx) { const d = Math.hypot(nx[i] - vx[i], ny[i] - vy[i]); if (d > j) j = d; } } for (const i of bnd) { const d = Math.hypot(X[i] - x0[i], Y[i] - y0[i]); if (d > dmx) dmx = d; } VIS.disp += dmx * CAM.z; lastMax = dmx * CAM.z; { const v = dmx * 60 / R; if (v > q.vmax) q.vmax = v; } if (EYE.pose && eyeP) { const ej = (Math.hypot(EYE.pose[0] + EYE.pose[2] - eyeP[0], EYE.pose[1] + EYE.pose[3] - eyeP[1]) / 2 - dmx) / R; if (ej > q.eyeJ) q.eyeJ = ej; if (ej > .1) q.eyeJN++; }
      if (ph === 'hold') { still++; if (still > 40) { q.jSum += j; q.jN++; if (j > q.jMax) q.jMax = j; } } else if (ph === 'rel') { jl.push(vx ? +j.toFixed(2) : -1); still = 0; } else still = 0;
      vx = nx; vy = ny; }
    eyeP = EYE.pose ? [EYE.pose[0] + EYE.pose[2], EYE.pose[1] + EYE.pose[3]] : null;
    if (rem && ph === 'rel') jl.push(-2);
    // 被抓那塊落後手指多少
    let lag = 0; for (const [id, g] of FG) { const f = fingers.get(id); if (!f || f.mode !== 'grab' || !f.mem.length) continue; let sx = 0, sy = 0, sw = 0; for (const mm of f.mem) { const w = mm[3]; sx += (X[mm[0]] - mm[1]) * w; sy += (Y[mm[0]] - mm[2]) * w; sw += w; } if (sw > 0) { const d = Math.hypot(sx / sw - f.x, sy / sw - f.y) / R; if (d > lag) lag = d; } } if (lag > q.lagMax) q.lagMax = lag; q.lagEnd = lag; q.str = Math.max(q.str, QSTR);
    if (PB.deep && frame % 2 === 0) vis();
    if (PB.trace) PB.trace.push({ fr: frame, ph, N, nb: bnd.length, rem: rem ? 1 : 0, x: xr, fl, qf, sh: +sh[0].toFixed(0), nk: +nk[0].toFixed(3), lag: +lag.toFixed(2), j: jl.length && ph === 'rel' ? jl[jl.length - 1] : null, len: lastLen, q: +QSTR.toFixed(2), cap: +CAPG.toFixed(2), c: VIS.last ? VIS.last.out.filter(o => o.a >= PB.CMIN).length : 0, ho: VIS.last ? VIS.last.holes.filter(o => o.a >= PB.HMIN).length : 0, er: VIS.last ? +VIS.last.er.toFixed(3) : 0, pop: VIS.last ? +VIS.last.pop.toFixed(2) : 0, ms: +ms.toFixed(1) });
    return rem;
  };
  const down = (id, x, y) => { FG.set(id, { x, y }); ev('pointerdown', id, x, y); };
  const move = (id, x, y) => { const [a, b] = clampS(x, y); FG.set(id, { x: a, y: b }); ev('pointermove', id, a, b); return [a, b]; };
  const up = id => { const f = FG.get(id); ev('pointerup', id, f ? f.x : 0, f ? f.y : 0); FG.delete(id); };
  const nstep = (phase, n) => { for (let i = 0; i < n; i++) PB.step(phase); };
  PB.lowlevel = { down, move, up, nstep };
  const rel = () => { const r = { settle: 0, j34: 0, j34max: 0, jmax: 0, over1: 0 }; let last = -1; for (let i = 0; i < jl.length; i++) if (jl[i] > 1) { last = i; r.over1++; } r.settle = last < 0 ? 0 : +((last + 1) / 60).toFixed(2); const tail = jl.slice(-60).filter(v => v >= 0); r.j34 = tail.length ? +(tail.reduce((a, b) => a + b, 0) / tail.length).toFixed(2) : 0; r.j34max = tail.length ? Math.max(...tail) : 0; r.jmax = Math.max(0, ...jl.filter(v => v >= 0)); return r; };
  PB.end = () => { M.rel = rel(); M.N = N; for (const id of [...FG.keys()]) up(id); for (const k in M.ph) { const q = M.ph[k]; for (const f in q) if (typeof q[f] === 'number') q[f] = +q[f].toFixed(3); } return M; };
  /* ---------- 抓點 ---------- */
  const tipAt = (ux, uy, depth) => { const c = globalC; let bi = bnd[0], bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } } return scr(X[bi] - ux * R * depth, Y[bi] - uy * R * depth); };
  const DIRS = { U: [0, -1], D: [0, 1], L: [-1, 0], R: [1, 0], UR: [.7071, -.7071], UL: [-.7071, -.7071], DR: [.7071, .7071] };
  PB.DIRS = DIRS;
  const toEdge = (sx, sy, ux, uy) => { let k = 1e9; if (ux > 1e-6) k = Math.min(k, (W - 4 - sx) / ux); if (ux < -1e-6) k = Math.min(k, (4 - sx) / ux); if (uy > 1e-6) k = Math.min(k, (H - 4 - sy) / uy); if (uy < -1e-6) k = Math.min(k, (4 - sy) / uy); return k; };
  const pullTo = (id, sx, sy, ux, uy, distPx, speedR) => { const n = Math.max(2, Math.ceil(distPx / R / speedR * 60)); let e = [sx, sy]; for (let s = 1; s <= n; s++) { e = move(id, sx + ux * distPx * s / n, sy + uy * distPx * s / n); PB.step('pull'); } return e; };
  /* ---------- 手勢 ---------- */
  PB.G = {
    pull(c) { const [ux, uy] = DIRS[c.dir], rnd = seeded(c.seed * 7919 + 13), g = SILL.g; const x0 = c.x0 === 'o' ? (ux < 0 ? g.r - R * 1.05 : g.l + R * 1.05) : null; PB.fresh(c.seed, x0);
      const jt = () => (rnd() - .5) * R * .16; let sx, sy;
      if (c.grab === 'center') { [sx, sy] = scr(globalC.xc, globalC.yc); sx += jt(); sy += jt(); }
      else if (c.grab === 'near') { [sx, sy] = tipAt(ux, uy, .15); sx += -uy * jt(); sy += ux * jt(); }
      else if (c.grab === 'far') { [sx, sy] = tipAt(-ux, -uy, .15); sx += -uy * jt(); sy += ux * jt(); }
      let vx1 = ux, vy1 = uy;
      if (c.grab === 'regrab') { [sx, sy] = tipAt(ux, uy, .15); down(1, sx, sy); nstep('pre', 4); const n = 38, d0 = Math.min(2.5 * R, toEdge(sx, sy, ux, uy)); let e = [sx, sy]; for (let s = 1; s <= n; s++) { e = move(1, sx + ux * d0 * s / n, sy + uy * d0 * s / n); PB.step('pre'); } nstep('pre', 12); up(1); nstep('pre', 24); [sx, sy] = tipAt(ux, uy, .2); const k = c.rep % 3; if (k === 1) { vx1 = -uy; vy1 = ux; } else if (k === 2) { vx1 = uy; vy1 = -ux; } }
      const te = toEdge(sx, sy, vx1, vy1); if (c.dist !== 'edge' && c.dist * R >= te - 1) { M.info = { skip: 1, lim: +(te / R).toFixed(2) }; return; } const dpx = c.dist === 'edge' ? te : Math.min(c.dist * R, te); M.info = { eff: +(dpx / R).toFixed(2), lim: +(te / R).toFixed(2) };
      down(1, sx, sy); nstep('pull', 4); pullTo(1, sx, sy, vx1, vy1, dpx, c.sp === 'fast' ? 25 : 4); nstep('hold', 180); up(1); nstep('rel', 240); },
    // 兩指往反方向
    opp(c) { PB.fresh(c.seed); const a = c.ang * Math.PI / 180, ux = Math.cos(a), uy = Math.sin(a), [cx, cy] = scr(globalC.xc, globalC.yc), o = c.from === 'edge' ? .75 : .35; let p1 = [cx + ux * R * o, cy + uy * R * o], p2 = [cx - ux * R * o, cy - uy * R * o]; const e1 = toEdge(p1[0], p1[1], ux, uy), e2 = toEdge(p2[0], p2[1], -ux, -uy), d1 = c.dist === 'edge' ? e1 : Math.min(c.dist * R, e1), d2 = c.dist === 'edge' ? e2 : Math.min(c.dist * R, e2); M.info = { d1: +(d1 / R).toFixed(2), d2: +(d2 / R).toFixed(2) };
      down(1, ...p1); down(2, ...p2); nstep('pull', 4); const n = Math.max(2, Math.ceil(Math.max(d1, d2) / R / (c.sp === 'fast' ? 20 : 3) * 60)); for (let s = 1; s <= n; s++) { move(1, p1[0] + ux * d1 * s / n, p1[1] + uy * d1 * s / n); move(2, p2[0] - ux * d2 * s / n, p2[1] - uy * d2 * s / n); PB.step('pull'); } nstep('hold', 180); up(1); nstep('rel', 6); up(2); nstep('rel', 234); },
    rot(c) { PB.fresh(c.seed); const [cx, cy] = scr(globalC.xc, globalC.yc); let r0 = R * .6, r1 = R * (c.grow ? 1.5 : .6), sg = c.sg || 1; const nf = c.nf || 2, pt = (k, s) => { const a = k * 2 * Math.PI / nf + sg * 2 * Math.PI * c.turns * s, r = r0 + (r1 - r0) * s; return [cx + Math.cos(a) * r, cy + Math.sin(a) * r]; }; for (let k = 0; k < nf; k++) down(k + 1, ...clampS(...pt(k, 0))); nstep('pull', 4); const n = Math.round(c.turns * 60 * (c.sp === 'fast' ? .5 : 1.4)); for (let s = 1; s <= n; s++) { for (let k = 0; k < nf; k++) move(k + 1, ...pt(k, s / n)); PB.step('pull'); } nstep('hold', 180); for (let k = 0; k < nf; k++) up(k + 1); nstep('rel', 240); },
    pinch(c) { PB.fresh(c.seed); const a = c.ang * Math.PI / 180, [cx, cy] = scr(globalC.xc, globalC.yc), pt = (k, s) => { const r = R * (.95 + (.12 - .95) * s) * (k ? -1 : 1); return [cx + Math.cos(a) * r, cy + Math.sin(a) * r]; }; down(1, ...pt(0, 0)); down(2, ...pt(1, 0)); nstep('pull', 4); const n = c.sp === 'fast' ? 8 : 50; for (let s = 1; s <= n; s++) { move(1, ...pt(0, s / n)); move(2, ...pt(1, s / n)); PB.step('pull'); } nstep('hold', 180); up(1); up(2); nstep('rel', 240); },
    three(c) { PB.fresh(c.seed); const [cx, cy] = scr(globalC.xc, globalC.yc), pt = (k, s) => { const a = -Math.PI / 2 + k * 2 * Math.PI / 3, r = R * (.4 + c.dist * s); return [cx + Math.cos(a) * r, cy + Math.sin(a) * r]; }; for (let k = 0; k < 3; k++) down(k + 1, ...clampS(...pt(k, 0))); nstep('pull', 4); const n = Math.max(3, Math.ceil(c.dist / (c.sp === 'fast' ? 20 : 3) * 60)); for (let s = 1; s <= n; s++) { for (let k = 0; k < 3; k++) move(k + 1, ...pt(k, s / n)); PB.step('pull'); } nstep('hold', 180); for (let k = 0; k < 3; k++) { up(k + 1); nstep('rel', 5); } nstep('rel', 225); },
    scrub(c) { PB.fresh(c.seed); const a = c.ang * Math.PI / 180, [cx, cy] = scr(globalC.xc, globalC.yc); down(1, cx, cy); nstep('pull', 4); let p = [cx, cy]; for (let s = 1; s <= 180; s++) { const u = Math.sin(2 * Math.PI * c.hz * s / 60) * c.amp * R; p = move(1, cx + Math.cos(a) * u, cy + Math.sin(a) * u); PB.step('pull'); } nstep('hold', 60); up(1); nstep('rel', 240); },
    stir(c) { PB.fresh(c.seed); let [cx, cy] = scr(globalC.xc, globalC.yc); const rr = c.rad * R; let sx = cx, sy = cy; if (c.from === 'edge') { [sx, sy] = tipAt(0, -1, .15); } down(1, sx, sy); nstep('pull', 4); const sg = c.sg || 1; for (let s = 1; s <= 300; s++) { const th = -Math.PI / 2 + sg * 2 * Math.PI * c.rps * s / 60, k = Math.min(1, s / 15); move(1, cx + (sx - cx) * (1 - k) + Math.cos(th) * rr * k, cy + (sy - cy) * (1 - k) + Math.sin(th) * rr * k); PB.step('pull'); } nstep('hold', 60); up(1); nstep('rel', 240); },
    fling(c) { const [ux, uy] = DIRS[c.dir]; PB.fresh(c.seed, c.x0 === 'o' ? (ux < 0 ? SILL.g.r - R * 1.05 : SILL.g.l + R * 1.05) : null); let sx, sy; if (c.grab === 'center') [sx, sy] = scr(globalC.xc, globalC.yc); else [sx, sy] = tipAt(ux, uy, .15); down(1, sx, sy); nstep('pull', 4); const te = toEdge(sx, sy, ux, uy), d = Math.min(c.dist * R, te); pullTo(1, sx, sy, ux, uy, d, 28); up(1); nstep('rel', 240); },
    // 拉著撞牆、貼牆滑
    wall(c) { PB.fresh(c.seed); let [sx, sy] = scr(globalC.xc, globalC.yc); if (c.grab === 'edge') { const [ux, uy] = DIRS[c.dir]; [sx, sy] = tipAt(ux, uy, .15); } down(1, sx, sy); nstep('pull', 4); let p = [sx, sy]; const go = (x, y, sp) => { const d = Math.hypot(x - p[0], y - p[1]), n = Math.max(2, Math.ceil(d / R / sp * 60)), a = p.slice(); for (let s = 1; s <= n; s++) { p = move(1, a[0] + (x - a[0]) * s / n, a[1] + (y - a[1]) * s / n); PB.step('pull'); } }, sp = c.sp === 'fast' ? 22 : 6;
      if (c.dir === 'R') { go(W - 4, sy - R * .5, sp); nstep('pull', 30); go(W - 4, sy - 3 * R, sp); go(W - 4, sy, sp); } else if (c.dir === 'L') { go(4, sy - R * .5, sp); nstep('pull', 30); go(4, sy - 3 * R, sp); go(4, sy, sp); } else if (c.dir === 'U') { go(sx, 4, sp); nstep('pull', 30); go(W - 4, 4, sp); go(4, 4, sp); } else { go(sx, H - 4, sp); nstep('pull', 30); go(W - 4, H - 4, sp); go(4, H - 4, sp); }
      nstep('hold', 180); up(1); nstep('rel', 240); },
    yoyo(c) { PB.fresh(c.seed); const rnd = seeded(c.seed * 31 + 7); for (let k = 0; k < 6; k++) { const a = c.mode === 'same' ? -Math.PI / 2 + (rnd() - .5) * .3 : rnd() * 6.283, ux = Math.cos(a), uy = Math.sin(a); const [sx, sy] = rnd() < .6 ? tipAt(ux, uy, .15) : scr(globalC.xc, globalC.yc); down(1, ...clampS(sx, sy)); nstep('pull', 3); const d = Math.min(c.dist * R, toEdge(sx, sy, ux, uy)); pullTo(1, sx, sy, ux, uy, d, c.sp === 'fast' ? 22 : 6); nstep('pull', 6); up(1); nstep('pull', 10); } nstep('rel', 240); },
    // 亂捏（照 fuzz.js 的產生法）
    fuzz(c) { const rnd = seeded(c.seed * 2654435761 % 4294967296); PB.fresh(c.seed); for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
      const pick = () => { const a = rnd() * 6.283, rr = Math.sqrt(rnd()) * .95, g = globalC; let bi = 0, bd = 1e9; const tx = g.xc + Math.cos(a) * R * rr, ty = g.yc + Math.sin(a) * R * rr; for (let i = 0; i < N; i++) { const d = (X[i] - tx) ** 2 + (Y[i] - ty) ** 2; if (d < bd) { bd = d; bi = i; } } return scr(X[bi], Y[bi]); };
      const drag = (id, x0, y0, x1, y1, n) => { let e = [x0, y0]; for (let s = 1; s <= n; s++) { e = move(id, x0 + (x1 - x0) * s / n, y0 + (y1 - y0) * s / n); PB.step('pull'); } return e; };
      const ng = 5 + Math.floor(rnd() * 4); M.info = { g: [] };
      for (let g = 0; g < ng; g++) { const kind = Math.floor(rnd() * 6), a = rnd() * 6.283, dist = (.5 + rnd() * 3.5) * R, n = 4 + Math.floor(rnd() * 36), hd = Math.floor(rnd() * 100); const [sx, sy] = pick(); M.info.g.push(['拉', '拉', '兩指', '刷', '攪', '折返'][kind] + (dist / R).toFixed(1) + 'R/' + n);
        if (kind === 0 || kind === 1) { down(1, sx, sy); nstep('pull', 4); drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n); still = 0; nstep('hold', hd); up(1); }
        else if (kind === 2) { const [tx, ty] = pick(); down(1, sx, sy); down(2, tx, ty); nstep('pull', 4); const ex = sx + Math.cos(a) * dist * .6, ey = sy + Math.sin(a) * dist * .6, fx = tx - Math.cos(a) * dist * .6, fy = ty - Math.sin(a) * dist * .6; for (let s = 1; s <= n; s++) { move(1, sx + (ex - sx) * s / n, sy + (ey - sy) * s / n); move(2, tx + (fx - tx) * s / n, ty + (fy - ty) * s / n); PB.step('pull'); } still = 0; nstep('hold', hd); up(1); nstep('pull', 6); up(2); }
        else if (kind === 3) { down(1, sx, sy); nstep('pull', 1); let px = sx, py = sy; for (let k = 0; k < 6; k++) { const sg = k % 2 ? -1 : 1, bx = sx + Math.cos(a) * dist * .5 * sg + (rnd() - .5) * R * .6, by = sy + Math.sin(a) * dist * .5 * sg + (rnd() - .5) * R * .6; [px, py] = drag(1, px, py, bx, by, 5 + Math.floor(rnd() * 8)); } up(1); }
        else if (kind === 4) { down(1, sx, sy); nstep('pull', 1); const rr = dist * .4, turns = 40 + Math.floor(rnd() * 60); for (let k = 1; k <= turns; k++) { const th = a + k * .35; move(1, sx + Math.cos(th) * rr - Math.cos(a) * rr, sy + Math.sin(th) * rr - Math.sin(a) * rr); PB.step('pull'); } still = 0; nstep('hold', hd >> 1); up(1); }
        else { down(1, sx, sy); nstep('pull', 3); let p = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n); nstep('pull', Math.floor(hd / 3)); const b = a + 1.6 + rnd() * 3; drag(1, p[0], p[1], sx + Math.cos(b) * dist, sy + Math.sin(b) * dist, 6 + Math.floor(rnd() * 20)); still = 0; nstep('hold', hd); up(1); }
        nstep('pull', 10 + Math.floor(rnd() * 80)); }
      nstep('rel', 240); },
    // 隨手一拉：身上任一點、任一方向、0.5R 到螢幕邊、每秒 3 到 25R、按住 0.3 到 3 秒
    rnd(c) { const rnd = seeded(c.seed * 104729 + 17); const x0 = SILL.g.l + R * 1.05 + rnd() * (SILL.g.r - SILL.g.l - R * 2.1); PB.fresh(c.seed, x0); let sx = 0, sy = 0, g = globalC; for (let k = 0; k < 60; k++) { const a = rnd() * 6.2832, r = Math.sqrt(rnd()) * R; const wx = g.xc + Math.cos(a) * r, wy = g.yc + Math.sin(a) * r; if (insideBody(wx, wy)) { [sx, sy] = scr(wx, wy); break; } }
      const a = rnd() * 6.2832, ux = Math.cos(a), uy = Math.sin(a), te = toEdge(sx, sy, ux, uy), d = Math.min(te, R * .5 + rnd() * Math.max(0, te - R * .5)), sp = 3 * Math.pow(25 / 3, rnd()), hd = Math.round(18 + rnd() * 162), c0 = scr(g.xc, g.yc), in0 = -((sx - c0[0]) * ux + (sy - c0[1]) * uy) / R;
      M.info = { d: +(d / R).toFixed(2), a: +(a * 57.3).toFixed(0), sp: +sp.toFixed(1), hd, inw: +in0.toFixed(2), r0: +(Math.hypot(sx - c0[0], sy - c0[1]) / R).toFixed(2), uy: +uy.toFixed(2) };
      down(1, sx, sy); nstep('pull', 4); pullTo(1, sx, sy, ux, uy, d, sp); nstep('hold', hd); up(1); nstep('rel', 180); },
    // 對照：不碰
    idle(c) { PB.fresh(c.seed); nstep('hold', 180); nstep('rel', 240); }
  };
  PB.run = c => { PB.begin(c.id, c.label, c.seed); PB.G[c.k](c); const m = PB.end(); m.c = c; Math.random = PB.real; return m; };
})();
