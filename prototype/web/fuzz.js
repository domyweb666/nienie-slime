/* 亂捏測試（開發用）：固定種子產生幾十種隨機的拉、扯、兩指、來回刷、撞牆，逐幀量「壞掉」。
   v2.52 A5：多兩組讀數，每個保險（拉到上限、壓到下限、防翻面、手指讓）作用的格數比例，和物理單獨的每格毫秒。手機版同一套在面板「量測」的「亂捏測試」（SlimeFuzz.swift）。
   window.FZ = { seeds:[...], over:{...} } 可以指定種子與參數覆寫。結果放 window.__fz。 */
(async () => {
  window.requestAnimationFrame = () => 0;
  await new Promise(r => setTimeout(r, 60));
  const CFG = window.FZ || {}, DT = 1 / 60;
  const realRandom = Math.random;
  if (typeof SFX !== 'undefined' && SFX && SFX.frame && !SFX.__fz) { const f0 = SFX.frame; SFX.frame = (...a) => { const r = Math.random; Math.random = realRandom; try { return f0.apply(SFX, a); } finally { Math.random = r; } }; SFX.__fz = 1; }
  try { sfxPlay = () => {}; } catch (e) {}
  WALK.noSave = true; WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; IMPSV.noSave = true;
  function seeded(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  let noUp = false; function ev(type, id, x, y) { if (noUp && type === 'pointerup') return; cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 })); }
  function segInt(ax, ay, bx, by, cx, cy, dx, dy) { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; }
  function selfX() { const n = bnd.length; let c = 0; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = bnd[j], q = bnd[(j + 1) % n]; if (segInt(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q])) c++; } } return c; }
  // 外框最尖的轉角（度）：相鄰兩段的夾角，180 是對折
  function sharp() { const n = bnd.length; let m = 0, cnt = 0; for (let i = 0; i < n; i++) { const a = bnd[(i + n - 1) % n], b = bnd[i], c = bnd[(i + 1) % n], ux = X[b] - X[a], uy = Y[b] - Y[a], vx = X[c] - X[b], vy = Y[c] - Y[b], an = Math.abs(Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)) * 57.3; if (an > m) m = an; if (an > 75) cnt++; } return [m, cnt]; }
  // 網格邊最長拉成靜止的幾倍；三角形最小面積比
  function strain(AX, AY) { let mx = 0; for (let e = 0, k = 0; e < EDG.length; e += 2, k++) { const i = EDG[e], j = EDG[e + 1], l = Math.hypot(AX[i] - AX[j], AY[i] - AY[j]) / EDL[k]; if (l > mx) mx = l; } return mx; }
  // 真的翻過去的三角形（面積小於原本的 -2%）。壓在窗台上疊成一線的（面積剛好 0）不算：那是被地板壓平，畫面上看不出來
  function inv(AX, AY) { const T = TRI; let n = 0; for (let k = 0, m = T.length; k < m; k += 3) { const a = T[k], b = T[k + 1], c = T[k + 2]; if (.5 * ((AX[b] - AX[a]) * (AY[c] - AY[a]) - (AY[b] - AY[a]) * (AX[c] - AX[a])) < -.02 * TRA[k / 3]) n++; } return n; }
  const W0 = innerWidth, H0 = innerHeight;
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const clampS = (x, y) => [Math.max(4, Math.min(W0 - 4, x)), Math.max(4, Math.min(H0 - 4, y))];
  const out = [];
  window.__fz = { done: false, out, n: 0 };
  const seeds = CFG.seeds || Array.from({ length: 40 }, (_, k) => 1000 + k);
  for (const seed of seeds) {
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    const rnd = seeded(seed * 2654435761 % 4294967296); Math.random = seeded(seed);
    mat = { ...PRESETS.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, ...(CFG.over || {}) }; VIEW.bg = 'day';
    setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0;
    for (let i = 0; i < 90; i++) update(DT);
    const base = sharp()[0];
    if (typeof GRD !== 'undefined') GRD.reset();   // v2.52 A5：保險計數從暖身之後算起
    let msSum = 0, msMax = 0;
    const M = { seed, g: [], flipFr: 0, flipMax: 0, qFlipMax: 0, xFr: 0, sharpMax: 0, strainMax: 0, qStrainMax: 0, jerkHold: 0, jerkHoldMean: 0, holdN: 0, nan: 0, frames: 0, worst: '' };
    let cur = '', vx = null, vy = null, still = 0, G = null; M.gs = [];
    const step = (holding) => {
      const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); const p0 = performance.now(); update(DT); const pm = performance.now() - p0; msSum += pm; if (pm > msMax) msMax = pm; M.frames++;
      const fc = inv(X, Y), qf = inv(QX, QY); if (fc > 0) M.flipFr++; if (G) { if (fc > G[1]) G[1] = fc; } if (fc > M.flipMax) { M.flipMax = fc; M.worst = cur; } if (qf > M.qFlipMax) M.qFlipMax = qf;
      if (M.frames % 2 === 0 && selfX() > 0) { M.xFr++; if (G) G[4]++; }
      const s = strain(X, Y); if (s > M.strainMax) M.strainMax = s; const qs = strain(QX, QY); if (qs > M.qStrainMax) M.qStrainMax = qs;
      // 手指停著時的跳動：扣整團平移後每顆速度變化的最大值
      let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N;
      const nx = new Float64Array(N), ny = new Float64Array(N); let j = 0; for (let i = 0; i < N; i++) { nx[i] = X[i] - x0[i] - ax; ny[i] = Y[i] - y0[i] - ay; if (vx) { const d = Math.hypot(nx[i] - vx[i], ny[i] - vy[i]); if (d > j) j = d; } if (!isFinite(X[i])) M.nan++; }
      vx = nx; vy = ny; still = holding ? still + 1 : 0;
      if (still > 40) { if (j > M.jerkHold) M.jerkHold = j; M.jerkHoldMean += j; M.holdN++; if (G) { G[2] += j; G[3]++; } }
    };
    const pick = () => { const a = rnd() * 6.283, rr = Math.sqrt(rnd()) * .95, c = globalC; let bi = 0, bd = 1e9; const tx = c.xc + Math.cos(a) * R * rr, ty = c.yc + Math.sin(a) * R * rr; for (let i = 0; i < N; i++) { const d = (X[i] - tx) ** 2 + (Y[i] - ty) ** 2; if (d < bd) { bd = d; bi = i; } } return scr(X[bi], Y[bi]); };
    const drag = (id, x0, y0, x1, y1, n) => { for (let s = 1; s <= n; s++) { const [x, y] = clampS(x0 + (x1 - x0) * s / n, y0 + (y1 - y0) * s / n); ev('pointermove', id, x, y); step(false); } return clampS(x1, y1); };
    const ng = 5 + Math.floor(rnd() * 4);
    for (let g = 0; g < ng; g++) {
      noUp = CFG.holdG === g; const kind = Math.floor(rnd() * 6), a = rnd() * 6.283, dist = (.5 + rnd() * 3.5) * R, n = 4 + Math.floor(rnd() * 36), hd = Math.floor(rnd() * 100);
      const [sx, sy] = pick(); if (G) { G[2] = +(G[2] / Math.max(1, G[3])).toFixed(1); M.gs.push(G.join(',')); } G = ['k' + kind + ' a' + a.toFixed(2) + ' d' + (dist / R).toFixed(1) + ' n' + n + ' h' + hd + ' at' + ((sx - scr(globalC.xc, globalC.yc)[0]) / R).toFixed(2) + ';' + ((sy - scr(globalC.xc, globalC.yc)[1]) / R).toFixed(2), 0, 0, 0, 0];
      if (kind === 0 || kind === 1) {   // 單指拉、停、放
        cur = 'pull d' + (dist / R).toFixed(1) + ' n' + n; M.g.push(cur); ev('pointerdown', 1, sx, sy); for (let i = 0; i < 4; i++) step(true);
        const [ex, ey] = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n); for (let i = 0; i < hd; i++) step(true); ev('pointerup', 1, ex, ey);
      } else if (kind === 2) {   // 兩指往兩邊拉
        cur = 'two d' + (dist / R).toFixed(1) + ' n' + n; M.g.push(cur); const [tx, ty] = pick(); ev('pointerdown', 1, sx, sy); ev('pointerdown', 2, tx, ty); for (let i = 0; i < 4; i++) step(true);
        const ex = sx + Math.cos(a) * dist * .6, ey = sy + Math.sin(a) * dist * .6, fx = tx - Math.cos(a) * dist * .6, fy = ty - Math.sin(a) * dist * .6; let e1 = [sx, sy], e2 = [tx, ty];
        for (let s = 1; s <= n; s++) { e1 = clampS(sx + (ex - sx) * s / n, sy + (ey - sy) * s / n); e2 = clampS(tx + (fx - tx) * s / n, ty + (fy - ty) * s / n); ev('pointermove', 1, e1[0], e1[1]); ev('pointermove', 2, e2[0], e2[1]); step(false); }
        for (let i = 0; i < hd; i++) step(true); ev('pointerup', 1, e1[0], e1[1]); for (let i = 0; i < 6; i++) step(false); ev('pointerup', 2, e2[0], e2[1]);
      } else if (kind === 3) {   // 來回刷
        cur = 'scrub d' + (dist / R).toFixed(1); M.g.push(cur); ev('pointerdown', 1, sx, sy); step(true); let px = sx, py = sy;
        for (let k = 0; k < 6; k++) { const sg = k % 2 ? -1 : 1, bx = sx + Math.cos(a) * dist * .5 * sg + (rnd() - .5) * R * .6, by = sy + Math.sin(a) * dist * .5 * sg + (rnd() - .5) * R * .6; [px, py] = drag(1, px, py, bx, by, 5 + Math.floor(rnd() * 8)); }
        ev('pointerup', 1, px, py);
      } else if (kind === 4) {   // 繞圈攪
        cur = 'stir d' + (dist / R).toFixed(1); M.g.push(cur); ev('pointerdown', 1, sx, sy); step(true); const rr = dist * .4, turns = 40 + Math.floor(rnd() * 60); let p = [sx, sy];
        for (let k = 1; k <= turns; k++) { const th = a + k * .35; p = clampS(sx + Math.cos(th) * rr - Math.cos(a) * rr, sy + Math.sin(th) * rr - Math.sin(a) * rr); ev('pointermove', 1, p[0], p[1]); step(false); }
        for (let i = 0; i < hd / 2; i++) step(true); ev('pointerup', 1, p[0], p[1]);
      } else {   // 拉出去再折回來、再往別的方向扯
        cur = 'zig d' + (dist / R).toFixed(1) + ' n' + n; M.g.push(cur); ev('pointerdown', 1, sx, sy); for (let i = 0; i < 3; i++) step(true);
        let p = drag(1, sx, sy, sx + Math.cos(a) * dist, sy + Math.sin(a) * dist, n); for (let i = 0; i < hd / 3; i++) step(true);
        const b = a + 1.6 + rnd() * 3; p = drag(1, p[0], p[1], sx + Math.cos(b) * dist, sy + Math.sin(b) * dist, 6 + Math.floor(rnd() * 20)); for (let i = 0; i < hd; i++) step(true); ev('pointerup', 1, p[0], p[1]);
      }
      if (noUp) break; const rest = 10 + Math.floor(rnd() * 80); for (let i = 0; i < rest; i++) step(false);
      const sh = sharp(); if (sh[0] > M.sharpMax) { M.sharpMax = sh[0]; M.sharpAt = cur; }
    }
    if (G) { G[2] = +(G[2] / Math.max(1, G[3])).toFixed(1); M.gs.push(G.join(',')); G = null; }
    if (noUp) { out.push(M); window.__fz.done = true; window.__fz.sum = 'held'; Math.random = realRandom; return; }
    for (let i = 0; i < 120; i++) step(false);
    const sh = sharp(); M.endSharp = +sh[0].toFixed(0); M.endSpikes = sh[1]; M.base = +base.toFixed(0); M.endFlip = inv(X, Y); M.endQFlip = inv(QX, QY); M.endX = selfX();
    M.sharpMax = +M.sharpMax.toFixed(0); M.strainMax = +M.strainMax.toFixed(1); M.qStrainMax = +M.qStrainMax.toFixed(1); M.jerkHold = +M.jerkHold.toFixed(1); M.jerkHoldMean = +(M.jerkHoldMean / Math.max(1, M.holdN)).toFixed(2); M.g = M.g.join('|');
    if (typeof GRD !== 'undefined') { GRD.fold(); M.grd = GRD.pct(); } M.physMs = +(msSum / Math.max(1, M.frames)).toFixed(2); M.physMsMax = +msMax.toFixed(1);   // v2.52 A5：每個保險作用的格數比例、物理單獨的每格毫秒
    out.push(M); window.__fz.n = out.length;
    await new Promise(r => setTimeout(r, 0));
  }
  for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
  Math.random = realRandom;
  const S = k => out.map(o => o[k]), mx = k => Math.max(...S(k)), cntIf = f => out.filter(f).length;
  window.__fz.sum = { n: out.length, flipTrials: cntIf(o => o.flipMax > 0), flipMaxAll: mx('flipMax'), flipFrPct: +(100 * S('flipFr').reduce((a, b) => a + b, 0) / S('frames').reduce((a, b) => a + b, 0)).toFixed(1), qFlipTrials: cntIf(o => o.qFlipMax > 0), xTrials: cntIf(o => o.xFr > 0), strainMax: mx('strainMax'), qStrainMax: mx('qStrainMax'), jerkHoldMax: mx('jerkHold'), jerkHoldMeanAvg: +(S('jerkHoldMean').reduce((a, b) => a + b, 0) / out.length).toFixed(2), sharpMaxAll: mx('sharpMax'), endSharpMax: mx('endSharp'), endSpikeTrials: cntIf(o => o.endSpikes > 0), endFlipTrials: cntIf(o => o.endFlip > 0 || o.endQFlip > 0), endXTrials: cntIf(o => o.endX > 0), nan: mx('nan') };
  // v2.52 A5（3-3 第 9、10 欄）：保險作用的格數比例（各組平均）、手指最多讓幾個半徑、往外拉時讓了多少（規則是 0）、物理單獨的每格毫秒（平均與最長一格）
  { const av = f => +(out.reduce((a, o) => a + (f(o) || 0), 0) / Math.max(1, out.length)).toFixed(2), G = o => o.grd || {};
    Object.assign(window.__fz.sum, { capHiPct: av(o => G(o).hi), capLoPct: av(o => G(o).lo), flipGuardPct: av(o => G(o).flip), givePct: av(o => G(o).give), giveMax: Math.max(...out.map(o => G(o).giveMax || 0)), givePullMax: Math.max(...out.map(o => G(o).givePull || 0)), physMs: av(o => o.physMs), physMsMax: mx('physMsMax') }); }
  window.__fz.done = true;
  try { const x = new XMLHttpRequest(); x.open('GET', '/__p?FZ=' + encodeURIComponent(JSON.stringify(window.__fz.sum)), false); x.send(); } catch (e) {}
})();
