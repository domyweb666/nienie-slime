/* 捏捏史萊姆 按壓與拉扯痕跡 設計稿共用引擎
   window.JellyDemo.mount(canvas, { press: 'NOW'|'A'|'B'|'C'|'D', pull: 同上, color: 'brown'|'berry'|'milk' })
   → { setColor(c), destroy() }
   純 2D canvas。痕跡全部用漸層疊在剪過的身體上，不逐像素運算。 */
(function () {
  'use strict';
  var W = 390, H = 844, N = 72;
  var SILL = 648;            // 史萊姆底部坐的高度（窗台上緣）
  var R = 110;               // 身體半寬
  var LIGHT = [-0.6, -0.8];  // 光從左上來（畫面座標，y 向下）

  var COLORS = {
    brown: { core: [150, 92, 52], base: [108, 60, 31], edge: [66, 34, 15], line: [40, 19, 8], sat: [176, 92, 36],
      shade: [36, 16, 6], aC: 0.68, aE: 0.94, eye: '#160a04', blush: 'rgba(255,140,118,0.42)' },
    berry: { core: [236, 104, 116], base: [206, 46, 66], edge: [146, 20, 40], line: [96, 10, 26], sat: [236, 34, 62],
      shade: [84, 6, 18], aC: 0.6, aE: 0.92, eye: '#3a0610', blush: 'rgba(255,196,206,0.55)' },
    milk: { core: [248, 230, 194], base: [234, 202, 148], edge: [204, 160, 100], line: [140, 98, 50], sat: [230, 168, 76],
      shade: [120, 80, 36], aC: 0.58, aE: 0.9, eye: '#3a2414', blush: 'rgba(240,128,108,0.42)', pearls: true }
  };
  function normColor(c) { return c === 'red' ? 'berry' : (COLORS[c] ? c : 'brown'); }
  function rgba(c, a) { return 'rgba(' + c[0] + ',' + c[1] + ',' + c[2] + ',' + Math.max(0, Math.min(1, a)).toFixed(3) + ')'; }
  function mixc(a, b, k) { return [Math.round(a[0] + (b[0] - a[0]) * k), Math.round(a[1] + (b[1] - a[1]) * k), Math.round(a[2] + (b[2] - a[2]) * k)]; }
  function clamp(x, a, b) { return x < a ? a : x > b ? b : x; }
  function sstep(a, b, x) { var t = clamp((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); }
  function ease(cur, target, dt, tau) { return cur + (target - cur) * (1 - Math.exp(-dt / Math.max(1e-4, tau))); }

  /* ---------- 背景：窗台場景 ---------- */
  function rr(g, x, y, w, h, r) {
    g.beginPath(); g.moveTo(x + r, y); g.lineTo(x + w - r, y); g.quadraticCurveTo(x + w, y, x + w, y + r);
    g.lineTo(x + w, y + h - r); g.quadraticCurveTo(x + w, y + h, x + w - r, y + h); g.lineTo(x + r, y + h);
    g.quadraticCurveTo(x, y + h, x, y + h - r); g.lineTo(x, y + r); g.quadraticCurveTo(x, y, x + r, y); g.closePath();
  }
  function cloud(g, x, y, s) {
    g.fillStyle = 'rgba(255,255,255,0.92)';
    var b = [[0, 0, 26], [24, -10, 22], [48, 0, 20], [22, 8, 22], [-20, 6, 16], [66, 8, 13]];
    g.beginPath();
    for (var i = 0; i < b.length; i++) { g.moveTo(x + b[i][0] * s + b[i][2] * s, y + b[i][1] * s); g.arc(x + b[i][0] * s, y + b[i][1] * s, b[i][2] * s, 0, Math.PI * 2); }
    g.fill();
    g.fillStyle = 'rgba(200,222,240,0.5)';
    g.beginPath(); g.ellipse(x + 24 * s, y + 18 * s, 50 * s, 7 * s, 0, 0, Math.PI * 2); g.fill();
  }
  function buildBg(dpr) {
    var c = document.createElement('canvas'); c.width = W * dpr; c.height = H * dpr;
    var g = c.getContext('2d'); g.scale(dpr, dpr);
    var wg = g.createLinearGradient(0, 0, 0, H); wg.addColorStop(0, '#f3ebe2'); wg.addColorStop(1, '#e7dacb');
    g.fillStyle = wg; g.fillRect(0, 0, W, H);
    var wx = 36, wy = 168, ww = 318, wh = 470;
    g.fillStyle = 'rgba(90,60,30,0.10)'; rr(g, wx - 18, wy - 14, ww + 36, wh + 34, 12); g.fill();
    g.fillStyle = '#a5744a'; rr(g, wx - 16, wy - 16, ww + 32, wh + 32, 10); g.fill();
    g.fillStyle = '#c29168'; rr(g, wx - 10, wy - 10, ww + 20, wh + 20, 6); g.fill();
    var sg = g.createLinearGradient(0, wy, 0, wy + wh);
    sg.addColorStop(0, '#79b6e6'); sg.addColorStop(0.55, '#b4d9f2'); sg.addColorStop(1, '#e2f0f7');
    g.fillStyle = sg; g.fillRect(wx, wy, ww, wh);
    g.save(); g.beginPath(); g.rect(wx, wy, ww, wh); g.clip();
    cloud(g, 70, 236, 1.0); cloud(g, 230, 300, 0.8); cloud(g, 150, 380, 0.6);
    g.fillStyle = '#cfe3c2';
    g.beginPath(); g.moveTo(wx, wy + wh - 150);
    g.bezierCurveTo(110, wy + wh - 210, 170, wy + wh - 120, 240, wy + wh - 170);
    g.bezierCurveTo(300, wy + wh - 210, 330, wy + wh - 150, wx + ww, wy + wh - 160);
    g.lineTo(wx + ww, wy + wh); g.lineTo(wx, wy + wh); g.closePath(); g.fill();
    g.fillStyle = '#b3d4a2';
    g.beginPath(); g.moveTo(wx, wy + wh - 80);
    g.bezierCurveTo(120, wy + wh - 130, 200, wy + wh - 60, 280, wy + wh - 100);
    g.bezierCurveTo(320, wy + wh - 120, 340, wy + wh - 95, wx + ww, wy + wh - 90);
    g.lineTo(wx + ww, wy + wh); g.lineTo(wx, wy + wh); g.closePath(); g.fill();
    var ig = g.createLinearGradient(0, wy, 0, wy + 26); ig.addColorStop(0, 'rgba(70,45,20,0.22)'); ig.addColorStop(1, 'rgba(70,45,20,0)');
    g.fillStyle = ig; g.fillRect(wx, wy, ww, 26);
    g.restore();
    g.fillStyle = '#c29168'; g.fillRect(wx + ww / 2 - 5, wy, 10, wh); g.fillRect(wx, wy + 196, ww, 9);
    g.fillStyle = 'rgba(255,240,220,0.35)'; g.fillRect(wx + ww / 2 - 5, wy, 2, wh);
    // 窗台
    g.fillStyle = 'rgba(70,40,15,0.16)'; g.fillRect(10, SILL + 36, W - 20, 12);
    g.fillStyle = '#b07f50'; rr(g, 4, SILL + 6, W - 8, 32, 4); g.fill();
    g.fillStyle = '#d6a979'; rr(g, 6, SILL - 12, W - 12, 22, 5); g.fill();
    g.strokeStyle = 'rgba(120,80,40,0.18)'; g.lineWidth = 1;
    for (var k = 0; k < 4; k++) { g.beginPath(); g.moveTo(16 + k * 7, SILL + 16 + k * 5); g.bezierCurveTo(140, SILL + 12 + k * 6, 250, SILL + 22 + k * 4, W - 14, SILL + 15 + k * 5); g.stroke(); }
    g.fillStyle = 'rgba(255,245,230,0.55)'; g.fillRect(10, SILL - 11, W - 20, 2);
    return c;
  }

  /* ---------- 每版的數字（取的值同步寫在 實作對照.md） ---------- */
  var MODES = {
    NOW: { push: false },
    A: { push: true },
    B: { push: true },
    C: { push: true },
    D: { push: true }
  };

  function mount(canvas, opts) {
    opts = opts || {};
    var pressMode = MODES[opts.press] ? opts.press : 'A';
    var pullMode = MODES[opts.pull] ? opts.pull : pressMode;
    var col = COLORS[normColor(opts.color)];
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr);
    var ctx = canvas.getContext('2d');
    var bg = buildBg(dpr);
    var LS = 560, lens = document.createElement('canvas'); lens.width = LS * dpr; lens.height = LS * dpr;
    var lc = lens.getContext('2d');

    /* 靜止形狀：有點不規則的圓團，底部稍平 */
    var cx0 = W / 2, ry0 = 92, bottomY = SILL + 1, cy0 = bottomY - ry0 * 0.86;
    var restX = [], restY = [];
    for (var i = 0; i < N; i++) {
      var th = i / N * Math.PI * 2 - Math.PI / 2;
      var r = 1 + 0.035 * Math.sin(2 * th + 0.7) + 0.025 * Math.sin(3 * th + 2.1) + 0.015 * Math.sin(5 * th + 0.3);
      var x = cx0 + Math.cos(th) * R * r * (1 + 0.06 * Math.max(0, Math.sin(th)));
      var y = cy0 + Math.sin(th) * ry0 * r;
      var f = bottomY - 12;
      if (y > f) y = f + 12 * Math.tanh((y - f) / 12);
      restX.push(x); restY.push(y);
    }
    var rcx = 0, rcy = 0, rminX = 1e9, rmaxX = -1e9, rminY = 1e9, rmaxY = -1e9;
    for (i = 0; i < N; i++) { rcx += restX[i]; rcy += restY[i]; rminX = Math.min(rminX, restX[i]); rmaxX = Math.max(rmaxX, restX[i]); rminY = Math.min(rminY, restY[i]); rmaxY = Math.max(rmaxY, restY[i]); }
    rcx /= N; rcy /= N;
    var restW = rmaxX - rminX, restH = rmaxY - rminY;
    var px = restX.slice(), py = restY.slice(), vx = new Array(N).fill(0), vy = new Array(N).fill(0);
    var tx = new Array(N).fill(0), ty = new Array(N).fill(0), wP = new Array(N).fill(0);
    var PEARLS = [[-44, 40, 9], [-8, 52, 10], [28, 46, 9], [56, 28, 8], [-66, 20, 8], [8, 26, 8], [-28, 18, 7]];

    /* 手勢狀態 */
    var ptr = null, down = null, cur = null, time = 0, last = 0, raf = 0, dead = false, paused = false;
    var physP = 0;  // 身體被撐開的量
    var pr = { on: false, x: 0, y: 0, cx: 0, cy: 0, vis: 0, v: 0, rel: 9, held: 0, ripples: [], rings: [], nextRip: 0, flashT: 9 };
    var pl = { on: false, iE: -1, dx: 0, dy: 0, rel: 9, ex: 0, ey: 0 };
    var blinkAt = 2.5, mosaicT = 0, mosaic = [];

    function toLocal(e) {
      var b = canvas.getBoundingClientRect();
      return { x: (e.clientX - b.left) * W / b.width, y: (e.clientY - b.top) * H / b.height };
    }
    function inside(p) {
      var c = false;
      for (var i = 0, j = N - 1; i < N; j = i++) {
        if ((py[i] > p.y) !== (py[j] > p.y) && p.x < (px[j] - px[i]) * (p.y - py[i]) / (py[j] - py[i]) + px[i]) c = !c;
      }
      if (c) return true;
      for (i = 0; i < N; i++) if (Math.hypot(px[i] - p.x, py[i] - p.y) < 14) return true;
      return false;
    }
    function centroid() { var x = 0, y = 0; for (var i = 0; i < N; i++) { x += px[i]; y += py[i]; } return { x: x / N, y: y / N }; }

    function begin(p) {
      down = p; cur = p;
      var c = centroid();
      pr.on = true; pr.x = p.x; pr.y = p.y; pr.cx = c.x; pr.cy = c.y; pr.held = 0; pr.rel = 0; pr.v = 0; pr.flashT = 9;
      if (pressMode === 'C') { pr.ripples.push({ t: 0, a: 0.5 }); pr.nextRip = 1.2; }
    }
    function startPull() {
      var ux = cur.x - down.x, uy = cur.y - down.y, l = Math.hypot(ux, uy) || 1; ux /= l; uy /= l;
      var best = 1e9, iE = 0;
      for (var i = 0; i < N; i++) {
        var dx = px[i] - down.x, dy = py[i] - down.y;
        var s = Math.hypot(dx, dy) - 0.8 * (dx * ux + dy * uy);
        if (s < best) { best = s; iE = i; }
      }
      for (i = 0; i < N; i++) { var d = Math.hypot(restX[i] - restX[iE], restY[i] - restY[iE]); wP[i] = Math.exp(-Math.pow(d / 66, 3)); }
      releasePress();
      pl.on = true; pl.iE = iE; pl.rel = 0;
    }
    function releasePress() {
      if (!pr.on) return;
      pr.on = false; pr.rel = 0; pr.flashT = 0;
      if (pressMode === 'B' && pr.vis > 0.15) pr.rings.push({ t: 0, a: pr.vis });
    }
    function end() {
      if (pl.on) { pl.on = false; pl.rel = 0; }
      releasePress();
      down = null; cur = null;
    }

    function onDown(e) {
      if (ptr !== null) return;
      var p = toLocal(e);
      if (!inside(p)) return;
      ptr = e.pointerId;
      try { canvas.setPointerCapture(ptr); } catch (err) { /* 合成事件沒有真的指標 */ }
      e.preventDefault();
      begin(p);
    }
    function onMove(e) {
      if (e.pointerId !== ptr) return;
      cur = toLocal(e);
      if (!pl.on && pr.on && Math.hypot(cur.x - down.x, cur.y - down.y) > 8) startPull();
    }
    function onUp(e) { if (e.pointerId !== ptr) return; ptr = null; end(); }
    canvas.addEventListener('pointerdown', onDown);
    canvas.addEventListener('pointermove', onMove);
    canvas.addEventListener('pointerup', onUp);
    canvas.addEventListener('pointercancel', onUp);
    canvas.style.touchAction = 'none';

    /* ---------- 物理 ---------- */
    function update(dt) {
      time += dt;
      // 按壓的視覺深度：每版時間不同
      if (pr.on) {
        pr.held += dt;
        physP = ease(physP, 1, dt, 0.06);
        if (pressMode === 'NOW') pr.vis = Math.min(1, pr.vis + dt / 0.08);
        else if (pressMode === 'A') pr.vis = ease(pr.vis, 1, dt, 0.028);        // 80ms 沉到九成五
        else if (pressMode === 'B') pr.vis = ease(pr.vis, 1, dt, 0.06);
        else if (pressMode === 'C') pr.vis = ease(pr.vis, 1, dt, 0.04);
        else pr.vis = ease(pr.vis, 1, dt, 0.05);
        if (pressMode === 'C') { pr.nextRip -= dt; if (pr.nextRip <= 0) { pr.ripples.push({ t: 0, a: 0.26 }); pr.nextRip = 1.2; } }
      } else {
        pr.rel += dt; pr.flashT += dt;
        physP = ease(physP, 0, dt, 0.05);
        if (pressMode === 'NOW') pr.vis = Math.max(0, pr.vis - dt / 1.5);
        else if (pressMode === 'A') {   // 0.35 秒彈回，過頭一點
          var w = 19, z = 0.5, sub = 4, h = dt / sub;
          for (var k = 0; k < sub; k++) { pr.v += (-w * w * pr.vis - 2 * z * w * pr.v) * h; pr.vis += pr.v * h; }
          if (Math.abs(pr.vis) < 0.002 && Math.abs(pr.v) < 0.02) { pr.vis = 0; pr.v = 0; }
        } else if (pressMode === 'B') pr.vis = ease(pr.vis, 0, dt, 0.09);
        else if (pressMode === 'C') pr.vis = ease(pr.vis, 0, dt, 0.025);
        else pr.vis = ease(pr.vis, 0, dt, 0.1);
      }
      for (k = pr.ripples.length - 1; k >= 0; k--) { pr.ripples[k].t += dt; if (pr.ripples[k].t > 0.5) pr.ripples.splice(k, 1); }
      for (k = pr.rings.length - 1; k >= 0; k--) { pr.rings[k].t += dt; if (pr.rings[k].t > 0.5) pr.rings.splice(k, 1); }
      if (!pl.on) pl.rel += dt;

      // 拉扯位移（軟上限 2.3R）
      var Dx = 0, Dy = 0;
      if (pl.on && cur) {
        var dx = cur.x - down.x, dy = cur.y - down.y, l = Math.hypot(dx, dy);
        if (l > 1e-3) { var m = 2.3 * R, le = m * Math.tanh(l / m); Dx = dx / l * le; Dy = dy / l * le; }
      }
      pl.dx = Dx; pl.dy = Dy;

      // 目標形狀
      var P = physP, br = Math.sin(time * 1.9) * 0.012;
      var sx = (1 + 0.07 * P) * (1 - br * 0.5), sy = (1 - 0.05 * P) * (1 + br);
      var c = centroid(), shiftX = c.x - pr.cx, shiftY = c.y - pr.cy;
      for (var i = 0; i < N; i++) {
        var X = cx0 + (restX[i] - cx0) * sx, Y = bottomY + (restY[i] - bottomY) * sy;
        if (P > 0.001) {
          var qx = restX[i] - pr.x, qy = restY[i] - pr.y, d = Math.hypot(qx, qy) || 1;
          var push = 9 * P * Math.exp(-(d / 120) * (d / 120));
          X += qx / d * push; Y += qy / d * push * 0.6;
        }
        if (pl.on) { var wt = 0.08 + 0.9 * wP[i]; X += Dx * wt; Y += Dy * wt; }
        tx[i] = X; ty[i] = Y;
      }
      // 彈簧＋阻尼＋鄰點平滑（Q 彈，放手晃兩下）
      var K = 190, Cd = 9, KS = 110, steps = Math.max(1, Math.ceil(dt / (1 / 240))), hh = dt / steps;
      for (var s = 0; s < steps; s++) {
        for (i = 0; i < N; i++) {
          var a = (i + N - 1) % N, b = (i + 1) % N;
          var lpx = (px[a] + px[b]) * 0.5 - px[i] - ((tx[a] + tx[b]) * 0.5 - tx[i]);
          var lpy = (py[a] + py[b]) * 0.5 - py[i] - ((ty[a] + ty[b]) * 0.5 - ty[i]);
          vx[i] += (K * (tx[i] - px[i]) - Cd * vx[i] + KS * lpx) * hh;
          vy[i] += (K * (ty[i] - py[i]) - Cd * vy[i] + KS * lpy) * hh;
        }
        for (i = 0; i < N; i++) {
          px[i] += vx[i] * hh; py[i] += vy[i] * hh;
          if (py[i] > bottomY + 1) { py[i] = bottomY + 1; if (vy[i] > 0) vy[i] = 0; vx[i] *= 0.96; }
        }
      }
      void shiftX; void shiftY;
    }

    /* ---------- 畫 ---------- */
    function bodyPath() {
      var p = new Path2D();
      var mx = (px[N - 1] + px[0]) / 2, my = (py[N - 1] + py[0]) / 2;
      p.moveTo(mx, my);
      for (var i = 0; i < N; i++) {
        var j = (i + 1) % N;
        p.quadraticCurveTo(px[i], py[i], (px[i] + px[j]) / 2, (py[i] + py[j]) / 2);
      }
      p.closePath();
      return p;
    }
    var LENS_MAG = 1.07;
    // 把身體底下（放大過的）背景，用柔邊橢圓遮罩透出來；ox oy 是取樣錯開（現況重影用）
    function reveal(cx, cy, rx, ry, ang, alpha, C, ox, oy) {
      if (alpha <= 0.004) return;
      rx = Math.min(rx, LS / 2 - 6); ry = Math.min(ry, LS / 2 - 6);
      var S = Math.ceil(2 * Math.max(rx, ry) + 8), x0 = cx - S / 2, y0 = cy - S / 2;
      lc.setTransform(dpr, 0, 0, dpr, 0, 0);
      lc.globalCompositeOperation = 'source-over';
      lc.clearRect(0, 0, S, S);
      lc.save();
      lc.translate(-x0 + (ox || 0), -y0 + (oy || 0));
      lc.translate(C.x, C.y); lc.scale(LENS_MAG, LENS_MAG); lc.translate(-C.x, -C.y);
      lc.drawImage(bg, 0, 0, W, H);
      lc.restore();
      lc.globalCompositeOperation = 'destination-in';
      lc.save();
      lc.translate(cx - x0, cy - y0); lc.rotate(ang); lc.scale(1, ry / rx);
      var g = lc.createRadialGradient(0, 0, 0, 0, 0, rx);
      g.addColorStop(0, 'rgba(0,0,0,1)'); g.addColorStop(0.5, 'rgba(0,0,0,0.85)'); g.addColorStop(1, 'rgba(0,0,0,0)');
      lc.fillStyle = g; lc.fillRect(-rx, -rx, 2 * rx, 2 * rx);
      lc.restore();
      lc.globalCompositeOperation = 'source-over';
      ctx.globalAlpha = alpha;
      ctx.drawImage(lens, 0, 0, S * dpr, S * dpr, x0, y0, S, S);
      ctx.globalAlpha = 1;
    }
    function softEllipse(cx, cy, rx, ry, ang, stops) {
      ctx.save(); ctx.translate(cx, cy); ctx.rotate(ang); ctx.scale(1, ry / rx);
      var g = ctx.createRadialGradient(0, 0, 0, 0, 0, rx);
      for (var i = 0; i < stops.length; i++) g.addColorStop(stops[i][0], stops[i][1]);
      ctx.fillStyle = g; ctx.fillRect(-rx, -rx, 2 * rx, 2 * rx); ctx.restore();
    }
    function fadeLine(x1, y1, x2, y2, cxp, cyp, color, a, width) {
      if (a <= 0.004) return;
      var g = ctx.createLinearGradient(x1, y1, x2, y2);
      g.addColorStop(0, rgba(color, 0)); g.addColorStop(0.22, rgba(color, a)); g.addColorStop(0.75, rgba(color, a)); g.addColorStop(1, rgba(color, 0));
      ctx.strokeStyle = g; ctx.lineWidth = width; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(x1, y1); ctx.quadraticCurveTo(cxp, cyp, x2, y2); ctx.stroke();
    }
    function arcFade(cx, cy, r, a0, a1, color, alpha, width) {
      var seg = 16, da = (a1 - a0) / seg;
      ctx.lineWidth = width; ctx.lineCap = 'round';
      for (var i = 0; i < seg; i++) {
        var f = Math.sin(Math.PI * (i + 0.5) / seg);
        ctx.strokeStyle = rgba(color, alpha * f);
        ctx.beginPath(); ctx.arc(cx, cy, r, a0 + da * i, a0 + da * (i + 1.05)); ctx.stroke();
      }
    }
    var WHITE = [255, 255, 255];

    // 拉長那段的幾何：從身體裡到被拉出去的尖端
    function neck(C) {
      if (pl.iE < 0) return null;
      var i = pl.iE, Tx = px[i], Ty = py[i];
      var Bx = rcx + (restX[i] - rcx) * 0.45 + (C.x - rcx) * 0.5, By = rcy + (restY[i] - rcy) * 0.45 + (C.y - rcy) * 0.5;
      var dx = Tx - Bx, dy = Ty - By, L = Math.hypot(dx, dy) || 1;
      var disp = Math.hypot(px[i] - restX[i], py[i] - restY[i]);
      var s = clamp(disp / (1.3 * R), 0, 1);
      var ux = dx / L, uy = dy / L, nx = -uy, ny = ux;
      if (nx * LIGHT[0] + ny * LIGHT[1] < 0) { nx = -nx; ny = -ny; }   // 法向朝光那一側
      return { Bx: Bx, By: By, Tx: Tx, Ty: Ty, L: L, ux: ux, uy: uy, nx: nx, ny: ny, s: s, ang: Math.atan2(dy, dx),
        dispX: px[i] - restX[i], dispY: py[i] - restY[i] };
    }
    function pullFade(mode) {
      if (pl.on) return 1;
      var t = pl.rel;
      if (mode === 'A' || mode === 'B') return Math.exp(-t / 0.13);   // 0.4 秒恢復
      if (mode === 'C') return Math.max(0, 1 - t / 0.5);              // 0.5 秒淡掉
      if (mode === 'NOW') return 1;                                   // 跟著形狀退
      return 0;
    }

    function drawPressMarks(C) {
      var v = pr.vis, m = pressMode;
      var ox = C.x - pr.cx, oy = C.y - pr.cy, X = pr.x + ox, Y = pr.y + oy;
      if (m === 'NOW') {
        if (v <= 0.01) return;
        var r0 = 66 * (0.6 + 0.4 * v), dk = col.line;
        var ring = [[0, rgba(dk, 0.28 * v)], [0.42, rgba(dk, 0.08 * v)], [0.62, rgba(dk, 0.55 * v)], [0.8, rgba(dk, 0.38 * v)], [1, rgba(dk, 0)]];
        reveal(X + 4, Y + 4, r0 * 0.7, r0 * 0.7, 0, 0.5 * v, C, -20, -14);   // 折射錯開的重影
        softEllipse(X, Y, r0, r0, 0, ring);
        var ring2 = ring.map(function (s) { return [s[0], s[1].replace(/,([0-9.]+)\)$/, function (_, a) { return ',' + (parseFloat(a) * 0.5).toFixed(3) + ')'; })]; });
        softEllipse(X + 17, Y + 11, r0 * 0.9, r0 * 0.9, 0, ring2);
        arcFade(X + 3, Y + 3, r0 * 0.74, -0.4, 2.0, WHITE, 0.6 * v, 3.5);
        ctx.fillStyle = rgba(WHITE, 0.55 * v); ctx.beginPath(); ctx.ellipse(X + r0 * 0.42, Y + r0 * 0.5, 5, 3, 0.6, 0, Math.PI * 2); ctx.fill();
        return;
      }
      if (m === 'A') {
        var r = 82, pv = Math.max(0, v);
        if (pv > 0.01) softEllipse(X - r * 0.22, Y - r * 0.24, r * 0.85, r * 0.8, 0, [[0, rgba(col.shade, 0.075 * pv)], [0.6, rgba(col.shade, 0.04 * pv)], [1, rgba(col.shade, 0)]]);
        var fl = Math.exp(-Math.pow((pr.flashT - 0.13) / 0.07, 2));   // 彈回時亮邊閃一下
        var ra = 0.5 * pv + 0.5 * fl;
        if (ra > 0.01) {
          var rA = r * 0.6 * (1 + 0.08 * fl);
          arcFade(X + 3, Y + 3, rA - 5, -0.35, 1.95, WHITE, ra * 0.16, 12);
          arcFade(X + 3, Y + 3, rA, -0.35, 1.95, WHITE, ra, 1.8);
        }
        return;
      }
      if (m === 'B') {
        var rb = 58;
        if (v > 0.01) {
          reveal(X, Y, rb * 0.95, rb * 0.95, 0, 0.6 * v, C, 0, 0);
          softEllipse(X, Y, rb, rb, 0, [[0, rgba(col.core, 0.22 * v)], [0.6, rgba(col.core, 0.1 * v)], [1, rgba(col.core, 0)]]);
          softEllipse(X, Y, rb, rb, 0, [[0, rgba(WHITE, 0.14 * v)], [0.6, rgba(WHITE, 0.06 * v)], [1, rgba(WHITE, 0)]]);
          softEllipse(X, Y, rb * 1.45, rb * 1.45, 0, [[0.5, rgba(col.sat, 0)], [0.7, rgba(col.sat, 0.32 * v)], [0.86, rgba(col.sat, 0.14 * v)], [1, rgba(col.sat, 0)]]);
        }
        for (var k = 0; k < pr.rings.length; k++) {   // 放手：那一圈往外漾
          var q = pr.rings[k], t = q.t / 0.5, rr2 = rb * 1.45 * (1 + 0.75 * (1 - Math.pow(1 - t, 2))), a = 0.3 * q.a * Math.pow(1 - t, 1.4);
          softEllipse(X, Y, rr2, rr2, 0, [[0.62, rgba(col.sat, 0)], [0.8, rgba(col.sat, a)], [0.9, rgba(WHITE, a * 0.35)], [1, rgba(col.sat, 0)]]);
        }
        return;
      }
      if (m === 'C') {
        var rc = 60;
        if (v > 0.01) softEllipse(X - 10, Y - 10, rc, rc, 0, [[0, rgba(col.shade, 0.045 * v)], [1, rgba(col.shade, 0)]]);
        for (k = 0; k < pr.ripples.length; k++) {
          var p2 = pr.ripples[k], tt = p2.t / 0.5, rad = rc * (0.25 + 1.25 * (1 - Math.pow(1 - tt, 2.2))), al = p2.a * Math.pow(1 - tt, 1.6);
          ctx.lineWidth = 7; ctx.strokeStyle = rgba(WHITE, al * 0.22);
          ctx.beginPath(); ctx.ellipse(X, Y, rad, rad * 0.9, 0, 0, Math.PI * 2); ctx.stroke();
          ctx.lineWidth = 2.2 * (1 - 0.5 * tt); ctx.strokeStyle = rgba(WHITE, al);
          ctx.beginPath(); ctx.ellipse(X, Y, rad, rad * 0.9, 0, 0, Math.PI * 2); ctx.stroke();
        }
      }
    }

    function drawPullMarks(C, nk) {
      if (!nk) return;
      var m = pullMode, k = nk.s * pullFade(m);
      if (k < 0.01) return;
      var mx = nk.Bx + (nk.Tx - nk.Bx) * 0.55, my = nk.By + (nk.Ty - nk.By) * 0.55;
      if (m === 'NOW') {
        var dk = col.line;
        reveal(mx, my, nk.L * 0.5 + 20, 34, nk.ang, 0.45 * k, C, 14, 9);
        softEllipse(mx, my, nk.L * 0.45 + 24, 19, nk.ang, [[0, rgba(dk, 0.62 * k)], [0.7, rgba(dk, 0.45 * k)], [1, rgba(dk, 0)]]);
        var offs = [-0.22 * R, 0.16 * R];
        for (var j = 0; j < offs.length; j++) {
          var o = offs[j];
          ctx.strokeStyle = rgba(dk, 0.38 * k); ctx.lineWidth = 6; ctx.lineCap = 'butt';
          ctx.beginPath(); ctx.moveTo(nk.Bx + nk.nx * o, nk.By + nk.ny * o); ctx.lineTo(nk.Tx - nk.ux * 22 + nk.nx * o * 0.5, nk.Ty - nk.uy * 22 + nk.ny * o * 0.5); ctx.stroke();
          ctx.strokeStyle = rgba(dk, 0.2 * k); ctx.lineWidth = 3;
          ctx.beginPath(); ctx.moveTo(nk.Bx + nk.nx * o + 7, nk.By + nk.ny * o + 5); ctx.lineTo(nk.Tx - nk.ux * 22 + nk.nx * o * 0.5 + 7, nk.Ty - nk.uy * 22 + nk.ny * o * 0.5 + 5); ctx.stroke();
        }
        // 馬賽克色塊
        if (time - mosaicT > 0.12) {
          mosaicT = time; mosaic = [];
          for (j = 0; j < 4; j++) mosaic.push([Math.random(), (Math.random() - 0.5) * 0.5 * R, Math.random() < 0.5]);
        }
        for (j = 0; j < mosaic.length; j++) {
          var t = 0.2 + 0.7 * mosaic[j][0], qx = nk.Bx + (nk.Tx - nk.Bx) * t + nk.nx * mosaic[j][1], qy = nk.By + (nk.Ty - nk.By) * t + nk.ny * mosaic[j][1];
          ctx.fillStyle = mosaic[j][2] ? rgba(dk, 0.4 * k) : 'rgba(170,210,240,' + (0.45 * k).toFixed(3) + ')';
          ctx.fillRect(Math.round(qx / 6) * 6, Math.round(qy / 6) * 6, 6, 6);
        }
        return;
      }
      if (m === 'A') {
        reveal(mx, my, nk.L * 0.55 + 10, R * 0.42 * (1 - 0.35 * nk.s), nk.ang, 0.55 * k, C, 0, 0);
        softEllipse(mx, my, nk.L * 0.55 + 10, R * 0.38, nk.ang, [[0, rgba(col.core, 0.10 * k)], [1, rgba(col.core, 0)]]);
        var off = R * 0.13 * (1 - 0.4 * nk.s);
        var x1 = nk.Bx + nk.ux * nk.L * 0.1 + nk.nx * off, y1 = nk.By + nk.uy * nk.L * 0.1 + nk.ny * off;
        var x2 = nk.Tx - nk.ux * R * 0.22 + nk.nx * off * 0.6, y2 = nk.Ty - nk.uy * R * 0.22 + nk.ny * off * 0.6;
        var cxp = (x1 + x2) / 2 + nk.nx * 5, cyp = (y1 + y2) / 2 + nk.ny * 5;
        fadeLine(x1, y1, x2, y2, cxp, cyp, WHITE, 0.16 * k, 9);
        fadeLine(x1, y1, x2, y2, cxp, cyp, WHITE, 0.78 * k, 2.4);
        return;
      }
      if (m === 'B') {
        reveal(mx, my, nk.L * 0.55 + 10, R * 0.3 * (1 - 0.3 * nk.s), nk.ang, 0.72 * k, C, 0, 0);
        softEllipse(mx, my, nk.L * 0.5 + 10, R * 0.2, nk.ang, [[0, rgba(WHITE, 0.16 * k)], [1, rgba(WHITE, 0)]]);
        return;
      }
      if (m === 'C') {
        var lines = [[-0.2 * R, 0.2], [0.02 * R, 0.3], [0.2 * R, 0.17]];
        for (var q = 0; q < lines.length; q++) {
          var o2 = lines[q][0] * (1 - 0.35 * nk.s), a = lines[q][1] * k;
          var ax = nk.Bx + nk.ux * nk.L * 0.08 + nk.nx * o2, ay = nk.By + nk.uy * nk.L * 0.08 + nk.ny * o2;
          var bx = nk.Tx - nk.ux * R * 0.28 + nk.nx * o2 * 0.45, by = nk.Ty - nk.uy * R * 0.28 + nk.ny * o2 * 0.45;
          var ccx = (ax + bx) / 2 + nk.nx * o2 * 0.25, ccy = (ay + by) / 2 + nk.ny * o2 * 0.25;
          fadeLine(ax, ay, bx, by, ccx, ccy, WHITE, a * 0.25, 6);
          fadeLine(ax, ay, bx, by, ccx, ccy, WHITE, a, 1.6);
        }
      }
    }

    function draw() {
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over';
      ctx.drawImage(bg, 0, 0, W, H);
      var C = centroid();
      var minX = 1e9, maxX = -1e9, minY = 1e9, maxY = -1e9;
      for (var i = 0; i < N; i++) { minX = Math.min(minX, px[i]); maxX = Math.max(maxX, px[i]); minY = Math.min(minY, py[i]); maxY = Math.max(maxY, py[i]); }
      var bw = clamp((maxX - minX) / restW, 0.85, 1.2), bh = clamp((maxY - minY) / restH, 0.85, 1.2);
      var path = bodyPath(), nk = neck(C);
      var pk = nk ? nk.s * pullFade(pullMode) : 0;

      // 窗台上的接觸影
      softEllipse(C.x, bottomY + 2, (maxX - minX) * 0.48, 7, 0, [[0, 'rgba(70,40,15,0.22)'], [1, 'rgba(70,40,15,0)']]);

      ctx.save();
      ctx.clip(path);
      // 透過身體看到的背景（放大一點，像透鏡）
      ctx.save(); ctx.translate(C.x, C.y); ctx.scale(LENS_MAG, LENS_MAG); ctx.translate(-C.x, -C.y);
      ctx.drawImage(bg, 0, 0, W, H); ctx.restore();
      // 果凍本體：中間淺、邊緣深
      var gr = Math.max(maxX - minX, maxY - minY) * 0.56;
      var g = ctx.createRadialGradient(C.x - 14, C.y - 16, 0, C.x, C.y, gr);
      g.addColorStop(0, rgba(col.core, col.aC)); g.addColorStop(0.65, rgba(col.base, (col.aC + col.aE) / 2)); g.addColorStop(1, rgba(col.edge, col.aE));
      ctx.fillStyle = g; ctx.fill(path);
      // 奶茶的珍珠
      if (col.pearls) {
        var sxp = 1 + 0.07 * physP, syp = 1 - 0.05 * physP;
        for (i = 0; i < PEARLS.length; i++) {
          var lx = PEARLS[i][0], ly = PEARLS[i][1], qx = rcx + lx * sxp + (C.x - rcx) * 0.6, qy = bottomY + (rcy + ly - bottomY) * syp + (C.y - rcy) * 0.6;
          if (nk) { var dd = Math.hypot(rcx + lx - restX[pl.iE], rcy + ly - restY[pl.iE]), ww = Math.exp(-(dd / 75) * (dd / 75)) * 0.7; qx += nk.dispX * ww; qy += nk.dispY * ww; }
          ctx.fillStyle = 'rgba(52,30,18,0.82)'; ctx.beginPath(); ctx.arc(qx, qy, PEARLS[i][2], 0, Math.PI * 2); ctx.fill();
          ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.beginPath(); ctx.arc(qx - PEARLS[i][2] * 0.35, qy - PEARLS[i][2] * 0.4, PEARLS[i][2] * 0.28, 0, Math.PI * 2); ctx.fill();
        }
        ctx.fillStyle = rgba(col.base, 0.22); ctx.fill(path);
      }
      // 邊緣變深（往內三層）；B 版拉扯時邊緣偏濃一點
      var rimC = pullMode === 'B' ? mixc(col.edge, col.sat, 0.55 * pk) : col.edge;
      ctx.lineJoin = 'round';
      var rw = [32, 19, 9], ra = [0.16, 0.2, 0.24];
      for (i = 0; i < 3; i++) { ctx.strokeStyle = rgba(rimC, ra[i] * (pullMode === 'B' ? 1 + 0.5 * pk : 1)); ctx.lineWidth = rw[i]; ctx.stroke(path); }
      var bs = ctx.createLinearGradient(0, C.y, 0, maxY);
      bs.addColorStop(0, rgba(col.shade, 0)); bs.addColorStop(1, rgba(col.shade, 0.22));
      ctx.fillStyle = bs; ctx.fill(path);

      // 底子：被拉長的那段本來就比較薄、比較透（app 的 thick 也是這樣），五版都有
      if (nk && nk.s > 0.01) reveal(nk.Bx + (nk.Tx - nk.Bx) * 0.6, nk.By + (nk.Ty - nk.By) * 0.6, nk.L * 0.5 + 10, R * 0.4, nk.ang, 0.22 * nk.s, C, 0, 0);
      // 痕跡
      drawPullMarks(C, nk);
      drawPressMarks(C);

      // 左上亮光：被手指推開、跟著拉長
      var hx = C.x + (-0.42 * R) * bw, hy = C.y + (-0.5 * ry0) * bh;
      var stretch = 1, sAng = 0, sqz = 1, pAng = 0;
      if (nk) {
        var dh = Math.hypot(rcx - 0.42 * R - restX[pl.iE], rcy - 0.5 * ry0 - restY[pl.iE]);
        var wh = Math.exp(-(dh / 95) * (dh / 95));
        hx += nk.dispX * wh * 0.6; hy += nk.dispY * wh * 0.6;
        stretch = 1 + nk.s * (0.25 + 1.4 * wh); sAng = nk.ang;
      }
      if (MODES[pressMode].push && physP > 0.01) {
        var Xp = pr.x + C.x - pr.cx, Yp = pr.y + C.y - pr.cy, qx2 = hx - Xp, qy2 = hy - Yp, d2 = Math.hypot(qx2, qy2) || 1;
        var fall = Math.exp(-(d2 / 95) * (d2 / 95)), pv = physP * fall;
        hx += qx2 / d2 * 22 * pv; hy += qy2 / d2 * 22 * pv; sqz = 1 - 0.28 * pv; pAng = Math.atan2(qy2, qx2);
      }
      ctx.save();
      ctx.translate(hx, hy);
      ctx.rotate(sAng); ctx.scale(stretch, 1 / Math.sqrt(stretch)); ctx.rotate(-sAng);
      ctx.rotate(pAng); ctx.scale(sqz, 1 / Math.sqrt(sqz)); ctx.rotate(-pAng);
      ctx.rotate(-0.6); ctx.scale(1, 13 / 24);
      var hg = ctx.createRadialGradient(0, 0, 0, 0, 0, 24);
      hg.addColorStop(0, 'rgba(255,255,255,0.88)'); hg.addColorStop(0.55, 'rgba(255,255,255,0.55)'); hg.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = hg; ctx.fillRect(-24, -24, 48, 48);
      ctx.restore();
      ctx.fillStyle = 'rgba(255,255,255,0.85)'; ctx.beginPath(); ctx.arc(hx + 22, hy - 12, 4.2, 0, Math.PI * 2); ctx.fill();

      // 沿輪廓朝光那段的細亮弧
      ctx.lineCap = 'round'; ctx.lineWidth = 2;
      for (i = 0; i < N; i++) {
        var j = (i + 1) % N, ex = px[j] - px[i], ey = py[j] - py[i], el = Math.hypot(ex, ey) || 1;
        var nx = ey / el, ny = -ex / el, face = nx * LIGHT[0] + ny * LIGHT[1], a = sstep(0.55, 0.95, face) * 0.7;
        if (a < 0.02) continue;
        ctx.strokeStyle = rgba(WHITE, a);
        ctx.beginPath(); ctx.moveTo(px[i] - nx * 4, py[i] - ny * 4); ctx.lineTo(px[j] - nx * 4, py[j] - ny * 4); ctx.stroke();
      }
      ctx.restore();

      // 細描邊
      ctx.strokeStyle = rgba(col.line, 0.55); ctx.lineWidth = 1.8; ctx.stroke(path);

      // 眼睛與腮紅：跟身體中心與整體形變走，不被拉開
      var ecx = rcx + (C.x - rcx) * 0.35, sy = 1 - 0.05 * physP;
      var ecy = bottomY + (cy0 - 0.12 * ry0 - bottomY) * sy + (C.y - rcy) * 0.35;
      if (nk) { ecx += nk.dispX * 0.1; ecy += nk.dispY * 0.1; }
      var sp = 30 * clamp(bw, 0.92, 1.12);
      if (time > blinkAt + 0.14) blinkAt = time + 2.5 + Math.random() * 3;
      var blink = time > blinkAt ? 0.12 : 1;
      ctx.fillStyle = col.blush;
      ctx.beginPath(); ctx.ellipse(ecx - sp - 17, ecy + 14, 13, 7, 0, 0, Math.PI * 2); ctx.fill();
      ctx.beginPath(); ctx.ellipse(ecx + sp + 17, ecy + 14, 13, 7, 0, 0, Math.PI * 2); ctx.fill();
      for (var e = -1; e <= 1; e += 2) {
        ctx.fillStyle = col.eye;
        ctx.beginPath(); ctx.ellipse(ecx + e * sp, ecy, 6.5, 8.5 * blink, 0, 0, Math.PI * 2); ctx.fill();
        if (blink > 0.5) { ctx.fillStyle = 'rgba(255,255,255,0.9)'; ctx.beginPath(); ctx.arc(ecx + e * sp - 2, ecy - 3.2, 2, 0, Math.PI * 2); ctx.fill(); }
      }
    }

    function frame(ts) {
      if (dead) return;
      raf = requestAnimationFrame(frame);
      var t = ts / 1000, dt = last ? Math.min(1 / 30, Math.max(0, t - last)) : 1 / 60;
      last = t;
      if (paused) return;
      update(dt); draw();
    }
    raf = requestAnimationFrame(frame);

    return {
      setColor: function (c) { col = COLORS[normColor(c)]; },
      destroy: function () {
        dead = true; cancelAnimationFrame(raf);
        canvas.removeEventListener('pointerdown', onDown);
        canvas.removeEventListener('pointermove', onMove);
        canvas.removeEventListener('pointerup', onUp);
        canvas.removeEventListener('pointercancel', onUp);
      },
      _pause: function (b) { paused = !!b; },
      _step: function (sec) { var n = Math.round(sec * 60); for (var k = 0; k < n; k++) update(1 / 60); draw(); },
      _state: function () { return { pl: pl, pr: { on: pr.on, vis: pr.vis }, physP: physP, ptr: ptr, tip: pl.iE >= 0 ? [px[pl.iE], py[pl.iE]] : null }; },
      // 測試用：不經過真的指標，直接餵手勢（座標是 390×844 的畫面座標）
      _sim: function (type, x, y) {
        var p = { x: x, y: y };
        if (type === 'down') { if (inside(p)) { ptr = 'sim'; begin(p); return true; } return false; }
        if (type === 'move' && ptr === 'sim') { cur = p; if (!pl.on && pr.on && Math.hypot(cur.x - down.x, cur.y - down.y) > 8) startPull(); return true; }
        if (type === 'up' && ptr === 'sim') { ptr = null; end(); return true; }
        return false;
      }
    };
  }

  window.JellyDemo = { mount: mount };
})();
