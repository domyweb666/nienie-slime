// 刺激與反應：每種刺激重複 n 次，記反應種類、延遲、機率
(() => {
  const O = OBS, R01 = () => O.rnd();
  const wait = s => O.idle(s);
  const cl = (v, a, b) => Math.max(a, Math.min(b, v));
  const bp = (a, b) => O.bodyPt(a, b);
  const J = k => (R01() - .5) * k;
  const STIM = {
    pokeC: () => { const [x, y] = bp(J(.3), -.1 + J(.2)); O.tap(x, y, .1); },
    pokeS: () => { const s = R01() < .5 ? -1 : 1, [x, y] = bp(.8 * s, -.1); O.tap(x, y, .1); },
    poke3: () => { for (let k = 0; k < 3; k++) { const [x, y] = bp(J(.6), -.15 + J(.3)); O.tap(x, y, .08); wait(.17); } },
    hold3: () => { const [x, y] = bp(J(.5), -.1 + J(.2)); O.hold(x, y, 3); },
    rub4: () => { const [x, y] = bp(J(.5), -.15 + J(.2)); O.rub(x, y, 4, .28, 1.4); },
    rub8: () => { const [x, y] = bp(J(.5), -.15 + J(.2)); O.rub(x, y, 8, .28, 1.4); },
    drag1: () => { const [x, y] = bp(0, -.1); O.drag(x, y, (globalC.xc > SILL.g.bx ? -1 : 1) * .8, 1.0); },
    yank: () => { const an = -Math.PI / 2 + J(1.6), [x, y] = bp(Math.cos(an) * .7, Math.sin(an) * .5); O.pull(x, y, an, 3, .2, .1); },
    pullHold: () => { const an = -Math.PI / 2 + J(1.6), [x, y] = bp(Math.cos(an) * .7, Math.sin(an) * .5); O.pull(x, y, an, 4, .5, 1.6); },
    stroke3: () => { const [x, y] = bp(-.75, -.2); for (let k = 0; k < 3; k++) { O.stroke(x, y, 1.4, 0, .45); wait(.15); } },
    blankTap: () => { const [x, y] = O.blankPt(.4 + .8 * R01()); O.blank(x, y, .1); },
    hover3: () => { const [x, y] = O.blankPt(.4 + .8 * R01()); O.blank(x, y, 3); },
    rhythm3: () => { const [x, y] = O.blankPt(.8); for (let k = 0; k < 3; k++) { O.blank(x, y, .07); wait(.38); } },
    tickle: () => { const [x, y] = bp(J(.4), -.1); const [sx, sy] = O.scr(x, y); O.down(sx, sy); for (let i = 0; i < 120; i++) { O.mv(sx + Math.sin(i / 60 * 2 * Math.PI * 4) * 20, sy + J(4)); O.step(); } O.up(); },
    bell: () => { const q = HANG.bell, [sx, sy] = O.scr(q.x, q.y + q.h * .7); O.down(sx, sy); for (let i = 0; i < 6; i++) O.step(); O.up(); },
    jar: () => { const p = PROPS.find(p => p.im === 'd_jar' && !p.gone); if (!p) return; const [sx, sy] = O.scr(p.x, p.y); O.down(sx, sy); for (let i = 0; i < 6; i++) O.step(); O.up(); },
    none: () => { },
  };
  const VIS = ['flinch', 'hop', 'flee', 'sniff', 'lean', 'gaitTo', 'wag', 'happy', 'shake', 'lookYou', 'wake', 'echo', 'e4', 'esc', 'route', 'blink', 'sigh'];
  O.sr = (name, ctx, n, o) => {
    o = o || {}; const out = [];
    for (let k = 0; k < n; k++) {
      const gap = o.gap == null ? 5 + 4 * R01() : o.gap; wait(gap);
      if (o.sleep) { BRAIN.z = .9; SLP.on = true; LIFE.st = 'sleep'; cutSniffs(); wait(6); }
      else { for (let i = 0; i < 1800 && (O.klass() !== 'rest' || SLP.on); i++) { BRAIN.z = Math.min(BRAIN.z, .2); O.step(); } }
      if (!o.keep) { IMP.tr = ctx.tr; IMP.w = ctx.w || 0; BRAIN.m = BRAIN.mS = ctx.m == null ? .15 : ctx.m; BMEM.cell.fill(0); BMEM.side = 0; IMP.askUntil = -9; E4.count = 99; DR.hab = {}; BRAIN.z = o.sleep ? BRAIN.z : .2; BRAIN.q = .3; BRAIN.s = 0; BRAIN.e = .2; }
      O.take(); const t0 = t, pre = { k: O.klass(), gx: EYE.gx, gy: EYE.gy, H: FLN.H, cx: globalC.xc, cy: globalC.yc, n: bnd.length, m: BRAIN.m, w: IMP.w, tr: IMP.tr };
      const ga = (mat.gazeAmp || .06) * R * (mat.eyeSize || 1); const op0 = EYE.openD * EYE.wideD; let lEye = null, lOpen = null, minOpen = op0, maxOpen = op0, lMode = null, mode0 = EYE.mode, maxCx = 0, ang = null, lDown = null;
      O.hook = () => { const u = t - t0; if (lEye == null && Math.hypot((EYE.gx - pre.gx) * ga, (EYE.gy - pre.gy) * ga * .75) > 2.5) lEye = u; const op = EYE.openD * EYE.wideD; if (lOpen == null && Math.abs(op - op0) > .12) lOpen = u; minOpen = Math.min(minOpen, op); maxOpen = Math.max(maxOpen, op); if (lMode == null && EYE.mode !== mode0) lMode = u; if (!O.engagedNow()) maxCx = Math.max(maxCx, Math.hypot(globalC.xc - pre.cx, globalC.yc - pre.cy)); };
      STIM[name](); const tEnd = t; wait(o.post || 5); O.hook = null;
      const ev = O.take().E, r = { k, pre: pre.k, H: +pre.H.toFixed(2), dur: +(tEnd - t0).toFixed(2), lEye: lEye == null ? null : +lEye.toFixed(3), lOpen: lOpen == null ? null : +lOpen.toFixed(3), lMode: lMode == null ? null : +lMode.toFixed(3), op: [+op0.toFixed(2), +minOpen.toFixed(2), +maxOpen.toFixed(2)], mv: +maxCx.toFixed(1), ev: [] };
      for (const e of ev) { const u = +(e.t - t0).toFixed(3); if (e.k === 'snd') r.ev.push(['snd:' + e.s, u]); else if (e.k === 'eyeMode') r.ev.push(['eye:' + e.m, u]); else if (e.k === 'life') r.ev.push(['life:' + e.to, u]); else if (VIS.includes(e.k)) r.ev.push([e.k + (e.k === 'lean' ? (e.S < 0 ? '-' : '+') : e.k === 'echo' ? ':' + e.st : e.k === 'e4' ? ':' + e.ph : ''), u, e.amp]); else if (e.k === 'drLook' || e.k === 'drCrash') r.ev.push([e.k, u]); }
      r.tr = +IMP.tr.toFixed(3); r.w = +IMP.w.toFixed(3); r.m = +BRAIN.m.toFixed(3); out.push(r);
    }
    return out;
  };
  O.STIM = Object.keys(STIM);
  return 'sr ok';
})()
