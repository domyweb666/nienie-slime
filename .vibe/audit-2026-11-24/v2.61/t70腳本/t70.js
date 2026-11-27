  // T70 v2.61 破皮（A7）。前面 69 項把皮釘成平塗、不讀畫面，看不到破皮。這項換成預設的清透皮、窗台、芋圓，真的畫出來，每 2 格讀 JEL.h2（畫面一半大、模糊過的遮罩，門檻 0.46 跟著色器同一個）：
  // 裂：0.004R² 以上的皮有兩塊以上（碰到螢幕邊的最多算一塊）；洞：0.002R² 以上、四面都是皮；突變：外框上一點離上一次的皮超過「這兩格外框最多走的」加 4 點加 0.12R。一組手勢只要有一格就算那組中。
  // 手勢：最糟四種各 10 次（抓中間往右、往左快扯到螢幕邊；抓中間往右下快扯 3R；兩指水平快拉到螢幕邊；種子固定），隨手拉（身上任一點、任一方向、0.5R 到螢幕邊、每秒 3 到 25R、按住 0.3 到 3 秒）。
  // 門檻：預設（皮 1、拉的三顆 0）只擋裂，最糟 40 組最多 2 組，洞和突變只記錄（換皮不會少，補量 27／40）；三顆全開最糟 40 組破（裂、洞、突變任一）0 組，隨手拉破的不超過 1%（無條件進位）。
  // 對照：同一批的前 20 組改皮 0（v2.60 的外框畫法）要裂 2 組以上，證明量得到（40 組補量裂 12 到 15）。回家力道：網頁自己的值用來擋，手機的值（KPIOS）只記錄。
  // 數字每次差幾組（物理裡有不吃種子的計時）。預設跑短版，約 8 分鐘；先設 window.T70LONG = 1 跑長版，約 40 分鐘：對照和手機力道也跑滿 40 組，隨手拉 300 次，手機力道隨手拉 100 次。只想快看一眼：window.T70N = 隨手拉次數。
  { const clock = saveClock(), view0 = { ...VIEW }, sl0 = SLIME, kp0 = window.KPIOS, long = !!window.T70LONG, r = { long, sec: {}, err: '' }, T0 = performance.now();
    Object.assign(VIEW, { skin: 'A', body: 'round', face: 1, bg: 'day', win: '' });
    const si = SLIMES.findIndex(q => q.id === 'taro'), s = SLIMES[si], OLD = { skinU: 0, pullHold: 0, pullWhole: 0, pullSoft: 0 }, DEF = { ...OLD, skinU: 1 }, ALL = { skinU: 1, pullHold: 1, pullWhole: 1, pullSoft: 1 };
    const SP = { ...PRE54[s.mat], seed: s.seed, ...s.p, shakeMode: 0, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0 };
    const fresh = (over, seed, x0) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(seed); SLIME = si; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0;
      if (x0 != null) { const dx = x0 - CX; for (let i = 0; i < N; i++) { X[i] += dx; PX[i] += dx; } HOMEX += dx; }
      steps(120); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const DIR = { R: [1, 0], L: [-1, 0], DR: [.7071, .7071] }, toEdge = (x, y, ux, uy) => { let k = 1e9; if (ux > 1e-6) k = Math.min(k, (W - 4 - x) / ux); if (ux < -1e-6) k = Math.min(k, (4 - x) / ux); if (uy > 1e-6) k = Math.min(k, (H - 4 - y) / uy); if (uy < -1e-6) k = Math.min(k, (4 - y) / uy); return k; };
    // 讀畫面：遮罩、皮幾塊、洞幾個、離皮多遠。只算身體那一框（外擴 1 格）
    let mw = 0, mh = 0, buf = null, cur = null, prev = null, lab = null, stk = null, box = null, pbox = null, disp = 0, lastMax = 0, o = null, fr = 0;
    const read = () => { draw(); const gl = JEL.gl; if (!gl || gl.isContextLost() || !JEL.float) throw new Error('T70：WebGL 沒開，畫不出果凍皮'); if (mw !== JEL.h2.w || mh !== JEL.h2.h) { mw = JEL.h2.w; mh = JEL.h2.h; buf = new Float32Array(mw * mh * 4); lab = new Int8Array(mw * mh); stk = new Int32Array(mw * mh); prev = null; }
      gl.bindFramebuffer(gl.FRAMEBUFFER, JEL.h2.f); gl.readPixels(0, 0, mw, mh, gl.RGBA, gl.FLOAT, buf); gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      cur = new Uint8Array(mw * mh); let x0 = mw, x1 = -1, y0 = mh, y1 = -1; for (let y = 0; y < mh; y++) for (let x = 0, p = (mh - 1 - y) * mw * 4, q = y * mw; x < mw; x++, p += 4, q++) if (buf[p] > .46) { cur[q] = 1; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      box = x1 < 0 ? null : [Math.max(0, x0 - 1), Math.max(0, y0 - 1), Math.min(mw - 1, x1 + 1), Math.min(mh - 1, y1 + 1)]; };
    const comps = v => { const [bx0, by0, bx1, by1] = box, out = [], px2 = (W / mw) * (H / mh) / (R * R); for (let y = by0; y <= by1; y++) lab.fill(0, y * mw + bx0, y * mw + bx1 + 1);   // v 1：皮（八連通）；0：皮以外（四連通），碰到框邊的不是洞
      for (let y = by0; y <= by1; y++) for (let x = bx0; x <= bx1; x++) { const st = y * mw + x; if (cur[st] !== v || lab[st]) continue; let n = 0, top = 0, be = 0, se = 0; stk[top++] = st; lab[st] = 1;
        while (top) { const p = stk[--top], px = p % mw, py = (p / mw) | 0; n++; if (px === bx0 || px === bx1 || py === by0 || py === by1) be = 1; if (px === 0 || py === 0 || px === mw - 1 || py === mh - 1) se = 1;
          for (let oy = -1; oy <= 1; oy++) for (let ox = -1; ox <= 1; ox++) { if ((!ox && !oy) || (!v && ox && oy)) continue; const ax = px + ox, ay = py + oy; if (ax < bx0 || ay < by0 || ax > bx1 || ay > by1) continue; const q = ay * mw + ax; if (cur[q] === v && !lab[q]) { lab[q] = 1; stk[top++] = q; } } }
        if (v || !be) out.push([n * px2, se]); } return out; };
    const dist = (m, b) => { const [bx0, by0, bx1, by1] = b, w = bx1 - bx0 + 1, hh = by1 - by0 + 1, d = new Float32Array(w * hh), D = 1.4142; for (let y = 0; y < hh; y++) for (let x = 0; x < w; x++) { const i = y * w + x; let v = m[(y + by0) * mw + x + bx0] ? 0 : 1e6; if (v) { if (x > 0) v = Math.min(v, d[i - 1] + 1); if (y > 0) { v = Math.min(v, d[i - w] + 1); if (x > 0) v = Math.min(v, d[i - w - 1] + D); if (x < w - 1) v = Math.min(v, d[i - w + 1] + D); } } d[i] = v; }
      for (let y = hh - 1; y >= 0; y--) for (let x = w - 1; x >= 0; x--) { const i = y * w + x; let v = d[i]; if (!v) continue; if (x < w - 1) v = Math.min(v, d[i + 1] + 1); if (y < hh - 1) { v = Math.min(v, d[i + w] + 1); if (x < w - 1) v = Math.min(v, d[i + w + 1] + D); if (x > 0) v = Math.min(v, d[i + w - 1] + D); } d[i] = v; } return d; };
    const look = () => { read(); if (!o.n++ && (!box || comps(1).every(c => c[0] < 1))) o.blank = 1;   // 第一次讀就沒有身體：畫不出來，不算過
      if (box) { let big = 0, eb = 0; for (const [a, e] of comps(1)) if (a >= .004) { if (!e) big++; else if (!eb) { eb = 1; big++; } } if (big > 1) o.split++; if (comps(0).some(c => c[0] >= .002)) o.hole++; }
      if (prev && box && pbox) { const b = [Math.min(box[0], pbox[0]), Math.min(box[1], pbox[1]), Math.max(box[2], pbox[2]), Math.max(box[3], pbox[3])], dc = dist(cur, b), dp = dist(prev, b), w = b[2] - b[0] + 1; let far = 0; for (let y = b[1]; y <= b[3]; y++) for (let x = b[0]; x <= b[2]; x++) { const q = y * mw + x; if (cur[q] === prev[q]) continue; const d = (cur[q] ? dp : dc)[(y - b[1]) * w + x - b[0]]; if (d > far) far = d; } const pop = (far * 2 - disp - 4) / R; if (pop > o.popMax) o.popMax = pop; if (pop > .12) o.pop++; }
      prev = cur; pbox = box; disp = 0; };
    const step = n => { for (let k = 0; k < n; k++) { const n0 = N, r0 = REM.n, l0 = REM.last, x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); fr++; if (N !== n0 || REM.n !== r0 || REM.last !== l0) disp += lastMax; else { let d = 0; for (const i of bnd) d = Math.max(d, Math.hypot(X[i] - x0[i], Y[i] - y0[i])); lastMax = d * CAM.z; disp += lastMax; }
      if (fr % 2 === 0) look(); } };
    const mv = (id, x, y) => ev('pointermove', id, Math.max(4, Math.min(W - 4, x)), Math.max(4, Math.min(H - 4, y)));
    const pull = (sx, sy, ux, uy, d, sp, hold, rel) => { ev('pointerdown', 1, sx, sy); step(4); const n = Math.max(2, Math.ceil(d / R / sp * 60)); for (let k = 1; k <= n; k++) { mv(1, sx + ux * d * k / n, sy + uy * d * k / n); step(1); } step(hold); ev('pointerup', 1, sx + ux * d, sy + uy * d); step(rel); };
    const go = { pull(c, over) { const [ux, uy] = DIR[c.dir], rr = seeded(c.seed * 7919 + 13), g = SILL.g, jt = () => (rr() - .5) * R * .16; fresh(over, c.seed, ux < 0 ? g.r - R * 1.05 : g.l + R * 1.05); let [x, y] = scr(globalC.xc, globalC.yc); x += jt(); y += jt(); pull(x, y, ux, uy, Math.min(c.d * R, toEdge(x, y, ux, uy)), 25, 180, 240); },
      opp(c, over) { fresh(over, c.seed); const [cx, cy] = scr(globalC.xc, globalC.yc), a = cx + R * .35, b = cx - R * .35, d1 = W - 4 - a, d2 = b - 4; ev('pointerdown', 1, a, cy); ev('pointerdown', 2, b, cy); step(4); const n = Math.max(2, Math.ceil(Math.max(d1, d2) / R / 20 * 60)); for (let k = 1; k <= n; k++) { mv(1, a + d1 * k / n, cy); mv(2, b - d2 * k / n, cy); step(1); } step(180); ev('pointerup', 1, a + d1, cy); step(6); ev('pointerup', 2, b - d2, cy); step(234); },
      rnd(c, over) { const rr = seeded(c.seed * 104729 + 17), g = SILL.g; fresh(over, c.seed, g.l + R * 1.05 + rr() * (g.r - g.l - R * 2.1)); let x = 0, y = 0; for (let k = 0; k < 60; k++) { const a = rr() * 6.2832, q = Math.sqrt(rr()) * R, wx = globalC.xc + Math.cos(a) * q, wy = globalC.yc + Math.sin(a) * q; if (insideBody(wx, wy)) { [x, y] = scr(wx, wy); break; } }
        const a = rr() * 6.2832, ux = Math.cos(a), uy = Math.sin(a), te = toEdge(x, y, ux, uy), d = Math.min(te, R * .5 + rr() * Math.max(0, te - R * .5)), sp = 3 * Math.pow(25 / 3, rr()), hd = Math.round(18 + rr() * 162); pull(x, y, ux, uy, d, sp, hd, 180); } };
    const worst = []; for (let k = 0; k < 10; k++) worst.push({ id: 'R' + k, k: 'pull', dir: 'R', d: 99, seed: 31175 + k * 1000 }, { id: 'DR' + k, k: 'pull', dir: 'DR', d: 3, seed: 31175 + k * 1000 }, { id: 'O' + k, k: 'opp', seed: 31201 + k * 1000 }, { id: 'L' + k, k: 'pull', dir: 'L', d: 99, seed: 31101 + k * 1000 });
    const casual = n => Array.from({ length: n }, (_, k) => ({ id: 'N' + k, k: 'rnd', seed: 45000 + k }));
    const batch = async (nm, cells, over, kp) => { const b0 = performance.now(), q = { n: 0, brk: 0, split: 0, hole: 0, pop: 0, blank: 0, nan: 0, popMax: 0, skin: null, who: '' }; if (kp) window.KPIOS = 1; else delete window.KPIOS;
      for (const c of cells) { o = { n: 0, split: 0, hole: 0, pop: 0, blank: 0, popMax: 0 }; prev = pbox = null; disp = lastMax = fr = 0; go[c.k](c, over); for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); let bad = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bad++;
        q.n++; if (o.split || o.hole || o.pop) { q.brk++; q.who += ' ' + c.id + (o.split ? '裂' : '') + (o.hole ? '洞' : '') + (o.pop ? '突' : ''); } if (o.split) q.split++; if (o.hole) q.hole++; if (o.pop) q.pop++; q.blank += o.blank; if (bad) q.nan++; q.popMax = Math.max(q.popMax, o.popMax); await new Promise(a => setTimeout(a, 0)); }
      q.popMax = +q.popMax.toFixed(2); if (typeof SKIN !== 'undefined') q.skin = SKIN.used; r[nm] = q; r.sec[nm] = Math.round((performance.now() - b0) / 1000); };
    try { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; fresh(DEF, 70); draw(); const nr = long ? 300 : window.T70N || 20, few = long ? worst : worst.slice(0, 20);
      await batch('old', few, OLD, 0); await batch('def', worst, DEF, 0); await batch('all', worst, ALL, 0);
      await batch('defR', casual(nr), DEF, 0); await batch('allR', casual(nr), ALL, 0);
      await batch('defP', long ? worst : worst.slice(0, 12), DEF, 1); await batch('allP', long ? worst : worst.slice(0, 12), ALL, 1);
      if (long) { await batch('defRP', casual(100), DEF, 1); await batch('allRP', casual(100), ALL, 1); }
    } catch (e) { r.err = String(e); }
    if (kp0 === undefined) delete window.KPIOS; else window.KPIOS = kp0;
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); SLIME = sl0; Object.assign(VIEW, view0); r.sec.total = Math.round((performance.now() - T0) / 1000);
    res.T70_skin = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    const ran = ['old', 'def', 'all', 'defR', 'allR', 'defP', 'allP'].every(k => r[k] && r[k].blank === 0 && r[k].nan === 0);
    res.PASS.skinWhole = r.err === '' && ran && r.old.split >= (long ? 6 : 2) && r.def.split <= 2 && r.all.brk === 0 && r.allR.brk <= Math.ceil(r.allR.n * .01);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
