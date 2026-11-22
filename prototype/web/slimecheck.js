/* 捏捏史萊姆 短檢查（2026-11-22 熬夜那一輪加的）
   整份 selftest.js 會佔住分頁好幾分鐘，分頁沒顯示時跑不完；這支每隻只跑約 700 幀，幾秒內回來。
   只抓「壞掉」：壞掉的數字（NaN）、外框自己交叉、面積跑掉。抓不到好不好捏。
   用法：頁面載入後在 console 貼上，或 javascript_tool 跑 (0,eval)(await (await fetch('slimecheck.js')).text())，
   然後 slimeCheck('taro') 或 slimeCheckAll()。跑完會切回原本那一隻。 */
window.slimeCheck = function (id) {
  const k = SLIMES.findIndex(s => s.id === id); if (k < 0) return { id, error: '沒有這一隻' };
  const realRAF = window.requestAnimationFrame, realRandom = Math.random, back = SLIME;
  const noSave0 = IMPSV.noSave, walkNoSave0 = WALK.noSave; IMPSV.noSave = true; WALK.noSave = true;   // 不碰使用者存的熟和窗台上的東西
  let a = 20261122; Math.random = () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  window.requestAnimationFrame = () => 0;
  const DT = 1 / 60, out = { id };
  try {
    chooseSlime(k, false, false);
    const ev = (type, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: 1, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: true }));
    const steps = n => { for (let i = 0; i < n; i++) update(DT); };
    const segInt = (ax, ay, bx, by, cx, cy, dx, dy) => { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; };
    const selfX = () => { const n = bnd.length; let c = 0; for (let i = 0; i < n; i++) { const p = bnd[i], q = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const r = bnd[j], s = bnd[(j + 1) % n]; if (segInt(X[p], Y[p], X[q], Y[q], X[r], Y[r], X[s], Y[s])) c++; } } return c; };
    const area = () => { let A = 0; const n = bnd.length; for (let i = 0; i < n; i++) { const p = bnd[i], q = bnd[(i + 1) % n]; A += X[p] * Y[q] - X[q] * Y[p]; } return Math.abs(A) / 2; };
    const bad = () => { let c = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) c++; return c; };
    const mid = () => { let x = 0, y = 0; for (const i of bnd) { x += X[i]; y += Y[i]; } return [x / bnd.length, y / bnd.length]; };
    steps(240); const A0 = area(); out.idle = { nan: bad(), selfX: selfX() };
    const [cx, cy] = mid(); ev('pointerdown', cx, cy);
    for (let i = 1; i <= 60; i++) { ev('pointermove', cx + i * R * 1.5 / 60, cy - i * R * .4 / 60); steps(1); }
    steps(30); out.pull = { nan: bad(), selfX: selfX(), area: +(area() / A0).toFixed(3) };
    ev('pointerup', cx + R * 1.5, cy - R * .4); steps(360);
    out.after = { nan: bad(), selfX: selfX(), area: +(area() / A0).toFixed(3) };
    draw();
    const cs = getComputedStyle(document.documentElement);
    out.colors = ['--body', '--shade', '--line', '--hi', '--eye'].map(v => cs.getPropertyValue(v).trim());
    out.mat = SLIMES[k].mat; out.N = N; out.nb = bnd.length;
    out.ok = out.idle.nan === 0 && out.pull.nan === 0 && out.after.nan === 0 && out.idle.selfX === 0 && out.after.selfX === 0 && Math.abs(out.after.area - 1) < .25;
  } catch (e) { out.error = String(e && e.stack || e).slice(0, 400); out.ok = false; }
  try { chooseSlime(back, false, false); } catch (_) { }
  IMPSV.noSave = noSave0; WALK.noSave = walkNoSave0; Math.random = realRandom; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  return out;
};
window.slimeCheckAll = function () { return SLIMES.map(s => slimeCheck(s.id)); };
