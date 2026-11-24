VIEW.bg='day';
const SPx = { ...PRE54.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, life2: 0, remeshCalm: 0 };
const freshx = (over,sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65+sd*1000); mat = { ...SPx, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 65+sd*1000 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(120); log.splice(0); };
const scrx = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
const wldx = (sx, sy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(sx - q.left - v.x) / CAM.z + CAM.x, (sy - q.top - v.y) / CAM.z + CAM.y]; };
const invx = () => { let n = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) n++; } return n; };
const lenx = (ux, uy) => { let a = -1e9, b = 1e9; for (const i of bnd) { const p = X[i] * ux + Y[i] * uy; a = Math.max(a, p); b = Math.min(b, p); } return +((a - b) / R).toFixed(2); };
const pullx = (over, sd, dx, dy, dist, hold, cb) => { freshx(over,sd); const L = Math.hypot(dx, dy), ux = dx / L, uy = dy / L, c = globalC; let bi = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } }
  const [sx, sy] = scrx(X[bi] - ux * R * .3, Y[bi] - uy * R * .3), pr = R * CAM.z; ev('pointerdown', 1, sx, sy); steps(4); let ex = sx, ey = sy;
  for (let s = 1; s <= 40; s++) { ex = Math.max(4, Math.min(innerWidth - 4, sx + ux * dist * pr * s / 40)); ey = Math.max(4, Math.min(innerHeight - 4, sy + uy * dist * pr * s / 40)); ev('pointermove', 1, ex, ey); steps(1); cb(s,ex,ey,ux,uy) }
  for (let k = 0; k < hold; k++) { steps(1); cb(41+k,ex,ey,ux,uy) } ev('pointerup', 1, ex, ey); steps(120); return lenx(ux,uy) };
const meas=(ex,ey)=>{const f=[...fingers.values()][0];let px=0,py=0,ox=0,oy=0,w=0,tx=0,ty=0;for(const m of f.mem){px+=X[m[0]]*m[3];py+=Y[m[0]]*m[3];ox+=m[1]*m[3];oy+=m[2]*m[3];w+=m[3]}
 px/=w;py/=w;ox/=w;oy/=w;const[fx,fy]=wldx(ex,ey);return{gap:Math.hypot(px-fx,py-fy)/R,lag:Math.hypot(px-ox-f.fx,py-oy-f.fy)/R,off:Math.hypot(ox,oy)/R,ox:ox/R,oy:oy/R,fw:Math.hypot(f.fx-fx,f.fy-fy)/R,n:f.mem.length,w,rem:REM.n,N,cap:CAPG,inv:invx(),mode:f.mode}};
