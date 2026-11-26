/* v2.62 扯斷成兩隻、碰到合回（T74）。selftest.js 最後會 fetch 這個檔來跑；也可以單獨在 console 貼上跑（回傳 {r, pass}）。
   每一種合併動畫（mergeFx 0 到 3）各跑一次：窗台、芋圓、真正的預設；往上猛扯 → 要斷成兩隻；再猛扯第二隻、再猛扯原本那隻 → 不准斷第二次；
   把第二隻拖去碰原本那隻 → 一定合回；放著 3 秒後粒子數和原本一樣、面積回到原本 ±3%、A 的大小 k 回到 1。
   另外：放著不碰，第二隻自己爬回去也一定合；合回之後 splitAgain 1 可以再斷、0 不行；split 0 怎麼扯都不斷。 */
(async () => {
  const PRE = window.__SPLIT_PRE || PRESETS, ownRAF = !window.__SPLIT_PRE, raf0 = window.requestAnimationFrame, rnd0 = Math.random, view0 = { ...VIEW }, sl0 = SLIME, mat0 = mat;
  if (ownRAF) { window.requestAnimationFrame = () => 0; await new Promise(r => setTimeout(r, 80)); }
  const seeded = s => { let a = s >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let q = a; q = Math.imul(q ^ (q >>> 15), q | 1); q ^= q + Math.imul(q ^ (q >>> 7), q | 61); return ((q ^ (q >>> 14)) >>> 0) / 4294967296; }; };
  const ev = (ty, id, x, y) => cv.dispatchEvent(new PointerEvent(ty, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const steps = n => { for (let i = 0; i < n; i++) update(1 / 60); };
  const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
  const areaA = () => { let A = 0; const n = bnd.length; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; A += X[a] * Y[b] - X[b] * Y[a]; } return Math.abs(A) / 2; };
  const upAll = () => { for (const id of [...fingers.keys(), ...B2.fg.keys()]) ev('pointerup', id, 0, 0); };
  Object.assign(VIEW, { skin: 'A', body: 'round', face: 1, bg: 'day', win: '' });
  const si = SLIMES.findIndex(q => q.id === 'taro'), s = SLIMES[si];
  const fresh = (seed, over) => { upAll(); Math.random = seeded(seed); SLIME = si; mat = { ...PRE[s.mat], seed: s.seed, ...s.p, eyes: 1, sill: 1, intro: 0, introSwim: 0, brain: 0, ...over }; setup(); SPLIT.n = 0; SPLIT.merged = 0;
    WANDER.moving = false; WANDER.next = t + 1e5; steps(150); };
  // 往上猛扯：抓身體中心往上 0.3R 的地方，每幀 0.3R（每秒 18R）往上拉，最多 14 幀
  const yank = (id, wx, wy) => { let [x, y] = scr(wx, wy); ev('pointerdown', id, x, y); steps(3); const n0 = SPLIT.n; for (let k = 0; k < 14 && SPLIT.n === n0; k++) { y = Math.max(6, y - R * .3); ev('pointermove', id, x, y); steps(1); } return [x, y]; };
  const r = { err: '', fx: [] };
  try {
    for (const fx of [0, 1, 2, 3]) {
      fresh(7401 + fx, { mergeFx: fx }); const N0 = N, a0 = areaA(), o = { fx };
      let [x, y] = yank(1, globalC.xc, globalC.yc - R * .3); steps(2);
      o.split = B2.on && SPLIT.n === 1; o.k = +SPLIT.k.toFixed(3); o.nB = B2.n || 0; o.Nsplit = N;
      // 斷了之後：手指 1 抓著第二隻搬到左上角、上下猛甩；手指 2 猛扯原本那隻（往右上）；都不准斷第二次
      { const [lx, ly] = scr(globalC.xc - R * 1.5, globalC.yc - R * 3.2); for (let k = 1; k <= 20; k++) { ev('pointermove', 1, x + (lx - x) * k / 20, y + (ly - y) * k / 20); steps(1); } x = lx; y = ly; }
      for (let k = 0; k < 12; k++) { ev('pointermove', 1, x, y + (k % 2 ? 1 : -1) * R * .5); steps(1); } ev('pointermove', 1, x, y); steps(20); o.k = +SPLIT.k.toFixed(3);
      { let [ax, ay] = scr(globalC.xc + R * .2, globalC.yc - R * .2); ev('pointerdown', 2, ax, ay); steps(3); for (let k = 0; k < 10; k++) { ax = Math.min(W - 6, ax + R * .25); ay = Math.max(6, ay - R * .25); ev('pointermove', 2, ax, ay); steps(1); } ev('pointerup', 2, ax, ay); }
      steps(40); o.n2 = SPLIT.n; o.one = SPLIT.n === 1 && B2.on;
      // 手指 1 把第二隻拖去碰原本那隻（每幀 0.08R），碰到就合；合完最多再等 4 秒
      o.merged = false; o.mergeF = -1;
      if (B2.on) { let px = x, py = y;
        for (let k = 0; k < 240 && !B2.mg; k++) { const [tx, ty] = scr(globalC.xc, globalC.yc), dx = tx - px, dy = ty - py, l = Math.hypot(dx, dy) || 1, sp = Math.min(l, R * .08); px += dx / l * sp; py += dy / l * sp; ev('pointermove', 1, px, py); steps(1); }
        ev('pointerup', 1, px, py); let f = 0; for (; f < 240 && B2.on; f++) steps(1); o.merged = !B2.on && SPLIT.merged === 1; o.mergeF = f; }
      steps(180); o.N0 = N0; o.N = N; o.area = +(areaA() / a0).toFixed(3); o.kEnd = SPLIT.k;
      r.fx.push(o); }
    // 放著不碰：第二隻自己爬回去
    { fresh(7411, { mergeFx: 2, rejoin: 3 }); const N0 = N, a0 = areaA(); const p = yank(1, globalC.xc, globalC.yc - R * .3); ev('pointerup', 1, p[0], p[1]);
      let f = 0; const sp = B2.on; for (; f < 60 * 14 && (B2.on || SPLIT.merged === 0); f++) steps(1); steps(180);
      r.crawl = { split: sp, merged: SPLIT.merged === 1, sec: +(f / 60).toFixed(1), N: N === N0, area: +(areaA() / a0).toFixed(3) }; }
    // 合回之後：splitAgain 1 可以再斷，0 不行
    for (const again of [1, 0]) { fresh(7421, { mergeFx: 1, rejoin: 1, splitAgain: again }); let p = yank(1, globalC.xc, globalC.yc - R * .3); ev('pointerup', 1, p[0], p[1]);
      for (let f = 0; f < 60 * 12 && (B2.on || !SPLIT.merged); f++) steps(1); steps(120); p = yank(2, globalC.xc, globalC.yc - R * .3); ev('pointerup', 2, p[0], p[1]); steps(10);
      r['again' + again] = { merged: SPLIT.merged, n: SPLIT.n }; }
    // split 0：怎麼扯都不斷
    { fresh(7431, { split: 0 }); const p = yank(1, globalC.xc, globalC.yc - R * .3); ev('pointerup', 1, p[0], p[1]); steps(10); r.off = { n: SPLIT.n, on: B2.on }; }
  } catch (e) { r.err = String(e && e.stack || e).slice(0, 400); }
  upAll(); twinDrop(); SLIME = sl0; Object.assign(VIEW, view0); mat = mat0; Math.random = rnd0;
  if (ownRAF) { window.requestAnimationFrame = raf0; chooseSlime(SLIME, false, false); requestAnimationFrame(frame); }
  const pass = r.err === '' && r.fx.length === 4 && r.fx.every(o => o.split && o.k < .8 && o.nB > 50 && o.Nsplit === o.N0 && o.one && o.n2 === 1 && o.merged && o.N === o.N0 && Math.abs(o.area - 1) <= .03 && o.kEnd === 1)
    && r.crawl.split && r.crawl.merged && r.crawl.N && Math.abs(r.crawl.area - 1) <= .03 && r.again1.merged === 1 && r.again1.n === 2 && r.again0.merged === 1 && r.again0.n === 1 && r.off.n === 0 && !r.off.on;
  return { r, pass };
})();
