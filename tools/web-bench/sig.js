// v2.64 C8 猜隻代理量（BATCH3 第 5 項）：十隻各放著 5 分鐘不碰（窗台、白天、擺飾、真正的預設），只記「看的人看得到的量」，給 sig.py 用最近中心分十隻。
// 用法：python st.py <web 資料夾> --tests "" --pre sig.js --reps 4 --procs 4 --arms '[{},{"signature":0}]' --out sig.json，再 python sig.py sig.json
// 看得到的量：每格待的比例、睡的比例、牠看著你的比例、醒著閉眼的比例；偽足一條條數（往上、往旁邊、往下，長的、撐很久的、短短一下的）；
// 朝一邊傾、搖偽足、沒被碰卻縮一下、整團轉著抖、快跑、嘆氣各幾次。招牌的紀錄（SG.log）不拿來分，只附在後面對照。
VIEW.bg = 'day'; VIEW.win = '';
const SGW = (k, sd, over) => {
  for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
  const S = SLIMES[k]; Math.random = seeded(sd); SLIME = k;
  mat = { ...PRE54[S.mat], seed: S.seed, ...S.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, ...over };
  setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = .3; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9;
  BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: sd }); brainReset(); LT.s = sd >>> 0; SG.s = (sd + 89) >>> 0; SG.gap = -1; SG.acc = 0; SG.n = { fire: 0, drop: 0 }; SG.log.length = 0; steps(60);
  const f = { cell: [0, 0, 0, 0, 0], slp: 0, look: 0, shut: 0, up: 0, side: 0, down: 0, long: 0, hold: 0, tiny: 0, lean: 0, wag: 0, shrink: 0, shake: 0, dash: 0, sigh: 0 };
  const seen = new WeakSet(); let n = 0, lean = E2.leanT, wag = MOOD.wagT, fl = FLN.t0, sk = SHK.t0, gd = false, sg = BRX.sighCyc;
  for (const s of LIFE.sns) seen.add(s);
  for (let q = 0; q < 60 * 300; q++) { steps(1);
    for (const s of LIFE.sns) if (!seen.has(s)) { seen.add(s); const sy = Math.sin(s.a); if (sy < -.7) f.up++; else if (sy > .5) f.down++; else f.side++; if (s.L >= .8) f.long++; if (s.T2 >= 2) f.hold++; if (s.L < .3) f.tiny++; }
    if (E2.leanT !== lean) { lean = E2.leanT; f.lean++; } if (MOOD.wagT !== wag) { wag = MOOD.wagT; f.wag++; }
    if (FLN.t0 !== fl) { fl = FLN.t0; if (t - lastTouch > 1) f.shrink++; } if (SHK.t0 !== sk) { sk = SHK.t0; f.shake++; }
    const d = GAIT.on && GAIT.dash; if (d && !gd) f.dash++; gd = d; if (BRX.sighCyc >= 0 && sg < 0) f.sigh++; sg = BRX.sighCyc;
    if (q % 30 === 0) { n++; f.cell[memCellAt(globalC.xc)]++; if (SLP.on) f.slp++; if (t < EYE.user && !SLP.on) f.look++; if (!SLP.on && EYE.openD < .3) f.shut++; } }
  f.cell = f.cell.map(v => +(v / n).toFixed(3)); for (const k of ['slp', 'look', 'shut']) f[k] = +(f[k] / n).toFixed(3);
  const kinds = {}; for (const q of SG.log) kinds[q.k] = (kinds[q.k] || 0) + 1;
  return { k, id: S.id, f, kinds };
};
const OVS = ARMS.length ? ARMS : [{}];
for (let ai = 0; ai < OVS.length; ai++) for (let k = 0; k < 10; k++) for (let sd = __SD0__; sd < __SD0__ + __REPS__; sd++) OUT.push({ test: 'SIG', arm: ai, sd, val: SGW(k, 5000 + sd * 101, OVS[ai]) });
