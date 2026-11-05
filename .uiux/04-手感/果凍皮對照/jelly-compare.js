/* 果凍皮靜態對照圖產生器（2026-11-06）
   在 prototype/web/index.html 的頁面裡載入：外框是引擎真的算出來的，不是手畫的。
   做法：外框畫成遮罩 → 模糊兩種半徑（半解析度、四分之一解析度）→ 當高度算法線 → 打光。
   這支只出圖，不改 index.html 的物理與畫面。 */
(() => {
const BASE = window.__JELLY_BASE;
const ev = (type, id, x, y) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 }));
const steps = n => { for (let i = 0; i < n; i++) update(1 / 60); };

/* ---------- 1. 用引擎產生外框 ---------- */
function base(over) {
  mat = { ...PRESETS.clay, seed: 12, emo: 0, life2: 0, intro: 0, drops: 0, dropsV: 0, e1: 0, e2: 0, e3: 0, e4: 0, imp: 0, sleep: 0, echo: 0, introSwim: 0, moodColor: 0, ...over };
  setup(); WANDER.moving = false; WANDER.next = t + 9999; steps(60);
}
function snapshot(name) {
  const P = boundaryPts().map(p => [p[0], p[1]]);
  const out = { name, P, R, eyes: null, dents: [] };
  if (EYE.L.length) out.eyes = [eyeAt(EYE.L), eyeAt(EYE.R)];
  for (const d of DENTS) { const r = R * mat.dentSize * d.d; if (r > .5) out.dents.push([X[d.i], Y[d.i], r, Math.min(1, d.d)]); }
  let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
  for (const p of P) { x0 = Math.min(x0, p[0]); x1 = Math.max(x1, p[0]); y0 = Math.min(y0, p[1]); y1 = Math.max(y1, p[1]); }
  out.box = [x0, y0, x1, y1];
  return out;
}
function glide(fs, n) { for (let k = 1; k <= n; k++) { for (const f of fs) ev('pointermove', f[0], f[1] + (f[3] - f[1]) * k / n, f[2] + (f[4] - f[2]) * k / n); steps(1); } }
function capture() {
  window.requestAnimationFrame = () => 0;
  sfxPlay = () => {};
  const poses = {};
  const blob = { ...OFF27, eyes: 1 };
  base(blob); poses.rest = snapshot('休息');
  { const cx = globalC.xc, cy = globalC.yc;
    ev('pointerdown', 1, cx + R * .45, cy + R * .5); steps(4);
    glide([[1, cx + R * .45, cy + R * .5, W - 24, cy + R * 2.9]], 60); steps(20);
    poses.pull = snapshot('拉長'); ev('pointercancel', 1, 0, 0); }
  base(blob);
  { const cx = globalC.xc, cy = globalC.yc;
    ev('pointerdown', 1, cx + R * .12, cy + R * .15); steps(70);
    poses.press = snapshot('按住'); ev('pointercancel', 1, 0, 0); }
  base(blob);
  { const cx = globalC.xc, cy = globalC.yc;
    ev('pointerdown', 1, cx - R * .5, cy); steps(1); ev('pointerdown', 2, cx + R * .5, cy); steps(4);
    glide([[1, cx - R * .5, cy, 20, cy + R * .1], [2, cx + R * .5, cy, W - 20, cy - R * .1]], 50); steps(20);
    poses.spread = snapshot('兩指拉'); ev('pointercancel', 1, 0, 0); ev('pointercancel', 2, 0, 0); }
  base({ eyes: 1 }); poses.tent = snapshot('8 條觸手');
  poses.seeds = {}; let best = 9;
  for (const sd of [4, 7, 12, 19, 23, 31, 42, 57]) { base({ ...blob, seed: sd }); const q = snapshot('種子' + sd), n = q.P.length; let per = 0, ar = 0; for (let i = 0; i < n; i++) { const a = q.P[i], b = q.P[(i + 1) % n]; per += Math.hypot(b[0] - a[0], b[1] - a[1]); ar += a[0] * b[1] - b[0] * a[1]; } const round = per * per / (4 * Math.PI * Math.abs(ar) / 2); poses.seeds[sd] = +round.toFixed(3); if (round < best) { best = round; poses.sit = q; poses.sitSeed = sd; } }
  return poses;
}

/* ---------- 2. 顏色與三種皮 ---------- */
const hex = h => { const n = parseInt(h.slice(1), 16); return [(n >> 16) / 255, (n >> 8 & 255) / 255, (n & 255) / 255]; };
const mix = (a, b, k) => a.map((v, i) => v + (b[i] - v) * k);
const WHITE = [1, 1, 1];
const SKINS = window.__JELLY_SKINS || {
  A: { name: 'A 清透果凍', kEdge: .45, kCore: .42, aEdge: .52, aCore: .80, amb: .86, dif: .24, glow: .60, line: .38, nk: .95, shin: 320, s0: .42, s1: .66, spec: .85, sheen: .12, refr: 16, arc: .92, arcC: .90, arcW: .05 },
  B: { name: 'B 奶凍', kEdge: .50, kCore: .16, aEdge: .86, aCore: .97, amb: .88, dif: .20, glow: .46, line: .26, nk: .90, shin: 320, s0: .42, s1: .68, spec: .80, sheen: .10, refr: 4, arc: .88, arcC: .90, arcW: .05 },
  C: { name: 'C 霧面軟膠', kEdge: .22, kCore: .10, aEdge: 1, aCore: 1, amb: .76, dif: .38, glow: .16, line: .10, nk: .72, shin: 9, s0: .35, s1: 1.15, spec: .34, sheen: .05, refr: 0, arc: 0, arcC: .34, arcW: .05 },
};
function palette(s) { const [b, sh, ln] = [hex(s.c[0]), hex(s.c[1]), hex(s.c[2])]; return { b, sh, ln }; }

/* ---------- 3. WebGL：遮罩 → 模糊 → 打光 ---------- */
const gc = document.createElement('canvas');
const gl = gc.getContext('webgl2', { premultipliedAlpha: false, preserveDrawingBuffer: true, antialias: false });
const floatOK = !!gl.getExtension('EXT_color_buffer_float') || !!gl.getExtension('EXT_color_buffer_half_float');
const VS = `#version 300 es
in vec2 p; out vec2 v; void main(){ v = p * .5 + .5; gl_Position = vec4(p, 0., 1.); }`;
const FB = `#version 300 es
precision highp float; in vec2 v; out vec4 o; uniform sampler2D t; uniform vec2 d; uniform float s;
void main(){ float sum = 0., w = 0.; int N = int(ceil(s * 2.6));
  for (int i = -N; i <= N; i++) { float g = exp(-.5 * float(i * i) / (s * s)); sum += texture(t, v + d * float(i)).r * g; w += g; }
  o = vec4(sum / w, 0., 0., 1.); }`;
const FS = `#version 300 es
precision highp float; in vec2 v; out vec4 o;
uniform sampler2D M, B1, B2, BG; uniform vec2 res; uniform float rpx;
uniform vec4 uD[6]; uniform int nD;
uniform vec3 cEdge, cCore, cLine, cGlow;
uniform float aEdge, aCore, amb, dif, glow, line, nk, shin, s0, s1, spec, sheen, refr, arc, arcC, arcW;
float H(vec2 uv){ float b1 = texture(B1, uv).r, b2 = texture(B2, uv).r;
  float h = .45 * smoothstep(0., 1., b1) + .55 * b2;
  vec2 px = uv * res; for (int i = 0; i < nD; i++) { vec2 q = (px - uD[i].xy) / uD[i].z; h -= uD[i].w * .24 * exp(-dot(q, q) * 1.6); }
  return h; }
void main(){
  float m = texture(M, v).r;
  vec3 bg0 = texture(BG, v).rgb;
  if (m < .002) { o = vec4(bg0, 1.); return; }
  vec2 e = 1.5 / res;
  float gx = (H(v + vec2(e.x, 0.)) - H(v - vec2(e.x, 0.))) / 3.;
  float gy = (H(v + vec2(0., e.y)) - H(v - vec2(0., e.y))) / 3.;
  vec3 n = normalize(vec3(-gx * rpx * nk, -gy * rpx * nk, 1.));
  vec3 L = normalize(vec3(-.5, .72, .9)), Hv = normalize(L + vec3(0., 0., 1.));
  float b1 = texture(B1, v).r, b2 = texture(B2, v).r;
  float thick = smoothstep(.08, .8, b2), fres = pow(1. - n.z, 2.);
  vec3 col = mix(cEdge, cCore, thick);
  col *= amb + dif * clamp(dot(n, L), 0., 1.);
  float tr = clamp(dot(n.xy, normalize(vec2(.35, -.94))), 0., 1.);
  col += cGlow * smoothstep(0., .7, tr) * (.25 + .75 * fres) * glow;
  vec3 bg = texture(BG, v + n.xy * refr / res).rgb;
  vec3 r = mix(bg, col, mix(aEdge, aCore, thick));
  r = mix(r, cLine, (1. - smoothstep(.5, .66, b1)) * line);
  float sp = pow(max(dot(n, Hv), 0.), shin);
  r += vec3(1.) * pow(max(dot(n, Hv), 0.), shin * .22) * sheen * (1. - thick * .4);
  r = mix(r, vec3(1.), smoothstep(s0, s1, sp) * spec);
  /* 亮弧：沿著外形的等高線走，只留朝光那一段；拉長、壓扁時自己跟著變形 */
  vec2 g2 = vec2(texture(B1, v + vec2(e.x * 2., 0.)).r - texture(B1, v - vec2(e.x * 2., 0.)).r, texture(B1, v + vec2(0., e.y * 2.)).r - texture(B1, v - vec2(0., e.y * 2.)).r);
  float gl2 = length(g2); if (gl2 > 1e-5 && arc > 0.) { float toL = dot(-g2 / gl2, normalize(vec2(-.62, .78))), dirF = smoothstep(.70, .97, toL), wd = arcW * dirF; if (wd > .002) r = mix(r, vec3(1.), (1. - smoothstep(wd * .55, wd, abs(b1 - arcC))) * arc); }
  o = vec4(mix(bg0, r, m), 1.);
}`;
function prog(vs, fs) { const p = gl.createProgram(); for (const [ty, src] of [[gl.VERTEX_SHADER, vs], [gl.FRAGMENT_SHADER, fs]]) { const s = gl.createShader(ty); gl.shaderSource(s, src); gl.compileShader(s); if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s)); gl.attachShader(p, s); } gl.bindAttribLocation(p, 0, 'p'); gl.linkProgram(p); if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p)); return p; }
const pBlur = prog(VS, FB), pFinal = prog(VS, FS);
const quad = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, quad); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
function texOf(src) { const tx = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, tx); gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true); gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, src); for (const [k, m] of [[gl.TEXTURE_MIN_FILTER, gl.LINEAR], [gl.TEXTURE_MAG_FILTER, gl.LINEAR], [gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE], [gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE]]) gl.texParameteri(gl.TEXTURE_2D, k, m); return tx; }
function fbo(w, h) { const tx = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, tx); if (floatOK) gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, w, h, 0, gl.RGBA, gl.HALF_FLOAT, null); else gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w, h, 0, gl.RGBA, gl.UNSIGNED_BYTE, null); for (const [k, m] of [[gl.TEXTURE_MIN_FILTER, gl.LINEAR], [gl.TEXTURE_MAG_FILTER, gl.LINEAR], [gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE], [gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE]]) gl.texParameteri(gl.TEXTURE_2D, k, m); const f = gl.createFramebuffer(); gl.bindFramebuffer(gl.FRAMEBUFFER, f); gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tx, 0); return { f, tx, w, h }; }
function kill(b) { gl.deleteFramebuffer(b.f); gl.deleteTexture(b.tx); }
function blurPass(srcTex, dst, dx, dy, s) { gl.bindFramebuffer(gl.FRAMEBUFFER, dst.f); gl.viewport(0, 0, dst.w, dst.h); gl.useProgram(pBlur); gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D, srcTex); gl.uniform1i(gl.getUniformLocation(pBlur, 't'), 0); gl.uniform2f(gl.getUniformLocation(pBlur, 'd'), dx, dy); gl.uniform1f(gl.getUniformLocation(pBlur, 's'), s); gl.drawArrays(gl.TRIANGLES, 0, 3); }

function tracePath(c, P, fx, fy) { const n = P.length; c.beginPath(); for (let i = 0; i < n; i++) { const p0 = P[(i + n - 1) % n], p1 = P[i], p2 = P[(i + 1) % n], p3 = P[(i + 2) % n]; if (i === 0) c.moveTo(fx(p1[0]), fy(p1[1])); c.bezierCurveTo(fx(p1[0] + (p2[0] - p0[0]) / 6), fy(p1[1] + (p2[1] - p0[1]) / 6), fx(p2[0] - (p3[0] - p1[0]) / 6), fy(p2[1] - (p3[1] - p1[1]) / 6), fx(p2[0]), fy(p2[1])); } c.closePath(); }

/* 把一個外框用某種皮畫到 bgCanvas 上。fx、fy：世界座標 → 畫布像素；rpx：一個半徑幾個像素 */
function renderJelly(bgCanvas, pose, skin, pal, fx, fy, rpx) {
  const w = bgCanvas.width, h = bgCanvas.height; gc.width = w; gc.height = h;
  const mc = document.createElement('canvas'); mc.width = w; mc.height = h; const m = mc.getContext('2d');
  m.fillStyle = '#000'; m.fillRect(0, 0, w, h); m.fillStyle = '#fff'; tracePath(m, pose.P, fx, fy); m.fill('nonzero');
  const tM = texOf(mc), tBG = texOf(bgCanvas);
  const h1 = fbo(w >> 1, h >> 1), h1b = fbo(w >> 1, h >> 1), q1 = fbo(w >> 2, h >> 2), q1b = fbo(w >> 2, h >> 2);
  const s1 = rpx * .07 / 2, s2 = rpx * .42 / 4;
  blurPass(tM, h1, 1 / h1.w, 0, s1); blurPass(h1.tx, h1b, 0, 1 / h1.h, s1);
  blurPass(tM, q1, 1 / q1.w, 0, s2); blurPass(q1.tx, q1b, 0, 1 / q1.h, s2);
  gl.bindFramebuffer(gl.FRAMEBUFFER, null); gl.viewport(0, 0, w, h); gl.useProgram(pFinal);
  const U = n => gl.getUniformLocation(pFinal, n);
  [[tM, 'M'], [h1b.tx, 'B1'], [q1b.tx, 'B2'], [tBG, 'BG']].forEach(([tx, n], i) => { gl.activeTexture(gl.TEXTURE0 + i); gl.bindTexture(gl.TEXTURE_2D, tx); gl.uniform1i(U(n), i); });
  gl.uniform2f(U('res'), w, h); gl.uniform1f(U('rpx'), rpx);
  const ds = new Float32Array(24); const dents = (pose.dents || []).slice(0, 6);
  dents.forEach((d, i) => { ds[i * 4] = fx(d[0]); ds[i * 4 + 1] = h - fy(d[1]); ds[i * 4 + 2] = d[2] * rpx / pose.R * 1.2; ds[i * 4 + 3] = d[3]; });
  gl.uniform4fv(U('uD'), ds); gl.uniform1i(U('nD'), dents.length);
  gl.uniform3fv(U('cEdge'), mix(pal.b, WHITE, skin.kEdge)); gl.uniform3fv(U('cCore'), mix(pal.b, pal.sh, skin.kCore));
  gl.uniform3fv(U('cLine'), mix(pal.sh, pal.ln, .35)); gl.uniform3fv(U('cGlow'), mix(pal.b, WHITE, .3));
  for (const k of ['aEdge', 'aCore', 'amb', 'dif', 'glow', 'line', 'nk', 'shin', 's0', 's1', 'spec', 'sheen', 'refr', 'arc', 'arcC', 'arcW']) gl.uniform1f(U(k), skin[k]);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
  const c = bgCanvas.getContext('2d'); c.drawImage(gc, 0, 0);
  [h1, h1b, q1, q1b].forEach(kill); gl.deleteTexture(tM); gl.deleteTexture(tBG);
}
function drawFace(c, pose, pal, fx, fy, rpx, ink) {
  if (!pose.eyes) return;
  const [L, Rr] = pose.eyes, ew = rpx * .056, eh = rpx * .074;
  const ang = Math.atan2(Rr[1] - L[1], Rr[0] - L[0]);
  for (const [p, sd] of [[L, -1], [Rr, 1]]) { const x = fx(p[0]) + Math.cos(ang) * sd * rpx * .23, y = fy(p[1]) + Math.sin(ang) * sd * rpx * .23 + rpx * .11, rx = rpx * .13, ry = rpx * .08;
    const g = c.createRadialGradient(0, 0, 0, 0, 0, 1); g.addColorStop(0, 'rgba(255,132,150,.72)'); g.addColorStop(.55, 'rgba(255,132,150,.42)'); g.addColorStop(1, 'rgba(255,132,150,0)');
    c.save(); c.translate(x, y); c.scale(rx, ry); c.fillStyle = g; c.beginPath(); c.arc(0, 0, 1, 0, Math.PI * 2); c.fill(); c.restore(); }
  for (const p of [L, Rr]) { const x = fx(p[0]), y = fy(p[1]);
    c.fillStyle = ink; c.beginPath(); c.ellipse(x, y, ew, eh, ang, 0, Math.PI * 2); c.fill();
    c.fillStyle = '#fff'; c.beginPath(); c.arc(x - ew * .3, y - eh * .38, ew * .34, 0, Math.PI * 2); c.fill(); }
}
function drawFlat(c, pose, s, fx, fy, rpx) {
  c.fillStyle = s.c[1]; tracePath(c, pose.P, fx, fy); c.fill();
  c.save(); tracePath(c, pose.P, fx, fy); c.clip(); c.fillStyle = s.c[0]; const o = pose.R * .07, o2 = pose.R * .085; tracePath(c, pose.P, x => fx(x - o), y => fy(y - o2)); c.fill(); c.restore();
  const [x0, y0, x1, y1] = pose.box; const hx = fx(x0 + (x1 - x0) * .36), hy = fy(y0 + (y1 - y0) * .3);
  c.fillStyle = s.c[3]; c.beginPath(); c.ellipse(hx, hy, rpx * .17, rpx * .085, -.5, 0, Math.PI * 2); c.fill();
  tracePath(c, pose.P, fx, fy); c.lineWidth = Math.max(3, rpx * .034); c.lineJoin = 'round'; c.strokeStyle = s.c[2]; c.stroke();
}

/* ---------- 4. 組圖 ---------- */
const FONT = '"Noto Sans TC","Microsoft JhengHei","PingFang TC",sans-serif';
function canvasOf(w, h, fill) { const k = document.createElement('canvas'); k.width = w; k.height = h; if (fill) { const c = k.getContext('2d'); c.fillStyle = fill; c.fillRect(0, 0, w, h); } return k; }
const load = u => new Promise((ok, no) => { const i = new Image(); i.crossOrigin = 'anonymous'; i.onload = () => ok(i); i.onerror = no; i.src = u; });
async function save(k, name, q) { const blob = await new Promise(r => k.toBlob(r, q ? 'image/jpeg' : 'image/png', q)); await fetch(BASE + '/save/' + name, { method: 'POST', body: new Blob([blob], { type: 'text/plain' }) }); return [name, k.width, k.height, blob.size]; }
const WALL = '#F2E7DC', mint = () => SLIMES[1];
function fitter(pose, cw, ch, rpx) { const [x0, y0, x1, y1] = pose.box, k0 = rpx / pose.R, k = Math.min(k0, (cw * .86) / (x1 - x0), (ch * .84) / (y1 - y0)), mx = (x0 + x1) / 2, my = (y0 + y1) / 2; return { fx: x => cw / 2 + (x - mx) * k, fy: y => ch / 2 + (y - my) * k, rpx: pose.R * k }; }

function gridSheet(poses) {
  const cols = [['rest', 360], ['pull', 620], ['press', 360], ['spread', 560], ['tent', 400]], rows = [null, 'A', 'B', 'C'], rowH = 400, head = 58, left = 170;
  const tw = left + cols.reduce((s, c) => s + c[1], 0);
  const sheet = canvasOf(tw, head + rowH * rows.length, '#FFFFFF'), c = sheet.getContext('2d'), s = mint(), pal = palette(s);
  c.fillStyle = '#3A2D29'; c.textBaseline = 'middle'; c.textAlign = 'center'; c.font = `600 26px ${FONT}`;
  let x = left; for (const [k, w] of cols) { c.fillText(poses[k].name, x + w / 2, head / 2); x += w; }
  rows.forEach((rk, ri) => { const y = head + ri * rowH; c.textAlign = 'left'; c.fillStyle = '#3A2D29'; c.font = `600 26px ${FONT}`; c.fillText(rk ? SKINS[rk].name : '現在 v2.27', 18, y + rowH / 2);
    let x = left; for (const [k, w] of cols) { const pose = poses[k], cell = canvasOf(w, rowH, WALL), { fx, fy, rpx } = fitter(pose, w, rowH, 130), cc = cell.getContext('2d');
      if (rk) { renderJelly(cell, pose, SKINS[rk], pal, fx, fy, rpx); drawFace(cc, pose, pal, fx, fy, rpx, s.c[4]); } else drawFlat(cc, pose, s, fx, fy, rpx);
      c.drawImage(cell, x, y); c.strokeStyle = '#fff'; c.lineWidth = 4; c.strokeRect(x, y, w, rowH); x += w; } });
  return sheet;
}
function keyGreen(img) { const k = canvasOf(img.width, img.height), c = k.getContext('2d'); c.drawImage(img, 0, 0); const d = c.getImageData(0, 0, k.width, k.height), a = d.data; for (let i = 0; i < a.length; i += 4) { const ex = a[i + 1] - Math.max(a[i], a[i + 2]); if (ex > 40) { a[i + 3] = Math.max(0, 255 - (ex - 40) * 3); if (a[i + 3] > 0) { a[i + 1] = Math.max(a[i], a[i + 2]); } } } c.putImageData(d, 0, 0); return k; }
function keyProps(img, sx, sy, sw, sh) { const k = canvasOf(sw, sh), c = k.getContext('2d'); c.drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh); const d = c.getImageData(0, 0, sw, sh), a = d.data; for (let i = 0; i < a.length; i += 4) { const dist = Math.hypot(a[i] - 237, a[i + 1] - 232, a[i + 2] - 228); a[i + 3] = dist < 12 ? 0 : dist > 26 ? 255 : (dist - 12) / 14 * 255; } c.putImageData(d, 0, 0); return k; }
function skyInto(c, w, h, x, y, sw, sh) { const g = c.createLinearGradient(0, y, 0, y + sh); g.addColorStop(0, '#9CCBF0'); g.addColorStop(1, '#DCEEF8'); c.fillStyle = g; c.fillRect(x, y, sw, sh);
  c.save(); c.beginPath(); c.rect(x, y, sw, sh); c.clip(); c.filter = 'blur(1.5px)'; c.fillStyle = 'rgba(255,255,255,.92)';
  for (const [cx, cy, r] of [[.26, .24, 1], [.72, .14, .8], [.82, .5, 1.15], [.3, .62, .7]]) { const u = sw * .1 * r, X0 = x + sw * cx, Y0 = y + sh * cy; for (const [dx, dy, rr] of [[-1.1, .2, .62], [-.3, -.25, .9], [.6, -.05, .75], [1.3, .25, .5]]) { c.beginPath(); c.arc(X0 + dx * u, Y0 + dy * u, rr * u, 0, Math.PI * 2); c.fill(); } c.fillRect(X0 - u * 1.6, Y0 + u * .1, u * 3.3, u * .62); }
  c.filter = 'none'; c.fillStyle = 'rgba(120,165,150,.45)'; c.beginPath(); c.moveTo(x, y + sh); for (let i = 0; i <= 40; i++) { const tt = i / 40; c.lineTo(x + sw * tt, y + sh * (.9 - .035 * Math.sin(tt * 9) - .02 * Math.sin(tt * 21))); } c.lineTo(x + sw, y + sh); c.fill(); c.restore(); }
function phoneScene(a) { /* a：{plate,bowl,succ,peb}。座標：@2x，一倍寬 393、高 852 */
  const K = 2, W0 = 393 * K, H0 = 852 * K, k = canvasOf(W0, H0, WALL), c = k.getContext('2d'), s = W0 / 860, off = 30 * K, ox = -66 * s;
  skyInto(c, W0, H0, ox + 156 * s, off + 304 * s, 680 * s, 828 * s);
  c.drawImage(a.plate, ox, off, 992 * s, 1586 * s);
  const sillY = off + 1228 * s;
  const shadow = (cx, y, rx, ry, al) => { c.save(); c.translate(cx, y); c.scale(rx, ry); const g = c.createRadialGradient(0, 0, 0, 0, 0, 1); g.addColorStop(0, `rgba(120,70,40,${al})`); g.addColorStop(1, 'rgba(120,70,40,0)'); c.fillStyle = g; c.beginPath(); c.arc(0, 0, 1, 0, Math.PI * 2); c.fill(); c.restore(); };
  const place = (img, cx, w) => { const h = img.height * w / img.width; shadow(cx, sillY - 2, w * .52, 11 * K, .28); c.drawImage(img, cx - w / 2, sillY - h, w, h); return { x: cx - w / 2, y: sillY - h, w, h }; };
  place(a.succ, 50 * K, 70 * K); place(a.peb, 343 * K, 76 * K);
  const bowlBox = place(a.bowl, 196.5 * K, 165 * K);
  return { canvas: k, bowlBox, K };
}
function bowlFront(a, box) { /* 碗的前半：碗口橢圓以外、碗口中線以下，蓋在身體前面 */
  const b = a.bowl, k = canvasOf(b.width, b.height), c = k.getContext('2d'); c.drawImage(b, 0, 0);
  c.globalCompositeOperation = 'destination-out'; c.fillStyle = '#000';
  const ex = b.width * .5, ey = b.height * .324, rx = b.width * .39, ry = b.height * .24;
  c.beginPath(); c.ellipse(ex, ey, rx, ry, 0, 0, Math.PI * 2); c.fill(); c.fillRect(0, 0, b.width, ey); c.globalCompositeOperation = 'source-over';
  return k;
}
function sitPose(pose, box, cx, wantW) { /* 示意用：實際做時由碰撞算 */
  const [x0, , x1, y1] = pose.box, k = wantW / (x1 - x0), sq = .92, mx = (x0 + x1) / 2, rimY = box.y + box.h * .42, band = box.h * .62, hw = box.w * .385, bottomY = box.y + box.h * .66;
  const sm = (a, b, v) => { const q = Math.max(0, Math.min(1, (v - a) / (b - a))); return q * q * (3 - 2 * q); };
  const map = p => { let dx = (p[0] - mx) * k; const py = bottomY - (y1 - p[1]) * k * sq, tt = sm(rimY - band, rimY, py), ad = Math.abs(dx), lim = ad + (Math.min(ad, hw) - ad) * tt; dx = Math.sign(dx) * lim; return [cx + dx, py]; };
  const P = pose.P.map(map), xs = P.map(q => q[0]), ys = P.map(q => q[1]);
  return { P, R: pose.R * k, eyes: pose.eyes && pose.eyes.map(map), dents: [], box: [Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys)] };
}
function phoneSheet(poses, a) {
  const pad = 36, W0 = 393, gap = 28, head = 56, n = 4, sheet = canvasOf(pad * 2 + n * W0 + (n - 1) * gap, head + 852 + pad, '#FFFFFF'), c = sheet.getContext('2d'), s = mint(), pal = palette(s);
  c.textBaseline = 'middle'; c.textAlign = 'center'; c.fillStyle = '#3A2D29'; c.font = `600 24px ${FONT}`;
  const put = (k, i, label) => { const x = pad + i * (W0 + gap); c.fillStyle = '#3A2D29'; c.fillText(label, x + W0 / 2, head / 2); c.save(); c.beginPath(); c.roundRect(x, head, W0, 852, 30); c.clip(); c.drawImage(k, x, head, W0, 852); c.restore(); };
  { const k = canvasOf(786, 1704), cc = k.getContext('2d'), g = cc.createLinearGradient(0, 0, 0, 1704); g.addColorStop(0, '#CBE9FB'); g.addColorStop(1, '#E4F4FD'); cc.fillStyle = g; cc.fillRect(0, 0, 786, 1704); const pose = poses.tent, K = 2, f = fitter(pose, 786, 1704, pose.R * K), ss = SLIMES[3]; drawFlat(cc, pose, ss, f.fx, y => f.fy(y) - 120, f.rpx); put(k, 0, '現在 v2.27'); }
  ['A', 'B', 'C'].forEach((rk, i) => { const sc = phoneScene(a), K = sc.K, box = sc.bowlBox, fr = bowlFront(a, box), sp = sitPose(poses.sit, box, 196.5 * K, 178 * K), id = v => v;
    renderJelly(sc.canvas, sp, SKINS[rk], pal, id, id, sp.R);
    const cc = sc.canvas.getContext('2d'); cc.drawImage(fr, box.x, box.y, box.w, box.h); drawFace(cc, sp, pal, id, id, sp.R, s.c[4]);
    put(sc.canvas, i + 1, SKINS[rk].name); });
  return sheet;
}
function colorSheet(poses) {
  const w = 360, h = 340, head = 54, left = 170, sheet = canvasOf(left + w * 4, head + h * 3, '#FFFFFF'), c = sheet.getContext('2d');
  c.textBaseline = 'middle'; c.font = `600 26px ${FONT}`; c.fillStyle = '#3A2D29'; c.textAlign = 'center'; SLIMES.forEach((s, i) => c.fillText(s.name, left + w * i + w / 2, head / 2));
  ['A', 'B', 'C'].forEach((rk, ri) => { c.textAlign = 'left'; c.fillStyle = '#3A2D29'; c.fillText(SKINS[rk].name, 18, head + ri * h + h / 2); SLIMES.forEach((s, i) => { const cell = canvasOf(w, h, WALL), f = fitter(poses.rest, w, h, 118), pal = palette(s); renderJelly(cell, poses.rest, SKINS[rk], pal, f.fx, f.fy, f.rpx); drawFace(cell.getContext('2d'), poses.rest, pal, f.fx, f.fy, f.rpx, s.c[4]); c.drawImage(cell, left + w * i, head + ri * h); }); });
  return sheet;
}

/* 亂玩到外框真的互疊，再比平塗和果凍皮：驗「不畫外框線，互疊就看不出來」 */
window.__jellyOverlap = async () => {
  const cross = P => { const n = P.length, seg = (a, b, c, d) => { const q = (b[0] - a[0]) * (d[1] - c[1]) - (b[1] - a[1]) * (d[0] - c[0]); if (Math.abs(q) < 1e-9) return false; const u = ((c[0] - a[0]) * (d[1] - c[1]) - (c[1] - a[1]) * (d[0] - c[0])) / q, v = ((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / q; return u > 0 && u < 1 && v > 0 && v < 1; }; let k = 0; for (let i = 0; i < n; i++) for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; if (seg(P[i], P[(i + 1) % n], P[j], P[(j + 1) % n])) k++; } return k; };
  let rnd = 12345; const rr = () => (rnd = (rnd * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
  const found = []; let tries = 0;
  for (const over of [{ ...OFF27, eyes: 1 }, { eyes: 1 }]) { base(over);
    for (let round = 0; round < 60 && found.length < 2; round++) { tries++;
      const cx = globalC.xc, cy = globalC.yc, a0 = rr() * 6.28, r0 = R * (.3 + rr() * .8), x0 = cx + Math.cos(a0) * r0, y0 = cy + Math.sin(a0) * r0, x1 = 20 + rr() * (W - 40), y1 = 120 + rr() * (H - 240);
      ev('pointerdown', 1, x0, y0); steps(2); glide([[1, x0, y0, x1, y1]], 6 + Math.floor(rr() * 18)); glide([[1, x1, y1, cx + (cx - x1) * .6, cy + (cy - y1) * .6]], 8); steps(2);
      const held = snapshot('抓著'), kh = cross(held.P); if (kh > 0) { held.k = kh; found.push(held); ev('pointercancel', 1, 0, 0); steps(30); continue; }
      ev('pointerup', 1, cx, cy); steps(8); const q = snapshot('放手'), k = cross(q.P); if (k > 0) { q.k = k; found.push(q); } } if (found.length >= 2) break; }
  if (!found.length) return JSON.stringify({ tries, found: 0 });
  const cw = 560, ch = 520, head = 54, left = 170, n = found.length, sheet = canvasOf(left + cw * n, head + ch * 2, '#FFFFFF'), c = sheet.getContext('2d'), sl = mint(), pal = palette(sl);
  c.textBaseline = 'middle'; c.font = `600 26px ${FONT}`; c.fillStyle = '#3A2D29'; c.fillText('現在 v2.27', 18, head + ch / 2); c.fillText('B 奶凍', 18, head + ch * 1.5);
  found.forEach((q, i) => { c.textAlign = 'center'; c.fillStyle = '#3A2D29'; c.fillText(`互疊 ${q.k} 處`, left + cw * i + cw / 2, head / 2); c.textAlign = 'left';
    const f = fitter(q, cw, ch, 130), a1 = canvasOf(cw, ch, WALL); drawFlat(a1.getContext('2d'), q, sl, f.fx, f.fy, f.rpx); c.drawImage(a1, left + cw * i, head);
    const a2 = canvasOf(cw, ch, WALL); renderJelly(a2, q, SKINS.B, pal, f.fx, f.fy, f.rpx); drawFace(a2.getContext('2d'), q, pal, f.fx, f.fy, f.rpx, sl.c[4]); c.drawImage(a2, left + cw * i, head + ch); });
  const out = await save(sheet, '4-互疊檢查.jpg', .93);
  return JSON.stringify({ tries, found: found.map(q => q.k), out });
};

window.__jellyRun = async () => {
  const poses = window.__poses || (window.__poses = capture());
  const [plateI, propsI] = await Promise.all([load(BASE + '/asset/plate.png'), load(BASE + '/asset/props.png')]);
  const a = { plate: keyGreen(plateI), bowl: keyProps(propsI, 225, 235, 500, 355), succ: keyProps(propsI, 915, 140, 330, 450), peb: keyProps(propsI, 1465, 260, 470, 320) };
  const out = [];
  out.push(await save(gridSheet(poses), '1-三種皮五種動作.jpg', .93));
  out.push(await save(phoneSheet(poses, a), '2-放進窗台.jpg', .93));
  out.push(await save(colorSheet(poses), '3-四隻的顏色.jpg', .93));
  return JSON.stringify({ floatOK, out, R: poses.rest.R, sitSeed: poses.sitSeed, seeds: poses.seeds, boxes: Object.fromEntries(Object.entries(poses).filter(e => e[1].box).map(([k, v]) => [k, [v.box.map(n => Math.round(n)), v.P.length, v.dents.length, !!v.eyes]])) });
};
})();
