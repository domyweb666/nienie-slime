/* v2.64 B9 rubTrail（batch3 #6）：揉的時候手指走過的痕跡，截圖給多米看。
   在頁面裡跑：停掉動畫迴圈，固定亂數，真正的畫面（VIEW 原樣：窗台、皮 A），每隻用自己的預設，熟 0.3、大腦關（量的時候不准自己走開）。
   揉法：抓著身體中間畫半徑 0.3R 的圈，每秒 1.5R，揉 3 秒；截「揉到 3 秒」「放手後 0.25 秒」「放手後 0.6 秒」三張。
   RS.run({slime, over, tag}) 回 {shots:[{tag, img}], trail:[揉 3 秒時痕跡點數, 放手 0.25 秒, 0.6 秒], skinUsed} */
(() => {
  const RUBS0 = window.RUBS = {};
  window.requestAnimationFrame = () => 0;
  const DT = 1 / 60;
  const seeded = seed => { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let q = a; q = Math.imul(q ^ (q >>> 15), q | 1); q ^= q + Math.imul(q ^ (q >>> 7), q | 61); return ((q ^ (q >>> 14)) >>> 0) / 4294967296; }; };
  const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
  const steps = n => { for (let i = 0; i < n; i++) update(DT); };
  const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
  function cap(fx, fy, s) {
    draw(); const k = document.createElement('canvas'); k.width = Math.round(W * s); k.height = Math.round(H * s); const c = k.getContext('2d'); c.drawImage(cv, 0, 0, k.width, k.height);
    if (fx != null) { c.beginPath(); c.arc(fx * s, fy * s, 17 * s, 0, 6.283); c.lineWidth = 3 * s; c.strokeStyle = 'rgba(255,255,255,.9)'; c.stroke(); c.lineWidth = 1.6 * s; c.strokeStyle = 'rgba(20,20,20,.9)'; c.stroke(); }
    return k.toDataURL('image/png');
  }
  RUBS0.run = c => {
    const s = c.scale || 1, si = SLIMES.findIndex(q => q.id === c.slime); IMPSV.noSave = true; WALK.noSave = true;
    Math.random = seeded(c.seed || 601); chooseSlime(si < 0 ? SLIME : si, false, false); Object.assign(mat, { brain: 0, intro: 0, introSwim: 0, signature: 0, lookTarget: 0 }, c.over || {}); setup();
    t = 0; lastTouch = -10; tLife = 0; SLP.on = false; SLP.lastAny = -99; IMP.tr = .3; IMP.w = 0; WANDER.moving = false; WANDER.next = 99; steps(150);
    const [x0, y0] = sc(globalC.xc, globalC.yc), u = R * CAM.z, rr = .3, v = c.v || 1.5, shots = [], trail = []; let x = x0, y = y0; ev('pointerdown', 1, x0, y0);
    for (let k = 1; k <= 180; k++) { const a = v * (k / 60) / rr; x = x0 + rr * u * Math.sin(a); y = y0 + rr * u * (1 - Math.cos(a)); ev('pointermove', 1, x, y); steps(1); }
    trail.push(TRAIL.length); shots.push({ tag: (c.tag || '') + '1_揉3秒', img: cap(x, y, s) });
    ev('pointerup', 1, x, y); steps(15); trail.push(TRAIL.length); shots.push({ tag: (c.tag || '') + '2_放手0.25秒', img: cap(null, null, s) });
    steps(21); trail.push(TRAIL.length); shots.push({ tag: (c.tag || '') + '3_放手0.6秒', img: cap(null, null, s) });
    return { shots, trail, skinUsed: !!SKIN.used, jel: typeof jelReady === 'function' ? !!jelReady() : null, skin: VIEW.skin, mode: 'ok' };
  };
})();
