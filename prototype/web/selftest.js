/* 捏捏史萊姆 網頁原型 回歸自測（Agent 程式自測：只抓「壞掉」，抓不到「好不好捏」）

   用法：瀏覽器開 index.html（用手機尺寸較準，例如 375×812），DevTools console 把這整個檔案貼上執行；
   或用 Claude 的 javascript_tool 直接跑。結果印在 console 並回傳，最後一欄 PASS 全 true 才算過。
   每次改演算法都跑（CLAUDE.md 硬規則）。

   量什麼：邊界自交數 selfX（要 0）、面積比 area（放手後回 1.00±0.02）、動能 ke（放手後衰減）、
   記形偏移 qdev（輕按後要 0、按住後 >3pt、揉回原形後 <1pt）、第一幀最大位移（要 >1pt）。
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
  function area() { let A = 0; const n = bnd.length; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; A += X[a] * Y[b] - X[b] * Y[a]; } return Math.abs(A) / 2; }
  function ke() { let s = 0; for (let i = 0; i < N; i++) s += (X[i] - PX[i]) ** 2 + (Y[i] - PY[i]) ** 2; return s; }
  function qdev() { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(QX[i] - Q0X[i], QY[i] - Q0Y[i])); return m; }
  function snap() { return { selfX: selfX(), area: +(area() / A0).toFixed(3), ke: +ke().toFixed(2), qdev: +qdev().toFixed(2) }; }
  function maxMove(ref) { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(X[i] - ref[0][i], Y[i] - ref[1][i])); return m; }
  const res = { W, H, R: +R.toFixed(1), N, nb: bnd.length, preset: 'clay' };
  function reset() { mat = { ...PRESETS.clay }; setup(); steps(60); }

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
  const sx = cx0 + R * 0.8, sy = cy0; ev('pointerdown', 1, sx, sy);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx + k * (R * 2.2 / 60), sy + k * (R * 0.8 / 60)); steps(1); }
  steps(60); const t3Peak = snap();
  ev('pointerup', 1, sx + R * 2.2, sy + R * 0.8); steps(180);
  res.T3_pull = { during: t3Peak, after3s: snap(), sfx: log.splice(0) };

  // T4 兩指對拉
  reset();
  ev('pointerdown', 1, cx0 - R * 0.7, cy0); ev('pointerdown', 2, cx0 + R * 0.7, cy0);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, cx0 - R * 0.7 - k * (R * 1.5 / 60), cy0); ev('pointermove', 2, cx0 + R * 0.7 + k * (R * 1.5 / 60), cy0); steps(1); }
  steps(30); const t4 = snap();
  ev('pointerup', 1, cx0 - R * 2.2, cy0); ev('pointerup', 2, cx0 + R * 2.2, cy0); steps(180);
  res.T4_twoFinger = { during: t4, after3s: snap(), sfx: log.splice(0) };

  // T5 亂甩 120 幀
  reset(); let fx = cx0, fy = cy0; ev('pointerdown', 1, fx, fy); let worst = 0;
  for (let k = 0; k < 120; k++) { fx = cx0 + (Math.random() - .5) * R * 4; fy = cy0 + (Math.random() - .5) * R * 4; ev('pointermove', 1, fx, fy); steps(1); worst = Math.max(worst, selfX()); }
  ev('pointerup', 1, fx, fy); steps(180);
  { const l = log.splice(0); res.T5_flail = { worstDuring: worst, after3s: snap(), pulls: l.filter(e => e[0] === 'pull').length, release: l.find(e => e[0] === 'release') }; }

  // T6 從外面推進來：第一次推到要有 press 音
  reset(); const px0 = cx0 - R * 2.4, py0 = cy0; ev('pointerdown', 1, px0, py0);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, px0 + k * (R * 2.0 / 60), py0); steps(1); }
  const t6 = snap(); ev('pointerup', 1, px0 + R * 2.0, py0); steps(120);
  res.T6_push = { during: t6, after2s: snap(), sfx: log.splice(0) };

  // T7 放著 20 秒
  reset(); let worstIdle = 0, minA = 9, maxA = 0;
  for (let k = 0; k < 1200; k++) { update(DT); if (k % 20 === 0) { worstIdle = Math.max(worstIdle, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
  res.T7_idle = { worstSelfX: worstIdle, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3), qdev: +qdev().toFixed(2) };

  // T8 pointercancel：不啵、手指清掉
  reset(); ev('pointerdown', 1, cx0, cy0); steps(30); ev('pointercancel', 1, cx0, cy0); steps(30);
  res.T8_cancel = { fingersLeft: fingers.size, sfx: log.splice(0) };

  // T9 快甩放手：峰值速度項
  reset(); ev('pointerdown', 1, cx0, cy0);
  for (let k = 1; k <= 6; k++) { ev('pointermove', 1, cx0 + k * R * 0.25, cy0); steps(1); }
  ev('pointerup', 1, cx0 + R * 1.5, cy0); steps(60);
  res.T9_flick = { sfx: log.splice(0), after: snap() };

  const okArea = s => s.area > 0.98 && s.area < 1.02;
  const rel = l => (l.find(e => e[0] === 'release') || [0, 0])[1];
  res.PASS = {
    noSelfIntersection: [res.T1_tap.after2s, res.T2_hold.during, res.T2_hold.afterRelease1s, res.T3_pull.during, res.T3_pull.after3s, res.T4_twoFinger.during, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(s => s.selfX === 0) && res.T5_flail.worstDuring === 0 && res.T7_idle.worstSelfX === 0,
    areaBack: [res.T1_tap.after2s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(okArea) && res.T7_idle.areaMin > 0.97 && res.T7_idle.areaMax < 1.03,
    firstFrameMoves: res.T1_tap.firstFrameMove > 1,
    tapLeavesNoMark: res.T1_tap.after2s.qdev < 1,
    holdLeavesMark: res.T2_hold.afterRelease1s.qdev > 3,
    relaxClearsMark: res.T2_hold.afterRelax1s.qdev < 1,
    slowReleaseStillPops: rel(res.T3_pull.sfx) > 0.7,
    flickPops: rel(res.T9_flick.sfx) > 0.9,
    pushMakesPressSound: res.T6_push.sfx.some(e => e[0] === 'press'),
    cancelIsSilent: !res.T8_cancel.sfx.some(e => e[0] === 'release') && res.T8_cancel.fingersLeft === 0,
  };
  res.ALL_PASS = Object.values(res.PASS).every(Boolean);

  draw();
  sfxPlay = origPlay; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  console.log(JSON.stringify(res, null, 1));
  return res;
})();
