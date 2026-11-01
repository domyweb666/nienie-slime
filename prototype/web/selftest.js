/* 捏捏史萊姆 網頁原型 回歸自測（Agent 程式自測：只抓「壞掉」，抓不到「好不好捏」）

   用法：瀏覽器開 index.html（用手機尺寸較準，例如 375×812），DevTools console 把這整個檔案貼上執行；
   或用 Claude 的 javascript_tool 直接跑。結果印在 console 並回傳，最後一欄 PASS 全 true 才算過。
   每次改演算法都跑（CLAUDE.md 硬規則）。

   量什麼：邊界自交數 selfX（終點要 0）、面積比 area（放手後回 1.00±0.02）、動能 ke（放手後衰減）、
   記形偏移 qdev（黏土：輕按 12 秒後 <1pt；按住後 >3pt、揉回原形後 <1pt。2026-11-01 多米真機回報後改，v2.7 是輕按不留痕）、第一幀最大位移（要 >1pt）、
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
  // reset 也要停掉遊走：setup() 把家放回中間，但上一輪留下的遊走還在走，家會繼續往遊走目標移，60 步內身體就飄開（量過飄 58 點，
  // 兩指捏的手指按到身體外面，只有一指抓到）。2026-11-01 v2.14 發現，之前連跑過是遊走剛好停著
  function reset() { mat = { ...PRESETS.clay }; setup(); WANDER.moving = false; WANDER.next = t + 5; steps(60); }
  // 固定亂數＋歸零時鐘，T11、T12 用：結果可重現。setup() 不重設時鐘；時鐘動過要還原，不然上一輪 T2 的 relaxUntil 留在未來，下一輪的記形會被當成「揉回原形」
  function seeded(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const realRandom = Math.random;
  const saveClock = () => ({ t, lastTouch, nextTwitch, tLife, relaxUntil, wNext: WANDER.next, wMoving: WANDER.moving });
  function restoreClock(c) { ({ t, lastTouch, nextTwitch, tLife, relaxUntil } = c); WANDER.next = c.wNext; WANDER.moving = c.wMoving; Math.random = realRandom; }
  function resetAligned(wanderNext, over) { mat = { ...PRESETS.clay, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; specialUntil = -1; releaseCount = 0; nextSpecial = 0; BR.phase = 0; BR.tlPrev = 0; WANDER.moving = false; WANDER.next = wanderNext; steps(60); }

  // T1 輕按 0.1 秒：第一幀要動；12 秒後不留痕（2026-11-01 黏土改成約 10 秒退）
  reset();
  const cx0 = globalC.xc, cy0 = globalC.yc;
  let ref = [Float64Array.from(X), Float64Array.from(Y)];
  ev('pointerdown', 1, cx0, cy0); steps(1);
  const firstFrame = +maxMove(ref).toFixed(2);
  steps(5); const t1Hold = snap();
  ev('pointerup', 1, cx0, cy0); steps(120); const t1After2 = snap(), t1Sfx = log.splice(0); steps(600);
  res.T1_tap = { firstFrameMove: firstFrame, hold: t1Hold, after2s: t1After2, after12s: snap(), sfx: t1Sfx };

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
  // v2.9 起身體形狀一直在變（偽足）：手指放在身體實際的最右邊往內 0.15R，不然有時落在身體外面變成推、沒抓到
  const edgeX = dir => { let b = -1; for (const i of bnd) if (b < 0 || dir * X[i] > dir * X[b]) b = i; return [X[b] - dir * R * 0.15, Y[b]]; };
  const [sx, sy] = edgeX(1); ev('pointerdown', 1, sx, sy); fold = 0; overlap = 0;
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx + k * (R * 2.2 / 60), sy + k * (R * 0.8 / 60)); steps(1); trk(); }
  for (let k = 0; k < 60; k++) { steps(1); trk(); } const t3Peak = snap();
  ev('pointerup', 1, sx + R * 2.2, sy + R * 0.8); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  res.T3_pull = { during: t3Peak, after3s: snap(), foldFrames: fold, overlapFrames: overlap, sfx: log.splice(0) };

  // T4 兩指對拉
  reset(); fold = 0; overlap = 0;
  { const [lx, ly] = edgeX(-1), [rx, ry] = edgeX(1);
  ev('pointerdown', 1, lx, ly); ev('pointerdown', 2, rx, ry);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, lx - k * (R * 1.5 / 60), ly); ev('pointermove', 2, rx + k * (R * 1.5 / 60), ry); steps(1); trk(); }
  for (let k = 0; k < 30; k++) { steps(1); trk(); } var t4 = snap();
  ev('pointerup', 1, lx - R * 1.5, ly); ev('pointerup', 2, rx + R * 1.5, ry); for (let k = 0; k < 180; k++) { steps(1); trk(); } }
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
  //     2026-11-01 黏土觸手記形之後，同一組亂數另跑一次 v2.7 對照（T11_v27）一起記
  function compressionGrid(over) { const clock = saveClock(); Math.random = seeded(20261101); let scenFold = 0, frames = 0, heldRuns = 0, overlapF = 0; const grid = [];   // 固定亂數：18 個情境每次一樣
    for (const gx of [0.65, 0.8, 0.95]) for (const gy of [-0.1, 0.1]) for (const [vx, vy] of [[2.2, 0.8], [2.0, 0], [1.6, -0.6]]) grid.push([gx, gy, vx, vy]);
    for (const [gx, gy, vx, vy] of grid) {
      resetAligned(3, over); const cx1 = globalC.xc, cy1 = globalC.yc, sx = cx1 + gx * R, sy = cy1 + gy * R; let f = 0;
      ev('pointerdown', 1, sx, sy);
      for (let k = 1; k <= 45; k++) { ev('pointermove', 1, sx + vx * R * k / 45, sy + vy * R * k / 45); steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      for (let k = 0; k < 45; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (classify()[0] > 0) heldRuns++;
      ev('pointerup', 1, sx + vx * R, sy + vy * R); for (let k = 0; k < 150; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (f > 0) scenFold++; frames += f;
    }
    log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay };
    return { scenarios: grid.length, scenariosWithFold: scenFold, foldFrames: frames, heldFoldRuns: heldRuns, overlapFrames: overlapF };
  }
  // v2.9 起預設沒有固定觸手：T11 改跑 v2.7 對照（舊外形），守住面板那顆對照按鈕不壞
  res.T11_compressionGrid = compressionGrid(V27.clay);

  const okArea = s => s.area > 0.98 && s.area < 1.02;
  const rel = l => (l.find(e => e[0] === 'release') || [0, 0])[1];
  // 提案第 41 條（2026-11-01）：抓觸手根部往尖端推會壓縮觸手、對折。橫檔＋中軸不折返之後剩手指正好壓在接點上時的幾幀。
  // T12 遊走與拖尾（第 20 條）：同一組亂數跑兩次（關拖尾當對照、開拖尾），放著 20 秒逐幀比觸手尖端在身體座標裡的位置差，
  //     投影到移動的反方向＝拖了幾點（maxTailPt）；走完停下 3 秒後差要回到 1.5pt 以內（afterStopPt；停下 1 到 2 秒內身體還在回正，量到 3.5pt）；過程零自交、面積不漂
  {
    const clock = saveClock();
    function wanderRun(tail) {
      Math.random = seeded(20261101); resetAligned(0, V27.clay); mat.tail = tail;   // 拖尾量觸手尖端：用 v2.7 對照（舊外形）跑   // 先歸零時鐘再暖身，兩次的亂數才會對齊
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

  // T17 拉出一塊（2026-11-01 多米：捏了要留痕、慢慢恢復）：抓身體最右邊的邊、往外拉 0.9R（0.25 秒）、停 0.15 秒放手。
  //     量記形偏移（參考形狀離原形最遠幾點）放手後 1、5、12 秒；同一組亂數跑 v2.7 對照（舊外形）當比較。過程與之後零自交、面積回來
  { const clock = saveClock();
    function tentRun(ctl) {
      Math.random = seeded(20261102); resetAligned(99, ctl ? V27.clay : {});
      let tip = -1; for (const i of bnd) if (TID[i] < 0 && (tip < 0 || X[i] > X[tip])) tip = i;
      const tq = () => +qdev().toFixed(2), selfAny = () => selfX();
      const sx = X[tip] - R * 0.1, sy = Y[tip]; let f = 0;
      ev('pointerdown', 1, sx, sy);
      for (let k = 1; k <= 15; k++) { ev('pointermove', 1, sx + R * 0.9 * k / 15, sy); steps(1); if (selfAny()) f++; }
      for (let k = 0; k < 9; k++) { steps(1); if (selfAny()) f++; }
      const atRelease = tq(); ev('pointerup', 1, sx + R * 0.9, sy);
      const out = { atRelease }; let fr = 0;
      for (let k = 1; k <= 720; k++) { steps(1); if (selfAny()) fr++; if (k === 60) out.after1s = tq(); if (k === 300) out.after5s = tq(); if (k === 720) out.after12s = tq(); }
      log.splice(0); return { ...out, foldFramesHeld: f, foldFramesAfter: fr, end: snap() };
    }
    res.T17_pullMark = { now: tentRun(false), v27: tentRun(true) };
    restoreClock(clock); mat = { ...PRESETS.clay };
  }

  // T18 蠕動不重複：放著 48 秒，每 0.5 秒記一次身體邊界（不含觸手）的蠕動位移（EX−QX），算「有效形狀數」
  //     （樣本共變異的 participation ratio＝(Σλ)²/Σλ²：只在一兩個樣子之間晃接近 1–2，形狀一直在換會變大），跟 v2.7 的固定行進波比。
  //     只記錄、不判手感；另量身體蠕動平均與最大位移幾點、過程零自交、面積不漂
  { const clock = saveClock();
    function idleRun(ctl) {
      Math.random = seeded(20261103); resetAligned(1e9, ctl ? V27.clay : {});   // resetAligned(1e9)：不遊走，只看形狀
      const S = []; let peak = 0, worst = 0, minA = 9, maxA = 0;
      for (let f = 1; f <= 2880; f++) { update(DT);
        if (f % 30 === 0 && f > 120) { const v = []; for (const i of bnd) { if (TID[i] >= 0) continue; const dx = EX[i] - QX[i], dy = EY[i] - QY[i]; v.push(dx, dy); peak = Math.max(peak, Math.hypot(dx, dy)); } S.push(v); worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      const n = S.length, m = S[0].length, mu = new Float64Array(m); for (const v of S) for (let j = 0; j < m; j++) mu[j] += v[j] / n;
      const C = S.map(v => v.map((x, j) => x - mu[j])); let tr = 0, fr = 0, rms = 0;
      for (let a = 0; a < n; a++) { rms += Math.sqrt(S[a].reduce((s, x) => s + x * x, 0) / (m / 2)); for (let b = 0; b < n; b++) { let g = 0; for (let j = 0; j < m; j++) g += C[a][j] * C[b][j]; if (a === b) tr += g; fr += g * g; } }
      return { meanPt: +(rms / n).toFixed(2), peakPt: +peak.toFixed(2), shapes: +(tr * tr / fr).toFixed(2), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) };
    }
    res.T18_idleMorph = { now: idleRun(false), v27: idleRun(true) };
    restoreClock(clock); mat = { ...PRESETS.clay };
  }

  // T19 偽足（2026-11-01 多米：觸手會收回去、又從上面長出來；不是海星）：放著 40 秒，數長了幾條、有沒有長在上半邊，
  //     最遠伸出去幾點（邊界粒子離中心的距離減原形），過程零自交、面積不漂
  { const clock = saveClock(); Math.random = seeded(20261104); resetAligned(1e9); nextTwitch = 1e9;
    const seen = new Set(); let upper = 0, maxOut = 0, worst = 0, minA = 9, maxA = 0; const angs = [];
    for (let f = 1; f <= 2400; f++) { update(DT);
      for (const q of POD.list) if (!seen.has(q)) { seen.add(q); angs.push(+(q.a * 180 / Math.PI).toFixed(0)); if (Math.sin(q.a) < -0.3) upper++; }
      if (f % 10 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a);
        let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
        for (const i of bnd) maxOut = Math.max(maxOut, Math.hypot(X[i] - mx, Y[i] - my) - Math.hypot(Q0X[i], Q0Y[i])); } }
    res.T19_pods = { spawned: seen.size, upper, anglesDeg: angs, maxOutPt: +maxOut.toFixed(1), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T20 水母呼吸（2026-11-01 多米：規律的律動，像水母）：關掉偽足與蠕動，放著 30 秒，逐幀量身體寬高比（二階矩）與重心高度。
  //     收縮＝寬高比的谷底；量週期平均與標準差、寬高比擺幅、收縮佔一個週期的比例（從峰到谷）、上浮幾點
  { const clock = saveClock(); Math.random = seeded(20261105); resetAligned(1e9, { pods: 0, wriggle: 0 }); nextTwitch = 1e9;
    const asp = [], cy = [];
    for (let f = 1; f <= 1800; f++) { update(DT);   // 30 秒：幅度調小之後 15 秒只量得到 3 個週期，標準差被雜訊撐大
      let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
      // 在身體自己的座標裡量（扣掉整身轉動）：身體 5.3 秒一次的慢搖會改變畫面座標的寬高比，跟 3 秒的呼吸疊成假的不規律（量過標準差 0.18 秒）
      const ga = Math.atan2(globalC.sn, globalC.cs), gc = Math.cos(ga), gs = Math.sin(ga);
      let ixx = 0, iyy = 0; for (let i = 0; i < N; i++) { const dx = X[i] - mx, dy = Y[i] - my, bx = gc * dx + gs * dy, by = -gs * dx + gc * dy; ixx += bx * bx; iyy += by * by; }
      asp.push(Math.sqrt(ixx / iyy)); cy.push(my); }
    { const sm = asp.map((_, f) => { let s = 0, n = 0; for (let k = Math.max(0, f - 3); k <= Math.min(asp.length - 1, f + 3); k++) { s += asp[k]; n++; } return s / n; }); asp.splice(0, asp.length, ...sm); }   // 7 幀平均：幅度調小之後，谷底被逐幀雜訊拉偏（週期標準差 0.17 秒），先平滑再找
    const mins = [], maxs = []; for (let f = 2; f < asp.length - 2; f++) { if (asp[f] < asp[f - 1] && asp[f] <= asp[f + 1] && asp[f] < asp[f - 2] && asp[f] <= asp[f + 2]) mins.push(f); if (asp[f] > asp[f - 1] && asp[f] >= asp[f + 1] && asp[f] > asp[f - 2] && asp[f] >= asp[f + 2]) maxs.push(f); }
    const sig = (arr, keep) => { const o = []; for (const f of arr) if (!o.length || f - o[o.length - 1] > 60) o.push(f); else if (keep(f, o[o.length - 1])) o[o.length - 1] = f; return o; };
    const lo = sig(mins, (a, b) => asp[a] < asp[b]), hi = sig(maxs, (a, b) => asp[a] > asp[b]);
    const per = []; for (let k = 2; k < lo.length; k++) per.push((lo[k] - lo[k - 1]) * DT);   // 第一個週期是起步的過渡，不算
    const pm = per.reduce((s, x) => s + x, 0) / Math.max(1, per.length), ps = Math.sqrt(per.reduce((s, x) => s + (x - pm) ** 2, 0) / Math.max(1, per.length));
    const share = []; for (const m of lo) { const h = hi.filter(x => x < m).pop(); if (h !== undefined) share.push((m - h) * DT / pm); }
    const tail = asp.slice(120), cyt = cy.slice(120);
    res.T20_jelly = { contractions: lo.length, periodMean: +pm.toFixed(3), periodStd: +ps.toFixed(3), aspectSwing: +((Math.max(...tail) - Math.min(...tail)) / Math.max(...tail)).toFixed(3),
      contractShare: +(share.reduce((s, x) => s + x, 0) / Math.max(1, share.length)).toFixed(2), liftPt: +(Math.max(...cyt) - Math.min(...cyt)).toFixed(1) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T21 拉很長（2026-11-01 多米：拖拉時沒辦法拖很長，要能自由塑形）：抓身體最下面往下拉 2.5R（1 秒）、停 0.5 秒放手，
  //     量握著、放手後 0.5 秒與 3 秒最下面比原本多出幾個 R，過程與之後零自交、面積回來。往右拉在手機寬度會先撞到畫面邊，所以往下
  { const clock = saveClock(); Math.random = seeded(20261106); resetAligned(1e9); nextTwitch = 1e9;
    const reach = () => { let b = -1e9; for (const i of bnd) b = Math.max(b, Y[i]); return b; };
    let bi = -1; for (const i of bnd) if (bi < 0 || Y[i] > Y[bi]) bi = i;
    const r0 = reach(), sx = X[bi], sy = Y[bi] - R * 0.15; let worst = 0; ev('pointerdown', 1, sx, sy);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx, sy + R * 2.5 * k / 60); steps(1); worst = Math.max(worst, selfX()); }
    for (let k = 0; k < 30; k++) { steps(1); worst = Math.max(worst, selfX()); }
    const held = reach() - r0; ev('pointerup', 1, sx, sy + R * 2.5); steps(30); const a05 = reach() - r0; steps(150); const a3 = reach() - r0;
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T21_longPull = { heldR: +(held / R).toFixed(2), after05sR: +(a05 / R).toFixed(2), after3sR: +(a3 / R).toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T22 攤平（肉餅）：兩指抓左右兩邊各往外拉 0.9R（1 秒）、停 1 秒放手，量放手後 1 秒的寬高比（原本的倍數），零自交、面積回來。
  //     懸空的身體往下壓沒東西頂著，只會把頂端推進身體裡，所以用兩指攤開量
  { const clock = saveClock(); Math.random = seeded(20261107); resetAligned(1e9); nextTwitch = 1e9;
    const aspect = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return (x1 - x0) / (y1 - y0); };
    const a0 = aspect(), [lx, ly] = edgeX(-1), [rx, ry] = edgeX(1); let worst = 0; ev('pointerdown', 1, lx, ly); ev('pointerdown', 2, rx, ry);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, lx - R * 0.9 * k / 60, ly); ev('pointermove', 2, rx + R * 0.9 * k / 60, ry); steps(1); worst = Math.max(worst, selfX()); }
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); }
    const held = aspect() / a0; ev('pointerup', 1, lx - R * 0.9, ly); ev('pointerup', 2, rx + R * 0.9, ry); steps(60); const a1 = aspect() / a0;
    for (let k = 0; k < 120; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T22_flatten = { heldAspectX: +held.toFixed(2), after1sAspectX: +a1.toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T23 一壓就攤平（2026-11-01 多米想看看）：單指按在頂端往內 0.15R、往下壓 1R（1 秒）、停 1 秒放手，
  //     量握著與放手 1 秒的寬高比（原本的倍數）、握著時最低點有沒有穿過桌面（點）、零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261108); resetAligned(1e9, { pressFlat: 1 }); nextTwitch = 1e9;   // v2.12 起預設關，打開來測機制還在
    const box = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return [x0, x1, y0, y1]; };
    const b0 = box(), a0 = (b0[1] - b0[0]) / (b0[3] - b0[2]); let top = -1; for (const i of bnd) if (top < 0 || Y[i] < Y[top]) top = i;
    const sx = X[top], sy = Y[top] + R * 0.15; let worst = 0, below = 0; ev('pointerdown', 1, sx, sy);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx, sy + R * k / 60); steps(1); worst = Math.max(worst, selfX()); below = Math.max(below, box()[3] - b0[3]); }
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); below = Math.max(below, box()[3] - b0[3]); }
    const bh = box(), held = ((bh[1] - bh[0]) / (bh[3] - bh[2])) / a0; ev('pointerup', 1, sx, sy + R); steps(60);
    const b1 = box(), a1 = ((b1[1] - b1[0]) / (b1[3] - b1[2])) / a0; for (let k = 0; k < 120; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T23_pressFlat = { heldAspectX: +held.toFixed(2), after1sAspectX: +a1.toFixed(2), floorPassPt: +below.toFixed(1), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T24 拉長再從中間拖過身體（2026-11-01 多米：交叉時像快壞掉）：往下拉 2.5R、放手 0.3 秒，抓那條的中間往左上拖過身體（1 秒）、停 0.5 秒放手。
  //     逐幀數自交，ringGuard 開／關各跑一次比
  { const clock = saveClock();
    function crossRun(guard) { Math.random = seeded(20261109); resetAligned(1e9, { ringGuard: guard }); nextTwitch = 1e9;
      let bi = -1; for (const i of bnd) if (bi < 0 || Y[i] > Y[bi]) bi = i; const sx = X[bi], sy = Y[bi] - R * 0.15; let during = 0, frames = 0;
      ev('pointerdown', 1, sx, sy); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, sx, sy + R * 2.5 * k / 40); steps(1); } ev('pointerup', 1, sx, sy + R * 2.5); steps(18);
      const my = sy + R * 1.4; let xs = []; for (const i of bnd) if (Math.abs(Y[i] - my) < R * 0.2) xs.push(X[i]); const mx = xs.length ? (Math.min(...xs) + Math.max(...xs)) / 2 : sx;
      ev('pointerdown', 1, mx, my);
      for (let k = 1; k <= 60; k++) { ev('pointermove', 1, mx - R * 1.6 * k / 60, my - R * 2.6 * k / 60); steps(1); const c = selfX(); during = Math.max(during, c); if (c) frames++; }
      for (let k = 0; k < 30; k++) { steps(1); const c = selfX(); during = Math.max(during, c); if (c) frames++; }
      ev('pointerup', 1, mx - R * 1.6, my - R * 2.6); let after = 0; for (let k = 0; k < 120; k++) { steps(1); const c = selfX(); after = Math.max(after, c); if (c) frames++; }
      log.splice(0); return { worstDuring: during, worstAfter: after, crossFrames: frames, end: snap() }; }
    res.T24_dragAcross = { guard: crossRun(1), noGuard: crossRun(0) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T25 按在畫面邊停住（v2.15 改）：v2.12 起停著的手指會跟著鏡頭在世界裡往外跑、形狀一直長，那就是多米 build 61 回報的抽搐來源。
  //     現在抓身體最右邊拖到畫面右緣停 3 秒：伸出去要有（鏡頭有退），停著的 3 秒形狀不能自己再長；放手後鏡頭跟著拉回來、零自交
  { const clock = saveClock(); Math.random = seeded(20261110); resetAligned(1e9); nextTwitch = 1e9;
    const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
    let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const e0 = X[b], sx = X[b] - R * 0.15, sy = Y[b]; let worst = 0, zMin = 1;
    ev('pointerdown', 1, sx, sy); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, sx + (W - 12 - sx) * k / 40, sy); steps(1); worst = Math.max(worst, selfX()); }
    steps(30); const w1 = wd();
    for (let k = 0; k < 150; k++) { steps(1); worst = Math.max(worst, selfX()); zMin = Math.min(zMin, CAM.z); }
    const w2 = wd(); let e1 = -1e9; for (const i of bnd) e1 = Math.max(e1, X[i]); ev('pointerup', 1, W - 12, sy);
    for (let k = 0; k < 720; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
    res.T25_edgeHold = { reachR: +((e1 - e0) / R).toFixed(2), grewWhileStillR: +(w2 - w1).toFixed(2), zoomMin: +zMin.toFixed(2), zoomAfter12s: +CAM.z.toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T26 鏡頭無限拉遠（v2.13 起；v2.15 改成重複抓）：手指停著不再自己拉長，要拉更長就放手、抓住最右端再拉，拉 6 次。
  //     手指從那一端拖到畫面右緣（手指出不了螢幕），每次停 1 秒帶一點手抖（±0.6 點）。量最長幾個 R、鏡頭縮到多少、整隻每幀都在畫面裡、按著時邊界每幀最大跳動（螢幕點），
  //     放手後零交叉。黏土拉伸 7R、記形 5R：超過約 8.5R 會抖（v2.15 量過拉到 9.5R 跳 13 到 22 點、交叉）
  { const clock = saveClock(); Math.random = seeded(20261113); resetAligned(1e9); nextTwitch = 1e9;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    let wMax = 0, zMin = 1, off = 0, holdX = 0, worstRel = 0, jMax = 0;
    for (let r = 0; r < 6; r++) {
      let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const wx = X[b] - R * 0.15, wy = Y[b];
      let [qx, qy] = sc(wx, wy); ev('pointerdown', 1, qx, qy); const f = [...fingers.values()][0];
      const q0 = qx; for (let k = 1; k <= 45; k++) { qx = q0 + (W - 12 - q0) * k / 45; ev('pointermove', 1, qx, qy); steps(1); }
      let prev = null, prev2 = null;
      for (let k = 0; k < 60; k++) { ev('pointermove', 1, qx + (Math.random() - 0.5) * 1.2, qy + (Math.random() - 0.5) * 1.2); steps(1);
        const cur = bnd.map(i => sc(X[i], Y[i]));
        if (prev2) for (let m = 0; m < cur.length; m++) jMax = Math.max(jMax, Math.hypot(cur[m][0] - 2 * prev[m][0] + prev2[m][0], cur[m][1] - 2 * prev[m][1] + prev2[m][1]));
        prev2 = prev; prev = cur; if (k % 3 === 0 && selfX()) holdX++;
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); }
        wMax = Math.max(wMax, (x1 - x0) / R); zMin = Math.min(zMin, CAM.z);
        const a = sc(x0, y0), c = sc(x1, y1); if (a[0] < 0 || c[0] > W || a[1] < 0 || c[1] > H) off++; }
      ev('pointerup', 1, qx, qy); for (let k = 0; k < 60; k++) { steps(1); if (k % 6 === 0) worstRel = Math.max(worstRel, selfX()); }
    }
    for (let k = 0; k < 600; k++) { steps(1); if (k % 10 === 0) worstRel = Math.max(worstRel, selfX()); }
    res.T26_zoomUnlimited = { widthMaxR: +wMax.toFixed(2), zoomMin: +zMin.toFixed(2), offScreenFrames: off, holdCrossFrames: holdX, jitterMaxPt: +jMax.toFixed(2), worstReleaseX: worstRel, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T29 手指停住不抖（v2.15，多米 build 61：拉到某個程度會抽搐）：抓最右邊往右拉 1、2、3R 各停 2 秒帶手抖，形狀不能自己長、邊界每幀最大跳動
  { const clock = saveClock(); const r29 = [];
    for (const d of [1, 2, 3]) { Math.random = seeded(20261116 + d); resetAligned(1e9); nextTwitch = 1e9;
      const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
      let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const wx = X[b] - R * 0.15, wy = Y[b];
      let [qx, qy] = sc(wx, wy); ev('pointerdown', 1, qx, qy); const f = [...fingers.values()][0];
      for (let k = 1; k <= 60; k++) { qx += (wx + d * R * k / 60 - f.x) * CAM.z; ev('pointermove', 1, qx, qy); steps(1); }
      steps(30); const w1 = wd(); let prev = null, prev2 = null, jMax = 0, xf = 0;
      for (let k = 0; k < 120; k++) { ev('pointermove', 1, qx + (Math.random() - 0.5) * 1.2, qy + (Math.random() - 0.5) * 1.2); steps(1);
        const cur = bnd.map(i => sc(X[i], Y[i]));
        if (prev2) for (let m = 0; m < cur.length; m++) jMax = Math.max(jMax, Math.hypot(cur[m][0] - 2 * prev[m][0] + prev2[m][0], cur[m][1] - 2 * prev[m][1] + prev2[m][1]));
        prev2 = prev; prev = cur; if (selfX()) xf++; }
      r29.push({ pullR: d, widthR: +wd().toFixed(2), grewR: +(wd() - w1).toFixed(2), jitterMaxPt: +jMax.toFixed(2), crossFrames: xf }); ev('pointerup', 1, qx, qy); steps(30); }
    res.T29_stillFinger = r29; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T30 點一下留凹痕（v2.15，多米 build 61：單純點一下也要有效果，也許是出現凹陷）：點身體中間 0.1 秒，凹痕要出現；放手 15 秒還看得到、淡了一些；
  //     按住拉開 1R 的那次凹痕要收掉
  { const clock = saveClock(); Math.random = seeded(20261117); resetAligned(1e9); nextTwitch = 1e9;
    const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(6); const dHeld = DENTS.length ? DENTS[DENTS.length - 1].d : 0; ev('pointerup', 1, cx, cy);
    steps(60); const d1 = DENTS.length ? DENTS[0].d : 0; steps(840); const d15 = DENTS.length ? DENTS[0].d : 0;
    resetAligned(1e9); nextTwitch = 1e9; ev('pointerdown', 1, cx, cy); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx + R * k / 30, cy); steps(1); } steps(30);
    ev('pointerup', 1, cx + R, cy); steps(60);
    res.T30_dent = { heldDepth: +dHeld.toFixed(2), after1s: +d1.toFixed(2), after15s: +d15.toFixed(2), dentsAfterPull: DENTS.length, end: snap() };
    log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T27 從身體中間往外拉（v2.14，多米 build 59：只有從邊緣才拖得動，從中間往外拉沒反應；量過右邊緣反而退 0.08R）：
  //     從重心往右、往上各拉 2R 花 1 秒、停 1 秒，量那一側外圈跟出去多少；零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261114); const r27 = {};
    for (const [name, ux, uy] of [['right', 1, 0], ['up', 0, -1]]) {
      resetAligned(1e9); nextTwitch = 1e9; const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      let x0 = 1e9, x1 = -1e9, y0 = 1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); }
      const cx = globalC.xc, cy = globalC.yc; let worst = 0, q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]); const f27 = [...fingers.values()][0];
      // v2.15 起手指在世界裡只跟著螢幕位移 ÷ 鏡頭倍率走：每幀照「世界目標 − 手指現在的世界位置」補螢幕位移
      for (let k = 1; k <= 120; k++) { const a = Math.min(1, k / 60) * 2 * R; q = [q[0] + (cx + ux * a - f27.x) * CAM.z, q[1] + (cy + uy * a - f27.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (k % 3 === 0) worst = Math.max(worst, selfX()); }
      let x1b = -1e9, y0b = 1e9; for (const i of bnd) { x1b = Math.max(x1b, X[i]); y0b = Math.min(y0b, Y[i]); }
      ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 300; k++) { steps(1); if (k % 5 === 0) worst = Math.max(worst, selfX()); }
      r27[name] = { edgeMovedR: +((ux ? x1b - x1 : y0 - y0b) / R).toFixed(2), worstSelfX: worst, end: snap() };
    }
    res.T27_pullFromMiddle = r27; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T28 回彈速度（v2.14，多米 build 59：回彈太快；recover 0.3 時拉 3R 放手 2 秒就退一半）：抓最右邊往右拉 3R、停 2 秒放手，
  //     量放手 2 秒、15 秒還留著幾成拉出來的寬度
  { const clock = saveClock(); Math.random = seeded(20261115); resetAligned(1e9); nextTwitch = 1e9;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
    const w0 = wd(); let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b];
    let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]);
    for (let k = 1; k <= 180; k++) { q = sc(sx + 3 * R * Math.min(1, k / 60), sy); ev('pointermove', 1, q[0], q[1]); steps(1); }
    const wh = wd(); ev('pointerup', 1, q[0], q[1]); steps(120); const w2 = wd(); steps(780); const w15 = wd();
    res.T28_relax = { heldR: +wh.toFixed(2), keep2s: +((w2 - w0) / (wh - w0)).toFixed(2), keep15s: +((w15 - w0) / (wh - w0)).toFixed(2), end: snap() };
    log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T3 的對折幀數留著只記錄；交疊（跨群）是設計允許的，永遠只記錄
  res.KNOWN_ISSUES = { T3_compressionFoldFrames: res.T3_pull.foldFrames, T3_foldStillHeld: res.T3_pull.during.fold, T4_foldFrames: res.T4_twoFinger.foldFrames, T4_foldStillHeld: res.T4_twoFinger.during.fold, T5_foldFrames: res.T5_flail.foldFrames, T13_pinchFoldFrames: res.T13_pinch.foldFrames, T26_holdCrossFrames: res.T26_zoomUnlimited.holdCrossFrames };
  res.PASS = {
    // folds must be gone once the finger is off (a fold the clay remembers would be a real bug)
    noFoldAfterRelease: [res.T1_tap.after2s, res.T2_hold.afterRelease1s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(s => s.fold === 0) && res.T7_idle.worstSelfX === 0,
    areaBack: [res.T1_tap.after2s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(okArea) && res.T7_idle.areaMin > 0.97 && res.T7_idle.areaMax < 1.03,
    firstFrameMoves: res.T1_tap.firstFrameMove > 1,
    // 2026-11-01 多米真機回報後：黏土留痕放著約 10 秒退掉；輕按 0.1 秒留多少只記錄（T1.after2s.qdev）
    tapMarkGone: res.T1_tap.after12s.qdev < 1,
    holdLeavesMark: res.T2_hold.afterRelease1s.qdev > 3,
    relaxClearsMark: res.T2_hold.afterRelax1s.qdev < 1,
    slowReleaseStillPops: rel(res.T3_pull.sfx) > 0.7,
    flickPops: rel(res.T9_flick.sfx) > 0.9,
    pushMakesPressSound: res.T6_push.sfx.some(e => e[0] === 'press'),
    cancelIsSilent: !res.T8_cancel.sfx.some(e => e[0] === 'release') && res.T8_cancel.fingersLeft === 0,
    candidatesDontBreak: res.T10_candidates.worstSelfX === 0 && okArea(res.T10_candidates.after) && res.T10_candidates.releases.length === 3,
    // 第 41 條修好的標準：握著時不能還留著對折；短暫幾幀（手指正好壓在接點上）先容忍，數字記在 T11
    // 2026-11-01 的水準：握著還在對折最多 1 個情境（手指正好壓在接點上）、對折幀數 100 以內；v2.4 以前是 6 個、282 幀
    // v2.9 起量的是 v2.7 對照（舊外形）：回到 v2.8 以前的判定，握著還對折最多 1 個情境、對折幀數 100 以內
    compressionFoldsRare: res.T11_compressionGrid.heldFoldRuns <= 1 && res.T11_compressionGrid.foldFrames < 100,
    // 第 20 條：拖尾只是表演，走完要收回來、過程不能自交或漏面積
    wanderTailClean: res.T12_wander.worstSelfX === 0 && res.T12_wander.areaMin > 0.97 && res.T12_wander.areaMax < 1.03 && res.T12_wander.afterStopPt < 1.5 && res.T12_wander.controlSame,
    // 第三批其餘（2026-11-01）：24 兩指捏要有 squish；25 滑脫要真的脫手、只啵一次；26 黏連要晚放、快甩不黏；候選全開也不壞
    pinchSquishes: res.T13_pinch.squishEvents >= 2 && res.T13_pinch.after3s.fold === 0 && okArea(res.T13_pinch.after3s),
    slipLetsGo: res.T14_slip.slipRelease === 1 && res.T14_slip.slipGain >= 0.99 && res.T14_slip.grabbedAfterSlip === 0 && res.T14_slip.popAfterLift === 0,
    stickDelaysPop: res.T15_stick.slow.popFrame >= 6 && res.T15_stick.slow.heldAtLift > 0 && res.T15_stick.slow.fingersLeft === 0 && res.T15_stick.fastImmediate,
    // 捏觸手要留痕、慢慢退；v2.7 對照應該一秒內就幾乎彈回（量法本身還抓得到差別）。過程零自交、面積回來
    // v2.14 起回原形放慢到 0.05（多米 build 59：回彈太快）：12 秒還在慢慢退（少於 1 秒時的 75%），不再要求退完
    pullKeepsMark: res.T17_pullMark.now.after1s > 3 && res.T17_pullMark.now.after12s < res.T17_pullMark.now.after1s * 0.75 && res.T17_pullMark.now.foldFramesAfter === 0 && okArea(res.T17_pullMark.now.end),
    podsGrowAnywhere: res.T19_pods.spawned >= 4 && res.T19_pods.upper > 0 && res.T19_pods.worstSelfX === 0 && res.T19_pods.areaMin > 0.95 && res.T19_pods.areaMax < 1.05 && res.T19_pods.maxOutPt > 0.25 * res.R,
    // 2026-11-01 多米：要能拉很長、攤很扁。往下拉 2.5R 握著要伸出 2R 以上、放手半秒還留 1.5R（之後照 recover 約 10 秒退）；
    // 兩指攤開放手 1 秒寬高比還是原本 1.3 倍以上；都不能自交、面積要回來
    sculptLong: res.T21_longPull.heldR > 2 && res.T21_longPull.after05sR > 1.5 && res.T21_longPull.worstSelfX === 0 && okArea(res.T21_longPull.end),
    sculptFlat: res.T22_flatten.after1sAspectX > 1.3 && res.T22_flatten.worstSelfX === 0 && okArea(res.T22_flatten.end),
    // 一壓就攤平：握著寬高比 1.5 倍以上、放手 1 秒還有 1.3 倍、最低點不穿過桌面超過 3 點；邊不能穿邊：拖過身體時交叉幀數比關掉時少、放手後沒有交叉
    pressFlattens: res.T23_pressFlat.heldAspectX > 1.5 && res.T23_pressFlat.after1sAspectX > 1.3 && res.T23_pressFlat.floorPassPt < 3 && res.T23_pressFlat.worstSelfX === 0 && okArea(res.T23_pressFlat.end),
    noCrossing: res.T24_dragAcross.guard.worstAfter === 0 && res.T24_dragAcross.guard.crossFrames <= res.T24_dragAcross.noGuard.crossFrames,
    // 鏡頭跟著拉遠：按在畫面右緣 3 秒要伸出 2.5R 以上（以前卡在 1.1R），放手 12 秒鏡頭回到 0.95 以上
    // 鏡頭無限拉遠（重複抓）：寬過 7R、鏡頭縮過 0.45、整隻一直在畫面裡、按著時邊界每幀跳動不到 3 點、放手後零交叉、面積回來
    zoomUnlimited: res.T26_zoomUnlimited.widthMaxR > 7 && res.T26_zoomUnlimited.zoomMin < 0.45 && res.T26_zoomUnlimited.offScreenFrames === 0 && res.T26_zoomUnlimited.jitterMaxPt < 3 && res.T26_zoomUnlimited.worstReleaseX === 0 && res.T26_zoomUnlimited.end.selfX === 0 && okArea(res.T26_zoomUnlimited.end),
    // 手指停住：形狀不自己長（< 0.3R）、邊界每幀跳動不到 3 點、零交叉
    stillFingerSteady: res.T29_stillFinger.every(r => r.grewR < 0.3 && r.jitterMaxPt < 3 && r.crossFrames === 0),
    // 點一下：按 0.1 秒凹痕深過 0.5、1 秒後還在、15 秒淡了但還看得到（0.15 以上）；拉開的那次凹痕收掉
    dentOnTap: res.T30_dent.heldDepth > 0.5 && res.T30_dent.after1s > 0.5 && res.T30_dent.after15s > 0.15 && res.T30_dent.after15s < res.T30_dent.after1s && res.T30_dent.dentsAfterPull === 0,
    // 從中間往右、往上拉 2R，那一側外圈要跟出去 1.5R 以上（v2.13 是 -0.08R）；零自交、面積回來
    pullFromMiddle: ['right', 'up'].every(k => res.T27_pullFromMiddle[k].edgeMovedR > 1.5 && res.T27_pullFromMiddle[k].worstSelfX === 0 && okArea(res.T27_pullFromMiddle[k].end)),
    // 回彈：放手 2 秒還留八成以上（v2.13 約五成）
    relaxSlow: res.T28_relax.keep2s > 0.8 && res.T28_relax.end.selfX === 0,
    // 按在畫面邊：手指能走多遠就伸多遠（手機寬約 1.2R 以上）、鏡頭有退，停著的 3 秒不能自己長超過 0.3R（v2.14 會一直長）
    edgeHoldStretches: res.T25_edgeHold.reachR > 1.2 && res.T25_edgeHold.zoomMin < 0.95 && res.T25_edgeHold.grewWhileStillR < 0.3 && res.T25_edgeHold.zoomAfter12s > res.T25_edgeHold.zoomMin + 0.1 && res.T25_edgeHold.worstSelfX === 0 && okArea(res.T25_edgeHold.end),
    jellyRegular: Math.abs(res.T20_jelly.periodMean - PRESETS.clay.jellyT) < 0.15 && res.T20_jelly.periodStd < 0.1 && res.T20_jelly.aspectSwing > 0.05 && res.T20_jelly.contractShare < 0.4,
    idleMorphClean: res.T18_idleMorph.now.worstSelfX === 0 && res.T7_idle.worstSelfX === 0 && res.T18_idleMorph.now.areaMin > 0.97 && res.T18_idleMorph.now.areaMax < 1.03,
    batch3DontBreak: res.T16_batch3.worstSelfX === 0 && okArea(res.T16_batch3.after) && res.T16_batch3.areaMin > 0.97 && res.T16_batch3.areaMax < 1.03 && res.T16_batch3.releases === 3,
  };
  res.ALL_PASS = Object.values(res.PASS).every(Boolean);

  draw();
  sfxPlay = origPlay; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  console.log(JSON.stringify(res, null, 1));
  return res;
})();
