/* v2.65 #9 markStyle（按壓、拉扯的痕跡）截圖：B 壓薄透光跟 v2.63 對照。
   在頁面裡跑：停掉動畫迴圈，固定亂數，真正的畫面（窗台、皮 A），每隻用自己的預設，熟 0.3、大腦關（量的時候不准自己走開）。
   動作：按身體中間 0.3 秒 → 放手 0.15 秒 → 等 1.5 秒 → 抓上面（中心往右 0.25R、往上 0.55R）往右上拉 1.5R（0.5 秒）撐 0.3 秒 → 放手 0.3 秒。
   MS.run({slime, over, tag, crop}) 回 {shots:[{tag, img}], info}；crop 1：只截身體上下那一段（整個寬、460 點高）（兩倍解析度） */
(() => {
  const MS = window.MS = {};
  window.requestAnimationFrame = () => 0;
  const DT = 1 / 60;
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let q = a; q = Math.imul(q ^ (q >>> 15), q | 1); q ^= q + Math.imul(q ^ (q >>> 7), q | 61); return ((q ^ (q >>> 14)) >>> 0) / 4294967296; }; };
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const steps = n => { for (let i = 0; i < n; i++) update(DT); };
  const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
  function cap(fx, fy, box) {
    draw(); const s = 2, k = document.createElement('canvas'); const [bx, by, bw, bh] = box || [0, 0, W, H];
    k.width = Math.round(bw * s); k.height = Math.round(bh * s); const c = k.getContext('2d');
    c.drawImage(cv, bx * DPR, by * DPR, bw * DPR, bh * DPR, 0, 0, k.width, k.height);
    if (fx != null) { c.beginPath(); c.arc((fx - bx) * s, (fy - by) * s, 17 * s, 0, 6.283); c.lineWidth = 2 * s; c.strokeStyle = 'rgba(255,255,255,.85)'; c.stroke(); c.lineWidth = 1 * s; c.strokeStyle = 'rgba(20,20,20,.8)'; c.stroke(); }
    return k.toDataURL('image/png');
  }
  MS.run = c => {
    const si = SLIMES.findIndex(q => q.id === c.slime); IMPSV.noSave = true; WALK.noSave = true;
    Math.random = seeded(c.seed || 951); chooseSlime(si < 0 ? SLIME : si, false, false);
    Object.assign(mat, { brain: 0, intro: 0, introSwim: 0, signature: 0, lookTarget: 0, tapBack: 0 }, c.over || {}); setup();
    t = 0; lastTouch = -10; tLife = 0; SLP.on = false; SLP.lastAny = -99; IMP.tr = .3; IMP.w = 0; WANDER.moving = false; WANDER.next = 99; steps(150);
    const [x0, y0] = sc(globalC.xc, globalC.yc), u = R * CAM.z, shots = [], tag = c.tag || '', info = { R: +R.toFixed(1), z: +CAM.z.toFixed(3), ms: mat.markStyle, jel: !!(typeof jelReady === 'function' && jelReady()), skin: VIEW.skin, used: !!SKIN.used };
    const box = c.crop ? [0, Math.max(0, y0 - 330), W, 460] : null;
    ev('pointerdown', 1, x0, y0); steps(18); shots.push({ tag: tag + '1_按住0.3秒', img: cap(x0, y0, box) });
    info.dent = DENTS.map(d => [+d.d.toFixed(2), d.mv == null ? null : +d.mv.toFixed(2)]);
    ev('pointerup', 1, x0, y0); steps(9); shots.push({ tag: tag + '2_放手0.15秒', img: cap(null, null, box) });
    steps(90);
    const [px, py] = sc(globalC.xc + R * .25, globalC.yc - R * .55), ux = c.ux != null ? c.ux : .45, uy = c.uy != null ? c.uy : -.89, PL = c.pull || 1.5; ev('pointerdown', 1, px, py); steps(3);
    for (let k = 1; k <= 30; k++) { ev('pointermove', 1, px + PL * u * ux * k / 30, py + PL * u * uy * k / 30); steps(1); } steps(18);
    shots.push({ tag: tag + '3_拉長' + PL + 'R撐住', img: cap(px + PL * u * ux, py + PL * u * uy, box) });
    info.pull = MARK.pull ? { i: MARK.pull.i, s: +markPullS(MARK.pull).toFixed(2) } : null;
    ev('pointerup', 1, px + PL * u * ux, py + PL * u * uy); steps(18); shots.push({ tag: tag + '4_放手0.3秒', img: cap(null, null, box) });
    return { shots, info };
  };
})();
