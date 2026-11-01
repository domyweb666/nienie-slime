/* 捏捏史萊姆的音效播放（v2 分層版，2026-11-01）。
 * index.html 與 listen.html 共用。Swift 版 ios/NieNie/Feedback/SlimeAudio.swift 照同一張表寫，數字改了兩邊一起改，
 * 表在 .uiux/04-手感/音效參數對應-暫定.md。
 *
 * 聲音不是「觸發一段音檔」，是物理參數決定每一層多大聲、多高、多亮：
 *   press(i)          i 0..1 按的力道（呼叫端給；Swift 另外乘上接觸面積）
 *   release(g)        g 是放手事件的 gain（0.35..1），換成強度 s = (g-0.35)/0.65
 *   strand(g)         拉長過一個段落時呼叫一次，固定響一根細絲
 *   frame(dt, st)     每幀呼叫：st = {rub 揉的程度 0..1, stretch 拉最長那指的拉伸（半徑）, grabbing 有沒有手指抓著}
 * 讀 manifest.json：v2 是 {"press":{"body":[],"wet":[],"air":[]}, ...}；舊的 {"press":[...]} 也吃（整包當一層 all）。
 */
(function () {
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  const rnd = (a, b) => a + Math.random() * (b - a);

  // ---- 對應表（跟 .uiux/04-手感/音效參數對應-暫定.md 同步）----
  const MAP = {
    maxVoices: 14,          // 同時最多幾個一次性聲音；超過就丟掉新的點綴層（air、settle、strand），主體層照放
    retrigger: 0.06,        // 同一類 60 毫秒內再觸發：只放 wet，音量 ×0.6（兩指捏、連點不糊成一團）
    press: {
      body: i => i > 0.3 ? { g: 0.9 * i ** 1.2, r: 1.06 - 0.14 * i, lp: 2600 } : null,
      wet: i => ({ g: 0.45 + 0.45 * i, r: 1, lp: 1600 + 3400 * i }),
      air: i => Math.random() < 0.35 + 0.6 * i ? { g: 0.25 + 0.45 * i, r: rnd(0.9, 1.15), lp: 6000, delay: rnd(0.015, 0.045), deco: true } : null,
    },
    release: {   // s 0..1；越用力越大顆（音高越低）、越多層
      air: s => ({ g: 0.55 + 0.45 * s, r: 1.08 - 0.14 * s, lp: 7000 }),
      wet: s => ({ g: 0.25 + 0.6 * s, r: 1, lp: 1800 + 4200 * s }),
      body: s => s > 0.2 ? { g: 0.85 * s ** 1.3, r: 1.05 - 0.1 * s, lp: 2400 } : null,
    },
    settle: {    // 放手後的餘韻。拉過（≥0.4R）冒小氣泡；壓久（≥0.5 秒）沒拉放開，嘶一聲
      bubbles: s => Math.round(1 + 2 * s), bubbleProb: 0.7, from: 0.12, to: 0.7,
      bubble: s => ({ g: rnd(0.12, 0.22) + 0.15 * s, r: rnd(0.85, 1.35), lp: 6000, deco: true }),
      hissProb: 0.6, hissHold: 0.5,
      hiss: s => ({ g: 0.35 + 0.35 * s, r: rnd(0.9, 1.1), lp: 8000, delay: 0.03, deco: true }),
    },
    pull: {      // st 拉伸（半徑），v 拉伸的變化速度（半徑／秒，平滑 60 毫秒）
      on: 0.2,                                            // 拉不到 0.2R 不算拉
      gain: (st, v) => 0.12 * clamp((st - 0.2) / 0.4, 0, 1) + 0.88 * Math.min(1, v / 2.5),
      rate: st => 0.85 + 0.4 * Math.tanh(st / 3),         // 越拉越細越高
      lp: st => 1000 + 3500 * Math.tanh(st / 3),          // 越拉越亮
      attack: 0.05, decay: 0.12,
      strandRate: (st, v) => st > 0.4 ? (2 + 16 * Math.tanh(st / 3)) * (0.25 + 0.75 * Math.min(1, v / 2.5)) : 0,   // 每秒幾根
      strand: st => ({ g: rnd(0.12, 0.3), r: (0.85 + 0.5 * Math.tanh(st / 3)) * rnd(0.92, 1.08), lp: 9000, deco: true }),
    },
    rub: {       // L 0..1（已乘揉的音量上限）；拉遠了讓位給拉絲，不疊成一團
      rate: n => 0.94 + 0.12 * n, lp: n => 1400 + 2600 * n,   // n = L / 上限
      duck: st => clamp(1 - (st - 0.3) / 0.7, 0, 1),
    },
  };

  const S = {
    MAP, ctx: null, master: null, manifest: null, buf: {}, muted: false, volume: 0.9, jitter: 0.08, pullMax: 0.6, rubMax: 0.7, settleAmt: 1,
    active: 0, last: {}, pending: [], st: 0, stS: 0, v: 0, lastStretch: 0, heldFor: 0, base: 'sfx/',
    pullV: null, rubV: null,
    // v2.21 背景音樂（多米 build 77：背景要放 lofi）：mode 0 音樂和音效、1 只有捏的聲音、2 全部靜音。bgmUrl 由呼叫端給（沒給就沒有音樂）
    mode: 0, bgmUrl: null, bgmVol: 0.25, bgmDuck: 0.6, bgmG: null, bgmSrc: null, bgmT: -1,
  };
  // 一首可以無縫循環的 lofi（prototype/sfx-design/design_lofi.py，40 小節、76 BPM）。自己一條 gain 直接接輸出，不經過音效的 master；
  // 手指抓著時降到六成，讓捏的聲音在前面（0.4 秒慢慢降、1.2 秒慢慢回）。AAC 解碼後尾巴可能多一點空白，循環只取前 40 小節
  const BGM_LOOP = 40 * 4 * 60 / 76;
  function startBgm() {
    const c = S.ctx; if (!c || !S.bgmUrl || S.bgmG) return;
    S.bgmG = c.createGain(); S.bgmG.gain.value = 0; S.bgmG.connect(c.destination);
    fetch(S.bgmUrl).then(r => r.ok ? r.arrayBuffer() : Promise.reject(r.status)).then(ab => c.decodeAudioData(ab)).then(b => {
      const src = c.createBufferSource(); src.buffer = b; src.loop = true;
      if (b.duration > BGM_LOOP + 0.005) { src.loopStart = 0; src.loopEnd = BGM_LOOP; }
      src.connect(S.bgmG); src.start(); S.bgmSrc = src; S.bgmT = -1;
    }).catch(() => {});
  }
  function bgmTarget(grabbing) { return S.mode === 0 ? S.bgmVol * (grabbing ? S.bgmDuck : 1) : 0; }

  function normManifest(m) {
    const out = {};
    for (const k of Object.keys(m || {})) {
      if (k === 'version') continue;
      const v = m[k];
      if (Array.isArray(v)) out[k] = k === 'rub' ? { loop: v } : k === 'pull' ? { strand: v } : { all: v };
      else out[k] = v;
    }
    return out;
  }

  S.load = function (base) {
    S.base = base || 'sfx/';
    return fetch(S.base + 'manifest.json', { cache: 'no-store' }).then(r => r.ok ? r.json() : null).then(m => { S.manifest = normManifest(m) }).catch(() => {});
  };

  // iOS 規定要在第一次觸碰裡建立音訊
  S.init = function () {
    if (S.ctx) { if (S.ctx.state === 'suspended') S.ctx.resume(); return; }
    if (!S.manifest) return;
    const C = window.AudioContext || window.webkitAudioContext; if (!C) return;
    const c = S.ctx = new C();
    S.master = c.createGain(); S.master.gain.value = S.muted ? 0 : S.volume; S.master.connect(c.destination);
    startBgm();
    for (const k of Object.keys(S.manifest)) for (const layer of Object.keys(S.manifest[k])) {
      const key = k + '.' + layer; S.buf[key] = [];
      for (const f of S.manifest[k][layer]) fetch(S.base + f).then(r => r.arrayBuffer()).then(ab => c.decodeAudioData(ab)).then(b => S.buf[key].push(b)).catch(() => {});
    }
  };

  S.setMuted = function (m) { S.muted = m; if (S.master) S.master.gain.setTargetAtTime(m ? 0 : S.volume, S.ctx.currentTime, 0.02); if (m) S.pending = []; };
  S.setMode = function (m) { S.mode = m; S.setMuted(m === 2); if (S.bgmG) { S.bgmT = bgmTarget(false); S.bgmG.gain.setTargetAtTime(S.bgmT, S.ctx.currentTime, 0.3); } };
  S.setVolume = function (v) { S.volume = v; if (S.master && !S.muted) S.master.gain.setTargetAtTime(v, S.ctx.currentTime, 0.02); };

  function pick(key) { const l = S.buf[key]; return l && l.length ? l[Math.floor(Math.random() * l.length)] : null; }

  function one(key, p) {
    const c = S.ctx; if (!c || S.muted || !p) return;
    if (p.deco && S.active >= MAP.maxVoices) return;
    if (S.active >= MAP.maxVoices + 4) return;
    const b = pick(key); if (!b) return;
    const src = c.createBufferSource(), g = c.createGain(), lp = c.createBiquadFilter();
    lp.type = 'lowpass'; lp.frequency.value = p.lp || 8000; lp.Q.value = 0.5;
    src.buffer = b; src.playbackRate.value = (p.r || 1) * (1 + (Math.random() * 2 - 1) * S.jitter);
    g.gain.value = clamp(p.g, 0, 1);
    src.connect(lp); lp.connect(g); g.connect(S.master);
    S.active++; src.onended = () => { S.active--; };
    src.start(c.currentTime + (p.delay || 0));
  }

  // 一次性事件：把一類的每一層各自挑一段、各自浮音高、各自決定要不要響
  function layered(kind, x) {
    const c = S.ctx; if (!c || S.muted) return;
    const now = c.currentTime, again = now - (S.last[kind] || -1) < MAP.retrigger; S.last[kind] = now;
    const spec = MAP[kind], lay = (S.manifest || {})[kind] || {};
    if (lay.all) { one(kind + '.all', { g: 0.4 + 0.6 * x, r: 1 }); return; }   // 舊格式（一類一包）
    for (const name of Object.keys(spec)) {
      if (again && name !== 'wet') continue;
      const p = spec[name](x); if (!p) continue;
      if (again) p.g *= 0.6;
      one(kind + '.' + name, p);
    }
  }

  S.press = function (i) { S.pending = []; layered('press', clamp(i, 0, 1)); };

  S.release = function (gain) {
    const s = clamp((gain - 0.35) / 0.65, 0, 1);
    layered('release', s);
    const T = MAP.settle, now = S.ctx ? S.ctx.currentTime : 0, amt = S.settleAmt;
    if (amt <= 0) return;
    if (S.lastStretch >= 0.4) {
      for (let k = 0; k < T.bubbles(s); k++) if (Math.random() < T.bubbleProb) {
        const p = T.bubble(s); p.g *= amt; S.pending.push({ at: now + rnd(T.from, T.to), key: 'settle.bubble', p });
      }
    } else if (S.heldFor >= T.hissHold && Math.random() < T.hissProb) {
      const p = T.hiss(s); p.g *= amt; one('settle.hiss', p);
    }
  };

  S.strand = function (gain) { const p = MAP.pull.strand(S.st); p.g = clamp(p.g * (0.6 + 0.8 * gain), 0, 1); p.deco = false; one('pull.strand', p); };

  function loopVoice(key) {
    const c = S.ctx, b = pick(key); if (!b) return null;
    const src = c.createBufferSource(), lp = c.createBiquadFilter(), g = c.createGain();
    lp.type = 'lowpass'; lp.Q.value = 0.6; g.gain.value = 0;
    src.buffer = b; src.loop = true; src.loopStart = 0; src.loopEnd = b.duration;
    src.connect(lp); lp.connect(g); g.connect(S.master); src.start();
    return { src, lp, g, level: 0 };
  }
  function stopLoop(v) { try { v.src.stop(); } catch (_) {} v.src.disconnect(); v.g.disconnect(); }

  S.frame = function (dt, st) {
    const c = S.ctx; if (!c) return;
    dt = Math.max(1e-3, Math.min(0.1, dt));
    const grabbing = !!st.grabbing, stretch = grabbing ? (st.stretch || 0) : 0;
    // 拉伸速度：差分後平滑 60 毫秒
    const vraw = Math.abs(stretch - S.st) / dt; S.st = stretch;
    S.v += (vraw - S.v) * (1 - Math.exp(-dt / 0.06));
    // 這次抓住拉最長多少、抓了多久：抓住那幀歸零，放開後留著（放手事件比下一幀早到，release 讀的就是剛放開那次）
    if (grabbing && !S._wasGrab) { S.lastStretch = 0; S.heldFor = 0; }
    if (grabbing) { S.lastStretch = Math.max(S.lastStretch, stretch); S.heldFor += dt; }
    S._wasGrab = grabbing;
    // 背景音樂的音量（模式、抓著時讓位）
    if (S.bgmG) { const bt = bgmTarget(grabbing); if (Math.abs(bt - S.bgmT) > 1e-4) { S.bgmG.gain.setTargetAtTime(bt, c.currentTime, bt < S.bgmT ? 0.4 : 1.2); S.bgmT = bt; } }
    // 餘韻排程
    if (S.pending.length) { const now = c.currentTime; S.pending = S.pending.filter(e => { if (e.at <= now) { one(e.key, e.p); return false; } return true; }); }
    if (S.muted) return;
    // 拉絲 loop
    const P = MAP.pull, pulling = grabbing && stretch > P.on;
    const target = pulling ? S.pullMax * clamp(P.gain(stretch, S.v), 0, 1) : 0;
    if (target > 0.005 && !S.pullV) S.pullV = loopVoice('pull.loop');
    if (S.pullV) {
      const V = S.pullV, k = 1 - Math.exp(-dt / (target > V.level ? P.attack : P.decay));
      V.level += (target - V.level) * k;
      V.g.gain.setTargetAtTime(V.level, c.currentTime, 0.015);
      if (pulling) { V.src.playbackRate.setTargetAtTime(P.rate(stretch), c.currentTime, 0.03); V.lp.frequency.setTargetAtTime(P.lp(stretch), c.currentTime, 0.03); }
      if (!pulling && V.level < 0.004) { stopLoop(V); S.pullV = null; }
    }
    if (pulling) { const lam = P.strandRate(stretch, S.v); if (Math.random() < lam * dt) one('pull.strand', P.strand(stretch)); }
    // 揉 loop
    const R = MAP.rub, L = clamp(st.rub || 0, 0, 1) * R.duck(stretch), n = S.rubMax > 0 ? clamp(L / S.rubMax, 0, 1) : 0;
    if (L > 0.005 && !S.rubV) S.rubV = loopVoice('rub.loop');
    if (S.rubV) {
      const V = S.rubV;
      V.g.gain.setTargetAtTime(L, c.currentTime, 0.06);
      V.src.playbackRate.setTargetAtTime(R.rate(n), c.currentTime, 0.05);
      V.lp.frequency.setTargetAtTime(R.lp(n), c.currentTime, 0.05);
      V.level += (L - V.level) * (1 - Math.exp(-dt / 0.06));
      if (L <= 0.005 && V.level < 0.004) { stopLoop(V); S.rubV = null; }
    }
  };

  window.SlimeSfx = S;
})();
