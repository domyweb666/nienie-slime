// 三種飼主的手。每個動作都記 act 事件（種類、落指時間、放手時間）。座標用世界座標算再換螢幕
(() => {
  const O = OBS;
  const rnd = O.rnd = O.seeded(4242);   // 飼主自己的亂數，不動牠的 Math.random
  const cl = (v, a, b) => Math.max(a, Math.min(b, v));
  const W0 = innerWidth, H0 = innerHeight;
  O.ownerSeed = s => { const r = O.seeded(s); O.rnd = r; };
  const R01 = () => O.rnd();
  const scr = (x, y) => { const q = O.scr(x, y); return [cl(q[0], 4, W0 - 4), cl(q[1], 4, H0 - 4)]; };
  function bodyPt(kx, ky) {   // 身體上的一點：重心加偏移（半徑的倍數），不在身體裡就往重心收
    let x = globalC.xc + kx * R, y = globalC.yc + ky * R; for (let i = 0; i < 10 && !insideBody(x, y); i++) { x += (globalC.xc - x) * .25; y += (globalC.yc - y) * .25; } return [x, y];
  }
  function start(kind, x, y) { const [sx, sy] = scr(x, y); const a = { kind, t0: t, pre: O.klass(), st: LIFE.st, slp: SLP.on, m: +BRAIN.m.toFixed(3), w: +IMP.w.toFixed(3), tr: +IMP.tr.toFixed(3), H: +FLN.H.toFixed(2), gx: EYE.gx, gy: EYE.gy }; O.cur = a; O.down(sx, sy); return a; }
  function end(a) { O.up(); a.t1 = t; a.fm = a.fm || ''; O.log('act', { kind: a.kind, t0: +a.t0.toFixed(3), t1: +t.toFixed(3), pre: a.pre, st: a.st, slp: a.slp, m: a.m, w: a.w, tr: a.tr, H: a.H }); O.cur = null; }
  const N = s => Math.round(s * 60);
  O.tap = (x, y, dur, kind) => { const a = start(kind || 'tap', x, y); for (let i = 0; i < N(dur || .1); i++) O.step(); end(a); return a; };
  O.hold = (x, y, dur, kind) => { const a = start(kind || 'hold', x, y); for (let i = 0; i < N(dur); i++) O.step(); end(a); return a; };
  O.rub = (x, y, dur, rad, per, kind) => { const a = start(kind || 'rub', x, y); const [sx, sy] = [O.fx, O.fy], ph = 0; for (let i = 0; i < N(dur); i++) { const u = i / 60, k = Math.min(1, u / .25), an = 2 * Math.PI * u / per; O.mv(cl(sx + Math.sin(an) * rad * R * k, 4, W0 - 4), cl(sy + (1 - Math.cos(an)) * rad * R * .5 * k, 4, H0 - 4)); O.step(); } end(a); return a; };
  O.stroke = (x, y, dx, dy, dur, kind) => { const a = start(kind || 'stroke', x, y); const sx = O.fx, sy = O.fy; const n = N(dur); for (let i = 1; i <= n; i++) { O.mv(cl(sx + dx * R * i / n, 4, W0 - 4), cl(sy + dy * R * i / n, 4, H0 - 4)); O.step(); } end(a); return a; };
  O.pull = (x, y, ang, dist, tOut, tHold, kind) => { const a = start(kind || 'pull', x, y); for (let i = 0; i < 3; i++) O.step(); const sx = O.fx, sy = O.fy, n = N(tOut); for (let i = 1; i <= n; i++) { const k = i / n; O.mv(cl(sx + Math.cos(ang) * dist * R * k, 4, W0 - 4), cl(sy + Math.sin(ang) * dist * R * k, 4, H0 - 4)); O.step(); } for (let i = 0; i < N(tHold); i++) O.step(); end(a); return a; };
  O.drag = (x, y, dxR, dur, kind) => O.stroke(x, y, dxR, 0, dur, kind || 'drag');
  O.blank = (x, y, dur, kind) => { const a = start(kind || 'blank', x, y); for (let i = 0; i < N(dur); i++) O.step(); end(a); return a; };
  O.bodyPt = bodyPt;
  // 空白處：身體旁邊 d 倍半徑的地方（在畫面裡、不在身體上、不在擺飾上）
  O.blankPt = (d) => { for (let i = 0; i < 40; i++) { const a = -Math.PI / 2 + (R01() - .5) * Math.PI * 1.2, x = globalC.xc + Math.cos(a) * R * (1.1 + d), y = globalC.yc + Math.sin(a) * R * (.8 + d); if (x < 20 || x > W0 - 20 || y < 60 || y > SILL.g.fl - 8) continue; if (insideBody(x, y) || nearBody(x, y, R * .3)) continue; if (propAt(x, y) || hangAt(x, y)) continue; return [x, y]; } return [globalC.xc, globalC.yc - R * 2]; };
  const wait = s => O.idle(s);
  O.gentle = sec => { const t1 = t + sec; while (t < t1) {
      const u = R01();
      if (u < .7) { const [x, y] = bodyPt((R01() - .5) * .7, -.15 + (R01() - .5) * .5); O.rub(x, y, 4 + 6 * R01(), .22 + .15 * R01(), 1.1 + .8 * R01()); }
      else if (u < .85) { const [x, y] = bodyPt((R01() - .5) * .6, -.1 + (R01() - .5) * .4); O.hold(x, y, 2 + 2 * R01(), 'holdSoft'); }
      else { const [x, y] = bodyPt(-.7, -.25); for (let k = 0; k < 3; k++) O.stroke(x, y, 1.3, 0, .5, 'stroke'); }
      wait(3 + 5 * R01());
    } };
  O.rough = sec => { const t1 = t + sec; while (t < t1) {
      const u = R01();
      if (u < .35) { const an = -Math.PI / 2 + (R01() - .5) * 2.2, [x, y] = bodyPt(Math.cos(an) * .7, Math.sin(an) * .5); O.pull(x, y, an, 2.5 + 2 * R01(), .18 + .12 * R01(), .1 + .3 * R01(), 'yank'); }
      else if (u < .6) { const an = -Math.PI / 2 + (R01() - .5) * 2.2, [x, y] = bodyPt(Math.cos(an) * .7, Math.sin(an) * .5); O.pull(x, y, an, 3 + 2 * R01(), .35, 1.4 + R01(), 'pullHold'); }
      else if (u < .85) { for (let k = 0; k < 3; k++) { const [x, y] = bodyPt((R01() - .5) * .8, -.2 + (R01() - .5) * .4); O.tap(x, y, .08, 'poke'); wait(.17); } }
      else { const [x, y] = bodyPt(0, -.2); const a = start('shakeDrag', x, y); const sx = O.fx, sy = O.fy; for (let i = 0; i < 60; i++) { O.mv(cl(sx + Math.sin(i / 60 * 2 * Math.PI * 3) * 1.4 * R, 4, W0 - 4), sy - 40); O.step(); } end(a); }
      wait(1 + 2 * R01());
    } };
  O.sporadic = sec => { const t1 = t + sec; while (t < t1) {
      wait(15 + 45 * R01()); if (t >= t1) break;
      const u = R01();
      if (u < .3) { const [x, y] = bodyPt((R01() - .5) * .8, -.2 + (R01() - .5) * .4); O.tap(x, y, .1, 'poke'); }
      else if (u < .5) { const [x, y] = bodyPt((R01() - .5) * .6, -.15); O.rub(x, y, 2 + 2 * R01(), .25, 1.3); }
      else if (u < .65) { const [x, y] = bodyPt(0, -.1); O.drag(x, y, (R01() < .5 ? -1 : 1) * .9, 1.0); }
      else if (u < .8) { const [x, y] = O.blankPt(.6 + R01()); O.blank(x, y, 2.5, 'hover'); }
      else if (u < .9) { const [x, y] = O.blankPt(.8); for (let k = 0; k < 3; k++) { O.blank(x, y, .07, 'rhythm'); wait(.38); } wait(4); }
      else { const an = -Math.PI / 2 + (R01() - .5) * 1.4, [x, y] = bodyPt(Math.cos(an) * .6, Math.sin(an) * .5); O.pull(x, y, an, 2.2, .5, .5, 'pullSoft'); }
    } };
  return 'own ok';
})()
