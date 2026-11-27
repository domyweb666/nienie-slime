/* A8 現況圖（batch3 #9）：兩指 45 度、三指拉的定時截圖。
   先載 F1 的 probe.js（.vibe/audit-2026-11-24/patches/F1-量測工具/probe.js，提供 PB.fresh、PB.step、破皮判定），再載這支。
   手勢照 probe.js 的 opp、three 寫（同樣的起點、速度、按住 3 秒、手指錯開放），多了：
   - 定時截圖：拉到最遠、按住 1 秒、按住 3 秒（放手前一格）、最後一指放開後 0.1 秒、1 秒
   - 破的那一格：裂、洞、突變各留最嚴重那一格（突變那張用紅點描上一次讀到的外框）
   - swap：放手後第一次換網格（點數變了）那一格和前一格各截一張
   - burst：[起, 迄] 這幾格每格都截（查一格突變是什麼）
   - 時間軸：每 2 格讀一次畫面，記幾塊、幾個洞、有沒有突變；nch 記網格點數或補點次數變的那幾格、扯斷成兩隻（v2.62 的第二隻 B2）出現和合回的那一格 */
(() => {
  const A8 = window.A8 = {}; const { down, move, up } = PB.lowlevel; const V = PB.VIS, scr = PB.scr;
  const F = new Map(); let fr = 0, ph = '', shots = [], worst = {}, tl = [], nch = [], lastUp = -1;
  const toEdge = (sx, sy, ux, uy) => { let k = 1e9; if (ux > 1e-6) k = Math.min(k, (W - 4 - sx) / ux); if (ux < -1e-6) k = Math.min(k, (4 - sx) / ux); if (uy > 1e-6) k = Math.min(k, (H - 4 - sy) / uy); if (uy < -1e-6) k = Math.min(k, (4 - sy) / uy); return k; };
  const D = (id, x, y) => { F.set(id, [x, y]); down(id, x, y); };
  const M = (id, x, y) => { const r = move(id, x, y); F.set(id, r); return r; };
  const U = id => { F.delete(id); up(id); lastUp = fr; };
  function cap(prev) {
    const s = A8.scale || 1, k = document.createElement('canvas'); k.width = Math.round(W * s); k.height = Math.round(H * s); const c = k.getContext('2d'); c.drawImage(cv, 0, 0, k.width, k.height);
    if (prev) { const w = V.w, hh = V.h; c.fillStyle = 'rgba(230,0,0,.95)'; for (let y = 1; y < hh - 1; y++) for (let x = 1; x < w - 1; x++) { const i = y * w + x; if (prev[i] && (!prev[i - 1] || !prev[i + 1] || !prev[i - w] || !prev[i + w])) c.fillRect(x * W / w * s, y * H / hh * s, 1.6 * s, 1.6 * s); } }
    for (const [x, y] of F.values()) { c.beginPath(); c.arc(x * s, y * s, 17 * s, 0, 6.283); c.lineWidth = 3 * s; c.strokeStyle = 'rgba(255,255,255,.9)'; c.stroke(); c.lineWidth = 1.6 * s; c.strokeStyle = 'rgba(20,20,20,.9)'; c.stroke(); }
    return k.toDataURL('image/png');
  }
  const step0 = PB.step;
  const step = p => {
    ph = p; const pm = V.prev, n0 = N, r0 = REM.n, b0 = !!B2.on; let pre = null; if (swapOn && p === 'rel' && !swapDone) { draw(); pre = cap(null); } step0(p); fr++; if (N !== n0 || REM.n !== r0) { nch.push([fr, p, 'N', n0, N, REM.n]); if (pre && N !== n0) { swapDone = true; shots.push({ tag: 'swapA', txt: '換網格前一格', fr: fr - 1, ph: p, img: pre }); draw(); shots.push({ tag: 'swapB', txt: '換網格這一格（紅點是前一格讀到的外框）', fr, ph: p, img: cap(pm) }); } } if (!!B2.on !== b0) nch.push([fr, p, B2.on ? 'twin' : 'merged']); if (burst && fr >= burst[0] && fr <= burst[1]) { draw(); shots.push({ tag: 'b' + fr, txt: '第 ' + fr + ' 格', fr, ph: p, img: cap(null) }); }
    if (V.prev === pm || !V.last) return;   // 這格沒讀畫面
    const L = V.last, big = []; let e1 = false; for (const o of L.out) { if (o.a < PB.CMIN) continue; if (o.eb) { if (!e1) { e1 = true; big.push(o); } } else big.push(o); }
    const hb = L.holes.filter(o => o.a >= PB.HMIN), pop = L.pop > PB.POP ? L.pop : 0;
    tl.push([fr, p, big.length, hb.length, +pop.toFixed(2), B2.on ? 1 : 0, +L.pop.toFixed(3)]);
    const ev = []; if (big.length > 1) ev.push(['split', big[1].a]); if (hb.length) ev.push(['hole', hb[0].a]); if (pop) ev.push(['pop', pop]);
    for (const [ty, sev] of ev) { const w = worst[ty]; if (!w || sev > w.sev * 1.05) worst[ty] = { ty, sev: +sev.toFixed(3), fr, ph: p, rel: lastUp >= 0 ? +((fr - lastUp) / 60).toFixed(2) : null, n: big.length, nh: hb.length, tw: B2.on ? 1 : 0, img: cap(ty === 'pop' ? pm : null) }; }
  };
  let burst = null, swapOn = false, swapDone = false;
  const nst = (p, n) => { for (let i = 0; i < n; i++) step(p); };
  const shot = (tag, txt) => { draw(); shots.push({ tag, txt, fr, ph, img: cap(null) }); };
  const G = {
    // 兩指往反方向：一指往 +ang（45 度是右下，拉到窗台下），一指往反方向
    opp(c) { PB.fresh(c.seed); const a = c.ang * Math.PI / 180, ux = Math.cos(a), uy = Math.sin(a), [cx, cy] = scr(globalC.xc, globalC.yc), o = c.from === 'edge' ? .75 : .35; const p1 = [cx + ux * R * o, cy + uy * R * o], p2 = [cx - ux * R * o, cy - uy * R * o]; const e1 = toEdge(p1[0], p1[1], ux, uy), e2 = toEdge(p2[0], p2[1], -ux, -uy), d1 = c.dist === 'edge' ? e1 : Math.min(c.dist * R, e1), d2 = c.dist === 'edge' ? e2 : Math.min(c.dist * R, e2);
      const info = { d1: +(d1 / R).toFixed(2), d2: +(d2 / R).toFixed(2), ground: +scr(0, GROUND)[1].toFixed(0) };
      D(1, ...p1); D(2, ...p2); nst('pull', 4); const n = Math.max(2, Math.ceil(Math.max(d1, d2) / R / (c.sp === 'fast' ? 20 : 3) * 60)); for (let s = 1; s <= n; s++) { M(1, p1[0] + ux * d1 * s / n, p1[1] + uy * d1 * s / n); M(2, p2[0] - ux * d2 * s / n, p2[1] - uy * d2 * s / n); step('pull'); }
      info.f1 = F.get(1).map(v => +v.toFixed(0)); info.f2 = F.get(2).map(v => +v.toFixed(0)); return info; },
    // 三指從中間往上、右下、左下各拉開 dist R
    three(c) { PB.fresh(c.seed); const [cx, cy] = scr(globalC.xc, globalC.yc), pt = (k, s) => { const a = -Math.PI / 2 + k * 2 * Math.PI / 3, r = R * (.4 + c.dist * s); return [cx + Math.cos(a) * r, cy + Math.sin(a) * r]; };
      for (let k = 0; k < 3; k++) D(k + 1, ...pt(k, 0)); nst('pull', 4); const n = Math.max(3, Math.ceil(c.dist / (c.sp === 'fast' ? 20 : 3) * 60)); for (let s = 1; s <= n; s++) { for (let k = 0; k < 3; k++) M(k + 1, ...pt(k, s / n)); step('pull'); }
      return { f: [...F.values()].map(p => p.map(v => +v.toFixed(0))) }; }
  };
  A8.run = c => {
    F.clear(); fr = 0; shots = []; worst = {}; tl = []; nch = []; lastUp = -1; A8.scale = c.scale || 1; burst = c.burst || null; swapOn = !!c.swap; swapDone = false; PB.snapOn = false;
    PB.begin(c.id, c.label, c.seed); const info = G[c.k](c);
    shot('far', '拉到最遠'); nst('hold', 60); shot('hold1', '按住 1 秒'); nst('hold', 119); shot('hold3', '按住 3 秒'); step('hold');
    const ids = [...F.keys()], gap = c.k === 'opp' ? 6 : 5; ids.forEach((id, i) => { U(id); if (i < ids.length - 1) nst('rel', gap); });
    const last = fr; nst('rel', 6); shot('rel01', '放手後 0.1 秒'); nst('rel', 54); shot('rel1', '放手後 1 秒'); nst('rel', 240 - (fr - last) - (ids.length - 1) * gap);
    const m = PB.end(); Math.random = PB.real;
    const ph = {}; for (const k in m.ph) { const q = m.ph[k]; ph[k] = { fr: q.fr, cFr: q.cFr, hFr: q.hFr, popN: q.popN, cMax: q.cMax, hMax: q.hMax, popMax: q.popMax, neck: q.neck, len: q.len, gapMax: q.gapMax, er: q.erMax, nan: q.nan }; }
    return { id: c.id, c, info, ph, ev: m.ev, shots, worst: Object.values(worst), tl, nch, N: m.N, release: last };
  };
})();
