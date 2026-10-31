/* 捏捏史萊姆 網頁原型 回歸自測（Agent 程式自測：只抓「壞掉」，抓不到「好不好捏」）

   用法：瀏覽器開 index.html（用手機尺寸較準，例如 375×812），DevTools console 把這整個檔案貼上執行；
   或用 Claude 的 javascript_tool 直接跑。結果印在 console 並回傳，最後一欄 PASS 全 true 才算過。
   每次改演算法都跑（CLAUDE.md 硬規則）。

   量什麼：邊界自交數 selfX（終點要 0）、面積比 area（放手後回 1.00±0.02）、動能 ke（放手後衰減）、
   記形偏移 qdev（輕按後要 0、按住後 >3pt、揉回原形後 <1pt）、第一幀最大位移（要 >1pt）、
   拖的過程逐幀的對折數 foldFrames（同一群自己交叉，要 0）與交疊數 overlapFrames（觸手疊在身體或別條觸手前面，設計上允許，只記錄）。
   怎麼跑：停掉 rAF，用固定 dt 1/60 驅動 update()（跟 iPhone Safari 一樣每幀 4 小步＝每秒 240 小步），
   用 PointerEvent 模擬手指。分頁在背景時 rAF 會被節流，所以不能靠動畫迴圈。 */
(async () => {
  const realRAF = window.requestAnimationFrame;
  window.requestAnimationFrame = () => 0;
  await new Promise(r => setTimeout(r, 80));
  const log = [];
  const origPlay = sfxPlay;
  sfxPlay = (k, g, r) => { log.push([k, +(+g).toFixed(3), +(+(r || 1)).toFixed(3)]); };
  const DT = 1 / 60;
  function ev(type, id, x, y) { cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 })); }
  function steps(n) { for (let i = 0; i < n; i++) update(DT); }
  function segInt(ax, ay, bx, by, cx, cy, dx, dy) { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; }
  function selfX() { const n = bnd.length; let c = 0; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = bnd[j], q = bnd[(j + 1) % n]; if (segInt(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q])) c++; } } return c; }
  // crossings split: same group (a tentacle or the body folding over itself: bad) vs different groups (one tentacle in front of another or the body: allowed by design)
  function classify() { const n = bnd.length; let same = 0, cross = 0; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = bnd[j], q = bnd[(j + 1) % n]; if (segInt(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q])) { if (TID[a] === TID[p] && TID[b] === TID[q]) same++; else cross++; } } } return [same, cross]; }
  let fold = 0, overlap = 0;
  const trk = () => { const [s, c] = classify(); if (s) fold++; if (c) overlap++; };
  function area() { let A = 0; const n = bnd.length; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; A += X[a] * Y[b] - X[b] * Y[a]; } return Math.abs(A) / 2; }
  function ke() { let s = 0; for (let i = 0; i < N; i++) s += (X[i] - PX[i]) ** 2 + (Y[i] - PY[i]) ** 2; return s; }
  function qdev() { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(QX[i] - Q0X[i], QY[i] - Q0Y[i])); return m; }
  function snap() { const [s, c] = classify(); return { selfX: s + c, fold: s, overlap: c, area: +(area() / A0).toFixed(3), ke: +ke().toFixed(2), qdev: +qdev().toFixed(2) }; }
  function maxMove(ref) { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(X[i] - ref[0][i], Y[i] - ref[1][i])); return m; }
  const res = { W, H, R: +R.toFixed(1), N, nb: bnd.length, preset: 'clay' };
  function reset() { mat = { ...PRESETS.clay }; setup(); steps(60); }
  // 固定亂數＋歸零時鐘，T11、T12 用：結果可重現。setup() 不重設時鐘；時鐘動過要還原，不然上一輪 T2 的 relaxUntil 留在未來，下一輪的記形會被當成「揉回原形」
  function seeded(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const realRandom = Math.random;
  const saveClock = () => ({ t, lastTouch, nextTwitch, tLife, relaxUntil, wNext: WANDER.next, wMoving: WANDER.moving });
  function restoreClock(c) { ({ t, lastTouch, nextTwitch, tLife, relaxUntil } = c); WANDER.next = c.wNext; WANDER.moving = c.wMoving; Math.random = realRandom; }
  function resetAligned(wanderNext) { mat = { ...PRESETS.clay }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; specialUntil = -1; releaseCount = 0; nextSpecial = 0; BR.phase = 0; BR.tlPrev = 0; WANDER.moving = false; WANDER.next = wanderNext; steps(60); }

  // T1 輕按 0.1 秒：第一幀要動，放手後不留痕
  reset();
  const cx0 = globalC.xc, cy0 = globalC.yc;
  let ref = [Float64Array.from(X), Float64Array.from(Y)];
  ev('pointerdown', 1, cx0, cy0); steps(1);
  const firstFrame = +maxMove(ref).toFixed(2);
  steps(5); const t1Hold = snap();
  ev('pointerup', 1, cx0, cy0); steps(120);
  res.T1_tap = { firstFrameMove: firstFrame, hold: t1Hold, after2s: snap(), sfx: log.splice(0) };

  // T2 按住 1.5 秒：越按越攤，黏土留痕；揉回原形清掉
  reset(); ref = [Float64Array.from(X), Float64Array.from(Y)];
  ev('pointerdown', 1, cx0, cy0); steps(6); const m01 = +maxMove(ref).toFixed(2);
  steps(84); const m15 = +maxMove(ref).toFixed(2); const s15 = snap();
  ev('pointerup', 1, cx0, cy0); steps(60); const afterHold = snap();
  relax(); steps(60); const afterRelax = snap();
  res.T2_hold = { move100ms: m01, move1500ms: m15, during: s15, afterRelease1s: afterHold, afterRelax1s: afterRelax, sfx: log.splice(0) };

  // T3 單指從右邊拉到底、停 1 秒、慢放（放手速度 0，啵要靠拉伸量）
  reset();
  // （這一拉抓的是朝右那條觸手的根部往右拖：觸手被壓縮，是最容易對折的動作，逐幀抓對折）
  const sx = cx0 + R * 0.8, sy = cy0; ev('pointerdown', 1, sx, sy); fold = 0; overlap = 0;
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx + k * (R * 2.2 / 60), sy + k * (R * 0.8 / 60)); steps(1); trk(); }
  for (let k = 0; k < 60; k++) { steps(1); trk(); } const t3Peak = snap();
  ev('pointerup', 1, sx + R * 2.2, sy + R * 0.8); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  res.T3_pull = { during: t3Peak, after3s: snap(), foldFrames: fold, overlapFrames: overlap, sfx: log.splice(0) };

  // T4 兩指對拉
  reset(); fold = 0; overlap = 0;
  ev('pointerdown', 1, cx0 - R * 0.7, cy0); ev('pointerdown', 2, cx0 + R * 0.7, cy0);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, cx0 - R * 0.7 - k * (R * 1.5 / 60), cy0); ev('pointermove', 2, cx0 + R * 0.7 + k * (R * 1.5 / 60), cy0); steps(1); trk(); }
  for (let k = 0; k < 30; k++) { steps(1); trk(); } const t4 = snap();
  ev('pointerup', 1, cx0 - R * 2.2, cy0); ev('pointerup', 2, cx0 + R * 2.2, cy0); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  res.T4_twoFinger = { during: t4, after3s: snap(), foldFrames: fold, overlapFrames: overlap, sfx: log.splice(0) };

  // T5 亂甩 120 幀
  reset(); let fx = cx0, fy = cy0; ev('pointerdown', 1, fx, fy); let worst = 0; fold = 0; overlap = 0;
  for (let k = 0; k < 120; k++) { fx = cx0 + (Math.random() - .5) * R * 4; fy = cy0 + (Math.random() - .5) * R * 4; ev('pointermove', 1, fx, fy); steps(1); worst = Math.max(worst, classify()[0]); trk(); }
  ev('pointerup', 1, fx, fy); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  { const l = log.splice(0); res.T5_flail = { worstDuring: worst, foldFrames: fold, overlapFrames: overlap, after3s: snap(), pulls: l.filter(e => e[0] === 'pull').length, release: l.find(e => e[0] === 'release') }; }

  // T6 從外面推進來：第一次推到要有 press 音
  reset(); const px0 = cx0 - R * 2.4, py0 = cy0; ev('pointerdown', 1, px0, py0);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, px0 + k * (R * 2.0 / 60), py0); steps(1); }
  const t6 = snap(); ev('pointerup', 1, px0 + R * 2.0, py0); steps(120);
  res.T6_push = { during: t6, after2s: snap(), sfx: log.splice(0) };

  // T7 放著 20 秒
  reset(); let worstIdle = 0, minA = 9, maxA = 0;
  for (let k = 0; k < 1200; k++) { update(DT); if (k % 20 === 0) { worstIdle = Math.max(worstIdle, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }   // idle: any crossing at all counts
  res.T7_idle = { worstSelfX: worstIdle, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3), qdev: +qdev().toFixed(2) };

  // T8 pointercancel：不啵、手指清掉
  reset(); ev('pointerdown', 1, cx0, cy0); steps(30); ev('pointercancel', 1, cx0, cy0); steps(30);
  res.T8_cancel = { fingersLeft: fingers.size, sfx: log.splice(0) };

  // T9 快甩放手：峰值速度項
  reset(); ev('pointerdown', 1, cx0, cy0);
  for (let k = 1; k <= 6; k++) { ev('pointermove', 1, cx0 + k * R * 0.25, cy0); steps(1); }
  ev('pointerup', 1, cx0 + R * 1.5, cy0); steps(60);
  res.T9_flick = { sfx: log.splice(0), after: snap() };

  // T10 候選 19（凍住）與候選 2（特別回彈，每次都來）開著，抓放三次也不壞
  reset(); mat.idleFreeze = 1; mat.specialEvery = 1; steps(120); let worst10 = 0, first10 = null;
  const note10 = (phase, r, k) => { const c = classify()[0]; if (c > 0) { worst10 = Math.max(worst10, c); if (!first10) first10 = { phase, r, k, home: [+HOMEX.toFixed(0), +HOMEY.toFixed(0)], body: [+globalC.xc.toFixed(0), +globalC.yc.toFixed(0)], t: +t.toFixed(2) }; } };
  for (let r = 0; r < 3; r++) {
    ev('pointerdown', 1, cx0, cy0);
    for (let k = 1; k <= 20; k++) { ev('pointermove', 1, cx0 + k * R * 0.08, cy0 - k * R * 0.04); steps(1); note10('drag', r, k); }
    ev('pointerup', 1, cx0 + R * 1.6, cy0 - R * 0.8);
    for (let k = 1; k <= 90; k++) { steps(1); note10('release', r, k); }
  }
  { const l = log.splice(0); res.T10_candidates = { worstSelfX: worst10, first: first10, after: snap(), releases: l.filter(e => e[0] === 'release').map(e => e[1]) }; }
  mat = { ...PRESETS.clay };

  // T11 壓縮觸手的 18 個情境（第 41 條的量法）：抓朝右那條觸手根部附近三個位置 × 軸線上下 × 三個拖的方向，逐幀記對折。
  //     基準（v2.4 以前）是 8 個情境對折、282 幀、6 個握著時還在對折；橫檔＋中軸不折返之後 3 個情境、24 幀、0 個握著還在
  { const clock = saveClock(); Math.random = seeded(20261101); let scenFold = 0, frames = 0, heldRuns = 0, overlapF = 0; const grid = [];   // 固定亂數：18 個情境每次一樣
    for (const gx of [0.65, 0.8, 0.95]) for (const gy of [-0.1, 0.1]) for (const [vx, vy] of [[2.2, 0.8], [2.0, 0], [1.6, -0.6]]) grid.push([gx, gy, vx, vy]);
    for (const [gx, gy, vx, vy] of grid) {
      resetAligned(3); const cx1 = globalC.xc, cy1 = globalC.yc, sx = cx1 + gx * R, sy = cy1 + gy * R; let f = 0;
      ev('pointerdown', 1, sx, sy);
      for (let k = 1; k <= 45; k++) { ev('pointermove', 1, sx + vx * R * k / 45, sy + vy * R * k / 45); steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      for (let k = 0; k < 45; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (classify()[0] > 0) heldRuns++;
      ev('pointerup', 1, sx + vx * R, sy + vy * R); for (let k = 0; k < 150; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (f > 0) scenFold++; frames += f;
    }
    log.splice(0);
    res.T11_compressionGrid = { scenarios: grid.length, scenariosWithFold: scenFold, foldFrames: frames, heldFoldRuns: heldRuns, overlapFrames: overlapF };
    restoreClock(clock);
  }

  const okArea = s => s.area > 0.98 && s.area < 1.02;
  const rel = l => (l.find(e => e[0] === 'release') || [0, 0])[1];
  // 提案第 41 條（2026-11-01）：抓觸手根部往尖端推會壓縮觸手、對折。橫檔＋中軸不折返之後剩手指正好壓在接點上時的幾幀。
  // T12 遊走與拖尾（第 20 條）：同一組亂數跑兩次（關拖尾當對照、開拖尾），放著 20 秒逐幀比觸手尖端在身體座標裡的位置差，
  //     投影到移動的反方向＝拖了幾點（maxTailPt）；走完停下 3 秒後差要回到 1.5pt 以內（afterStopPt；停下 1 到 2 秒內身體還在回正，量到 3.5pt）；過程零自交、面積不漂
  {
    const clock = saveClock();
    function wanderRun(tail) {
      Math.random = seeded(20261101); resetAligned(0); mat.tail = tail;   // 先歸零時鐘再暖身，兩次的亂數才會對齊
      const tips = []; for (let k = 0; k < TENT.length; k++) { let b = -1; for (let i = 0; i < N; i++) if (TID[i] === k && (b < 0 || TU[i] > TU[b])) b = i; if (b >= 0) tips.push(b); }
      const frames = []; let worst = 0, minA = 9, maxA = 0, stopAt = -9, moved = 0;
      for (let f = 0; f < 1200; f++) { update(DT);
        if (f % 4 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); }
        let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
        const ga = Math.atan2(globalC.sn, globalC.cs), ca = Math.cos(ga), sa = Math.sin(ga), wv = Math.hypot(WANDER.vx, WANDER.vy);
        if (WANDER.moving) { stopAt = t; moved++; }
        frames.push({ pos: tips.map(i => { const dx = X[i] - mx, dy = Y[i] - my; return [ca * dx + sa * dy, -sa * dx + ca * dy]; }), moving: WANDER.moving,
          bx: wv > 1e-6 ? -(ca * WANDER.vx + sa * WANDER.vy) / wv : 0, by: wv > 1e-6 ? -(-sa * WANDER.vx + ca * WANDER.vy) / wv : 0, since: t - stopAt });
      }
      return { frames, worst, minA, maxA, moved };
    }
    const ctl = wanderRun(0), run = wanderRun(PRESETS.clay.tail);
    let maxTail = 0, afterStop = 0;
    for (let f = 0; f < run.frames.length; f++) { const a = ctl.frames[f], b = run.frames[f];
      for (let k = 0; k < b.pos.length; k++) { const dx = b.pos[k][0] - a.pos[k][0], dy = b.pos[k][1] - a.pos[k][1];
        if (b.moving) maxTail = Math.max(maxTail, dx * b.bx + dy * b.by); else if (b.since > 3) afterStop = Math.max(afterStop, Math.hypot(dx, dy)); } }
    res.T12_wander = { tail: PRESETS.clay.tail, movingFrames: run.moved, maxTailPt: +maxTail.toFixed(2), afterStopPt: +afterStop.toFixed(2), worstSelfX: run.worst, areaMin: +run.minA.toFixed(3), areaMax: +run.maxA.toFixed(3), controlSame: ctl.moved === run.moved };
    restoreClock(clock);
  }
  // T13 兩指捏（第 24 條）：兩指在身體兩側抓住、相向靠近到起始距離的 35%，要有 squish（press 音）至少兩次；放手後零對折、面積回來（過程的對折幀只記錄）
  reset(); fold = 0; overlap = 0;
  { const d0 = R * 0.9; ev('pointerdown', 1, cx0 - d0 / 2, cy0); ev('pointerdown', 2, cx0 + d0 / 2, cy0); steps(2); log.splice(0);
    for (let k = 1; k <= 40; k++) { const d = d0 * (1 - 0.65 * k / 40); ev('pointermove', 1, cx0 - d / 2, cy0); ev('pointermove', 2, cx0 + d / 2, cy0); steps(1); trk(); }
    for (let k = 0; k < 30; k++) { steps(1); trk(); }
    const during = snap(), squish = log.filter(e => e[0] === 'press').length;
    ev('pointerup', 1, cx0 - d0 * 0.175, cy0); ev('pointerup', 2, cx0 + d0 * 0.175, cy0); steps(180);
    res.T13_pinch = { squishEvents: squish, during, after3s: snap(), foldFrames: fold, overlapFrames: overlap }; log.splice(0); }

  // T14 拉太遠滑脫（候選 25，開著）：拉到上限 1.3 倍停 0.3 秒，手指還按著就要脫手（最重的放手音、沒有粒子被抓著）；之後抬手不再第二次啵
  reset(); mat.slip = 1; log.splice(0);
  { const far = PRESETS.clay.maxPull * 1.3 * R; ev('pointerdown', 1, cx0, cy0);
    for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx0 + far * k / 30, cy0); steps(1); }
    for (let k = 0; k < 20; k++) steps(1);
    const slipped = log.filter(e => e[0] === 'release'), grabbed = Array.from(GRAB).filter(Boolean).length;
    log.splice(0); ev('pointerup', 1, cx0 + far, cy0); steps(60);
    res.T14_slip = { slipRelease: slipped.length, slipGain: slipped.length ? slipped[0][1] : 0, grabbedAfterSlip: grabbed, popAfterLift: log.filter(e => e[0] === 'release').length, after1s: snap() }; log.splice(0); }

  // T15 放手黏連（候選 26，0.12 秒）：慢慢移 0.3R 再抬手，啵要晚 6 幀以上才來、抬手那一刻那塊還被抓著；快甩抬手要當幀就啵
  reset(); mat.stick = 0.12; log.splice(0);
  { ev('pointerdown', 1, cx0, cy0); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx0 + R * 0.3 * k / 30, cy0); steps(1); }
    log.splice(0); ev('pointerup', 1, cx0 + R * 0.3, cy0); let popAt = -1; const heldAtLift = Array.from(GRAB).filter(Boolean).length;
    for (let k = 0; k < 30; k++) { steps(1); if (popAt < 0 && log.some(e => e[0] === 'release')) popAt = k + 1; }
    steps(60); const slow = { popFrame: popAt, heldAtLift, fingersLeft: fingers.size };
    ev('pointerdown', 1, cx0, cy0); for (let k = 1; k <= 6; k++) { ev('pointermove', 1, cx0 + k * R * 0.25, cy0); steps(1); }
    log.splice(0); ev('pointerup', 1, cx0 + R * 1.5, cy0); const fastImmediate = log.some(e => e[0] === 'release'); steps(60);
    res.T15_stick = { slow, fastImmediate, after: snap() }; log.splice(0); }

  // T16 第三批候選全開（21 回家慢、22 餘韻、23 呼吸三項、27 局部面積、33 家 0.46）：抓放三次加放著 5 秒也不壞
  reset(); Object.assign(mat, { homeK: 0.003, afterglow: 0.25, breathT: 6, breathShape: 1, breathDeep: 1, localArea: 1, homeFrac: 0.46 }); steps(120);
  { let worst16 = 0; const note = () => { worst16 = Math.max(worst16, classify()[0]); }; const c16x = globalC.xc, c16y = globalC.yc;
    for (let r = 0; r < 3; r++) {
      ev('pointerdown', 1, c16x, c16y);
      for (let k = 1; k <= 20; k++) { ev('pointermove', 1, c16x + k * R * 0.08, c16y - k * R * 0.04); steps(1); note(); }
      for (let k = 0; k < 20; k++) { steps(1); note(); }
      ev('pointerup', 1, c16x + R * 1.6, c16y - R * 0.8); for (let k = 0; k < 90; k++) { steps(1); note(); }
    }
    let minA16 = 9, maxA16 = 0; for (let k = 0; k < 300; k++) { update(DT); if (k % 10 === 0) { note(); const a = area() / A0; minA16 = Math.min(minA16, a); maxA16 = Math.max(maxA16, a); } }
    res.T16_batch3 = { worstSelfX: worst16, after: snap(), areaMin: +minA16.toFixed(3), areaMax: +maxA16.toFixed(3), releases: log.filter(e => e[0] === 'release').length }; log.splice(0); }

  // T3 的對折幀數留著只記錄；交疊（跨群）是設計允許的，永遠只記錄
  res.KNOWN_ISSUES = { T3_compressionFoldFrames: res.T3_pull.foldFrames, T3_foldStillHeld: res.T3_pull.during.fold, T4_foldFrames: res.T4_twoFinger.foldFrames, T4_foldStillHeld: res.T4_twoFinger.during.fold, T5_foldFrames: res.T5_flail.foldFrames, T13_pinchFoldFrames: res.T13_pinch.foldFrames };
  res.PASS = {
    // folds must be gone once the finger is off (a fold the clay remembers would be a real bug)
    noFoldAfterRelease: [res.T1_tap.after2s, res.T2_hold.afterRelease1s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(s => s.fold === 0) && res.T7_idle.worstSelfX === 0,
    areaBack: [res.T1_tap.after2s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(okArea) && res.T7_idle.areaMin > 0.97 && res.T7_idle.areaMax < 1.03,
    firstFrameMoves: res.T1_tap.firstFrameMove > 1,
    tapLeavesNoMark: res.T1_tap.after2s.qdev < 1,
    holdLeavesMark: res.T2_hold.afterRelease1s.qdev > 3,
    relaxClearsMark: res.T2_hold.afterRelax1s.qdev < 1,
    slowReleaseStillPops: rel(res.T3_pull.sfx) > 0.7,
    flickPops: rel(res.T9_flick.sfx) > 0.9,
    pushMakesPressSound: res.T6_push.sfx.some(e => e[0] === 'press'),
    cancelIsSilent: !res.T8_cancel.sfx.some(e => e[0] === 'release') && res.T8_cancel.fingersLeft === 0,
    candidatesDontBreak: res.T10_candidates.worstSelfX === 0 && okArea(res.T10_candidates.after) && res.T10_candidates.releases.length === 3,
    // 第 41 條修好的標準：握著時不能還留著對折；短暫幾幀（手指正好壓在接點上）先容忍，數字記在 T11
    // 2026-11-01 的水準：握著還在對折最多 1 個情境（手指正好壓在接點上）、對折幀數 100 以內；v2.4 以前是 6 個、282 幀
    compressionFoldsRare: res.T11_compressionGrid.heldFoldRuns <= 1 && res.T11_compressionGrid.foldFrames < 100,
    // 第 20 條：拖尾只是表演，走完要收回來、過程不能自交或漏面積
    wanderTailClean: res.T12_wander.worstSelfX === 0 && res.T12_wander.areaMin > 0.97 && res.T12_wander.areaMax < 1.03 && res.T12_wander.afterStopPt < 1.5 && res.T12_wander.controlSame,
    // 第三批其餘（2026-11-01）：24 兩指捏要有 squish；25 滑脫要真的脫手、只啵一次；26 黏連要晚放、快甩不黏；候選全開也不壞
    pinchSquishes: res.T13_pinch.squishEvents >= 2 && res.T13_pinch.after3s.fold === 0 && okArea(res.T13_pinch.after3s),
    slipLetsGo: res.T14_slip.slipRelease === 1 && res.T14_slip.slipGain >= 0.99 && res.T14_slip.grabbedAfterSlip === 0 && res.T14_slip.popAfterLift === 0,
    stickDelaysPop: res.T15_stick.slow.popFrame >= 6 && res.T15_stick.slow.heldAtLift > 0 && res.T15_stick.slow.fingersLeft === 0 && res.T15_stick.fastImmediate,
    batch3DontBreak: res.T16_batch3.worstSelfX === 0 && okArea(res.T16_batch3.after) && res.T16_batch3.areaMin > 0.97 && res.T16_batch3.areaMax < 1.03 && res.T16_batch3.releases === 3,
  };
  res.ALL_PASS = Object.values(res.PASS).every(Boolean);

  draw();
  sfxPlay = origPlay; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  console.log(JSON.stringify(res, null, 1));
  return res;
})();
