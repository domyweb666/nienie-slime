/* 禪模式（2026-11-08，多米：背景放佛經、捏史萊姆發出木魚聲，做個切換鍵看效果）。
 * 實驗，獨立一個檔：index.html 只多一行 <script src="sfx/zen.js">，放在 engine.js 後面。拿掉那行就完全回原樣。
 *
 * 開著時：
 *   按下去（SlimeSfx.press）  → 木魚「叩」，力道決定大小聲；手指按的話跳一個「功德 +1」
 *   放手、拉絲、揉            → 不出聲（木魚只有「點」，沒有連續的聲音）
 *   它自己的聲音（E1）、黏液  → 照舊
 *   背景                      → lofi 淡出，換成 sfx/zen/chant-loop.m4a（design_zen.py 合成的佛號）；手指抓著時降到七成
 * 喇叭按鈕三段照舊：音樂和音效／只有捏的聲音（沒有唱誦，有木魚）／全部靜音。
 * 切換鍵在右上角喇叭左邊（🪷），開關記在這支瀏覽器（localStorage）。
 */
(function () {
  const S = window.SlimeSfx; if (!S) return;
  const BASE = 'sfx/zen/';
  const Z = { on: false, man: null, muyu: [], chantG: null, chantSrc: null, chantT: -1, vol: 0.32, duck: 0.7, last: -1, merit: 0, lofiVol: S.bgmVol, ptT: -9, px: 0, py: 0, loading: false };
  S.zen = Z;

  // 頁面一打開就先把檔案抓下來（還沒碰螢幕不能建音訊，解碼等第一次切換或觸碰）；不然第一次切換會有幾秒沒聲音
  const raw = {};
  const got = f => raw[f] || (raw[f] = fetch(BASE + f).then(r => r.arrayBuffer()));
  fetch(BASE + 'manifest.json', { cache: 'no-store' }).then(r => r.ok ? r.json() : null).then(m => { Z.man = m; if (m) { m.muyu.forEach(got); got(m.chant); } }).catch(() => {});

  function loadBuffers() {
    const c = S.ctx; if (!c || !Z.man || Z.loading) return;
    Z.loading = true;
    for (const f of Z.man.muyu) got(f).then(ab => c.decodeAudioData(ab.slice(0))).then(b => Z.muyu.push(b)).catch(() => {});
    Z.chantG = c.createGain(); Z.chantG.gain.value = 0; Z.chantG.connect(c.destination);
    got(Z.man.chant).then(ab => c.decodeAudioData(ab.slice(0))).then(b => {
      const src = c.createBufferSource(); src.buffer = b; src.loop = true;
      const pad = Z.man.pad || 0, L = Z.man.loop || b.duration, ok = b.duration > pad + L;
      if (ok) { src.loopStart = pad; src.loopEnd = pad + L; }
      src.connect(Z.chantG); src.start(0, ok ? pad : 0); Z.chantSrc = src; Z.chantT = -1;
    }).catch(() => {});
  }
  function chantTarget(grabbing) { return Z.on && S.mode === 0 ? Z.vol * (grabbing ? Z.duck : 1) : 0; }
  function setChant(grabbing, tau) {
    if (!Z.chantG) return; const v = chantTarget(grabbing);
    if (Math.abs(v - Z.chantT) > 1e-4) { Z.chantG.gain.setTargetAtTime(v, S.ctx.currentTime, tau != null ? tau : (v < Z.chantT ? 0.4 : 1.2)); Z.chantT = v; }
  }

  function knock(i) {
    const c = S.ctx; if (!c || S.muted || !Z.muyu.length) return;
    const now = c.currentTime;
    if (now - Z.last < 0.07) return;   // 兩指捏、連續碰：70 毫秒內只敲一下
    Z.last = now;
    const b = Z.muyu[Math.floor(Math.random() * Z.muyu.length)];
    const src = c.createBufferSource(), g = c.createGain();
    src.buffer = b; src.playbackRate.value = 1 + (Math.random() * 2 - 1) * 0.025;
    g.gain.value = Math.min(1, 0.35 + 0.6 * i);
    src.connect(g); g.connect(S.master || c.destination); src.start(now);
    // 手指剛按下（150 毫秒內）才算你敲的，跳「功德 +1」；落地、吞黏液這種它自己的碰撞不算
    if (performance.now() - Z.ptT < 150) merit();
  }

  // 功德 +1：從手指的位置往上飄、淡掉
  const css = document.createElement('style');
  css.textContent = '.zen-merit{position:fixed;z-index:30;pointer-events:none;font-weight:800;font-size:17px;color:var(--ink,#3a3a3a);' +
    'text-shadow:0 1px 0 rgba(255,255,255,.8);transform:translate(-50%,-100%);animation:zenUp .9s ease-out forwards;white-space:nowrap}' +
    '@keyframes zenUp{0%{opacity:0;margin-top:0}15%{opacity:1}100%{opacity:0;margin-top:-56px}}' +
    '#b-zen[aria-pressed="false"]{opacity:.55}.zen-right{display:flex;gap:10px;align-items:center}';
  document.head.appendChild(css);
  function merit() {
    Z.merit++;
    const d = document.createElement('div'); d.className = 'zen-merit'; d.textContent = '功德 +1';
    d.style.left = Z.px + 'px'; d.style.top = (Z.py - 24) + 'px';
    document.body.appendChild(d); setTimeout(() => d.remove(), 950);
  }
  addEventListener('pointerdown', e => { Z.ptT = performance.now(); Z.px = e.clientX; Z.py = e.clientY; }, { capture: true, passive: true });

  // 把原本的聲音接過來：開著時換成木魚，關著時一字不動
  const orig = { press: S.press, release: S.release, strand: S.strand, frame: S.frame, init: S.init, setMode: S.setMode };
  S.press = function (i) { if (!Z.on) return orig.press(i); S.pending = []; knock(Math.max(0, Math.min(1, i))); };
  S.release = function (g) { if (!Z.on) return orig.release(g); };
  S.strand = function (g) { if (!Z.on) return orig.strand(g); };
  S.frame = function (dt, st) {
    if (!Z.on) { orig.frame(dt, st); setChant(false); return; }
    orig.frame(dt, { rub: 0, stretch: 0, grabbing: st.grabbing });   // 拉絲、揉的 loop 不響；lofi 照 bgmVol（已經是 0）淡出
    setChant(!!st.grabbing);
  };
  S.init = function () { orig.init(); if (S.ctx && Z.on) loadBuffers(); };
  S.setMode = function (m) { orig.setMode(m); setChant(false, 0.3); };

  function apply(on) {
    Z.on = on;
    if (on) { if (S.bgmVol > 0) Z.lofiVol = S.bgmVol; S.bgmVol = 0; } else S.bgmVol = Z.lofiVol;
    if (S.ctx) { if (on) loadBuffers(); if (S.bgmG) { S.bgmT = -1; } setChant(false, on ? 1.2 : 0.4); }
    const b = document.getElementById('b-zen');
    if (b) { b.setAttribute('aria-pressed', String(on)); b.title = on ? '禪模式：開（木魚＋佛號）' : '禪模式：關'; }
    try { localStorage.setItem('nienie.zen', on ? '1' : '0'); } catch (_) {}
  }

  function mount() {
    const mute = document.getElementById('b-mute'); if (!mute || document.getElementById('b-zen')) return;
    const wrap = document.createElement('div'); wrap.className = 'zen-right';
    mute.parentNode.insertBefore(wrap, mute);
    const b = document.createElement('button'); b.className = 'round'; b.id = 'b-zen'; b.textContent = '🪷'; b.setAttribute('aria-pressed', 'false');
    wrap.appendChild(b); wrap.appendChild(mute);
    b.addEventListener('click', () => { S.init(); apply(!Z.on); });
    let saved = false; try { saved = localStorage.getItem('nienie.zen') === '1'; } catch (_) {}
    apply(saved);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', mount); else mount();
})();
