// 行為觀察器：停掉 rAF，用固定 dt 驅動 update，記錄狀態與事件（只讀狀態，不改行為）
(() => {
  if (window.OBS) return 'already';
  const DT = 1 / 60;
  function seeded(s) { s = (s >>> 0) || 1; return () => { s = (s + 0x6D2B79F5) >>> 0; let z = s; z = Math.imul(z ^ (z >>> 15), z | 1); z ^= z + Math.imul(z ^ (z >>> 7), z | 61); return ((z ^ (z >>> 14)) >>> 0) / 4294967296; }; }
  if (SFX) { SFX.init = () => {}; SFX.frame = () => {}; SFX.press = () => {}; SFX.release = () => {}; SFX.strand = () => {}; SFX.voice = () => {}; SFX.knock = () => {}; SFX.fx = () => {}; }
  WALK.noSave = true; IMPSV.noSave = true;
  const E = []; let rec = true;
  const log = (k, o) => { if (rec) E.push(Object.assign({ t: +t.toFixed(3), k }, o)); };
  // 包一層：只記錄，不改行為、不多抽亂數
  sfxPlay = function (k, g, r) { log('snd', { s: k, g: +(+(g == null ? 1 : g)).toFixed(2) }); };
  const oSniff = startSniff; startSniff = function (a, L, T1, T2, T3) { log('sniff', { a: +a.toFixed(2), L: +L.toFixed(2), st: LIFE.st }); return oSniff.apply(this, arguments); };
  const oGait = gaitTo; gaitTo = function (x, y, d) { log('gaitTo', { x: +x.toFixed(1), from: +globalC.xc.toFixed(1), d: !!d, act: BRAIN.act }); return oGait.apply(this, arguments); };
  const oRoute = routeStart; routeStart = function (s) { log('route', { n: s ? s.length : 0 }); return oRoute.apply(this, arguments); };
  const oFlee = flee; flee = function (a, b, c) { log('flee', { ux: +a.toFixed(2), uy: +b.toFixed(2), d: +c.toFixed(1) }); return oFlee.apply(this, arguments); };
  const oHop = hop; hop = function () { log('hop', {}); return oHop.apply(this, arguments); };
  const oWake = wake; wake = function (s, self) { if (SLP.on) log('wake', { sharp: !!s, self: !!self }); return oWake.apply(this, arguments); };
  const oPick = brainPick; brainPick = function (c) { const B = BRAIN, w = oPick.apply(this, arguments); log('pick', { w, why: B.why, z: +B.z.toFixed(2), q: +B.q.toFixed(2), s: +B.s.toFixed(2), f: +B.f.toFixed(2), e: +B.e.toFixed(2), m: +B.m.toFixed(2) }); return w; };
  const oOffer = memOffer; memOffer = function () { log('offer', {}); return oOffer.apply(this, arguments); };
  const oCat = drCat; drCat = function () { log('cat', {}); return oCat.apply(this, arguments); };
  const oHome = brainGoHome; brainGoHome = function () { const r = oHome.apply(this, arguments); log('goHome', { ok: !!r }); return r; };
  const oLook = drLook; drLook = function () { const n0 = DR.n.look; const r = oLook.apply(this, arguments); if (DR.n.look > n0) log('drLook', {}); return r; };
  const oCrash = drCrash; drCrash = function (p, b) { const n0 = DR.n.scare; const r = oCrash.apply(this, arguments); log('drCrash', { im: p.im, scared: DR.n.scare > n0 }); return r; };
  const last = { blink: -9, sac: 0, flt0: -9, st: '', sigh: -1, happy: -9, mode: '', slp: false, pre: null, e4: '', lure: false, echo: 'idle', esc: false, wag: -9, shk: -9, lean: -9, user: -9 };
  function edge() {   // 每幀查狀態邊緣
    if (EYE.blinkT !== last.blink) { if (EYE.mode === 'open' && t - EYE.blinkT < .05) log('blink', {}); last.blink = EYE.blinkT; }
    if (FLN.t0 !== last.flt0) { if (t - FLN.t0 < .05) log('flinch', { amp: +FLN.amp.toFixed(3), H: +FLN.H.toFixed(2) }); last.flt0 = FLN.t0; }
    if (LIFE.st !== last.st) { log('life', { from: last.st, to: LIFE.st, act: BRAIN.act }); last.st = LIFE.st; }
    if (BRX.sighCyc !== last.sigh) { if (BRX.sighCyc >= 0) log('sigh', {}); last.sigh = BRX.sighCyc; }
    if (MOOD.happyT !== last.happy) { log('happy', {}); last.happy = MOOD.happyT; }
    if (MOOD.wagT !== last.wag) { log('wag', {}); last.wag = MOOD.wagT; }
    if (EYE.mode !== last.mode) { log('eyeMode', { m: EYE.mode }); last.mode = EYE.mode; }
    if (SLP.on !== last.slp) { log(SLP.on ? 'sleepOn' : 'sleepOff', { z: +BRAIN.z.toFixed(2) }); last.slp = SLP.on; }
    const pk = BRAIN.pre ? BRAIN.pre.k : null; if (pk !== last.pre) { if (pk) log('pre', { p: pk }); last.pre = pk; }
    const e4 = E4.on ? E4.ph : ''; if (e4 !== last.e4) { log('e4', { ph: e4 }); last.e4 = e4; }
    if (LURE.on !== last.lure) { log('lure', { on: LURE.on }); last.lure = LURE.on; }
    if (ECHO.st !== last.echo) { log('echo', { st: ECHO.st, same: ECHO.same }); last.echo = ECHO.st; }
    if (ESC.on !== last.esc) { log('esc', { on: ESC.on }); last.esc = ESC.on; }
    if (SHK.t0 !== last.shk) { if (t - SHK.t0 < .05) log('shake', { amp: +SHK.amp.toFixed(2) }); last.shk = SHK.t0; }
    if (E2.leanT !== last.lean) { log('lean', { S: E2.leanS }); last.lean = E2.leanT; }
    if (EYE.sacT !== last.sac) { log('sac', { you: EYE.sx === 0 && EYE.sy === 0 }); last.sac = EYE.sacT; }
    if (EYE.user !== last.user) { if (EYE.user > t) log('lookYou', { d: +(EYE.user - t).toFixed(1) }); last.user = EYE.user; }
  }
  function engagedNow() { for (const f of fingers.values()) if (f.mode === 'grab' || t - f.hitT < .3 && !(f.lure && Math.hypot(f.vxS, f.vyS) < R)) return true; return false; }
  function klass() {   // 看得到的狀態（外人看牠會寫的分類）
    const eng = engagedNow();
    if (SLP.on) return eng ? 'held' : 'sleep';
    if (ESC.on) return 'flee';
    if (eng) return PURR > .3 ? 'purr' : MOOD.strain > .15 ? 'strain' : 'held';
    if (t < MOOD.cowerUntil) return 'cower';
    if (DR.push) return 'push';
    if (E4.on) return 'greet';
    if (BRAIN.pre && BRAIN.pre.k === 'sleep') return 'drowsy';
    if (BRAIN.pre && BRAIN.pre.k === 'greet') return 'greet';
    if (LURE.on) return 'lure';
    if (ECHO.st !== 'idle') return 'echo';
    if (CLING.on || SILL.stickT >= 0) return 'cling';
    if (SILL.air || SILL.hop) return 'air';
    if (INTRO.on) return 'hop';
    if (GAIT.on || WANDER.moving || LIFE.st === 'go' || LIFE.st === 'arrive' || SILL.route) return 'walk';
    if (LIFE.st === 'look' || LIFE.sns.some(s => !(s.cut > 0))) return 'look';
    return 'rest';
  }
  function shape() { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9, A = 0; const n = bnd.length; for (let k = 0; k < n; k++) { const i = bnd[k], j = bnd[(k + 1) % n]; if (X[i] < x0) x0 = X[i]; if (X[i] > x1) x1 = X[i]; if (Y[i] < y0) y0 = Y[i]; if (Y[i] > y1) y1 = Y[i]; A += X[i] * Y[j] - X[j] * Y[i]; } return { x0, x1, y0, y1, A: Math.abs(A) / 2 }; }
  // 外框每點相對重心的位移（上一取樣到這一取樣），用來量看得到的動
  let pB = null, pC = null;
  function motion() { const n = bnd.length; const cx = globalC.xc, cy = globalC.yc; const B = new Float64Array(n * 2); for (let k = 0; k < n; k++) { B[2 * k] = X[bnd[k]] - cx; B[2 * k + 1] = Y[bnd[k]] - cy; } let s = 0, mx = 0; if (pB && pB.length === B.length) { for (let k = 0; k < n; k++) { const d = Math.hypot(B[2 * k] - pB[2 * k], B[2 * k + 1] - pB[2 * k + 1]); s += d; if (d > mx) mx = d; } s /= n; } const tr = pC ? Math.hypot(cx - pC[0], cy - pC[1]) : 0; pB = B; pC = [cx, cy]; return [s, mx, tr]; }
  const S = [];
  function sample() {
    const B = BRAIN, sh = shape(), mo = motion(); const ga = (mat.gazeAmp || .06) * (1 - .8 * EYE.dk) * R * (mat.eyeSize || 1);
    S.push([+t.toFixed(2), klass(), LIFE.st, B.act, +B.z.toFixed(3), +B.q.toFixed(3), +B.s.toFixed(3), +B.f.toFixed(3), +B.e.toFixed(3), +B.m.toFixed(3),
      +IMP.tr.toFixed(3), +IMP.w.toFixed(3), +MOOD.c.toFixed(3), +MOOD.a.toFixed(3), +MOOD.scare.toFixed(3), +PURR.toFixed(3),
      +(EYE.gx * ga).toFixed(1), +(EYE.gy * ga * .75).toFixed(1), EYE.mode, +(EYE.openD * EYE.wideD).toFixed(2),
      +globalC.xc.toFixed(1), +globalC.yc.toFixed(1), +(sh.x1 - sh.x0).toFixed(1), +(sh.y1 - sh.y0).toFixed(1), +(sh.A / A0).toFixed(3),
      +mo[0].toFixed(2), +mo[1].toFixed(2), +mo[2].toFixed(2), BMEM.cell.map(v => +v.toFixed(2)), +BMEM.side.toFixed(2)]);
  }
  const OBS = window.OBS = {
    E, S, seeded, log, klass, shape, DT, engagedNow,
    reset(o) {   // 換一隻、熟多少、亂數種子
      o = o || {}; for (const f of [...fingers.values()]) releaseFinger(f, true);
      Math.random = seeded(o.seed || 1);
      for (const k in IMPS) delete IMPS[k];
      if (o.slime != null) chooseSlime(o.slime, false, false);
      VIEW.bg = o.bg || 'day';
      Object.assign(mat, o.over || {});
      t = 0; tLife = 0; setup();
      t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = o.tr || 0; IMP.w = o.w || 0; IMPD.tr = IMP.tr; IMPD.w = IMP.w;
      E4.count = 0; E4.lastT = -99; E4.wait = -1; BMEM.cell = (o.cell || [0, 0, 0, 0, 0]).slice(); BMEM.side = o.side || 0; BMEM.offerAt = -99; voice.last = -9; EYE.user = -9; EYE.sacT = 0; EYE.nextBlink = 2; BRX.sighNext = -1; MOOD.happyT = -9; MOOD.wagT = -9; ECHO.joyUntil = -9; ECHO.prev = null; DENTS.length = 0; SLP.wakeT = -9; DR.lookT = -9; DR.wideT = null; IMP.askUntil = -9; releaseCount = 0; IMP.has = false;
      BRAIN.seed = o.bseed == null ? 20261114 : o.bseed; brainReset(); BRAIN.m = BRAIN.mS = o.m == null ? .15 : o.m;
      E.length = 0; S.length = 0; pB = pC = null; Object.assign(last, { st: LIFE.st, sigh: BRX.sighCyc, blink: EYE.blinkT, flt0: FLN.t0, happy: MOOD.happyT, wag: MOOD.wagT, mode: EYE.mode, slp: SLP.on, pre: null, e4: '', lure: false, echo: 'idle', esc: false, shk: SHK.t0, lean: E2.leanT, sac: EYE.sacT, user: EYE.user });
      // 先落地站穩 3 秒
      rec = false; if (!o.raw) for (let i = 0; i < 180; i++) update(DT); rec = true; OBS.k = 0;
    },
    step() { update(DT); edge(); if (OBS.hook) OBS.hook(); OBS.k++; if (OBS.k % 30 === 0) sample(); },
    idle(sec) { const n = Math.round(sec * 60); for (let i = 0; i < n; i++) OBS.step(); },
    take() { const r = { E: E.splice(0), S: S.splice(0) }; return r; },
    // 手指
    scr(wx, wy) { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; },
    ev(type, id, x, y) { cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 })); },
    down(x, y, id) { OBS.fx = x; OBS.fy = y; OBS.ev('pointerdown', id || 1, x, y); }, mv(x, y, id) { OBS.fx = x; OBS.fy = y; OBS.ev('pointermove', id || 1, x, y); }, up(id) { OBS.ev('pointerup', id || 1, OBS.fx, OBS.fy); },
  };
  return 'ok';
})()
