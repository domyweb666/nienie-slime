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
  const VIEW0 = { ...VIEW }; Object.assign(VIEW, { skin: 'flat', body: 'tent', face: 0, bg: 'blue' });   // v2.28 預覽：舊項目量的是 v2.27 的畫面與外形，跑完還原
  window.requestAnimationFrame = () => 0;
  await new Promise(r => setTimeout(r, 80));
  const log = [];
  const origPlay = sfxPlay;
  sfxPlay = (k, g, r) => { log.push([k, +(+g).toFixed(3), +(+(r || 1)).toFixed(3)]); };
  const DT = 1 / 60;
  // 音效引擎不准碰測試的亂數（2026-11-03）：音效檔載完之後引擎每幀抽 Math.random，把各項用固定種子產生的手抖序列錯開；載完的時間點落在第一輪中途，
  // 第一輪跟之後幾輪抽到的手抖不一樣（v2.16 到 v2.23 每版第一輪 T26 都是 3.25、之後 1.3 左右，就是這個）。跑 selftest 時音效那一幀改用真的亂數，跑完換回
  const realRandom0 = Math.random, sfxFrame0 = SFX && SFX.frame;
  if (SFX) SFX.frame = (...a) => { const r = Math.random; Math.random = realRandom0; try { return sfxFrame0.apply(SFX, a); } finally { Math.random = r; } };
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
  // v2.20：舊項目量的是 v2.19 的行為，一律關掉拖著走、凹痕退快、印象（跟關情緒、關活物一樣）；v2.20 在 T35 用 P0 打開（拉力 slide 0），v2.21 拉力在 T36。跑完換回來
  // 三種材質都換（舊項目也用果凍、麻糬的預設）
  // v2.23：新功能（黏液 v2.23、眼睛、睡著、節奏、游過來）舊項目一律關；T35 到 T37 用 P0（v2.23 關），T38 用 P1（全開）
  // v2.24：舊項目與 T35 到 T38 一律回 v2.23（OFF24：身體 0.22、舊鏡頭、舊幅度、舊揉的門檻），v2.24 只在 T39 測（用 PSAVE 全開）
  const P1 = { ...PRESETS.clay, ...OFF24 }, OFF23 = { dropsV: 0, eyes: 0, sleep: 0, echo: 0, introSwim: 0 }, P0 = { ...P1, ...OFF23 }, P27 = { ...PRESETS }, PSAVE = {}; for (const k in PRESETS) PSAVE[k] = { ...PRESETS[k], ...OFF27 }; for (const k in PRESETS) PRESETS[k] = { ...PRESETS[k], ...OFF24, slide: 0, drag: 0, dentFade: 10, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, drops: 0, ...OFF23 };
  // reset 也要停掉遊走：setup() 把家放回中間，但上一輪留下的遊走還在走，家會繼續往遊走目標移，60 步內身體就飄開（量過飄 58 點，
  // 兩指捏的手指按到身體外面，只有一指抓到）。2026-11-01 v2.14 發現，之前連跑過是遊走剛好停著
  function reset() { mat = { ...PRESETS.clay, emo: 0, life2: 0 }; setup();   // emo 0：情緒（逃跑、閃開）會把身體移走，回歸測試量的是物理；情緒在 T33 測；life2 0：v2.19 活物感另外在 T34 測
  WANDER.moving = false; WANDER.next = t + 5; steps(60); }
  // 固定亂數＋歸零時鐘，T11、T12 用：結果可重現。setup() 不重設時鐘；時鐘動過要還原，不然上一輪 T2 的 relaxUntil 留在未來，下一輪的記形會被當成「揉回原形」
  function seeded(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const realRandom = Math.random;
  const saveClock = () => ({ t, lastTouch, nextTwitch, tLife, relaxUntil, wNext: WANDER.next, wMoving: WANDER.moving });
  function restoreClock(c) { ({ t, lastTouch, nextTwitch, tLife, relaxUntil } = c); WANDER.next = c.wNext; WANDER.moving = c.wMoving; Math.random = realRandom; }
  function resetAligned(wanderNext, over) { mat = { ...PRESETS.clay, emo: 0, life2: 0, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; specialUntil = -1; releaseCount = 0; nextSpecial = 0; BR.phase = 0; BR.tlPrev = 0; WANDER.moving = false; WANDER.next = wanderNext; steps(60); }

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
  //     跳動門檻 5 點（原本 3）：2026-11-03 同一套物理換 8 組手抖（種子），量到 1.18 到 4.21 點，3 點卡在正常範圍中間；真的抖是 13 點以上
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

  // T31 按壓（v2.16，多米：按壓動畫像兒戲）：黏土按住身體中間 0.8 秒，整團面積要變大 4% 到 15%（press2=0 是 1.00）；按 3 秒跟 1.5 秒比，
  //     最遠位移不能一直長（黏土記下推開的形狀、再推一次的話會一直攤開）；放手 1 秒凹痕還在。果凍放手要過頭往外彈（p 掉到負的）、1 秒內收乾淨。全程零自交
  { const clock = saveClock(); Math.random = seeded(20261118); const r31 = {}; let xf = 0;
    const hold = (over, n) => { resetAligned(1e9, over); nextTwitch = 1e9; const cx = globalC.xc, cy = globalC.yc, a0 = area(), ref = [Float64Array.from(X), Float64Array.from(Y)];
      ev('pointerdown', 1, cx, cy); const mv = []; let am = 0; for (let k = 1; k <= n; k++) { steps(1); if (classify()[0]) xf++; if (k === 48) am = area() / a0; if (k === 90 || k === 180) mv.push(maxMove(ref)); }
      return { cx, cy, a0, am, mv }; };
    { const h = hold({}, 180); r31.clayArea08 = +h.am.toFixed(3); r31.clayMove15 = +h.mv[0].toFixed(1); r31.clayMove3 = +h.mv[1].toFixed(1);
      ev('pointerup', 1, h.cx, h.cy); steps(60); r31.clayDent1s = DENTS.length ? +DENTS[DENTS.length - 1].d.toFixed(2) : 0; }
    { const h = hold({ press2: 0 }, 48); r31.offArea08 = +h.am.toFixed(3); ev('pointerup', 1, h.cx, h.cy); steps(30); }
    { const h = hold({ ...PRESETS.jelly }, 48); ev('pointerup', 1, h.cx, h.cy); let pMin = 1; for (let k = 0; k < 60; k++) { steps(1); if (classify()[0]) xf++; for (const dn of DENTS) pMin = Math.min(pMin, dn.p); }
      r31.jellyArea08 = +h.am.toFixed(3); r31.jellyOvershoot = +pMin.toFixed(2); r31.jellyDentsAfter1s = DENTS.length; }
    r31.foldFrames = xf; r31.end = snap();
    res.T31_press = r31; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T32 開場與鏡頭跟隨（v2.17，多米：打開時從遠處一跳一跳跑過來；鏡頭不要釘在中間，史萊姆會跑出畫面，鏡頭慢慢跟）：
  //     開場要落地 4 次、落地那幾幀高寬比壓到平常的 0.9 以下、3.2 秒內結束、全程零對折、結束後面積回來；途中碰一下直接到家（0.5 秒內大小回到 1）；
  //     家往右移 0.6 個畫面寬：身體要有一段跑出畫面、4 秒後鏡頭追到 followStop 附近（v2.18 起不拉回正中間）；抓著時鏡頭不動
  { const clock = saveClock(); Math.random = seeded(20261119); const r32 = {}; let xf = 0;
    const asp = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return (y1 - y0) / (x1 - x0); };
    resetAligned(1e9); nextTwitch = 1e9; const a0 = asp(); startIntro(); let lands = 0, prev = INTRO.ph, minA = 9, fr = 0;
    while (INTRO.on && fr < 600) { steps(1); fr++; if (classify()[0]) xf++; if (INTRO.ph === 'land' && prev !== 'land') lands++; if (INTRO.ph === 'land') minA = Math.min(minA, asp()); prev = INTRO.ph; }
    steps(120); r32.introLands = lands; r32.introSec = +(fr / 60).toFixed(2); r32.landAspect = +(minA / a0).toFixed(2); r32.afterIntro = snap();
    resetAligned(1e9); nextTwitch = 1e9; startIntro(); steps(40); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 2, cx, cy); ev('pointerup', 2, cx, cy); }
    steps(30); r32.skipOff = !INTRO.on; r32.skipScale = +IV.s.toFixed(3); r32.skipFingers = fingers.size;
    resetAligned(1e9); nextTwitch = 1e9; WANDER.next = 1e9; const v = viewV(), H0 = HOMEX, half = (W - 16) / 2; let outMax = -1e9;
    for (let k = 1; k <= 240; k++) { HOMEX = H0 + W * 0.6 * Math.min(1, k / 150); steps(1); if (classify()[0]) xf++; let x1 = -1e9; for (const i of bnd) x1 = Math.max(x1, (X[i] - CAM.x) * CAM.z + v.x); outMax = Math.max(outMax, x1 - W); }
    r32.followOutPt = +outMax.toFixed(0); r32.followEndOff = +(Math.abs((globalC.xc - CAM.x) * CAM.z) / half).toFixed(2);
    { const cx = (globalC.xc - CAM.x) * CAM.z + v.x, cy = (globalC.yc - CAM.y) * CAM.z + v.y, c0 = CAM.x; ev('pointerdown', 3, cx, cy); steps(60); r32.grabCamMovePt = +Math.abs(CAM.x - c0).toFixed(2); ev('pointerup', 3, cx, cy); steps(60); }
    r32.foldFrames = xf; r32.end = snap();
    res.T32_introFollow = r32; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T33 情緒（v2.18，多米：被拉扯想逃、舒服時呼嚕）：抓右緣往右拉 2.2R 撐 1.5 秒，想逃要滿（strain > 0.8）、舒服掉到負的；放手要開始逃、
  //     2.5 秒後家往左（拉的反方向）移超過 0.4 個畫面寬。中間輕揉 2.5 秒（半徑 0.25R 的小圈），舒服 > 0.3、呼嚕 > 0.3，放手要開心小跳。
  //     1 秒內戳 3 下要閃開（2 秒後移超過 0.15 個畫面寬）。全程零對折、逃完面積回來
  { const clock = saveClock(); Math.random = seeded(20261120); const r33 = {}; let xf = 0; const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b], h0 = HOMEX;
    let q = sc(sx, sy), sMax = 0; ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);   // 手指用累加位移（鏡頭拉的時候會動，世界換螢幕會讓手指退回來）
    for (let k = 1; k <= 120; k++) { const tx = sx + 2.2 * R * Math.min(1, k / 30); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; sMax = Math.max(sMax, MOOD.strain); }
    r33.strainHeld = +sMax.toFixed(2); r33.moodPulled = +MOOD.c.toFixed(2); ev('pointerup', 1, q[0], q[1]); r33.fleeStarted = ESC.on;
    for (let k = 0; k < 150; k++) { steps(1); if (classify()[0]) xf++; } r33.fledW = +((h0 - HOMEX) / W).toFixed(2); steps(120); r33.afterFlee = snap();
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; { const cx = globalC.xc, cy = globalC.yc; let pMax = 0, cMax = 0; q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]);
      for (let k = 1; k <= 150; k++) { const a = 2 * Math.PI * 0.5 * k / 60; q = sc(cx + R * 0.25 * Math.sin(a), cy + R * 0.25 * (1 - Math.cos(a))); ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; pMax = Math.max(pMax, PURR); cMax = Math.max(cMax, MOOD.c); }
      ev('pointerup', 1, q[0], q[1]); r33.purrMax = +pMax.toFixed(2); r33.comfortMax = +cMax.toFixed(2); r33.happyHop = INTRO.on && !!INTRO.mini; for (let k = 0; k < 90; k++) { steps(1); if (classify()[0]) xf++; } }
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; { const h1x = HOMEX, h1y = HOMEY, cx = globalC.xc + R * 0.2, cy = globalC.yc; q = sc(cx, cy);
      for (let n = 0; n < 3; n++) { ev('pointerdown', 1, q[0], q[1]); steps(5); ev('pointerup', 1, q[0], q[1]); steps(10); }
      r33.dartStarted = ESC.on; for (let k = 0; k < 120; k++) { steps(1); if (classify()[0]) xf++; } r33.dartW = +(Math.hypot(HOMEX - h1x, HOMEY - h1y) / W).toFixed(2); }
    r33.foldFrames = xf; r33.end = snap();
    res.T33_mood = r33; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T34 活物感（v2.19，多米 build 73：沒有活物感、不像生物）。a 放著不碰 120 秒：休息（沒走、沒探）佔 0.35 到 0.65（v2.18 量到 0.02），有探有走，零自交、面積不漂；
  //     b 按住中間 4 秒：呼吸還在（寬高比起伏是沒碰時的 0.35 以上，lifeHeld 0 時 0.15 以下）；放手 1 秒記形偏移不比 lifeHeld 0 多 1pt 以上（呼吸沒被記進形狀）；
  //     c 晚一拍才縮：按下 0.05 秒面積跟 lifeFlinch 0 差不到 1.5%、0.3 秒時小 4% 以上；連按 5 下（間隔 0.6 秒），第 5 下不到第 1 下的三成；
  //     d 一縮一衝：叫它往右走 1.5 個畫面寬，八成以上的下速度高峰落在這一下開始 0.35 秒內（收縮推它走），方向有變（最大減最小 > 8 度），停在目標 0.5R 內，零自交、面積不漂；
  //     e 碰它右邊 1.8R 的空白處：0.6 秒內有一條偽足朝右（30 度內），按著時呼吸縮放還在變（沒凍住）；
  //     f 抓右緣拉 1.6R 放手：0.25 到 0.45 秒開始甩、0.4 到 0.8 秒往手指離開的方向探（30 度內）。全程零對折
  { const clock = saveClock(); Math.random = seeded(20261121); const r34 = {}; let xf = 0;
    const L2 = o => resetAligned(1e9, { life2: 1, ...o });
    const aspect = () => { let mx = 0, my = 0; for (const i of bnd) { mx += X[i]; my += Y[i]; } mx /= bnd.length; my /= bnd.length; const ga = Math.atan2(globalC.sn, globalC.cs), gc = Math.cos(ga), gs = Math.sin(ga); let ixx = 0, iyy = 0; for (const i of bnd) { const dx = X[i] - mx, dy = Y[i] - my, bx = gc * dx + gs * dy, by = -gs * dx + gc * dy; ixx += bx * bx; iyy += by * by; } return Math.sqrt(ixx / iyy); };
    { L2({ emo: 1 }); const S = { rest: 0, look: 0, go: 0, arrive: 0 }, seen = new Set(); let goes = 0, prev = '', worst = 0, minA = 9, maxA = 0;
      for (let f = 0; f < 7200; f++) { steps(1); S[LIFE.st]++; if (LIFE.st === 'go' && prev !== 'go') goes++; prev = LIFE.st; for (const s of LIFE.sns) seen.add(s);
        if (f % 20 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      r34.idle = { restFrac: +(S.rest / 7200).toFixed(2), lookFrac: +(S.look / 7200).toFixed(2), goFrac: +(S.go / 7200).toFixed(2), goes, sniffs: seen.size, worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) }; }
    const held = o => { L2({ pods: 0, wriggle: 0, ...o }); LIFE.until = 1e9; let lo = 9, hi = 0; for (let k = 0; k < 360; k++) { steps(1); const a = aspect(); lo = Math.min(lo, a); hi = Math.max(hi, a); } const idle = hi - lo;
      const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(60); lo = 9; hi = 0; for (let k = 0; k < 240; k++) { steps(1); if (classify()[0]) xf++; const a = aspect(); lo = Math.min(lo, a); hi = Math.max(hi, a); }
      ev('pointerup', 1, cx, cy); steps(60); return { ratio: +((hi - lo) / idle).toFixed(2), qdev1s: +qdev().toFixed(2) }; };
    { const on = held({}), off = held({ lifeHeld: 0 }); r34.held = { ratio: on.ratio, ratioOff: off.ratio, qdev1s: on.qdev1s, qdev1sOff: off.qdev1s }; }
    const tapA = o => { L2(o); LIFE.until = 1e9; const cx = globalC.xc, cy = globalC.yc, a0 = area(); ev('pointerdown', 1, cx, cy); steps(3); const a05 = area() / a0; steps(15); const a30 = area() / a0; ev('pointerup', 1, cx, cy); steps(60); return { a05, a30 }; };
    { const on = tapA({}), off = tapA({ lifeFlinch: 0 }); L2({}); LIFE.until = 1e9; const amps = [], cx = globalC.xc, cy = globalC.yc;
      for (let n = 0; n < 5; n++) { ev('pointerdown', 1, cx, cy); steps(6); ev('pointerup', 1, cx, cy); steps(30); amps.push(FLN.last); }
      r34.flinch = { at05: +(on.a05 / off.a05).toFixed(3), at30: +(on.a30 / off.a30).toFixed(3), fifthOverFirst: +(amps[4] / amps[0]).toFixed(2) }; }
    { L2({ dash: 0 }); LIFE.until = 1e9; const tx = HOMEX + W * 1.5, ty = HOMEY; Object.assign(GAIT, { on: true, tx, ty, dash: false, ph: -1, prep: 0, v: 0, h: 0, k: 1, str: 1, last: false, off: 0 }); LIFE.st = 'go'; WANDER.moving = true;
      const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
      let [px, py] = cen(), fr = 0, cur = null, lastPh = -2, worst = 0, minA = 9, maxA = 0; const st = [];
      while ((GAIT.on || LIFE.st === 'arrive') && fr < 1800) { steps(1); fr++; const [x, y] = cen(), v = Math.hypot(x - px, y - py) / DT / R; px = x; py = y;
        if (GAIT.on && GAIT.ph >= 0) { if (cur === null || GAIT.ph < lastPh) { cur = { v: 0, ph: 0, h: GAIT.h }; st.push(cur); } lastPh = GAIT.ph; if (v > cur.v) { cur.v = v; cur.ph = GAIT.ph; } }
        if (fr % 6 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      const hs = st.map(s => s.h * 180 / Math.PI);
      r34.gait = { strokes: st.length, peakInContraction: +(st.filter(s => s.ph <= 0.35).length / Math.max(1, st.length)).toFixed(2), peakSpeedR: +Math.max(...st.map(s => s.v)).toFixed(2), headingSpreadDeg: +(Math.max(...hs) - Math.min(...hs)).toFixed(0), endDistR: +(Math.hypot(HOMEX - tx, HOMEY - ty) / R).toFixed(2), sec: +(fr / 60).toFixed(1), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) }; }
    { L2({}); LIFE.until = 1e9; const bx = globalC.xc + 1.8 * R, by = globalC.yc; ev('pointerdown', 4, bx, by); let best = 0, ang = 180, lo = 9, hi = 0;
      for (let k = 0; k < 120; k++) { steps(1); lo = Math.min(lo, PSM[3]); hi = Math.max(hi, PSM[3]); if (k < 36) for (const s of LIFE.sns) { const e = sniffEnv(s); if (e > best) { best = e; ang = Math.abs(Math.atan2(Math.sin(s.a), Math.cos(s.a))) * 180 / Math.PI; } } }
      ev('pointerup', 4, bx, by); r34.blank = { sniffEnv06s: +best.toFixed(2), angDeg: +ang.toFixed(0), breathRange: +(hi - lo).toFixed(4) }; }
    { L2({}); LIFE.until = 1e9; let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b], v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);   // 手指用累加位移（鏡頭會動）
      for (let k = 1; k <= 60; k++) { const tx = sx + 1.6 * R * Math.min(1, k / 30); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      const t0 = t; ev('pointerup', 1, q[0], q[1]); let att = -1, attAng = 180;
      for (let k = 0; k < 90; k++) { steps(1); if (classify()[0]) xf++; if (att < 0) for (const s of LIFE.sns) if (sniffEnv(s) > 0.05) { att = t - t0; attAng = Math.abs(Math.atan2(Math.sin(s.a), Math.cos(s.a))) * 180 / Math.PI; } }
      r34.release = { shakeAt: +(SHK.t0 - t0).toFixed(2), attendAt: +att.toFixed(2), attendAngDeg: +attAng.toFixed(0), end: snap() }; }
    r34.foldFrames = xf;
    res.T34_life = r34; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T35 v2.20（多米 build 75：拖的時候只有形變沒有位移；點它的凹回復太久；沒有跟人互動的感覺）。舊項目一律關 v2.20（PRESETS.clay 在最上面換成 OFF220），這裡打開。
  //     a D1 抓右緣往右拉 2R 停 1 秒：重心跟過去 0.55R 到 0.85R（drag 0 不到 0.1R）；被抓那端跟手指的距離跟 drag 0 差不到 0.3R；放手 2 秒往回退不到 0.1R，
  //       面積不比 drag 0 多 1%（黏土拉 2R 放手 2 秒面積本來就還沒回來，drag 0 量到 1.035）；
  //     b D2 點一下 0.12 秒：放手 0.6 秒凹痕 < 0.05；按 1 秒：放手 1.5 秒 < 0.05；捏走的形狀跟 dentFade 10 差不到 0.5pt；
  //     c 印象：輕揉 6 秒熟漲 0.1 以上；扯到想逃戒漲 0.2 以上；不碰 3 分鐘戒剩一半（0.45 到 0.55）；
  //     d C1 熟 0.8、手指停在右邊 2R：6 秒內偽足或身體碰到手指；戒 0.8、手指停在右邊 0.8R：5 秒後離手指遠 0.5R 以上；
  //     e C2 熟 0.5、手指在右邊 2.5R 慢慢往下移 1.5 秒再停：停下 0.5 秒內撲；不熟時手指快甩過去：嚇一下（縮）；
  //     f C4 輕揉 2.5 秒放手：排了討摸，5 秒內再揉呼嚕 0.6 秒內來（第一次 1 秒以上）；g C5 戒 0.8 時被碰縮的量是戒 0 的 1.5 倍以上。全程零對折
  { const clock = saveClock(); Math.random = seeded(20261102); const r35 = {}; let xf = 0;
    const V20 = { slide: 0, drag: P0.drag, dentFade: P0.dentFade, imp: 1, life2: 1 };
    const L3 = o => { resetAligned(1e9, { ...V20, ...o }); impReset(); LIFE.st = 'rest'; LIFE.until = 1e9; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const edgeTo = (x, y) => { let d = 1e9; for (const i of bnd) d = Math.min(d, Math.hypot(X[i] - x, Y[i] - y)); return d; };
    const rightPt = () => { let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; return b; };
    const rub = (id, frames) => { const cx = globalC.xc + R * 0.3, cy = globalC.yc; let q = sc(cx, cy); ev('pointerdown', id, q[0], q[1]); const f = fingers.get(id);
      let tp = -1; for (let k = 0; k < frames; k++) { const tx = cx + Math.sin(k / 16) * R * 0.25; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', id, q[0], q[1]); steps(1); if (classify()[0]) xf++; if (tp < 0 && PURR > 0.2) tp = k / 60; }
      ev('pointerup', id, q[0], q[1]); return tp; };
    // a 拖著走
    const pull = o => { L3(o); const c0 = cen(), b = rightPt(), sx = X[b] - R * 0.15, sy = Y[b]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);
      for (let k = 1; k <= 90; k++) { const tx = sx + 2 * R * Math.min(1, k / 30); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      const c1 = cen(), gap = (f1.fx - X[b]) / R; ev('pointerup', 1, q[0], q[1]); let worst = 0; for (let k = 0; k < 120; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      const c2 = cen(); return { followR: +((c1[0] - c0[0]) / R).toFixed(2), grabGapR: +gap.toFixed(2), backAfter2sR: +((c1[0] - c2[0]) / R).toFixed(2), worstSelfX: worst, end: snap() }; };
    { const on = pull({}), off = pull({ drag: 0 }); r35.drag = { on, off }; }
    // b 凹痕
    const dent = (o, hold, wait) => { L3({ imp: 0, ...o }); const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 2, cx, cy); steps(hold); ev('pointerup', 2, cx, cy);
      const dn = DENTS[DENTS.length - 1]; steps(wait); return { d: DENTS.includes(dn) ? +dn.d.toFixed(3) : 0, qdev: qdev() }; };
    { const tap = dent({}, 7, 36), hold = dent({}, 60, 90), tapOld = dent({ dentFade: 10 }, 7, 36);
      r35.dent = { tapAt06: tap.d, holdAt15: hold.d, tapOldAt06: tapOld.d, qdevDiffPt: +Math.abs(tap.qdev - tapOld.qdev).toFixed(2) }; }
    // c 印象怎麼漲、怎麼退
    { L3({ emo: 1 }); rub(3, 360); const trRub = IMP.tr; L3({ emo: 1 }); const b = rightPt(), sx = X[b] - R * 0.15, sy = Y[b]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);
      for (let k = 1; k <= 150; k++) { const tx = sx + 3 * R * Math.min(1, k / 20); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      ev('pointerup', 1, q[0], q[1]); steps(30); const wPull = IMP.w; impStep(180); r35.imp = { trAfterRub6s: +trRub.toFixed(2), wAfterStrain: +wPull.toFixed(2), wAfter3minRatio: +(IMP.w / wPull).toFixed(2) }; impReset(); }
    // d C1 手指停在旁邊
    { L3({}); IMP.tr = 0.8; const b = rightPt(), fx = X[b] + 2 * R, fy = Y[b], q = sc(fx, fy); ev('pointerdown', 5, q[0], q[1]); const f = fingers.get(5); let hit = -1, minE = 1e9;
      for (let k = 0; k < 360; k++) { steps(1); if (classify()[0]) xf++; minE = Math.min(minE, edgeTo(f.fx, f.fy)); if (hit < 0 && t - f.hitT < 0.02) hit = k / 60; }
      ev('pointerup', 5, q[0], q[1]); steps(30); const come = { hitS: +hit.toFixed(2), minEdgeR: +(minE / R).toFixed(2) };
      L3({}); IMP.w = 0.8; const b2 = rightPt(), gx = X[b2] + 0.8 * R, gy = Y[b2], q2 = sc(gx, gy), c0 = cen(); ev('pointerdown', 5, q2[0], q2[1]); for (let k = 0; k < 300; k++) { steps(1); if (classify()[0]) xf++; }
      const c1 = cen(); ev('pointerup', 5, q2[0], q2[1]); steps(30);
      r35.c1 = { come, backGainR: +((Math.hypot(gx - c1[0], gy - c1[1]) - Math.hypot(gx - c0[0], gy - c0[1])) / R).toFixed(2), end: snap() }; }
    // e C2 逗它
    { L3({}); IMP.tr = 0.5; const b = rightPt(); let q = sc(X[b] + 2.5 * R, Y[b]); ev('pointerdown', 6, q[0], q[1]);
      for (let k = 0; k < 90; k++) { q = [q[0], q[1] + R * CAM.z * 1.2 / 60]; ev('pointermove', 6, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      let pounce = -1; for (let k = 0; k < 120; k++) { steps(1); if (classify()[0]) xf++; if (pounce < 0 && LURE.pounced) pounce = k / 60; } ev('pointerup', 6, q[0], q[1]); steps(30);
      L3({}); const b2 = rightPt(); q = sc(X[b2] + 1.5 * R, Y[b2]); ev('pointerdown', 7, q[0], q[1]); steps(30); const fl0 = FLN.t0;
      for (let k = 0; k < 12; k++) { q = [q[0], q[1] + R * CAM.z * 6 / 60]; ev('pointermove', 7, q[0], q[1]); steps(1); } steps(20); const startled = FLN.t0 > fl0; ev('pointerup', 7, q[0], q[1]); steps(30);
      r35.c2 = { pounceS: +pounce.toFixed(2), startled }; }
    // f C4 討摸
    { L3({ emo: 1 }); const first = rub(8, 150); L3({ emo: 1 }); IMP.tr = 0.5; rub(8, 150); const asked = !!LIFE.ask; steps(90); const second = rub(8, 60);
      r35.c4 = { firstPurrS: +first.toFixed(2), asked, secondPurrS: +second.toFixed(2) }; }
    // g C5 戒高時縮得大
    { const fl = w => { L3({}); IMP.w = w; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(30); ev('pointerup', 1, cx, cy); steps(30); return FLN.last; };
      const a0 = fl(0), a8 = fl(0.8); r35.c5 = { flinchRatio: +(a8 / a0).toFixed(2) }; }
    r35.foldFrames = xf; impReset();
    res.T35_v220 = r35; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T36 v2.21 拉力（多米 build 77 錄影：往右下拉，史萊姆也要一併往右下靠；量過果凍拉 2.5R 整團只跟 0.56R）。
  //     a 果凍抓右下緣往右下拉 2.5R 停：整團跟過去 1.5R 以上、被拉長的量 0.9R 以下（slide 0 不到 0.7R）；b 黏土猛一扯（4 幀）那一下拉得比慢拉長 0.3R 以上；
  //     c 黏土兩指往兩邊各拉 1.5R：寬過 4.5R、整團移不到 0.2R；d 果凍往右甩 0.4 秒放手：再滑 0.3R 以上。全程零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261103); const r36 = {}; let worst = 0;
    const PS = { ...PSAVE };
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L4 = (m, o) => { resetAligned(1e9, { ...PS[m], emo: 0, life2: 0, ...o }); };
    const pullDR = (m, o, frames) => { L4(m, o); let b = -1; for (const i of bnd) if (b < 0 || X[i] + Y[i] > X[b] + Y[b]) b = i;
      const c0 = cen(), sx = X[b] - 4, sy = Y[b] - 4; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let maxSt = 0; const d = 2.5 * R / Math.SQRT2;
      for (let k = 1; k <= frames + 40; k++) { const u = Math.min(1, k / frames); q = [q[0] + (sx + d * u - f.x) * CAM.z, q[1] + (sy + d * u - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); maxSt = Math.max(maxSt, f.stretch); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      const c1 = cen(), st = f.stretch; ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      return { moveR: +(Math.hypot(c1[0] - c0[0], c1[1] - c0[1]) / R).toFixed(2), stretchR: +st.toFixed(2), maxStretchR: +maxSt.toFixed(2), end: snap() }; };
    r36.jelly = pullDR('jelly', {}, 30); r36.jellyOff = pullDR('jelly', { slide: 0 }, 30);
    r36.claySlow = pullDR('clay', {}, 30); r36.clayYank = pullDR('clay', {}, 4);
    { L4('clay', {}); let l = -1, r = -1; for (const i of bnd) { if (l < 0 || X[i] < X[l]) l = i; if (r < 0 || X[i] > X[r]) r = i; }
      const c0 = cen(), lx = X[l] + 4, ly = Y[l], rx = X[r] - 4, ry = Y[r]; let a = sc(lx, ly), b = sc(rx, ry); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); const f1 = fingers.get(1), f2 = fingers.get(2);
      for (let k = 1; k <= 70; k++) { const u = Math.min(1, k / 40) * 1.5 * R; a = [a[0] + (lx - u - f1.x) * CAM.z, a[1] + (ly - f1.y) * CAM.z]; b = [b[0] + (rx + u - f2.x) * CAM.z, b[1] + (ry - f2.y) * CAM.z]; ev('pointermove', 1, a[0], a[1]); ev('pointermove', 2, b[0], b[1]); steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      let x0 = 1e9, x1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } const c1 = cen();
      r36.twoFinger = { widthR: +((x1 - x0) / R).toFixed(2), moveR: +(Math.hypot(c1[0] - c0[0], c1[1] - c0[1]) / R).toFixed(2) };
      ev('pointerup', 1, a[0], a[1]); ev('pointerup', 2, b[0], b[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); } }
    { L4('jelly', {}); const sx = globalC.xc, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1);
      for (let k = 1; k <= 24; k++) { q = [q[0] + (sx + 4 * R * k / 60 - f.x) * CAM.z, q[1] + (sy - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); }
      const c1 = cen(); ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); } const c2 = cen();
      r36.fling = { glideR: +((c2[0] - c1[0]) / R).toFixed(2), end: snap() }; }
    r36.worstSelfX = worst;
    res.T36_pull = r36; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T37 v2.22（多米 build 77：還是沒有互動的感覺；繼續做黏液）。a 點一下：放手 0.25 到 0.45 秒開始朝手指傾、「噗」；b 按著不動 2.5 秒：左右蹭 0.03R 以上、「嗯～」；
  //     c 搔癢：扭 3 次以上、3.2 到 5 秒掙脫（撥 4 下才算開始搔癢，之後 3 秒）、有咯咯笑和「嗯嗯」；d E3 輕揉 5 秒熟過 0.5（E3 關不到 0.3）；e E4 熟 0.8、不碰 30 秒內游到前面（0.6R 內）打招呼；
  //     f 黏土兩指往兩邊拉 1.8R：掉黏液、身體變小，放手 90 秒內全部吸回去、身體長回來（drops 0 不掉）；g 把一滴拖到身上 1 秒內吸掉；h 抓著一滴放旁邊，它 10 秒內游過來搶。全程零自交
  { const clock = saveClock(); Math.random = seeded(20261104); const r37 = {}; let worst = 0;
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L5 = o => { resetAligned(1e9, { ...P0, emo: 0, ...o }); impReset(); voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; LIFE.st = 'rest'; LIFE.until = 1e9; log.splice(0); };
    const voices = () => log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6));
    { L5({}); IMP.tr = 0.6; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(7); const t0 = t; ev('pointerup', 1, cx, cy); steps(40);
      r37.tap = { leanAfter: +(E2.leanT - t0).toFixed(2), voices: voices() }; }
    { L5({}); IMP.tr = 0.6; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); let lo = 1e9, hi = -1e9; for (let k = 0; k < 150; k++) { steps(1); const c = cen(); lo = Math.min(lo, c[0]); hi = Math.max(hi, c[0]); }
      ev('pointerup', 1, cx, cy); steps(30); r37.nuzzle = { swayR: +((hi - lo) / R).toFixed(3), voices: voices() }; }
    { L5({}); const sx = globalC.xc, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let sh = 0, esc = -1; const t0 = t;
      for (let k = 0; k < 330; k++) { const tx = sx + Math.sign(Math.sin(k * Math.PI / 5)) * R * 0.15; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', 1, q[0], q[1]); steps(1); if (SHK.t0 > 0 && Math.abs(t - SHK.t0) < 0.009) sh++; if (esc < 0 && f.mode === 'none') esc = t - t0; if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      ev('pointerup', 1, q[0], q[1]); steps(60); r37.tickle = { shakes: sh, escapeS: +esc.toFixed(2), voices: voices() }; }
    const rubTr = o => { L5({ emo: 1, ...o }); const sx = globalC.xc + R * 0.3, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 2, q[0], q[1]); const f = fingers.get(2);
      for (let k = 0; k < 300; k++) { const tx = sx + Math.sin(k / 16) * R * 0.25; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', 2, q[0], q[1]); steps(1); } ev('pointerup', 2, q[0], q[1]); steps(10); return +IMP.tr.toFixed(2); };
    r37.e3 = { trOn: rubTr({}), trOff: rubTr({ e3: 0 }) };
    { L5({}); E4.count = 0; IMP.tr = 0.8; LIFE.until = -1; let hello = -1; for (let k = 0; k < 1800 && E4.count < 1; k++) { steps(1); if (hello < 0 && voices().includes('hello')) hello = t; if (k % 30 === 0) worst = Math.max(worst, selfX()); }
      const c = cen(), q = toWorld(W / 2, v.y + H * 0.12); r37.e4 = { count: E4.count, helloAt: +hello.toFixed(1), distR: +(Math.hypot(c[0] - q.x, c[1] - q.y) / R).toFixed(2) }; }
    const pullApart = o => { L5({ emo: 0, ...o }); let l = -1, r = -1; for (const i of bnd) { if (l < 0 || X[i] < X[l]) l = i; if (r < 0 || X[i] > X[r]) r = i; }
      const lx = X[l] + 4, ly = Y[l], rx = X[r] - 4, ry = Y[r]; let a = sc(lx, ly), b = sc(rx, ry); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); const f1 = fingers.get(1), f2 = fingers.get(2);
      for (let k = 1; k <= 50; k++) { const u = Math.min(1, k / 40) * 1.8 * R; a = [a[0] + (lx - u - f1.x) * CAM.z, a[1] + (ly - f1.y) * CAM.z]; b = [b[0] + (rx + u - f2.x) * CAM.z, b[1] + (ry - f2.y) * CAM.z]; ev('pointermove', 1, a[0], a[1]); ev('pointermove', 2, b[0], b[1]); steps(1); }
      const n = DROPS.length, m = MASS; ev('pointerup', 1, a[0], a[1]); ev('pointerup', 2, b[0], b[1]); return { n, m }; };
    { const off = pullApart({ drops: 0 }); const on = pullApart({}); LIFE.until = t + 1; let done = -1;
      for (let k = 0; k < 5400; k++) { steps(1); if (k % 30 === 0) worst = Math.max(worst, selfX()); if (!DROPS.length) { done = k / 60; break; } }
      steps(60); r37.drops = { spawned: on.n, massAfter: +on.m.toFixed(3), allEatenS: +done.toFixed(1), massEnd: +MASS.toFixed(3), offSpawned: off.n, gulps: voices().filter(x => x === 'gulp').length, end: snap() }; }
    { L5({}); dropSpawn(globalC.xc + R * 2.2, globalC.yc, 0, 0, R * 0.18); steps(70); const d = DROPS[0]; let q = sc(d.x, d.y); ev('pointerdown', 3, q[0], q[1]); const f = fingers.get(3), held = d.st;
      const tx = globalC.xc, ty = globalC.yc, x0 = f.x, y0 = f.y; for (let k = 1; k <= 30; k++) { q = [q[0] + (x0 + (tx - x0) * k / 30 - f.x) * CAM.z, q[1] + (y0 + (ty - y0) * k / 30 - f.y) * CAM.z]; ev('pointermove', 3, q[0], q[1]); steps(1); }
      ev('pointerup', 3, q[0], q[1]); steps(60); r37.dragIn = { held, left: DROPS.length, mass: +MASS.toFixed(3) }; }
    { L5({}); IMP.tr = 0.3; dropSpawn(globalC.xc + R * 2.5, globalC.yc - R * 0.5, 0, 0, R * 0.18); steps(70); const d = DROPS[0], q = sc(d.x, d.y); ev('pointerdown', 4, q[0], q[1]); LIFE.until = -1; let got = -1;
      for (let k = 0; k < 600; k++) { steps(1); if (got < 0 && (!DROPS.length || d.st === 'eat')) { got = t; break; } } ev('pointerup', 4, q[0], q[1]); steps(30); r37.snatch = { gotAt: got > 0 ? +(got - 0).toFixed(2) : -1, left: DROPS.length }; }
    r37.worstSelfX = worst;
    res.T37_v222 = r37; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T38 v2.23（多米 build 86：黏液不自然、形狀不自然、太容易掉、太多；還是沒有互動感；加表情看看，只要眼睛；睡著、節奏、游過來、收集一起做）。
  //   a 黏液：黏土單指慢拉 2.5R（2 秒）不掉；兩指往兩邊慢慢拉 1.8R 不掉（v2.22 會掉）；猛扯（0.12 秒拉 2.6R 再停）掉 1 滴、有拉絲（neck 8 幀以上）、斷開 0.6 秒後離身體 0.25R 以上（黏土最近，量過 0.34），同一抓再扯、放手都不再掉
  //   b 眼睛：手指按在右邊 2.2R 的空白處 1 秒，眼睛往右看（gx 0.5 以上）；放著 10 秒眨 2 次以上；搔癢出現 > <；揉到呼嚕出現 ∩
  //   c 睡著：不碰 40 到 45 秒睡著、∪；點身體當下醒、縮得比平常大（0.06 以上）、「嗯？」
  //   d 節奏：空白處點 3 下（間隔 0.4 秒）→ 回 3 下、間隔 0.35 到 0.45、第一下在最後一點後 0.9 到 1.6 秒；接著點一樣的 → 回完開心（「噗咿」）；只點一下不回
  //   e 游過來：從家右邊 2R 以外開始，4.5 秒內到家 0.6R 內、打招呼，鏡頭不動（5 點內）；f 收集：四隻輪流換，材質、種子、顏色對，放 3 秒零自交、面積 0.97 到 1.03；換回來印象還在。全程零自交
  { const clock = saveClock(); Math.random = seeded(20261105); const r38 = {}; let worst = 0;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L6 = o => { resetAligned(1e9, { ...P1, ...o }); impReset(); voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; DROPV.last = -99; log.splice(0); };
    const voices = () => log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6));
    const pull = (dur, dist) => { L6({}); const x0 = globalC.xc + R * 0.8, y0 = globalC.yc; let q = sc(x0, y0); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let neck = 0;
      for (let k = 0; k < dur + 40; k++) { const tx = x0 + dist * R * Math.min(1, k / dur); q = [q[0] + (tx - f.x) * CAM.z, q[1] + (y0 - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (DROPS.some(d => d.neck > 0 && d.neck < 1)) neck++; if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      const n = DROPS.length, d = DROPS[0]; let sep = -1;
      if (d) { steps(Math.max(0, Math.round((0.6 - (t - d.snapT)) * 60))); let m = 1e9; for (const i of bnd) m = Math.min(m, Math.hypot(X[i] - d.x, Y[i] - d.y)); sep = m / R; }
      const x1 = f.x; for (let k = 0; k < 30; k++) { const tx = x1 + R * 1.5 * Math.sin(Math.min(1, k / 6) * Math.PI / 2); q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', 1, q[0], q[1]); steps(1); }
      const n2 = DROPS.length; ev('pointerup', 1, q[0], q[1]); steps(30); return { n, neck, sepR: +sep.toFixed(2), n2, after: DROPS.length }; };
    const apart = () => { L6({}); let l = -1, r = -1; for (const i of bnd) { if (l < 0 || X[i] < X[l]) l = i; if (r < 0 || X[i] > X[r]) r = i; }
      const lx = X[l] + 4, ly = Y[l], rx = X[r] - 4, ry = Y[r]; let a = sc(lx, ly), b = sc(rx, ry); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); const f1 = fingers.get(1), f2 = fingers.get(2);
      for (let k = 1; k <= 50; k++) { const u = Math.min(1, k / 40) * 1.8 * R; a = [a[0] + (lx - u - f1.x) * CAM.z, a[1] + (ly - f1.y) * CAM.z]; b = [b[0] + (rx + u - f2.x) * CAM.z, b[1] + (ry - f2.y) * CAM.z]; ev('pointermove', 1, a[0], a[1]); ev('pointermove', 2, b[0], b[1]); steps(1); }
      const n = DROPS.length; ev('pointerup', 1, a[0], a[1]); ev('pointerup', 2, b[0], b[1]); steps(30); return n; };
    r38.drops = { slow: pull(120, 2.5), yank: pull(7, 2.6), apart: apart() };
    { L6({}); const q = sc(globalC.xc + R * 2.2, globalC.yc); ev('pointerdown', 2, q[0], q[1]); steps(60); const gx = +EYE.gx.toFixed(2); ev('pointerup', 2, q[0], q[1]); steps(30);
      let bl = 0, lastB = EYE.blinkT; for (let k = 0; k < 600; k++) { steps(1); if (EYE.blinkT !== lastB) { bl++; lastB = EYE.blinkT; } }
      L6({}); const sx = globalC.xc, sy = globalC.yc; let p = sc(sx, sy); ev('pointerdown', 1, p[0], p[1]); const f = fingers.get(1); let sq = 0;
      for (let k = 0; k < 240; k++) { const tx = sx + Math.sign(Math.sin(k * Math.PI / 5)) * R * 0.15; p = [p[0] + (tx - f.x) * CAM.z, p[1]]; ev('pointermove', 1, p[0], p[1]); steps(1); if (EYE.mode === 'squeeze') sq++; }
      ev('pointerup', 1, p[0], p[1]); steps(60);
      L6({}); const rx = globalC.xc + R * 0.3, ry = globalC.yc; p = sc(rx, ry); ev('pointerdown', 2, p[0], p[1]); const g = fingers.get(2); let hp = 0;
      for (let k = 0; k < 300; k++) { const tx = rx + Math.sin(k / 16) * R * 0.25; p = [p[0] + (tx - g.x) * CAM.z, p[1]]; ev('pointermove', 2, p[0], p[1]); steps(1); if (EYE.mode === 'happy') hp++; }
      ev('pointerup', 2, p[0], p[1]); steps(30); r38.eyes = { lookGx: gx, blinks10s: bl, tickleSqueeze: sq, purrHappy: hp }; }
    { L6({}); lastTouch = t; let at = -1; const t0 = t; for (let k = 0; k < 60 * 50 && at < 0; k++) { steps(1); if (SLP.on) at = t - t0; if (k % 60 === 0) worst = Math.max(worst, selfX()); }
      steps(150); const eye = EYE.mode, kk = SLP.k; log.splice(0);
      const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 3, q[0], q[1]); const woke = !SLP.on; steps(30); const fl = FLN.amp; ev('pointerup', 3, q[0], q[1]); steps(60);
      r38.sleep = { at: +at.toFixed(1), eye, k: +kk.toFixed(2), woke, flinch: +fl.toFixed(3), voices: voices() }; }
    const tapsAt = (ivs, id) => { const q = sc(globalC.xc, globalC.yc + R * 1.8), tp = []; for (let i = 0; i <= ivs.length; i++) { if (i) steps(Math.round(ivs[i - 1] * 60) - 3); ev('pointerdown', id, q[0], q[1]); tp.push(t); steps(3); ev('pointerup', id, q[0], q[1]); } return tp; };
    const listen = n => { const b = []; let last = ECHO.beatT; for (let k = 0; k < n; k++) { steps(1); if (ECHO.beatT !== last) { b.push(ECHO.beatT); last = ECHO.beatT; } if (k % 20 === 0) worst = Math.max(worst, selfX()); } return b; };
    { L6({}); const tp = tapsAt([0.4, 0.4], 4), b = listen(240); log.splice(0); tapsAt([0.42, 0.38], 4); const b2 = listen(240), joy = voices().includes('happy');
      L6({}); tapsAt([], 4); const b3 = listen(180);
      r38.echo = { beats: b.length, iv: b.slice(1).map((x, i) => +(x - b[i]).toFixed(2)), firstAfter: b.length ? +(b[0] - tp[tp.length - 1]).toFixed(2) : -1, again: b2.length, joy, single: b3.length }; }
    { L6({}); LIFE.until = -1; const cam0 = CAM.x, home = [CX, CY]; startIntro(); let mx = 0; for (let i = 0; i < N; i++) mx += X[i]; mx /= N; let arr = -1, hello = -1; const t0 = t;
      for (let k = 0; k < 600; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); if (hello < 0 && voices().includes('hello')) hello = t - t0; if (arr < 0 && Math.hypot(globalC.xc - home[0], globalC.yc - home[1]) < R * 0.6) arr = t - t0; if (hello > 0 && t - t0 > hello + 1) break; }
      r38.swim = { startOffR: +((mx - home[0]) / R).toFixed(2), arriveS: +arr.toFixed(2), helloS: +hello.toFixed(2), camMoved: +Math.abs(CAM.x - cam0).toFixed(1), end: snap() }; }
    { L6({}); const s0 = SLIME, o = []; IMP.tr = 0.7; IMP.w = 0.1; chooseSlime((s0 + 1) % SLIMES.length, false, false);
      for (let i = 0; i < SLIMES.length; i++) { chooseSlime(i, false, false); mat.emo = 0; WANDER.moving = false; LIFE.until = 1e9; let aMin = 9, aMax = 0, x = 0;
        for (let k = 0; k < 180; k++) { steps(1); const a = area() / A0; aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); if (k % 10 === 0) x = Math.max(x, selfX()); }
        o.push({ id: SLIMES[i].id, mat: curMat === SLIMES[i].mat, seed: mat.seed === SLIMES[i].seed, color: getComputedStyle(document.documentElement).getPropertyValue('--body').trim().toUpperCase() === SLIMES[i].c[0], aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), selfX: x }); }
      chooseSlime(s0, false, false); r38.collect = { slimes: o, impBack: +IMP.tr.toFixed(2) }; }
    r38.worstSelfX = worst;
    res.T38_v223 = r38; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T39 v2.24（多米 11-04：手感做到極致；.uiux/04-手感/手感診斷-暫定.md）。舊項目一律回 v2.23（OFF24），v2.24 只在這裡測，用 PSAVE（全開）。
  //   a F1：身體 0.30；b F2：點一下縮到 0.91 以下、外緣朝手指多 0.12R 以上（鼓包加整團靠過去）、按著蹭擺幅 0.15R 以上、手指在右邊空白臉滑 0.15R 以上、按正中兩顆眼睛都不被手指蓋住；
  //   c F3：一般手速的揉 1.7 秒內呼嚕、不搔癢、不逃；很快的小撥 1 秒內搔癢、先抗議、5.5 到 7.5 秒才掙脫；按著不動的呼嚕比揉慢；
  //   d 揉不補抓：外圈沒有點被釘住、輪廓折角 25 度以內；從中間直直往外拉，外圈照樣跟出去；e camGrip：抓著時畫面不滑（手指跟被抓那塊差很少）、放手形狀太靠邊會挪回來；
  //   f 留形不動：拉 1.5R 放手 2 秒還留七成五；g 三種材質暴力玩法（拉、甩、兩指擠、兩指拉、揉）零交叉、面積回來
  { const clock = saveClock(); Math.random = seeded(20261104); const r39 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L7 = (name, o) => { resetAligned(1e9, { ...PSAVE[name], ...OFF25, seed: 7, ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; DROPV.last = -99; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(20); log.splice(0); };
    const box = () => { let a = 1e9, b = -1e9, c = 1e9, d = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); c = Math.min(c, Y[i]); d = Math.max(d, Y[i]); } return [a, b, c, d]; };
    const kink = () => { const n = bnd.length; let m = 0; for (let k = 0; k < n; k++) { const a = bnd[(k + n - 1) % n], b = bnd[k], c = bnd[(k + 1) % n], u = Math.atan2(Y[b] - Y[a], X[b] - X[a]), w = Math.atan2(Y[c] - Y[b], X[c] - X[b]); m = Math.max(m, Math.abs(Math.atan2(Math.sin(w - u), Math.cos(w - u)))); } return m * 180 / Math.PI; };
    const hidden = (p, fx, fy) => { const qx = p[0] - fx, qy = p[1] - fy, u = qx * .5 + qy * .866, uc = Math.max(0, Math.min(160, u)), rr = 30 + 18 * uc / 160; return Math.hypot(qx - .5 * uc, qy - .866 * uc) < rr; };   // 手指：接觸面半徑 30 點、從右下伸過來、往後變寬到 48 點
    const face = () => { const [lx, ly] = eyeAt(EYE.L), [rx, ry] = eyeAt(EYE.R), S = R * (mat.eyeSize || 1) * Math.sqrt(MASSD), ga = mat.gazeAmp * (1 - .8 * EYE.dk), ox = (EYE.gx * ga + EYE.dx) * S, oy = (EYE.gy * ga * .75 + EYE.dy) * S; return { l: [lx + ox, ly + oy], r: [rx + ox, ry + oy], ox, oy }; };
    // a F1
    L7('clay', {}); { const b = box(); r39.size = { rOverW: +(R / W).toFixed(3), widthPt: +(b[1] - b[0]).toFixed(0), z: +CAM.z.toFixed(3) }; }
    // b F2 縮、傾（關掉放手後的探，只看傾）
    L7('clay', { lifeAttend: 0 }); { const b0 = box(), c0 = globalC.xc; let q = sc(globalC.xc + R * .6, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(4); ev('pointerup', 1, q[0], q[1]); let sMin = 1, lean = -1e9; for (let k = 0; k < 90; k++) { steps(1); sMin = Math.min(sMin, FLN.s); if (t - E2.leanT > 0) lean = Math.max(lean, box()[1]); } r39.tap = { flinchMin: +sMin.toFixed(3), leanGainR: +((lean - b0[1]) / R).toFixed(3), voices: log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6)) }; }
    // 蹭：按著不動，重心上下擺幅
    L7('clay', {}); { const q = sc(globalC.xc + R * .45, globalC.yc + R * .1); ev('pointerdown', 1, q[0], q[1]); steps(60); let a = 1e9, b = -1e9; for (let k = 0; k < 180; k++) { steps(1); a = Math.min(a, globalC.yc); b = Math.max(b, globalC.yc); } r39.nuzzleSwingR = +((b - a) / R).toFixed(3); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 看：手指按在右邊 2.2R 的空白處
    L7('clay', {}); { const q = sc(globalC.xc + R * 2.2, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(60); r39.gazeR = +(face().ox / R).toFixed(3); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 按正中：兩顆眼睛都不被手指蓋住；關 dodge 當對照
    for (const [nm, o] of [['on', {}], ['off', { dodge: 0, gazeAmp: .06 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); steps(60); const F = face(); (r39.dodge = r39.dodge || {})[nm] = { l: hidden(F.l, f.x, f.y), r: hidden(F.r, f.x, f.y), oy: +(F.oy / R).toFixed(3) }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // c F3 揉（kind：c 圓圈、l 來回；r 點、hz；T 秒）
    const rub = (name, kind, r, hz, T, o = {}) => { L7(name, o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(6); let th = 0, tP = -1, tT = -1, tF = -1, tProt = -1, sp = 0, n = 0, mk = 0;
      for (let k = 0; k < T * 60; k++) { th += 2 * Math.PI * hz * DT; const px = kind === 'c' ? q[0] + r * Math.cos(th) : q[0] + r * Math.sin(th), py = kind === 'c' ? q[1] + r * Math.sin(th) : q[1]; if (r > 0) ev('pointermove', 1, px, py); steps(1); const g = fingers.get(1); if (!g || g.mode !== 'grab') { tF = k * DT; break; } sp += Math.hypot(g.vxS, g.vyS); n++; mk = Math.max(mk, kink()); if (tP < 0 && PURR > .3) tP = k * DT; if (tT < 0 && tickOn()) tT = k * DT; if (tProt < 0 && log.some(x => x[0] === 'voice.protest')) tProt = k * DT; }
      const res1 = { cmS: +(sp / Math.max(1, n) / 60).toFixed(1), purr: +tP.toFixed(2), tickle: +tT.toFixed(2), free: +tF.toFixed(2), protest: +tProt.toFixed(2), kink: +mk.toFixed(0) }; if (fingers.size) ev('pointerup', 1, q[0], q[1]); steps(4); return res1; };
    r39.rub = { c1cm: rub('clay', 'c', 10, 1, 4), c5cm: rub('clay', 'c', 30, 1.5, 4), c12cm: rub('clay', 'c', 50, 2.5, 4), l5cm: rub('clay', 'l', 30, 3, 8), l7cm: rub('clay', 'l', 60, 2, 8), jelly: rub('jelly', 'c', 30, 1.5, 4), mochi: rub('mochi', 'c', 30, 1.5, 4), hold: rub('clay', 'c', 0, 1, 4), tickle: rub('clay', 'l', 20, 4, 9), oldRub: rub('clay', 'c', 30, 1.5, 4, { rubSpeed: 0 }) };
    // 按著不動 4 秒：外框不折（Q 不記遠端的小誤差）；關 pressLocal 當對照
    for (const [nm, o] of [['on', {}], ['off', { pressLocal: 0 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); let mk = 0; for (let k = 0; k < 240; k++) { steps(1); mk = Math.max(mk, kink()); } (r39.hold = r39.hold || {})[nm] = +mk.toFixed(0); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 按一下留痕還在：按 1.5 秒，手指附近的形狀記住了
    L7('clay', {}); { const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(90); let qm = 0; for (let i = 0; i < N; i++) qm = Math.max(qm, Math.hypot(QX[i] - Q0X[i], QY[i] - Q0Y[i])); r39.pressMemPt = +qm.toFixed(1); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // d 揉不補抓
    for (const [nm, o] of [['on', {}], ['off', { reachV: 0 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc + R * .1); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let th = 0, mk = 0; for (let k = 0; k < 180; k++) { th += 2 * Math.PI * 1.5 * DT; ev('pointermove', 1, q[0] + 30 * Math.cos(th), q[1] + 30 * Math.sin(th)); steps(1); mk = Math.max(mk, kink()); } (r39.reach = r39.reach || {})[nm] = { edgePinned: f.mem.filter(m => BIDX[m[0]] >= 0).length, kink: +mk.toFixed(0) }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 從中間直直往外拉 1.5R（手指真的走得到的距離）：外圈要跟出去
    for (const [nm, ux, uy] of [['right', 1, 0], ['up', 0, -1]]) { L7('clay', {}); const b0 = box(), cx = globalC.xc, cy = globalC.yc; let q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let wx = 0; for (let k = 1; k <= 90; k++) { const a = Math.min(1, k / 45) * 1.5 * R; q = [q[0] + (cx + ux * a - f.x) * CAM.z, q[1] + (cy + uy * a - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (k % 3 === 0) wx = Math.max(wx, selfX()); } const b1 = box(); r39.reach[nm] = { edgeMovedR: +((ux ? b1[1] - b0[1] : b0[2] - b1[2]) / R).toFixed(2), selfX: wx }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // e camGrip：抓右緣往右 70、90 點，往下 300 點，停 0.67 秒量手指跟被抓那塊在畫面上差多少
    const gap = (o, dist, dx, dy) => { L7('clay', { lifeAttend: 0, ...o }); let bi = -1, bb = -1e9; for (const i of bnd) { const p = X[i] * dx + Y[i] * dy; if (p > bb) { bb = p; bi = i; } } const q0 = sc(X[bi] - dx * R * .15, Y[bi] - dy * R * .15); let x = q0[0], y = q0[1]; ev('pointerdown', 1, x, y); steps(6); const f = fingers.get(1), mem = f.mem; for (let k = 0; k < 20; k++) { x += dx * dist / 20; y += dy * dist / 20; ev('pointermove', 1, x, y); steps(1); } steps(40); let px = 0, py = 0, w = 0; for (const m of mem) { const a = m[3]; px += (X[m[0]] - m[1]) * a; py += (Y[m[0]] - m[2]) * a; w += a; } const s1 = sc(px / w, py / w), z = CAM.z; ev('pointerup', 1, x, y); steps(90); const b = box(), right = sc(b[1], b[2])[0]; return { gapPt: +Math.hypot(x - s1[0], y - s1[1]).toFixed(1), z: +z.toFixed(3), rightAfter: +right.toFixed(0) }; };
    r39.cam = { r70: gap({}, 70, 1, 0), r90: gap({}, 90, 1, 0), d300: gap({}, 300, 0, 1), oldR100: gap({ camGrip: 0 }, 100, 1, 0), oldD300: gap({ camGrip: 0 }, 300, 0, 1) };
    // f 留形：抓最右邊往右拉 1.5R、停 1 秒放手，量放手 2 秒還留幾成拉出來的寬度
    L7('clay', { lifeAttend: 0 }); { const wd = () => { const b = box(); return (b[1] - b[0]) / R; }, w0 = wd(); let bi = -1; for (const i of bnd) if (bi < 0 || X[i] > X[bi]) bi = i; const sx = X[bi] - R * .15, sy = Y[bi]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); for (let k = 1; k <= 90; k++) { const a = sx + 1.5 * R * Math.min(1, k / 30); q = [q[0] + (a - f.x) * CAM.z, q[1]]; ev('pointermove', 1, q[0], q[1]); steps(1); } const wh = wd(); ev('pointerup', 1, q[0], q[1]); steps(120); r39.keep = { heldR: +wh.toFixed(2), keep2s: +((wd() - w0) / (wh - w0)).toFixed(2) }; }
    // g 暴力玩法
    const abuse = name => { L7(name, {}); mat.drops = 0; mat.dropsV = 0; let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / (A0 * MASSD); aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r39.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    res.T39_v224 = r39; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

  // T40 v2.25 F4（診斷第二節：放手 33 毫秒彈完、每秒晃 7 下）。舊項目與 T39 都關慣性（OFF25），這裡開慣性、關 v2.26（OFF26，T41 才開）。F5 觸覺只在 Swift，這裡測不到。
  //   a 放手：抓右緣拉 1R 放手，第一下 120 毫秒以上（關掉不到 50）、放手那一幀跳動 8 點內（關掉 16 到 47）、麻糬果凍晃 3 下以上、黏土 1 秒留形不比關掉差；
  //   b 拖到一半停：整隻衝過頭 8 點以上（關掉 1 點內）、0.15 到 0.6 秒到頂；c 拉力、跟手不變（整團跟隨差 0.05R 內、手指跟被抓那塊差 3 點內）；
  //   d 猛甩放手、兩指放一指、按住放手、揉回原形：零交叉、不炸（QD 離 Q 不超過 2.5R）、放手跳動小；e 放著：QD 收回 Q、不漂；f 減少動態：不過衝；g 三種材質全開暴力玩法零交叉
  { const clock = saveClock(); Math.random = seeded(20261225); const r40 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, drops: 0, dropsV: 0, eyes: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L8 = (name, o, full) => { resetAligned(1e9, { ...PSAVE[name], ...OFF26, seed: 7, ...(full ? {} : QUIET), ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; DROPV.last = -99; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(30); log.splice(0); };
    const OFF = { inertiaHz: 0, dragSpring: 0 };
    const edgeI = (dx, dy) => { let bi = -1, bb = -1e9; for (const i of bnd) { const p = X[i] * dx + Y[i] * dy; if (p > bb) { bb = p; bi = i; } } return bi; };
    const jumpFrom = (x0, y0) => { let m = 0; for (const i of bnd) m = Math.max(m, Math.hypot(X[i] - x0[i], Y[i] - y0[i])); return m; };
    // 小步取樣（每秒 240 次）
    const sub1 = substep; let sample = null; substep = (a, b, c, d) => { sub1(a, b, c, d); if (sample) sample(); };
    // a 放手
    const ring = (name, o) => { L8(name, o); const bi = edgeI(1, 0), rest = X[bi] - globalC.xc; let q = sc(X[bi] - R * .1, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0]; for (let i = 0; i < 15; i++) { x += R / 15; ev('pointermove', 1, x, q[1]); steps(1); } steps(30);
      const pre = X[bi] - globalC.xc, ser = [], x0 = Float64Array.from(X), y0 = Float64Array.from(Y); sample = () => ser.push(X[bi] - globalC.xc); ev('pointerup', 1, x, q[1]); steps(1); const jump = jumpFrom(x0, y0); steps(59); const at1 = X[bi] - globalC.xc; steps(60); const at2 = X[bi] - globalC.xc; sample = null;
      let i0 = 0; for (let i = 1; i < ser.length; i++) { if (ser[i] < ser[i0]) i0 = i; if (ser[i] > ser[i0] + .8 && i > 2) break; } const ext = []; for (let i = 2; i < ser.length; i++) { const a = ser[i - 2], b = ser[i - 1], c = ser[i]; if ((b - a) * (c - b) < 0 && Math.abs(b - at2) > 1.5) ext.push(i - 1); } let maxV = 0; for (let i = 1; i < ser.length; i++) maxV = Math.max(maxV, Math.abs(ser[i] - ser[i - 1]) * 240);
      return { firstMs: +(i0 / .24).toFixed(0), swings: ext.length, maxV: +maxV.toFixed(0), jump: +jump.toFixed(1), keep1s: +((at1 - rest) / (pre - rest)).toFixed(2) }; };
    r40.ring = { clay: ring('clay', {}), mochi: ring('mochi', {}), jelly: ring('jelly', {}), clayOff: ring('clay', OFF), mochiOff: ring('mochi', OFF), jellyOff: ring('jelly', OFF) };
    // b 拖到一半停
    const stop = (name, o) => { L8(name, o); const bi = edgeI(1, 0); let q = sc(X[bi] - R * .2, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0]; const c0 = globalC.xc, cs = []; let xf = 0; for (let i = 0; i < 99; i++) { if (i < 9) { x += 200 / 9; ev('pointermove', 1, x, q[1]); } steps(1); cs.push(globalC.xc - c0); if (selfX()) xf++; } ev('pointerup', 1, x, q[1]); steps(4); const fin = cs[cs.length - 1], pk = Math.max(...cs); return { overPt: +(pk - fin).toFixed(1), atS: +((cs.indexOf(pk) - 9) / 60).toFixed(2), crossFrames: xf }; };
    r40.stop = { clay: stop('clay', {}), mochi: stop('mochi', {}), jelly: stop('jelly', {}), clayOff: stop('clay', OFF), jellyOff: stop('jelly', OFF) };
    // c 拉力、跟手
    const pull = (name, o, rr, frames) => { L8(name, o); const bi = edgeI(.707, .707); let q = sc(X[bi] - R * .1, Y[bi] - R * .1); const c0x = globalC.xc, c0y = globalC.yc; ev('pointerdown', 1, q[0], q[1]); steps(6); const f = fingers.get(1), mem = f.mem; let x = q[0], y = q[1]; const dd = rr * R * .707 / frames; for (let i = 0; i < frames; i++) { x += dd; y += dd; ev('pointermove', 1, x, y); steps(1); } steps(40); const move = Math.hypot(globalC.xc - c0x, globalC.yc - c0y) / R; let px = 0, py = 0, w = 0; for (const m of mem) { const a = m[3]; px += (X[m[0]] - m[1]) * a; py += (Y[m[0]] - m[2]) * a; w += a; } const s1 = sc(px / w, py / w); const gap = Math.hypot(x - s1[0], y - s1[1]); ev('pointerup', 1, x, y); steps(4); return { moveR: +move.toFixed(2), gap: +gap.toFixed(1) }; };
    r40.pull = { jelly: pull('jelly', {}, 2.5, 30), jellyOff: pull('jelly', OFF, 2.5, 30), clay: pull('clay', {}, 2, 60), clayOff: pull('clay', OFF, 2, 60), mochi: pull('mochi', {}, 2, 30), mochiOff: pull('mochi', OFF, 2, 30) };
    // d 邊緣情況
    const qdMax = () => { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(QDX[i] - QX[i], QDY[i] - QY[i])); return m / R; };
    const fling = name => { L8(name, {}); const bi = edgeI(-1, 0); let q = sc(X[bi] + R * .2, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(4); let x = q[0], y = q[1]; for (let i = 0; i < 5; i++) { x -= 60; y += 30; ev('pointermove', 1, x, y); steps(1); } ev('pointerup', 1, x, y); let xf = 0, qm = 0; for (let i = 0; i < 180; i++) { steps(1); if (selfX()) xf++; qm = Math.max(qm, qdMax()); } return { crossFrames: xf, qdMaxR: +qm.toFixed(2), endSelfX: selfX() }; };
    r40.fling = { clay: fling('clay'), mochi: fling('mochi'), jelly: fling('jelly') };
    const twoOne = name => { L8(name, {}); let a = sc(globalC.xc - R * .7, globalC.yc), b = sc(globalC.xc + R * .7, globalC.yc); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); steps(4); let ax = a[0], bx = b[0]; for (let i = 0; i < 30; i++) { ax -= R * .8 / 30; bx += R * .8 / 30; ev('pointermove', 1, ax, a[1]); ev('pointermove', 2, bx, b[1]); steps(1); } steps(20); const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); ev('pointerup', 2, bx, b[1]); steps(1); const jump = jumpFrom(x0, y0); let xf = 0; for (let i = 0; i < 90; i++) { steps(1); if (selfX()) xf++; } ev('pointerup', 1, ax, a[1]); for (let i = 0; i < 90; i++) { steps(1); if (selfX()) xf++; } return { jump: +jump.toFixed(1), crossFrames: xf }; };
    r40.twoOne = { clay: twoOne('clay'), jelly: twoOne('jelly') };
    const pressUp = name => { L8(name, {}); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(60); const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); ev('pointerup', 1, q[0], q[1]); steps(1); const jump = jumpFrom(x0, y0); let xf = 0; for (let i = 0; i < 120; i++) { steps(1); if (selfX()) xf++; } return { jump: +jump.toFixed(1), crossFrames: xf }; };
    r40.press = { clay: pressUp('clay'), mochi: pressUp('mochi'), jelly: pressUp('jelly') };
    L8('clay', {}); { const bi = edgeI(1, 0); let q = sc(X[bi] - R * .1, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(4); let x = q[0]; for (let i = 0; i < 30; i++) { x += R * 2 / 30; ev('pointermove', 1, x, q[1]); steps(1); } ev('pointerup', 1, x, q[1]); steps(30); relax(); let xf = 0; for (let i = 0; i < 120; i++) { steps(1); if (selfX()) xf++; } r40.relax = { crossFrames: xf, qdevPt: +qdev().toFixed(1) }; }
    // e 放著
    L8('clay', {}); { steps(180); const q1 = qdMax(); r40.idleQdPt = +(q1 * R).toFixed(2); }
    // f 減少動態：阻尼比至少 0.7，不過衝
    r40.reduced = ring('jelly', { inertiaZ: .7 });
    sample = null; substep = sub1;
    // g 全開暴力玩法
    const abuse = name => { L8(name, { drops: 0, dropsV: 0 }, true); let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / (A0 * MASSD); aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r40.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    // 放著走路 30 秒：走路是整團平移，參考形狀不該被帶歪
    L8('jelly', { sleep: 0 }, true); LIFE.until = t + .5; { let xf = 0, qm = 0; for (let i = 0; i < 1800; i++) { steps(1); if (selfX()) xf++; qm = Math.max(qm, qdMax()); } r40.walk = { crossFrames: xf, qdMaxR: +qm.toFixed(3) }; }
    res.T40_v225 = r40; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

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
  // T41 v2.26 F6 F7（診斷第二節：手指劃過身體整團被帶走 74 到 113 點、凹痕整個在手指底下）。舊項目、T39、T40 都關（OFF26），這裡全開。
  //   a 摸：左半劃到右外，手指滑過去（stroke），整團最多被帶 0.3R 內、放開回來 2 點內、零交叉、黏土不記形（關掉帶 0.5R 以上）；
  //   b 拉（抓是主要動作，寧可判成抓）：從身體側邊快速往下拖（v2.26.1，一般手指要加速 0.2 秒到每秒 1100 點）、邊緣往外扯、往右下拉（T36，多米 build 77 錄影的拉法）、中心往外甩、一般拖法（慢慢加速）、猛扯、兩指快拉都還是抓，拉力跟關掉差 0.05R 內；第二根手指緊接著落下，第一根摸回抓；
  //   c 摸到一半停住變抓，接著拉得動；d 從外面劃進來是摸，慢慢推還是推；e 摸三下：2.5 秒內舒服、呼嚕、熟，不縮、不逃；
  //   f 按著：手指外面看得到的變化比關掉多 1500 平方點以上；揉的時候凹痕還在、痕跡半秒內淡完；g 亮光跟著拉伸；h 全開暴力玩法（含一直劃過去）零交叉、留形不變
  { const clock = saveClock(); Math.random = seeded(20261226); const r41 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, drops: 0, dropsV: 0, eyes: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L10 = (name, o, full) => { resetAligned(1e9, { ...PSAVE[name], seed: 7, ...(full ? {} : QUIET), ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; DROPV.last = -99; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(30); log.splice(0); };
    const OFF = OFF26, MATS = ['clay', 'mochi', 'jelly'], U = Math.SQRT1_2;
    const go = (name, o, lx, ly, dx, dy, peak, rampT, T, full) => { L10(name, o, full); const q = sc(globalC.xc + lx * R, globalC.yc + ly * R); let x = q[0], y = q[1]; const c0x = globalC.xc, c0y = globalC.yc; ev('pointerdown', 1, x, y); const f = fingers.get(1); let first = null, pk = 0, xf = 0; const fr = Math.round(T * 60);
      for (let i = 1; i <= fr; i++) { const vv = peak * Math.min(1, (i / 60) / rampT); x += dx * vv / 60; y += dy * vv / 60; ev('pointermove', 1, x, y); steps(1); if (!first && !f.judge) first = f.mode; pk = Math.max(pk, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); if (selfX()) xf++; }
      const end = f.mode, mv = Math.hypot(globalC.xc - c0x, globalC.yc - c0y); ev('pointerup', 1, x, y); for (let i = 0; i < 120; i++) { steps(1); pk = Math.max(pk, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); if (selfX()) xf++; }
      return { first, end, moveR: +(mv / R).toFixed(2), peakR: +(pk / R).toFixed(3), backPt: +Math.hypot(globalC.xc - c0x, globalC.yc - c0y).toFixed(1), crossFrames: xf, qdev: +qdev().toFixed(2) }; };
    // a 摸
    r41.swipe = {}; for (const k of MATS) { r41.swipe[k] = go(k, {}, -.55, 0, 1, 0, 500, .001, .42); r41.swipe[k + 'Fast'] = go(k, {}, -.55, .2, 1, 0, 1200, .001, .25); r41.swipe[k + 'Off'] = go(k, OFF, -.55, 0, 1, 0, 500, .001, .42); }
    // b 拉
    const pair = (name, ...a) => ({ on: go(name, {}, ...a), off: go(name, OFF, ...a) });
    r41.pull = { edge: pair('jelly', .8, .3, 1, 0, 600, .001, .5), rb: pair('jelly', .7, .7, U, U, 590, .001, .5), center: pair('jelly', 0, 0, 1, 0, 240, .001, .4), dragSlow: pair('clay', -.5, 0, 1, 0, 600, .25, .5), yank: pair('clay', .75, .4, 1, .3, 1500, .001, .12), press: pair('mochi', -.5, 0, 1, 0, 100, .001, 1) };
    { L10('clay', {}); const c = sc(globalC.xc, globalC.yc); let a = c[0] - R * .7, b = c[0] + R * .7; const y = c[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); const f1 = fingers.get(1), f2 = fingers.get(2); for (let i = 0; i < 30; i++) { a -= 12; b += 12; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); steps(1); } let x0 = 1e9, x1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } r41.twoFinger = { m1: f1.mode, m2: f2.mode, widthR: +((x1 - x0) / R).toFixed(2) }; ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); steps(30); }
    { L10('clay', {}); const c = sc(globalC.xc, globalC.yc); let a = c[0] - R * .7; const y = c[1]; ev('pointerdown', 1, a, y); const f1 = fingers.get(1); for (let i = 0; i < 4; i++) { a += 10; ev('pointermove', 1, a, y); steps(1); } const m0 = f1.mode; ev('pointerdown', 2, c[0] + R * .7, y); steps(1); r41.secondFinger = { before: m0, after: f1.mode, m2: fingers.get(2).mode }; ev('pointerup', 1, a, y); ev('pointerup', 2, c[0] + R * .7, y); steps(30); }
    // c 摸到一半停住
    { L10('clay', {}); const q = sc(globalC.xc - R * .6, globalC.yc); let x = q[0]; ev('pointerdown', 1, x, q[1]); const f = fingers.get(1); for (let i = 0; i < 12; i++) { x += 500 / 60; ev('pointermove', 1, x, q[1]); steps(1); } const mid = f.mode, memMid = f.mem.length; steps(18); const after = f.mode, memAfter = f.mem.length, c0 = globalC.xc; for (let i = 0; i < 30; i++) { x -= 6; ev('pointermove', 1, x, q[1]); steps(1); } steps(20); r41.stopGrab = { mid, memMid, after, memAfter, movedPt: +Math.abs(globalC.xc - c0).toFixed(1) }; ev('pointerup', 1, x, q[1]); steps(30); }
    // d 從外面
    r41.fromOut = go('clay', {}, -1.5, 0, 1, 0, 500, .001, .7); r41.slowPush = go('clay', {}, -1.5, 0, 1, 0, 100, .001, 1.2);
    // e 摸三下（行為全開）
    { L10('clay', {}, true); LIFE.st = 'rest'; LIFE.until = 1e9; SLP.lastAny = t; WANDER.next = 1e9; const t0 = t, f0 = FLN.t0; let first = -1, pm = 0, cm = 0;
      for (let s3 = 0; s3 < 3; s3++) { const q = sc(globalC.xc - R * .6, globalC.yc + R * .1); let x = q[0]; ev('pointerdown', 1, x, q[1]); for (let i = 0; i < 21; i++) { x += 500 / 60; ev('pointermove', 1, x, q[1]); steps(1); pm = Math.max(pm, PURR); cm = Math.max(cm, MOOD.c); if (first < 0 && PURR > .03) first = t - t0; } ev('pointerup', 1, x, q[1]); for (let i = 0; i < 18; i++) { steps(1); pm = Math.max(pm, PURR); if (first < 0 && PURR > .03) first = t - t0; } }
      r41.pet = { firstPurrS: +first.toFixed(2), purrMax: +pm.toFixed(2), cMax: +cm.toFixed(2), tr: +IMP.tr.toFixed(3), esc: ESC.on, flinched: FLN.t0 !== f0 }; steps(70); r41.pet.happy = MOOD.happyT > t0; for (let i = 0; i < 60; i++) steps(1); }
    // f 手指外面看得到多少（手指畫成寬 96、高 140 的橢圓，指尖在按的點上方 30 點）
    const visible = (o, name) => { L10(name, o); draw(); const W2 = cv.width, H2 = cv.height, g0 = ctx.getImageData(0, 0, W2, H2).data.slice(), q = sc(globalC.xc, globalC.yc), d0 = W2 / W; ev('pointerdown', 1, q[0], q[1]); steps(30); draw(); const d1 = ctx.getImageData(0, 0, W2, H2).data; let n = 0; const st = 2; for (let y = 0; y < H2; y += st) for (let x = 0; x < W2; x += st) { const ex = (x / d0 - q[0]) / 48, ey = (y / d0 - q[1] - 40) / 70; if (ex * ex + ey * ey < 1) continue; const k = (y * W2 + x) * 4; if (Math.abs(g0[k] - d1[k]) + Math.abs(g0[k + 1] - d1[k + 1]) + Math.abs(g0[k + 2] - d1[k + 2]) > 12) n++; } ev('pointerup', 1, q[0], q[1]); steps(30); return Math.round(n * st * st / (d0 * d0)); };
    r41.visible = { clay: visible({}, 'clay'), clayOff: visible(OFF, 'clay'), jelly: visible({}, 'jelly'), jellyOff: visible(OFF, 'jelly') };
    { L10('clay', {}); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(12); let x, y; for (let i = 0; i < 60; i++) { const a = i / 60 * 2 * Math.PI * 1.5; x = q[0] + R * .3 * (1 - Math.cos(a)); y = q[1] + R * .3 * Math.sin(a); ev('pointermove', 1, x, y); steps(1); } const dn = DENTS.find(o => o.f === 1); r41.rub = { dentD: dn ? +dn.d.toFixed(2) : 0, trail: TRAIL.length, mode: fingers.get(1).mode }; ev('pointerup', 1, x, y); steps(40); r41.rub.trailAfter = TRAIL.length; }
    // g 亮光
    { L10('clay', {}); const q = sc(X[hiIdx] - R * .05, Y[hiIdx] - R * .05); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0], y = q[1]; for (let i = 0; i < 30; i++) { x -= R * 1.2 * .64 / 30; y -= R * 1.2 * .77 / 30; ev('pointermove', 1, x, y); steps(1); } steps(10); const [a, b, c, d] = dentFrame(HIF), h0 = (a + d) / 2, h1 = Math.hypot((a - d) / 2, (b + c) / 2); r41.hi = { big: +(h0 + h1).toFixed(2), small: +(h0 - h1).toFixed(2) }; ev('pointerup', 1, x, y); steps(30); }
    // h 暴力玩法、留形
    const abuse = name => { L10(name, { drops: 0, dropsV: 0 }, true); let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / (A0 * MASSD); aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      for (let k = 0; k < 6; k++) { q = c(); x = q[0] - R * .8; y = q[1] + R * (k * .25 - .6); ev('pointerdown', 1, x, y); tick(24, () => { x += R * 2 / 24; y += R * .1 / 24; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(8); } tick(60);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r41.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    const keep = o => { L10('clay', o); let bi = bnd[0]; for (const i of bnd) if (X[i] > X[bi]) bi = i; const rest = X[bi] - globalC.xc, q = sc(X[bi] - R * .1, Y[bi]); let x = q[0]; ev('pointerdown', 1, x, q[1]); steps(6); for (let i = 0; i < 15; i++) { x += R / 15; ev('pointermove', 1, x, q[1]); steps(1); } steps(30); const pre = X[bi] - globalC.xc; ev('pointerup', 1, x, q[1]); steps(120); return +((X[bi] - globalC.xc - rest) / (pre - rest)).toFixed(2); };
    r41.keep2s = { on: keep({}), off: keep(OFF) };
    r41.pull.dragSide = pair('clay', -.5, 0, 0, 1, 1100, .2, .4);   // v2.26.1
    res.T41_v226 = r41; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }


  // T42 v2.27（多米 11-05：去眼睛、8 條真觸手、心情變色、觸手互撞）。舊項目都關（OFF27），這裡全開。
  //   a 外形：8 條、整隻在畫面裡、沒有眼睛；b 每條都抓得住、拉得長、抓著不抖（v2.8 真機就是這裡纏住抖）；c 黏土拉長留著、果凍彈回；
  //   d 往根推、繞到身體後面：滑開不對折；e 亂玩 3 種材質 2 組亂數：沒有留下對折或互疊、停得下來；f 撞到別條會彈開；g 心情染色、平常原色、不跳
  { const clock = saveClock(); Math.random = seeded(20261105); const r42 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, drops: 0, dropsV: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L = (name, o) => { resetAligned(1e9, { ...P27[name], seed: 7, ...QUIET, ...(o || {}) }); impReset(); IMPD.tr = 0; IMPD.w = 0; CAM.x = viewV().x; MC.c = MC.s = MC.w = MC.z = 0; };
    const tip = k => { let b = -1; for (const i of bnd) if (TID[i] === k && (b < 0 || TU[i] > TU[b])) b = i; return b; };
    const rootOf = k => { let x = 0, y = 0; for (const i of TENT[k].root) { x += X[i]; y += Y[i]; } const n = TENT[k].root.length; return [x / n, y / n]; };
    const jit = (m, on) => { let jm = 0, xf = 0, ax = Float64Array.from(X), ay = Float64Array.from(Y); for (let i = 0; i < m; i++) { if (on) on(i); steps(1); let d = 0; for (let j = 0; j < N; j++) d = Math.max(d, Math.hypot(X[j] - ax[j], Y[j] - ay[j])); ax = Float64Array.from(X); ay = Float64Array.from(Y); if (i > m * .4) jm = Math.max(jm, d); if (classify()[0]) xf++; } return { jm: +jm.toFixed(1), xf }; };
    // a 外形
    L('clay'); { let a = 1e9, b = -1e9, c = 1e9, d = -1e9; for (const i of bnd) { const p = sc(X[i], Y[i]); a = Math.min(a, p[0]); b = Math.max(b, p[0]); c = Math.min(c, p[1]); d = Math.max(d, p[1]); } r42.shape = { tents: TENT.length, N, x0: a | 0, x1: b | 0, y0: c | 0, y1: d | 0, W, H, z: +CAM.z.toFixed(2), selfX: selfX(), eyes: ['clay', 'mochi', 'jelly'].map(k => P27[k].eyes) }; }
    // b 每條都抓得住
    r42.pulls = {}; for (const name of ['clay', 'mochi', 'jelly']) { L(name); let held = 9e9, gap = 0, hj = 0, xf = 0, grab = 0; for (let k = 0; k < TENT.length; k++) { const b = tip(k), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy) || 1, p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const f = fingers.get(1); held = Math.min(held, f.mem.length); const mv = jit(24, () => { x += ux / ul * R * 1.2 / 24; y += uy / ul * R * 1.2 / 24; ev('pointermove', 1, x, y); }); steps(40); const hold = jit(30); const g = sc(X[b], Y[b]); gap = Math.max(gap, Math.hypot(g[0] - x, g[1] - y)); hj = Math.max(hj, hold.jm); xf += mv.xf + hold.xf; if (f.mode === 'grab') grab++; ev('pointerup', 1, x, y); xf += jit(90).xf; } r42.pulls[name] = { minHeld: held, grabbed: grab, maxGap: +gap.toFixed(1), holdJ: hj, foldFrames: xf, end: selfX() }; }
    // b2 從身體中間往觸手的方向拉，要抓得住（一度會馬上滑開：補抓帶到觸手的粒子就被當成抓觸手）
    r42.bodyPull = {}; for (const name of ['clay', 'jelly']) { let lost = 0, mv = 0; for (let k = 0; k < TENT.length; k++) { L(name); const b = tip(k), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy), p = sc(c.xc + ux / ul * R * .3, c.yc + uy / ul * R * .3); let x = p[0], y = p[1]; const c0x = c.xc, c0y = c.yc; ev('pointerdown', 1, x, y); steps(8); const f = fingers.get(1); for (let i = 0; i < 16; i++) { x += ux / ul * R * 1.6 / 16; y += uy / ul * R * 1.6 / 16; ev('pointermove', 1, x, y); steps(1); } if (f.mode !== 'grab') lost++; mv = Math.max(mv, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); ev('pointerup', 1, x, y); steps(20); } r42.bodyPull[name] = { lost, moved: +mv.toFixed(1) }; }
    // c 長度留著
    const keep = name => { L(name); const b = tip(2), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy), p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); jit(24, () => { x += ux / ul * R * 1.2 / 24; y += uy / ul * R * 1.2 / 24; ev('pointermove', 1, x, y); }); jit(60); const held = Math.hypot(X[b] - globalC.xc, Y[b] - globalC.yc); ev('pointerup', 1, x, y); jit(120); const a2 = Math.hypot(X[b] - globalC.xc, Y[b] - globalC.yc); return { rest: +ul.toFixed(1), held: +held.toFixed(1), after2s: +a2.toFixed(1), keep: +((a2 - ul) / (held - ul)).toFixed(2) }; };
    r42.keep = { clay: keep('clay'), jelly: keep('jelly') };
    // d 往根推、繞到身體後面
    const cross = name => { L(name); let hj = 0, xf = 0, end = 0; for (let k = 0; k < TENT.length; k += 2) { const b = tip(k), c = globalC, p = sc(X[b], Y[b]), q = sc(c.xc - (X[b] - c.xc), c.yc - (Y[b] - c.yc)); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const dx = (q[0] - x) / 50, dy = (q[1] - y) / 50; const a = jit(50, () => { x += dx; y += dy; ev('pointermove', 1, x, y); }); const h = jit(40); hj = Math.max(hj, h.jm); xf += a.xf + h.xf; ev('pointerup', 1, x, y); xf += jit(120).xf; end += selfX(); } return { holdJ: hj, foldFrames: xf, end }; };
    const around = name => { L(name); let hj = 0, xf = 0, end = 0; for (let k = 0; k < TENT.length; k += 3) { const b = tip(k), c = globalC, a0 = Math.atan2(Y[b] - c.yc, X[b] - c.xc), rr = Math.hypot(X[b] - c.xc, Y[b] - c.yc) * 1.05, p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const a = jit(70, i => { const an = a0 + (i + 1) / 70 * 2.4, q = sc(c.xc + Math.cos(an) * rr, c.yc + Math.sin(an) * rr); x = q[0]; y = q[1]; ev('pointermove', 1, x, y); }); const h = jit(40); hj = Math.max(hj, h.jm); xf += a.xf + h.xf; ev('pointerup', 1, x, y); xf += jit(120).xf; end += selfX(); } return { holdJ: hj, foldFrames: xf, end }; };
    r42.cross = {}; r42.around = {}; for (const name of ['clay', 'mochi', 'jelly']) { r42.cross[name] = cross(name); r42.around[name] = around(name); }
    // e 亂玩
    const abuse = (name, seed) => { Math.random = seeded(seed); L(name); let same = 0, n = 0; const cnt = () => { if (classify()[0]) same++; n++; }; for (let s = 0; s < 24; s++) { const c = globalC, a0 = Math.random() * 6.28, rr = R * (.3 + Math.random() * 1.3), p = sc(c.xc + Math.cos(a0) * rr, c.yc + Math.sin(a0) * rr); let x = p[0], y = p[1]; const a1 = Math.random() * 6.28, sp = R * (1 + Math.random() * 6) / 60, two = s % 5 === 4, x2 = x + R * .9, y2 = y; ev('pointerdown', 1, x, y); if (two) ev('pointerdown', 2, x2, y2); const m = 20 + Math.random() * 50 | 0; for (let i = 0; i < m; i++) { x += Math.cos(a1) * sp; y += Math.sin(a1) * sp; ev('pointermove', 1, x, y); if (two) ev('pointermove', 2, x2 + Math.cos(a1) * sp * i, y2 - Math.sin(a1) * sp * i); steps(1); cnt(); } for (let i = 0; i < 40; i++) { steps(1); cnt(); } ev('pointerup', 1, x, y); if (two) ev('pointerup', 2, x2, y2); for (let i = 0; i < 30; i++) { steps(1); cnt(); } } const last = jit(240), e = classify(); return { n, foldFrames: same, endJ: last.jm, endFold: e[0], endOverlap: e[1] }; };
    r42.abuse = {}; for (const name of ['clay', 'mochi', 'jelly']) r42.abuse[name] = [abuse(name, 11), abuse(name, 22)];
    // f 撞到別條會彈開：固定一條，拿另一條去撞
    const hit = (name, o, m) => { Math.random = seeded(5); L(name, o); const a = tip(0), b = tip(1), d = tip(3), dp = sc(X[d], Y[d]); ev('pointerdown', 2, dp[0], dp[1]); let p = sc(X[a], Y[a]), x = p[0], y = p[1]; const q = sc(X[b] + (X[b] - X[a]) * .9, Y[b] + (Y[b] - Y[a]) * .9); TBUMP.n = 0; ev('pointerdown', 1, x, y); const tr = [], rec = () => { const r = rootOf(1); tr.push([X[b] - r[0], Y[b] - r[1]]); }; const dx = (q[0] - x) / m, dy = (q[1] - y) / m; jit(m, () => { x += dx; y += dy; ev('pointermove', 1, x, y); rec(); }); jit(30, rec); ev('pointerup', 1, x, y); ev('pointerup', 2, dp[0], dp[1]); jit(60, rec); return { tr, kicks: TBUMP.n, end: selfX() }; };
    r42.bump = {}; for (const name of ['clay', 'jelly']) { const A = hit(name, {}, 40), B = hit(name, { tentBump: 0 }, 40); let dm = 0; for (let i = 0; i < Math.min(A.tr.length, B.tr.length); i++) dm = Math.max(dm, Math.hypot(A.tr[i][0] - B.tr[i][0], A.tr[i][1] - B.tr[i][1])); r42.bump[name] = { kicks: A.kicks, kicksOff: B.kicks, tipDiff: +dm.toFixed(1), end: A.end }; }
    // g 心情染色
    const near = (a, b) => { const p = s => s[0] === '#' ? [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)] : s.match(/\d+/g).map(Number), u = p(a), w = p(b); return Math.max(Math.abs(u[0] - w[0]), Math.abs(u[1] - w[1]), Math.abs(u[2] - w[2])); };
    { const O = { emo: 1, moodColor: .8 }, base = '#FFD96B'; L('clay', O); steps(180); r42.mood = { calmOff: near(tint(base), base), calm: { ...MC } };
      let c0 = globalC, p = sc(c0.xc, c0.yc), th = 0, maxStep = 0, prev = tint(base); ev('pointerdown', 1, p[0] + 30, p[1]); for (let i = 0; i < 240; i++) { th += .12; ev('pointermove', 1, p[0] + 30 * Math.cos(th), p[1] + 30 * Math.sin(th)); steps(1); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.comfy = +MC.c.toFixed(2); r42.mood.comfyOff = near(tint(base), base); r42.mood.purr = +PURR.toFixed(2); ev('pointerup', 1, p[0], p[1]); steps(30);
      L('clay', O); prev = tint(base); c0 = globalC; p = sc(c0.xc + R * .3, c0.yc); let x = p[0]; ev('pointerdown', 1, x, p[1]); steps(8); let spk = 0; for (let i = 0; i < 16; i++) { x += R * 2.6 / 16; ev('pointermove', 1, x, p[1]); steps(1); spk = Math.max(spk, MC.s); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } for (let i = 0; i < 40; i++) { steps(1); spk = Math.max(spk, MC.s); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.strain = +spk.toFixed(2); r42.mood.strainMax = +MOOD.strainMax.toFixed(2); ev('pointerup', 1, x, p[1]); steps(10);
      L('clay', { ...O, sleep: 1, life2: 1 }); prev = tint(base); SLP.lastAny = t; LIFE.st = 'sleep'; LIFE.until = 1e9; SLP.on = true; for (let i = 0; i < 300; i++) { steps(1); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.sleep = +MC.z.toFixed(2); SLP.on = false; steps(5);
      L('clay', { ...O, imp: 1 }); IMP.w = .9; IMPD.w = .9; for (let i = 0; i < 90; i++) { IMP.w = .9; IMPD.w = .9; steps(1); } r42.mood.wary = +MC.w.toFixed(2); impReset(); IMPD.w = 0;
      r42.mood.maxStep = maxStep; mat = { ...mat, moodColor: 0 }; MC.c = MC.s = MC.w = MC.z = 0; r42.mood.offEqualsBase = near(tint(base), base); }
    { const cost = o => { L('clay', o); const c = globalC, p = sc(c.xc + R * .4, c.yc); ev('pointerdown', 1, p[0], p[1]); const t0 = performance.now(); for (let i = 0; i < 200; i++) { ev('pointermove', 1, p[0] + 40 * Math.cos(i / 10), p[1] + 40 * Math.sin(i / 10)); steps(1); } const ms = (performance.now() - t0) / 200; ev('pointerup', 1, p[0], p[1]); return +ms.toFixed(2); }; r42.msPerFrame = { off: cost({ limbs: 0 }), on: cost({}) }; }
    res.T42_v227 = r42; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

  const L9 = res.T34_life;
  const V5 = res.T35_v220, P6 = res.T36_pull, V7 = res.T37_v222, X8 = res.T38_v223, Y9 = res.T39_v224, Z0 = res.T40_v225, A1 = res.T41_v226;
  res.PASS = {
    // folds must be gone once the finger is off (a fold the clay remembers would be a real bug)
    noFoldAfterRelease: [res.T1_tap.after2s, res.T2_hold.afterRelease1s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(s => s.fold === 0) && res.T7_idle.worstSelfX === 0,
    areaBack: [res.T1_tap.after2s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(okArea) && res.T7_idle.areaMin > 0.97 && res.T7_idle.areaMax < 1.03,
    firstFrameMoves: res.T1_tap.firstFrameMove > 1,
    // 2026-11-01 多米真機回報後：黏土留痕放著約 10 秒退掉；輕按 0.1 秒留多少只記錄（T1.after2s.qdev）
    tapMarkGone: res.T1_tap.after12s.qdev < 1,
    holdLeavesMark: res.T2_hold.afterRelease1s.qdev > 3,
    // 門檻 1.5（v2.24）：T2 沒把呼吸相位歸零，掃 24 個相位量到 0.87 到 1.01，1 就壓在雜訊上（每輪長度一變就會掛）；揉回原形壞掉時是 19
    relaxClearsMark: res.T2_hold.afterRelax1s.qdev < 1.5,
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
    zoomUnlimited: res.T26_zoomUnlimited.widthMaxR > 7 && res.T26_zoomUnlimited.zoomMin < 0.45 && res.T26_zoomUnlimited.offScreenFrames === 0 && res.T26_zoomUnlimited.jitterMaxPt < 5 && res.T26_zoomUnlimited.worstReleaseX === 0 && res.T26_zoomUnlimited.end.selfX === 0 && okArea(res.T26_zoomUnlimited.end),
    // 手指停住：形狀不自己長（< 0.3R）、邊界每幀跳動不到 3 點、零交叉
    stillFingerSteady: res.T29_stillFinger.every(r => r.grewR < 0.3 && r.jitterMaxPt < 3 && r.crossFrames === 0),
    // 點一下：按 0.1 秒凹痕深過 0.5、1 秒後還在、15 秒淡了但還看得到（0.15 以上）；拉開的那次凹痕收掉
    // 按壓：整團變大 4% 到 15%、關掉時不變；按 3 秒的最遠位移不超過 1.5 秒的 1.3 倍；黏土放手 1 秒凹痕還在；果凍過頭彈、1 秒收乾淨；零自交
    pressReal: res.T31_press.clayArea08 > 1.04 && res.T31_press.clayArea08 < 1.15 && res.T31_press.offArea08 < 1.01 && res.T31_press.clayMove3 < res.T31_press.clayMove15 * 1.3 && res.T31_press.clayDent1s > 0.5 && res.T31_press.jellyOvershoot < -0.1 && res.T31_press.jellyDentsAfter1s === 0 && res.T31_press.foldFrames === 0,
    // 開場：落地 4 次、落地壓扁到 0.9 以下、3.2 秒內、碰一下直接到家；鏡頭跟隨：會跑出畫面、4 秒後追到中心附近、抓著時鏡頭不動；全程零對折
    introFollow: res.T32_introFollow.introLands === 4 && res.T32_introFollow.landAspect < 0.9 && res.T32_introFollow.introSec < 3.2 && okArea(res.T32_introFollow.afterIntro) && res.T32_introFollow.skipOff && Math.abs(res.T32_introFollow.skipScale - 1) < 0.01 && res.T32_introFollow.skipFingers === 0 && res.T32_introFollow.followOutPt > 0 && res.T32_introFollow.followEndOff < PRESETS.clay.followStop + 0.1 && res.T32_introFollow.grabCamMovePt < 1 && res.T32_introFollow.foldFrames === 0,
    // 情緒：拉扯想逃（strain > 0.8、舒服變負、放手往反方向逃 0.4 畫面寬以上）、輕揉呼嚕（舒服、呼嚕 > 0.3、放手開心小跳）、連戳 3 下閃開；零對折、面積回來
    moodWorks: res.T33_mood.strainHeld > 0.8 && res.T33_mood.moodPulled < 0 && res.T33_mood.fleeStarted && res.T33_mood.fledW > 0.4 && okArea(res.T33_mood.afterFlee) && res.T33_mood.purrMax > 0.3 && res.T33_mood.comfortMax > 0.3 && res.T33_mood.happyHop && res.T33_mood.dartStarted && res.T33_mood.dartW > 0.15 && res.T33_mood.foldFrames === 0,
    // v2.19 活物感：休息 0.35 到 0.65、有探有走；碰著呼吸還在、沒被記進形狀；晚一拍才縮、會習慣；一縮一衝的速度高峰在收縮那段、路線彎、走得到；
    // 碰旁邊空白處會探、不凍住；拉完甩一甩、探手指離開的地方；全程零對折
    // v2.20：拖著走（跟過去 0.55R 到 0.85R、被抓那端照樣跟手、放手不退、零自交、面積回來）；凹痕 0.6 秒、1.5 秒退完，形狀照舊；印象漲退；
    // C1 熟的碰到手指、戒的退開；C2 撲、嚇一下；C4 討摸後呼嚕來得快；C5 戒的縮得大；零對折
    v220: V5.drag.on.followR > 0.55 && V5.drag.on.followR < 0.85 && V5.drag.off.followR < 0.1 && Math.abs(V5.drag.on.grabGapR - V5.drag.off.grabGapR) < 0.3 && V5.drag.on.backAfter2sR < 0.1 && V5.drag.on.worstSelfX === 0 && V5.drag.on.end.area < V5.drag.off.end.area + 0.01
      && V5.dent.tapAt06 < 0.05 && V5.dent.holdAt15 < 0.05 && V5.dent.tapOldAt06 > 0.4 && V5.dent.qdevDiffPt < 0.5
      && V5.imp.trAfterRub6s > 0.1 && V5.imp.wAfterStrain > 0.2 && V5.imp.wAfter3minRatio > 0.45 && V5.imp.wAfter3minRatio < 0.55
      && V5.c1.come.hitS >= 0 && V5.c1.come.hitS < 6 && V5.c1.backGainR > 0.5 && V5.c1.end.selfX === 0
      && V5.c2.pounceS >= 0 && V5.c2.pounceS < 0.5 && V5.c2.startled
      && V5.c4.firstPurrS > 1 && V5.c4.asked && V5.c4.secondPurrS >= 0 && V5.c4.secondPurrS < 0.6 && V5.c5.flinchRatio > 1.5 && V5.foldFrames === 0,
    // v2.21 拉力：果凍單指拉 2.5R 整團跟 1.5R 以上、拉長 0.9R 以下（slide 0 不到 0.7R）；猛一扯比慢拉長 0.3R；兩指往兩邊拉寬過 4.5R、整團不動；甩出去再滑 0.3R；零自交、面積回來
    pullForce: P6.jelly.moveR > 1.5 && P6.jelly.stretchR < 0.9 && P6.jellyOff.moveR < 0.7 && P6.clayYank.maxStretchR > P6.claySlow.maxStretchR + 0.3 && P6.twoFinger.widthR > 4.5 && P6.twoFinger.moveR < 0.2
      && P6.fling.glideR > 0.3 && P6.worstSelfX === 0 && okArea(P6.jelly.end) && okArea(P6.fling.end),
    // v2.22：點一下會傾、會「噗」；按著會蹭、會「嗯～」；搔癢會扭、會笑、撥久會掙脫；E3 熟得快；E4 會游過來打招呼；黏液會掉、會被吸回去、你拖過去會吸、你抓著它會來搶；零自交
    v222: V7.tap.leanAfter > 0.25 && V7.tap.leanAfter < 0.45 && V7.tap.voices.includes('poke') && V7.nuzzle.swayR > 0.03 && V7.nuzzle.voices.includes('mmm')
      && V7.tickle.shakes >= 3 && V7.tickle.escapeS > 3.2 && V7.tickle.escapeS < 5 && V7.tickle.voices.includes('giggle') && V7.tickle.voices.includes('protest')
      && V7.e3.trOn > 0.5 && V7.e3.trOff < 0.3 && V7.e4.count === 1 && V7.e4.helloAt > 0 && V7.e4.distR < 0.6
      && V7.drops.spawned >= 1 && V7.drops.massAfter < 1 && V7.drops.allEatenS >= 0 && V7.drops.massEnd > 0.995 && V7.drops.offSpawned === 0 && V7.drops.gulps >= 1
      && V7.dragIn.held === 'held' && V7.dragIn.left === 0 && V7.dragIn.mass > 0.995 && V7.snatch.gotAt > 0 && V7.snatch.left === 0 && V7.worstSelfX === 0,
    // v2.23：慢拉、兩指慢慢拉開不掉黏液，猛扯掉一滴、有拉絲、會離開；眼睛看手指、會眨、搔癢 > <、呼嚕 ∩；40 秒睡著、碰到嚇醒；照節奏回、你接著回它會開心、點一下不回；游過來到家打招呼、鏡頭不動；四隻都正常、印象分開記
    v223: X8.drops.slow.n === 0 && X8.drops.apart === 0 && X8.drops.yank.n === 1 && X8.drops.yank.neck >= 8 && X8.drops.yank.sepR > 0.25 && X8.drops.yank.n2 === 1 && X8.drops.yank.after === 1
      && X8.eyes.lookGx > 0.5 && X8.eyes.blinks10s >= 2 && X8.eyes.tickleSqueeze > 10 && X8.eyes.purrHappy > 10
      && X8.sleep.at >= 39.9 && X8.sleep.at < 45 && X8.sleep.eye === 'sleep' && X8.sleep.woke && X8.sleep.flinch > 0.06 && X8.sleep.voices.includes('ask')
      && X8.echo.beats === 3 && X8.echo.iv.every(x => x > 0.35 && x < 0.45) && X8.echo.firstAfter > 0.9 && X8.echo.firstAfter < 1.6 && X8.echo.again === 3 && X8.echo.joy && X8.echo.single === 0
      && X8.swim.startOffR > 2 && X8.swim.arriveS > 0 && X8.swim.arriveS < 4.5 && X8.swim.helloS > 0 && X8.swim.camMoved < 5 && X8.swim.end.selfX === 0
      && X8.collect.slimes.every(q => q.mat && q.seed && q.color && q.aMin > 0.97 && q.aMax < 1.03 && q.selfX === 0) && X8.collect.impBack === 0.7 && X8.worstSelfX === 0,
    // v2.26：見 T41 開頭的 a 到 h
    v227: (() => { const A = res.T42_v227, s = A.shape, ok3 = f => ['clay', 'mochi', 'jelly'].every(f); return s.tents === 8 && s.selfX === 0 && s.x0 >= 0 && s.x1 <= s.W && s.y0 >= 0 && s.y1 <= s.H && s.z >= .85 && s.eyes.every(e => e === 0)
      && ok3(k => { const p = A.pulls[k]; return p.grabbed === 8 && p.minHeld >= 5 && p.maxGap < 25 && p.holdJ < 6 && p.foldFrames === 0 && p.end === 0; }) && A.bodyPull.clay.lost === 0 && A.bodyPull.jelly.lost === 0 && A.keep.clay.keep > .6 && A.keep.jelly.keep < .4
      && ok3(k => A.cross[k].holdJ < 15 && A.cross[k].foldFrames === 0 && A.cross[k].end === 0 && A.around[k].holdJ < 15 && A.around[k].end === 0)
      && ok3(k => A.abuse[k].every(r => r.foldFrames < r.n * .05 && r.endFold === 0 && r.endJ < 12))
      && A.bump.clay.kicks >= 1 && A.bump.clay.tipDiff > 5 && A.bump.clay.kicksOff === 0 && A.bump.clay.end === 0
      && A.mood.calmOff <= 1 && A.mood.comfy > .5 && A.mood.comfyOff > 20 && A.mood.purr > .1 && A.mood.strain > .4 && A.mood.sleep > .5 && A.mood.wary > .5 && A.mood.maxStep < 25 && A.mood.offEqualsBase === 0; })(),
    v226: ['clay', 'mochi', 'jelly'].every(k => { const a = A1.swipe[k], q = A1.swipe[k + 'Fast'], o = A1.swipe[k + 'Off']; return a.first === 'stroke' && a.end === 'stroke' && a.peakR < .3 && a.backPt < 2 && a.crossFrames === 0 && a.qdev < 1 && q.first === 'stroke' && q.peakR < .3 && q.crossFrames === 0 && o.first === 'grab' && o.peakR > .5; })
      && ['edge', 'rb', 'center', 'dragSlow', 'dragSide', 'yank', 'press'].every(k => { const p = A1.pull[k]; return p.on.first === 'grab' && p.on.end === 'grab' && Math.abs(p.on.moveR - p.off.moveR) < .05 && p.on.crossFrames === 0; })
      && A1.twoFinger.m1 === 'grab' && A1.twoFinger.m2 === 'grab' && A1.twoFinger.widthR > 3.2 && A1.secondFinger.before === 'stroke' && A1.secondFinger.after === 'grab' && A1.secondFinger.m2 === 'grab'
      && A1.stopGrab.mid === 'stroke' && A1.stopGrab.memMid === 0 && A1.stopGrab.after === 'grab' && A1.stopGrab.memAfter > 0 && A1.stopGrab.movedPt > 40
      && A1.fromOut.end === 'stroke' && A1.fromOut.peakR < .35 && A1.fromOut.backPt < 2 && A1.fromOut.crossFrames === 0 && A1.slowPush.end === 'push'
      && A1.pet.firstPurrS > 0 && A1.pet.firstPurrS < 2.5 && A1.pet.purrMax > .2 && A1.pet.tr > 0 && !A1.pet.esc && !A1.pet.flinched && A1.pet.happy
      && A1.visible.clay > A1.visible.clayOff + 1500 && A1.visible.jelly > A1.visible.jellyOff + 1500 && A1.rub.mode === 'grab' && A1.rub.dentD > .5 && A1.rub.trail > 5 && A1.rub.trailAfter === 0
      && A1.hi.big > 1.1 && ['clay', 'mochi', 'jelly'].every(k => A1.abuse[k].crossFrames === 0 && A1.abuse[k].endSelfX === 0) && A1.keep2s.on >= A1.keep2s.off - .03,
    // v2.25：見 T40 開頭的 a 到 g
    v225: ['clay', 'mochi', 'jelly'].every(k => Z0.ring[k].firstMs > 120 && Z0.ring[k + 'Off'].firstMs < 50 && Z0.ring[k].jump < 8 && Z0.ring[k].maxV < Z0.ring[k + 'Off'].maxV / 2) && Z0.ring.mochi.swings >= 3 && Z0.ring.jelly.swings >= 3 && Z0.ring.clay.keep1s >= Z0.ring.clayOff.keep1s - .02 && Z0.ring.jellyOff.jump > 20
      && ['clay', 'mochi', 'jelly'].every(k => Z0.stop[k].overPt > 8 && Z0.stop[k].atS > .15 && Z0.stop[k].atS < .6 && Z0.stop[k].crossFrames === 0) && Z0.stop.clayOff.overPt < 1 && Z0.stop.jellyOff.overPt < 1
      && ['clay', 'mochi', 'jelly'].every(k => Math.abs(Z0.pull[k].moveR - Z0.pull[k + 'Off'].moveR) < .05 && Math.abs(Z0.pull[k].gap - Z0.pull[k + 'Off'].gap) < 3)
      && ['clay', 'mochi', 'jelly'].every(k => Z0.fling[k].crossFrames === 0 && Z0.fling[k].qdMaxR < 2.5 && Z0.fling[k].endSelfX === 0 && Z0.press[k].jump < 8 && Z0.press[k].crossFrames === 0) && Z0.twoOne.clay.crossFrames === 0 && Z0.twoOne.jelly.crossFrames === 0 && Z0.twoOne.jelly.jump < 20 && Z0.relax.crossFrames === 0 && Z0.relax.qdevPt < 5
      && Z0.idleQdPt < .5 && Z0.reduced.swings <= 1 && ['clay', 'mochi', 'jelly'].every(k => Z0.abuse[k].crossFrames === 0 && Z0.abuse[k].endSelfX === 0) && Z0.walk.crossFrames === 0 && Z0.walk.qdMaxR < .2,
    // v2.24：見 T39 開頭的 a 到 g
    v224: Y9.size.rOverW > 0.29 && Y9.size.widthPt > 220 && Y9.size.z > 0.99
      && Y9.tap.flinchMin < 0.91 && Y9.tap.leanGainR > 0.12 && Y9.nuzzleSwingR > 0.15 && Y9.gazeR > 0.15 && !Y9.dodge.on.l && !Y9.dodge.on.r
      && [Y9.rub.c1cm, Y9.rub.c5cm, Y9.rub.c12cm, Y9.rub.l5cm, Y9.rub.l7cm, Y9.rub.jelly, Y9.rub.mochi].every(q => q.purr >= 0 && q.purr < 1.7 && q.tickle < 0 && q.free < 0) && Y9.rub.hold.purr > 1.9 && Y9.rub.oldRub.purr < 0
      && Y9.rub.tickle.tickle >= 0 && Y9.rub.tickle.tickle < 1 && Y9.rub.tickle.free > 5.5 && Y9.rub.tickle.free < 7.5 && Y9.rub.tickle.protest > 0 && Y9.rub.tickle.protest < Y9.rub.tickle.free - 1 && Y9.rub.tickle.kink < 65
      && Y9.reach.on.edgePinned === 0 && Y9.reach.on.kink < 25 && Y9.reach.off.edgePinned > 0 && Y9.hold.on < 25 && Y9.hold.off > 35 && Y9.pressMemPt > 3 && Y9.reach.right.edgeMovedR > 0.8 && Y9.reach.up.edgeMovedR > 0.8 && Y9.reach.right.selfX === 0 && Y9.reach.up.selfX === 0
      && Y9.cam.r70.gapPt < 10 && Y9.cam.r70.z > 0.99 && Y9.cam.r90.gapPt < 10 && Y9.cam.d300.gapPt < 20 && Y9.cam.oldR100.gapPt > 40 && Y9.cam.r90.rightAfter < W - 8 && Y9.cam.oldD300.gapPt > 60
      && Y9.keep.keep2s > 0.75 && ['clay', 'mochi', 'jelly'].every(k => Y9.abuse[k].crossFrames === 0 && Y9.abuse[k].endSelfX === 0),
    lifeV219: L9.idle.restFrac > 0.35 && L9.idle.restFrac < 0.65 && L9.idle.sniffs >= 4 && L9.idle.goes >= 2 && L9.idle.worstSelfX === 0 && L9.idle.areaMin > 0.97 && L9.idle.areaMax < 1.03
      && L9.held.ratio > 0.35 && L9.held.ratioOff < 0.15 && L9.held.qdev1s < L9.held.qdev1sOff + 1
      && Math.abs(L9.flinch.at05 - 1) < 0.015 && L9.flinch.at30 < 0.96 && L9.flinch.fifthOverFirst < 0.3
      && L9.gait.strokes >= 8 && L9.gait.peakInContraction >= 0.8 && L9.gait.headingSpreadDeg > 8 && L9.gait.endDistR < 0.5 && L9.gait.worstSelfX === 0 && L9.gait.areaMin > 0.97 && L9.gait.areaMax < 1.03
      && L9.blank.sniffEnv06s > 0.3 && L9.blank.angDeg < 30 && L9.blank.breathRange > 0.005
      && L9.release.shakeAt > 0.25 && L9.release.shakeAt < 0.45 && L9.release.attendAt > 0.4 && L9.release.attendAt < 0.8 && L9.release.attendAngDeg < 30 && L9.release.end.selfX === 0 && L9.foldFrames === 0,
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
  // T43 v2.28 預覽：切換列只換畫面。三種皮畫得出來、切來切去物理不變、平塗和 v2.27 同一條路徑
  { mat = { ...PRESETS.clay, emo: 0, life2: 0 }; setup(); WANDER.moving = false; WANDER.next = t + 999; steps(30);
    const cx = globalC.xc, cy = globalC.yc, r43 = { skins: {} }, pix = () => { draw(); const d = ctx.getImageData(Math.round(cx * DPR), Math.round(cy * DPR), 1, 1).data; return [d[0], d[1], d[2]]; }, X0 = Float64Array.from(X), bg0 = (VIEW.skin = 'flat', pix());
    for (const k of ['A', 'B', 'C', 'flat']) { VIEW.skin = k; let threw = null; try { r43.skins[k] = pix(); } catch (e) { threw = e.message; } if (threw) r43.skins[k] = threw; }
    let dx = 0; for (let i = 0; i < N; i++) dx = Math.max(dx, Math.abs(X[i] - X0[i]));
    r43.moved = +dx.toFixed(6); r43.flatSame = r43.skins.flat.join() === bg0.join(); r43.jelFail = JEL.fail;
    VIEW.skin = 'flat'; res.T43_v228 = r43;
    res.PASS.v228 = !r43.jelFail && r43.moved === 0 && r43.flatSame && ['A', 'B', 'C'].every(k => Array.isArray(r43.skins[k]) && r43.skins[k].join() !== bg0.join()); }
  // T44 v2.28 窗台：有重力、坐得進碗、不飄走、不穿地板。背景藍的舊項目完全不受影響（SILL.on 關）
  { const r = {}, SP = { ...P27.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, emo: 0, life2: 0, seed: 12, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, drops: 0, dropsV: 0, sleep: 0, echo: 0 };
    const bottom = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, Y[i]); return m; }, top = () => { let m = 1e9; for (const i of bnd) m = Math.min(m, Y[i]); return m; };
    const fresh = () => { mat = { ...SP }; setup(); WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; };
    const worst = n => { let lo = 1e9, hi = -1e9, x0 = 1e9, x1 = -1e9, sx = 0, ar0 = 9, ar1 = 0, maxFold = 0; for (let k = 0; k < n; k++) { steps(1); lastTouch = t; const b = bottom(); lo = Math.min(lo, b); hi = Math.max(hi, b); for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } const a = area() / A0; ar0 = Math.min(ar0, a); ar1 = Math.max(ar1, a); } return { lo, hi, x0, x1, ar0, ar1 }; };
    // a 掉進碗裡停住
    fresh(); const g = SILL.g, y0 = bottom(); const a1 = worst(240); const b1 = bottom(), cy1 = globalC.yc; const a2 = worst(120);
    r.bowl = { on: SILL.on, inBowl: SILL.inBowl, startedAbove: y0 < g.rim, drift: +Math.abs(globalC.yc - cy1).toFixed(2), x: +(globalC.xc - g.bx).toFixed(1), range: +(a2.hi - a2.lo).toFixed(2), belowFloor: +(a1.hi - g.fl).toFixed(2), area: [+a1.ar0.toFixed(3), +a1.ar1.toFixed(3)], selfX: snap().selfX, air: SILL.air };
    // b 往上拉會拉高，放手掉回碗裡；拉的時候手指底下那塊跟手
    { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy - R * .4); steps(4); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, cy - R * .4 - k * R * 2.2 / 40); steps(1); } steps(20); const lift = cy - globalC.yc, outB = !SILL.inBowl; ev('pointerup', 1, cx, cy - R * 2.6); const a3 = worst(30), mid = SILL.air; const a4 = worst(240); r.pull = { liftR: +(lift / R).toFixed(2), leftBowl: outB, airAfter: mid, backInBowl: SILL.inBowl, belowFloor: +(a4.hi - g.fl).toFixed(2), selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    // c 甩到旁邊：掉到窗台上，不在碗裡，停得住
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 16; k++) { ev('pointermove', 1, cx + k * (W * .44) / 16, cy - k * R * .4 / 16); steps(1); } steps(14); ev('pointerup', 1, cx + W * .44, cy - R * .4); const a5 = worst(60); const a6 = worst(300); r.side = { inBowl: SILL.inBowl, onSill: Math.abs(a6.hi - g.fl) < 2, belowFloor: +(Math.max(a5.hi, a6.hi) - g.fl).toFixed(2), x: +globalC.xc.toFixed(0), inFrame: a6.x0 >= g.l - .5 && a6.x1 <= g.r + .5, selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    // d 走路：高度不變，往目標走
    { const x0 = globalC.xc, tx = sillClampX(x0 + (x0 < W / 2 ? 1 : -1) * R * 1.3); mat.life2 = 1; mat.lifeGait = 1; gaitTo(tx, 0, false); const dir = Math.sign(tx - x0); let lo = 1e9, hi = -1e9, n = 0; while (GAIT.on && n < 600) { lastTouch = t - 3; steps(1); const b = bottom(); lo = Math.min(lo, b); hi = Math.max(hi, b); n++; } r.walk = { frames: n, moved: +((globalC.xc - x0) * dir / R).toFixed(2), footRange: +(hi - lo).toFixed(2), selfX: snap().selfX }; mat.life2 = 0; }
    // e 閒著就跳回碗
    { lastTouch = t - 20; SILL.lastHome = t - 20; LIFE.st = 'rest'; let n = 0; let peak = 1e9; while (!SILL.inBowl && n < 400) { steps(1); peak = Math.min(peak, bottom()); n++; } const a7 = (lastTouch = t, worst(180)); r.home = { frames: n, inBowl: SILL.inBowl, clearedRim: peak < g.rim, belowFloor: +(a7.hi - g.fl).toFixed(2), selfX: snap().selfX }; }
    // f 跳出碗
    { sillHop(sillClampX(g.bx + g.bw * .5 + R * 1.2), false); const a8 = worst(180); r.hopOut = { inBowl: SILL.inBowl, onSill: Math.abs(bottom() - g.fl) < 2, x: +((globalC.xc - g.bx) / R).toFixed(2), selfX: snap().selfX, belowFloor: +(a8.hi - g.fl).toFixed(2) }; }
    // g 慢慢放在窗戶上：黏住、滑下來、掉回窗台
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc, tx = g.gx + g.gw * .85, ty = g.gy + g.gh * .18; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 70; k++) { ev('pointermove', 1, cx + (tx - cx) * k / 70, cy + (ty - cy) * k / 70); steps(1); } steps(50); ev('pointerup', 1, tx, ty); steps(3); const stuck = !!SILL.glass, y0g = globalC.yc; steps(60); lastTouch = t; const slid = globalC.yc - y0g; let n = 0; while (SILL.glass && n < 1800) { steps(1); lastTouch = t; n++; } const a9 = worst(120); r.glass = { stuck, slidR: +(slid / R).toFixed(2), framesOnGlass: n, off: !SILL.glass, onSill: Math.abs(bottom() - g.fl) < 2, selfX: snap().selfX }; }
    // h 拉不出房間：往下壓不穿地板、拉到上面不出畫面
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx, cy + k * H * .5 / 30); steps(1); } const a10 = worst(30); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, cy + H * .5 - k * H * 1.1 / 40); steps(1); } steps(20); const tp = top(); ev('pointercancel', 1, 0, 0); r.bounds = { belowFloor: +(a10.hi - g.fl).toFixed(2), top: +tp.toFixed(1), selfX: snap().selfX }; }
    // 全程開：活物、情緒都開，放 25 秒不碰，不飛走不穿牆
    mat = { ...SP, emo: 1, life2: 1, lifeGait: 1 }; setup(); { let hi = -1e9, x0 = 1e9, x1 = -1e9, m = 0; for (let k = 0; k < 1500; k++) { steps(1); hi = Math.max(hi, bottom()); for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } m = Math.max(m, Math.abs(globalC.yc - SILL.g.fl)); } r.alive = { belowFloor: +(hi - SILL.g.fl).toFixed(2), x0: +x0.toFixed(0), x1: +x1.toFixed(0), inFrame: x0 >= SILL.g.l - 1 && x1 <= SILL.g.r + 1, maxFromFloorR: +(m / R).toFixed(2), selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    mat = { ...PRESETS.clay }; setup();
    r.offInBlue = SILL.on === false;
    res.T44_sill = r;
    res.PASS.sill = r.bowl.on && r.bowl.inBowl && r.bowl.startedAbove && !r.bowl.air && r.bowl.drift < 1.5 && Math.abs(r.bowl.x) < 6 && r.bowl.belowFloor <= .01 && r.bowl.area[0] > .9 && r.bowl.area[1] < 1.1 && r.bowl.selfX === 0
      && r.pull.liftR > .6 && r.pull.leftBowl && r.pull.backInBowl && r.pull.belowFloor <= .01 && r.pull.selfX === 0 && Math.abs(r.pull.area - 1) < .06
      && !r.side.inBowl && r.side.onSill && r.side.belowFloor <= .01 && r.side.inFrame && r.side.selfX === 0
      && r.walk.moved > .5 && r.walk.footRange < 6 && r.walk.selfX === 0
      && r.home.inBowl && r.home.clearedRim && r.home.belowFloor <= .01 && r.home.selfX === 0
      && !r.hopOut.inBowl && r.hopOut.onSill && r.hopOut.selfX === 0
      && r.glass.stuck && r.glass.slidR > .05 && r.glass.off && r.glass.onSill && r.glass.selfX === 0
      && r.bounds.belowFloor <= 6 && r.bounds.top >= 3.9 && r.alive.belowFloor <= .01 && r.alive.inFrame && r.alive.maxFromFloorR < 6 && r.alive.selfX === 0 && Math.abs(r.alive.area - 1) < .1 && r.offInBlue; }
  res.ALL_PASS = Object.values(res.PASS).every(Boolean);

  draw();
  Object.assign(VIEW, VIEW0); viewSync();
  Object.assign(PRESETS, P27); SLP.lastAny = -99; chooseSlime(SLIME, false, false);   // v2.23：回到原本那隻（材質、個性、顏色）
  if (SFX) SFX.frame = sfxFrame0;
  sfxPlay = origPlay; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  console.log(JSON.stringify(res, null, 1));
  return res;
})();
