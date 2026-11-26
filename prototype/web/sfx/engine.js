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
      gain: (st, v) => (0.12 + 0.18 * (1 - Math.exp(-Math.max(0, st - 0.6) / 4))) * clamp((st - 0.2) / 0.4, 0, 1) + 0.88 * Math.min(1, v / 2.5),   // v2.54：拉著不動也有一點聲，拉越長越清楚
      rate: st => 0.85 * Math.pow(2, 16 * (1 - Math.exp(-st / 5)) / 12),   // 越拉越細越高。v2.54 無限拉：以前 3R 後就幾乎不再變高（tanh），現在一路往上，1R 高 3 個半音、3R 7 個、6R 11 個、12R 14.5 個，最多 16 個
      lp: st => 1000 + 7000 * (1 - Math.exp(-st / 5)),    // 越拉越亮（v2.54 一路亮到 8 kHz）
      attack: 0.05, decay: 0.12,
      strandRate: (st, v) => st > 0.4 ? (2 + 16 * (1 - Math.exp(-st / 4))) * (0.25 + 0.75 * Math.min(1, v / 2.5)) : 0,   // 每秒幾根
      strand: st => ({ g: rnd(0.12, 0.3), r: 0.85 * Math.pow(2, 18 * (1 - Math.exp(-st / 5)) / 12) * rnd(0.92, 1.08), lp: 9000, deco: true }),
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
    // v2.40 環境音（多米 11-09：背景音改成真實環境聲，下雨、木材燃燒）：amb 'rain'／'fire'／'noise'／'lofi'（noise 是 11-22 加的粉紅噪音，只有底、沒有事件）。雨和柴火是「底＋零星事件」，
    // 底是兩分鐘無縫循環，事件照 amb.json 的頻率隨機冒出來（大小、左右、音高每次不同），聽不出循環。lofi 照舊
    // ambVol 0.4：雨的底播出來約 −32 dBFS、柴火 −34.5，捏的聲音 −34 左右；0.8 時雨比捏的聲音大 6 dB，ASMR 要史萊姆在前面（抓著時再降到六成）
    snd61: 1,   // v2.61 B1：揉的新循環（rub.loop61）和抓著時雨降到 0.3；0 回 rub.loop、0.6
    b5: 1, bufB5: {},   // v2.63 B5（sndB5）：嚇到、開心、不要啦、按的濕聲用跳過前奏的那一份（bufB5，載入時從同一個檔做的，leadTrim）；0 回原本的
    b6: 1,      // v2.63 B6（sndB6）：按下去只清上次放手的餘韻（排程裡 tail 的那幾顆），別的照放；0 回改之前（按下去整排清掉）
    amb: 'rain', ambMeta: null, ambVol: 0.4, ambSrc: null, ambSrcG: null, ambTok: 0, ambNext: {}, ambLast: {}, ambBuf: {},
  };
  // 一首可以無縫循環的 lofi（prototype/sfx-design/design_lofi.py，40 小節、76 BPM）。自己一條 gain 直接接輸出，不經過音效的 master；
  // 手指抓著時降到六成，讓捏的聲音在前面（0.4 秒慢慢降、1.2 秒慢慢回）。AAC 解碼後頭尾會多空白（2026-11-06 多米：循環有斷掉的聲音），檔案頭尾各多寫 1 秒週期內容，只循環中間那段，解碼器墊多少都接得上
  const BGM_LOOP = 5570526 / 44100, BGM_PAD = 1;   // 跟 design_lofi.py 印出來的格數一致
  // v2.40：bgmG 是所有背景聲（環境音、lofi）共用的匯流排，模式和抓著時讓位都在這一條；底聲各自一條 gain 接上來，換場景時交叉淡化
  function startBgm() {
    const c = S.ctx; if (!c || S.bgmG) return;
    S.bgmG = c.createGain(); S.bgmG.gain.value = 0; S.bgmG.connect(c.destination); S.bgmT = -1;
    S.setAmb(S.amb);
  }
  // 環境音自己的亂數（不碰 Math.random）：selftest 用固定種子取代 Math.random 量物理，環境音的事件在背景一直抽，
  // 會把整串亂數錯開，T49 同一個種子每輪結果都不一樣（11-09 量到休息比例 0.572 變 0.382 到 0.427）
  let arndS = (Date.now() ^ 0x9E3779B9) >>> 0;
  function arnd() { arndS = (arndS + 0x6D2B79F5) >>> 0; let t = arndS; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }
  function ambLoad(url) {
    if (!S.ambBuf[url]) S.ambBuf[url] = fetch(url).then(r => r.ok ? r.arrayBuffer() : Promise.reject(r.status)).then(ab => S.ctx.decodeAudioData(ab)).catch(() => null);
    return S.ambBuf[url];
  }
  function ambScene() { return S.ambMeta && S.ambMeta.scenes ? S.ambMeta.scenes[S.amb] : null; }
  // 換環境音：舊的 0.4 秒淡出、新的 0.6 秒淡入；底聲從循環裡隨機一點開始，每次打開聽到的開頭不一樣
  S.setAmb = function (name) {
    S.amb = name; S.ambNext = {};
    const c = S.ctx; if (!c || !S.bgmG) return;
    if (S.ambSrc) { const src = S.ambSrc, g = S.ambSrcG; g.gain.setTargetAtTime(0, c.currentTime, 0.4); setTimeout(() => { try { src.stop(); } catch (_) {} }, 2500); }
    S.ambSrc = null; S.ambSrcG = null;
    let url, pad, len, vol;
    const sc = ambScene();
    if (name === 'lofi') { if (!S.bgmUrl) return; url = S.bgmUrl; pad = BGM_PAD; len = BGM_LOOP; vol = S.bgmVol; }
    else if (sc) { url = S.base + sc.bed; pad = S.ambMeta.pad; len = sc.loopFrames / S.ambMeta.sr; vol = S.ambVol;
      for (const k of Object.keys(sc.events)) for (const f of sc.events[k].files) ambLoad(S.base + f); }
    else return;
    const tok = ++S.ambTok;
    ambLoad(url).then(b => {
      if (!b || tok !== S.ambTok) return;
      const src = c.createBufferSource(); src.buffer = b; src.loop = true;
      const ok = b.duration > pad + len - 0.01;   // 舊檔或解碼失敗就退回整個檔案循環
      if (ok) { src.loopStart = pad; src.loopEnd = pad + len; }
      const g = c.createGain(); g.gain.value = 0; g.gain.setTargetAtTime(vol, c.currentTime, 0.6);
      src.connect(g); g.connect(S.bgmG); src.start(0, ok ? pad + (name === 'lofi' ? 0 : arnd() * len) : 0);
      S.ambSrc = src; S.ambSrcG = g; if (name === 'lofi') S.bgmSrc = src;
    });
  };
  // 零星事件：每一種照 perMin 的頻率（指數分布的間隔，不少於 minGap 秒）出現；burst 是一次連著幾顆（劈啪常常兩三顆一起）。
  // 每顆隨機挑檔（不跟上一顆同一個）、音量在 gain 範圍裡、左右在 ±pan 裡、音高 ±4%。只在「環境音和音效」模式
  function ambStep() {
    const sc = ambScene(), c = S.ctx; if (!sc || S.mode !== 0 || !S.ambSrc) return;
    const now = c.currentTime, gap = e => Math.max(e.minGap || 0, -Math.log(1 - arnd()) * 60 / Math.max(0.01, e.perMin));
    for (const k of Object.keys(sc.events)) {
      const e = sc.events[k];
      if (S.ambNext[k] == null) { S.ambNext[k] = now + gap(e) * arnd() + 1; continue; }
      if (now < S.ambNext[k]) continue;
      S.ambNext[k] = now + gap(e);
      const b = e.burst || [1, 1], n = b[0] + Math.floor(arnd() * (b[1] - b[0] + 1));
      let at = now + 0.02;
      for (let i = 0; i < n; i++) { ambOne(k, e, at); at += 0.05 + 0.15 * arnd(); }
    }
  }
  function ambOne(k, e, at) {
    const c = S.ctx; let i = Math.floor(arnd() * e.files.length);
    if (e.files.length > 1 && i === S.ambLast[k]) i = (i + 1) % e.files.length;
    S.ambLast[k] = i;
    ambLoad(S.base + e.files[i]).then(buf => {
      if (!buf || !S.bgmG) return;
      const src = c.createBufferSource(); src.buffer = buf; src.playbackRate.value = 1 + (arnd() * 2 - 1) * 0.04;
      const g = c.createGain(); g.gain.value = S.ambVol * (e.gain[0] + arnd() * (e.gain[1] - e.gain[0]));
      let tail = g;
      if (c.createStereoPanner && e.pan) { const p = c.createStereoPanner(); p.pan.value = (arnd() * 2 - 1) * e.pan; g.connect(p); tail = p; }
      src.connect(g); tail.connect(S.bgmG); src.start(Math.max(at, c.currentTime));
    });
  }
  function bgmTarget(grabbing) { return S.mode === 0 ? (grabbing ? (S.snd61 && S.amb === 'rain' ? 0.3 : S.bgmDuck) : 1) : 0; }

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
    fetch(S.base + 'amb.json', { cache: 'no-store' }).then(r => r.ok ? r.json() : null).then(m => { S.ambMeta = m; if (S.ctx && S.bgmG && !S.ambSrc) S.setAmb(S.amb); }).catch(() => {});   // v2.40 環境音
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
      const key = k + '.' + layer, b5 = B5K.keys.includes(key); S.buf[key] = []; if (b5) S.bufB5[key] = [];
      for (const f of S.manifest[k][layer]) fetch(S.base + f).then(r => r.arrayBuffer()).then(ab => c.decodeAudioData(ab)).then(b => { S.buf[key].push(b); if (b5) S.bufB5[key].push(leadTrim(b)); }).catch(() => {});   // v2.63 B5：同一個回呼裡推，兩邊的順序一樣（洗牌袋的檔號對得上）
    }
  };

  S.setMuted = function (m) { S.muted = m; if (S.master) S.master.gain.setTargetAtTime(m ? 0 : S.volume, S.ctx.currentTime, 0.02); if (m) S.pending = []; };
  S.setMode = function (m) { S.mode = m; S.setMuted(m === 2); if (S.bgmG) { S.bgmT = bgmTarget(false); S.bgmG.gain.setTargetAtTime(S.bgmT, S.ctx.currentTime, 0.3); } };
  S.setVolume = function (v) { S.volume = v; if (S.master && !S.muted) S.master.gain.setTargetAtTime(v, S.ctx.currentTime, 0.02); };

  // v2.63 B5：這四種音檔開頭有一段很小聲的前奏（量到最大聲晚 60 到 267 毫秒），聽起來像比動作晚一拍。不改音檔：載入時每個檔另外做一份跳過前奏的，
  // 開頭到 −6 dB（5 毫秒一格取最大值，到全檔最大的一半）超過 late 秒，就從那一點前 keep 秒開始放，頭 fade 秒升餘弦淡入。Swift SlimeAudio 同一套數字（B5Set）
  const B5K = { keys: ['voice.startle', 'voice.happy', 'voice.protest', 'press.wet'], thr: 0.5, late: 0.03, keep: 0.02, fade: 0.013 };
  function onsetOf(b) {   // 開頭到 −6 dB 的毫秒（on）、最大聲那一格的毫秒（pk）
    const sr = b.sampleRate, w = Math.max(1, Math.round(0.005 * sr)), nb = Math.floor(b.length / w), env = new Float32Array(nb); let pk = 0, pi = 0;
    for (let k = 0; k < nb; k++) { let m = 0; for (let ch = 0; ch < b.numberOfChannels; ch++) { const d = b.getChannelData(ch); for (let i = k * w; i < (k + 1) * w; i++) { const a = Math.abs(d[i]); if (a > m) m = a; } } env[k] = m; if (m > pk) { pk = m; pi = k; } }
    let on = 0; while (on < nb && env[on] < pk * B5K.thr) on++;
    return { on: Math.round(on * w / sr * 1000), pk: Math.round(pi * w / sr * 1000), at: on * w / sr };
  }
  function leadTrim(b) {
    const o = onsetOf(b); if (o.at <= B5K.late || !S.ctx) return b;
    const sr = b.sampleRate, skip = Math.round((o.at - B5K.keep) * sr), n = b.length - skip, fade = Math.round(B5K.fade * sr); if (n <= 0) return b;
    const out = S.ctx.createBuffer(b.numberOfChannels, n, sr);
    for (let ch = 0; ch < b.numberOfChannels; ch++) { const s = b.getChannelData(ch), d = out.getChannelData(ch); for (let i = 0; i < n; i++) d[i] = s[i + skip] * (i < fade ? 0.5 - 0.5 * Math.cos(Math.PI * i / fade) : 1); }
    return out;
  }
  S.onsetOf = onsetOf; S.B5K = B5K;
  function pick(key, take) { const l = S.b5 && S.bufB5[key] && S.bufB5[key].length ? S.bufB5[key] : S.buf[key]; return l && l.length ? l[take != null ? take % l.length : Math.floor(Math.random() * l.length)] : null; }   // v2.63 C6: take = which file (the page's shuffle bag, rubVary); none = random as before

  function one(key, p) {
    const c = S.ctx; if (!c || S.muted || !p) return;
    if (p.deco && S.active >= MAP.maxVoices) return;
    if (S.active >= MAP.maxVoices + 4) return;
    const b = pick(key, p.take); if (!b) return;
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

  S.press = function (i) { S.pending = S.b6 ? S.pending.filter(e => !e.tail) : []; layered('press', clamp(i, 0, 1)); };   // 再按就切掉上次放手的尾巴

  S.release = function (gain) {
    const s = clamp((gain - 0.35) / 0.65, 0, 1);
    layered('release', s);
    const T = MAP.settle, now = S.ctx ? S.ctx.currentTime : 0, amt = S.settleAmt;
    if (amt <= 0) return;
    if (S.lastStretch >= 0.4) {
      for (let k = 0; k < T.bubbles(s); k++) if (Math.random() < T.bubbleProb) {
        const p = T.bubble(s); p.g *= amt; S.pending.push({ at: now + rnd(T.from, T.to), key: 'settle.bubble', p, tail: true });
      }
    } else if (S.heldFor >= T.hissHold && Math.random() < T.hissProb) {
      const p = T.hiss(s); p.g *= amt; one('settle.hiss', p);
    }
  };

  // v2.22 它的聲音（E1）：一種情緒一層，r 由呼叫端依印象給（熟的高、戒的低）；黏液滴下是一顆小泡
  S.voice = function (kind, g, r, take) { one('voice.' + kind, { g: clamp(g, 0, 1), r: r || 1, lp: 4000, take }); };
  // v2.30 擺飾碰到東西：kind pot 或 dish，g 力道；rate 小於 1 是掉到看不到的地方（遠一點、悶一點）
  S.knock = function (kind, g, rate) { const far = rate && rate < 1; one('prop.' + kind, { g: clamp(g, 0, 1) * (far ? 0.5 : 0.9), r: rnd(0.94, 1.06) * (far ? 0.9 : 1), lp: far ? 1200 : 5000 }); };
  // v2.50 場景聲（AI 音效，manifest fx.<kind>）：走、爬窗框、落地、游進來、黏到窗框、拔開、黏液滴、睡著、嘆氣、擺飾倒下、掉出窗外、走過布墊。
  // 同一種 0.25 秒內只響一次；音高 ±4% 每次不同；沒有檔案就安靜（舊的 manifest 照樣能用）
  S.fx = function (kind, g, r, delay) {
    const c = S.ctx; if (!c) return;
    const k = 'fx.' + kind, now = c.currentTime;
    if (now - (S.last[k] || -9) < 0.25) return; S.last[k] = now;
    one(k, { g: clamp(g, 0, 1), r: (r || 1) * rnd(0.96, 1.04), lp: 9000, delay: delay || 0 });
  };
  // v2.63 D4（flinchFx）：牠縮那一下的小聲：放手「噗」的 air 層，小聲、高一點點（g 由頁面給，0.3 × 縮的大小）。不排餘韻、不動 lastStretch。Swift SlimeAudio.flinch 同一套
  S.flinch = function (g) { one('release.air', { g: clamp(g, 0, 1), r: rnd(1.08, 1.16), lp: 7000 }); };
  S.drip = function (g) { one('settle.bubble', { g: clamp(g, 0, 1) * 0.6, r: rnd(0.8, 1.1), lp: 3000, deco: true }); };
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
    ambStep();   // v2.40 環境音的零星事件
    // 餘韻排程
    if (S.pending.length) { const now = c.currentTime; S.pending = S.pending.filter(e => { if (e.at <= now) { one(e.key, e.p); return false; } return true; }); }
    if (S.muted) return;
    // 拉絲 loop
    // v2.63 B1 拉（pullFx）：st.open = 手指往外拉出新距離的速度（半徑／秒，頁面算，pullFx 0 時給 0）。慢拉時身體一直跟上、拉伸過不了 0.2R，loop 要很久才起來；
    // 有在拉開就給一個底 pullMax × PF.g × min(1, open ÷ PF.v)，跟原本的取大。Swift SlimeAudio pullOpen 同一套
    const P = MAP.pull, PF = { g: 0.3, v: 0.5 }, open = grabbing ? Math.max(0, st.open || 0) : 0, floor = open > 0 ? S.pullMax * PF.g * Math.min(1, open / PF.v) : 0;
    const pulling = grabbing && (stretch > P.on || floor > 0.005);
    const target = pulling ? Math.max(stretch > P.on ? S.pullMax * clamp(P.gain(stretch, S.v), 0, 1) : 0, floor) : 0;
    S.pullT = target;   // v2.63：這一格拉絲 loop 要多大（selftest 讀；音效沒載到也有）
    if (target > 0.005 && !S.pullV) S.pullV = loopVoice('pull.loop');
    if (S.pullV) {
      const V = S.pullV, k = 1 - Math.exp(-dt / (target > V.level ? P.attack : P.decay));
      V.level += (target - V.level) * k;
      V.g.gain.setTargetAtTime(V.level, c.currentTime, 0.015);
      if (pulling) { V.src.playbackRate.setTargetAtTime(P.rate(stretch), c.currentTime, 0.03); V.lp.frequency.setTargetAtTime(P.lp(stretch), c.currentTime, 0.03); }
      if (!pulling && V.level < 0.004) { stopLoop(V); S.pullV = null; }
    }
    if (pulling && stretch > P.on) { const lam = P.strandRate(stretch, S.v); if (Math.random() < lam * dt) one('pull.strand', P.strand(stretch)); }
    // 揉 loop
    const R = MAP.rub, L = clamp(st.rub || 0, 0, 1) * R.duck(stretch), n = S.rubMax > 0 ? clamp(L / S.rubMax, 0, 1) : 0;
    if (L > 0.005 && !S.rubV) S.rubV = loopVoice(S.snd61 && S.buf['rub.loop61'] && S.buf['rub.loop61'].length ? 'rub.loop61' : 'rub.loop');
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
