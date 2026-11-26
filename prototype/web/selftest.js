/* 捏捏史萊姆 網頁原型 回歸自測（Agent 程式自測：只抓「壞掉」，抓不到「好不好捏」）

   v2.64（11-27）：加 T88（D8 點一下傾完 0.4 秒頂回來、看你 1.5 秒、不碰時戒熟交情不動、1.5 秒內再碰沒有另外的獎勵；揉 30 秒有慢眨、只用睜眼和閉眼那條線；兩顆開著但沒點沒呼嚕時跟 0 逐點一樣；在 T87 後面、T74 前面跑）。
     舊項目一律 tapBack 0、slowBlink 0；T79、T82、T87 也釘 0（整份比對過預設 1 和全關，這三項的數字會變）。兩顆全關時整份跟第 3 項之後只差本來每次都不同的 T42、T65 到 T67、T70、T81，和接在 T88 後面的 T74（合回面積 1.002 變 0.996，見 BATCH3 卡住的項目）
   v2.64（11-26）：T78、T84 釘 lookTarget 0（整份比對過 lookTarget 0 和 1，這兩項的數字會變；舊項目一律 0；lookTarget 全關時整份跟 v2.63 只差 T42、T70、T73 的毫秒秒數和 T81 音檔載入順序）。
     T74 沒釘：它的數字也會變，但釘 0 時 mergeFx 1 那組 4 秒內合不回來（只在整份連跑時；單獨跑、T84 或 T87 接 T74 都合得回來）。原因是前面項目留下的狀態（EYE.nextBlink 這類 setup() 不歸零的量，決定第一次眨眼抽亂數的時間）把 T74 的亂數錯開，合回幀數在 52、179、192 幾種之間跳，記在 BATCH3「卡住的項目」
   v2.64（11-26）：加 T87（C5 張望有對象：窗台、窗景河邊的櫻、30 分鐘每 5 分鐘點一下，看完有反應 12 次以上、對象兩種以上、方向朝對象；lookTarget 0 沒挑對象沒反應；沒有對象時 1 跟 0 抽的方向一樣；在 T86 後面、T74 前面跑）
   v2.63（11-26）：加 T86（未做 83 調節台換材質、回到預設牠不彈一下：真正的預設、窗台和藍底，換果凍、換麻糬、果凍放 4 秒再回預設，之後 1.5 秒外框每格最大位移；deskSmooth 0 對照；在 T85 後面、T74 前面跑）
   v2.63（11-26）：加 T85（B9 動一點一顆：手指每走一小段一顆顆粒、手停就停、兩倍速約兩倍顆、每秒最多 20 顆、循環聲一半；sndGrain 0 沒有顆粒、其他聲音逐筆一樣；在 T84 後面、T74 前面跑）
   v2.63（11-26）：T77 釘 bond 0（整份比對兩版找出，其他項目逐筆同；T42 毫秒、T65 到 T67、T81 載入順序本來每次都不同）。T74 第一組合回面積 0.996 變 1.003：在 T74 裡釘 bond 0 也一樣，是前面多跑了 T84、T85 留下的狀態，沒釘
   v2.63（11-26）：加 T84（D6 戒高溫柔摸先 3 秒嘆氣才呼嚕、三分鐘後照常；交情只升不降、每分鐘 0.01、高的第一下不縮朝手指靠；存檔 bd；畫面沒有天數等級；bond 0 對照；在 T83 後面、T74 前面跑）
   v2.63（11-26）：加 T83（B1 拉、B3 慢慢拉 0.4 秒內就有拉絲聲和手機的連續震動；快拉照舊；揉只記錄；pullFx 0 對照；震動讀 hapContStep 記的 HAP.log；在 T82 後面、T74 前面跑）
   v2.63（11-26）：加 T82（D4 牠縮那一下有一小聲和一下輕震、0.3 秒內放手的「噗」不重複、連點越點越小到不出聲不震；flinchFx 0 對照；震動讀 HAP.log；在 T81 後面、T74 前面跑）
   v2.63（11-26）：加 T81（B2 按聲跟著力道、B5 嚇到開心不要啦按的聲音跟動作同一格、音檔前奏跳過；sndB2、sndB5 0 對照；在 T80 後面、T74 前面跑）；T72 釘 sndB5 0（g 推醒一醒就查 startle，嚇到那聲排到縮的那一格後查不到）
   v2.63（11-26）：加 T80（B6 拉回去再拉有絲聲、按下去只清上次放手的餘韻；sndB6 0 對照；音效接真的引擎；在 T79 後面、T74 前面跑）
   v2.63（11-26）：加 T79（C6 揉牠反應輪流、小跳 40 秒一次、叫聲洗牌袋；rubVary 0 對照；在 T78 後面、T74 前面跑）；舊項目一律 rubVary 0，T66、T67、T76 也釘 0（整份比對過，這幾項的數字會變；T65 也變，但它只跑這一項時兩版本來每次都不一樣，不是 rubVary 造成的，沒釘）
   v2.63（11-26）：加 T78（C5 張望不朝窗台下面；lookNoDown 0 對照；在 T77 後面、T74 前面跑）；T44、T45、T46、T48、T55、T74 釘 lookNoDown 0（整份比對過，這六項的數字會變）
   v2.63（11-26）：加 T77（D3 怕的不滑走、搔癢不掙脫、兩指照舊撕開；兩顆 0 對照；在 T76 後面、T74 前面跑）
   v2.63（11-26）：加 T76（C9 揉夠了放手，在你手邊睡著；nap 0 對照；在 T75 後面、T74 前面跑）
   v2.63（11-26）：加 T75（切回來也先看你：visibilitychange、blur／focus，睡著的慢慢醒不嚇；在 T74 前面跑，幾秒）
   v2.62（11-26）：加 T74（扯斷成兩隻、碰到合回，測試在 splittest.js，最後跑）；T62 也釘 split 0（真正的預設往上猛扯會斷）
   v2.61（11-25）：加 T73（慢拉往裡穿過去時跟手照舊變少，最後跑，約 30 秒）
   v2.61（11-25）：加 T72（補守預設開著、原本沒人守的開關，最後跑，約 30 秒）；T71 的換隻記憶原本恆真，改成真的開著大腦再看
   v2.61（11-25）：加 T71（W3：睡醒、手指放旁邊、打開先看你、眼睛、換隻記憶）
   v2.61（11-25）：加 T70（破皮，真的畫出來讀畫面），多跑約 8 到 9 分鐘；window.T70LONG = 1 跑長版
   v2.59（11-24）：加 T69（窗景）；跑的時候窗戶一律原本那扇，跑完還原
   v2.56（11-23）：加 T67（補點後站穩）；T65、T66 照慣例把它關掉。
   v2.52（11-22）：加 T63；舊項目釘住 v2.51 關掉、窗台拉伸上限回 3.2（見下面 PRE47 那段的說明）。

   用法：瀏覽器開 index.html，視窗固定 393×852（各項門檻是在這個尺寸定的；375×812 時 T42 亂捏觸手的黏土放手動能量到 38.8、門檻 12，會不過，2026-11-14），DevTools console 把這整個檔案貼上執行；
   或用 Claude 的 javascript_tool 直接跑。結果印在 console 並回傳，最後一欄 PASS 全 true 才算過。
   每次改演算法都跑（CLAUDE.md 硬規則）。

   量什麼：邊界自交數 selfX（終點要 0）、面積比 area（放手後回 1.00±0.02）、動能 ke（放手後衰減）、
   記形偏移 qdev（黏土：輕按 12 秒後 <1pt；按住後 >3pt、揉回原形後 <1pt。2026-11-01 多米真機回報後改，v2.7 是輕按不留痕）、第一幀最大位移（要 >1pt）、
   拖的過程逐幀的對折數 foldFrames（同一群自己交叉，要 0）與交疊數 overlapFrames（觸手疊在身體或別條觸手前面，設計上允許，只記錄）。
   怎麼跑：停掉 rAF，用固定 dt 1/60 驅動 update()（跟 iPhone Safari 一樣每幀 4 小步＝每秒 240 小步），
   用 PointerEvent 模擬手指。分頁在背景時 rAF 會被節流，所以不能靠動畫迴圈。 */
(async () => {
  const realRAF = window.requestAnimationFrame;
  const VIEW0 = { ...VIEW }; Object.assign(VIEW, { skin: 'flat', body: 'tent', face: 0, bg: 'blue', win: '' });   // v2.28 預覽：舊項目量的是 v2.27 的畫面與外形，跑完還原
  window.requestAnimationFrame = () => 0;
  await new Promise(r => setTimeout(r, 80));
  const log = [];
  const origPlay = sfxPlay;
  sfxPlay = (k, g, r) => { log.push([k, +(+g).toFixed(3), +(+(r || 1)).toFixed(3)]); };
  const DT = 1 / 60;
  // 音效引擎不准碰測試的亂數（2026-11-03）：音效檔載完之後引擎每幀抽 Math.random，把各項用固定種子產生的手抖序列錯開；載完的時間點落在第一輪中途，
  // 第一輪跟之後幾輪抽到的手抖不一樣（v2.16 到 v2.23 每版第一輪 T26 都是 3.25、之後 1.3 左右，就是這個）。跑 selftest 時音效那一幀改用真的亂數，跑完換回
  // 走路：測試不准碰使用者存的東西；窗框下緣的東西會擋手指，先清空
  WALK.noSave = true; WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null;
  // v2.34 熟留下來：測試不准碰使用者存的熟（chooseSlime、切背景都會寫），跑完原樣還回去
  SLP.openT = -99;   // v2.61 C1：時鐘歸零的項目不算「剛打開」（剛打開 40 秒不睡），不然量打盹的 T55 到 T57 等不到
  Object.assign(GREET, { st: '', until: -9, at: -9 }); EYE.user = -9; BRAIN.seed = 20261114;   // v2.61 C4：開頁面時的「先看你」把眼睛看哪裡排到第 3 秒左右、大腦的亂數起點也是真的亂數；時鐘歸零後每一項的頭幾秒眼睛都在看你、少抽亂數，後面整串手抖錯開（11-25：開關全關也紅 v226、v252，就是這個）
  IMPSV.noSave = true; const IMP0 = { tr: IMP.tr, w: IMP.w }, IMPS0 = JSON.stringify(IMPS);
  const realRandom0 = Math.random, sfxFrame0 = SFX && SFX.frame;
  if (SFX) SFX.frame = (...a) => { const r = Math.random; Math.random = realRandom0; try { return sfxFrame0.apply(SFX, a); } finally { Math.random = r; } };
  function ev(type, id, x, y) { cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1 })); }
  function steps(n) { for (let i = 0; i < n; i++) update(DT); }
  function segInt(ax, ay, bx, by, cx, cy, dx, dy) { const d = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx); if (Math.abs(d) < 1e-12) return false; const u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / d, v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / d; return u > 0 && u < 1 && v > 0 && v < 1; }
  function selfX() { const n = bnd.length; let c = 0; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = bnd[j], q = bnd[(j + 1) % n]; if (segInt(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q])) c++; } } return c; }
  // crossings split: same group (a tentacle or the body folding over itself: bad) vs different groups (one tentacle in front of another or the body: allowed by design)
  function classify() { const n = bnd.length; let same = 0, cross = 0; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; for (let j = i + 2; j < n; j++) { if (i === 0 && j === n - 1) continue; const p = bnd[j], q = bnd[(j + 1) % n]; if (segInt(X[a], Y[a], X[b], Y[b], X[p], Y[p], X[q], Y[q])) { if (TID[a] === TID[p] && TID[b] === TID[q]) same++; else cross++; } } } return [same, cross]; }
  let fold = 0, overlap = 0;
  const trk = () => { const [s, c] = classify(); if (s) fold++; if (c) overlap++; };
  function area() { let A = 0; const n = bnd.length; for (let i = 0; i < n; i++) { const a = bnd[i], b = bnd[(i + 1) % n]; A += X[a] * Y[b] - X[b] * Y[a]; } return Math.abs(A) / 2; }
  function ke() { let s = 0; for (let i = 0; i < N; i++) s += (X[i] - PX[i]) ** 2 + (Y[i] - PY[i]) ** 2; return s; }
  function qdev() { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(QX[i] - Q0X[i], QY[i] - Q0Y[i])); return m; }
  function snap() { const [s, c] = classify(); return { selfX: s + c, fold: s, overlap: c, area: +(area() / A0).toFixed(3), ke: +ke().toFixed(2), qdev: +qdev().toFixed(2) }; }
  function maxMove(ref) { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(X[i] - ref[0][i], Y[i] - ref[1][i])); return m; }
  const res = { W, H, R: +R.toFixed(1), N, nb: bnd.length, preset: 'clay' };
  // v2.20：舊項目量的是 v2.19 的行為，一律關掉拖著走、凹痕退快、印象（跟關情緒、關活物一樣）；v2.20 在 T35 用 P0 打開（拉力 slide 0），v2.21 拉力在 T36。跑完換回來
  // 三種材質都換（舊項目也用果凍、麻糬的預設）
  // v2.23：新功能（黏液 v2.23、眼睛、睡著、節奏、游過來）舊項目一律關；T35 到 T37 用 P0（v2.23 關），T38 用 P1（全開）
  // v2.24：舊項目與 T35 到 T38 一律回 v2.23（OFF24：身體 0.22、舊鏡頭、舊幅度、舊揉的門檻），v2.24 只在 T39 測（用 PSAVE 全開）
  // v2.47（多米 11-16 手機錄影）：舊項目量的是 v2.46 的手感，一律用舊數字：拉開了就不攤、拉得遠不衝過頭、記形抹圓都關，黏土的軟硬、慢一拍、按下去沉多久用調節台之前的值。
  // 換掉 PRESETS 本身，後面的 P1、P27、PSAVE、P27R 都從這裡來；PRE47 是真正的預設值，T61 用，跑完還給 PRESETS
  // v2.48：每一小塊的上下限、手指讓、被扯不發抖不扒，舊項目一律關（量的是原本的行為），只在 T62 開
  // v2.51（不規則外形、黏條、捏邊緣算拉、分裂、黏螢幕四周）推上去時沒跑過這份測試；11-22 補跑，63 項有 11 項不過（pressReal、pullForce、v227、v225、v224、sill、knot、walk、extreme、deco、pullCalm）。
  //   照 v2.47、v2.48 的做法：舊項目一律關掉這五樣（量的是原本的行為），關掉之後剩 pullCalm（T61）不過，T61 的 SP 也一起關。v2.51 自己的行為還沒有專門的項目，只有 T63 g 量了捏邊緣往外拉
  // v2.52：窗台不再蓋掉拉伸上限（A1）。舊項目的門檻是在「窗台上最多 3.2R、記形 2.6R」下定的，用 sillCap 3.2 回到那個行為；新的行為在 T63 測
  const PRE62 = {}; for (const k in PRESETS) PRE62[k] = { ...PRESETS[k] };   // v2.62 真正的預設（扯斷開著）：T74 用，跑完用它還回去
  const PRE54 = {}; for (const k in PRESETS) PRE54[k] = { ...PRESETS[k], split: 0 };   // v2.62：T65 到 T73 量的是扯斷之前的行為，亂拉時不准斷   // v2.54 真正的預設（無限拉開著）：T65 用，跑完還回去
  for (const k in PRESETS) PRESETS[k] = { ...PRESETS[k], rubVary: 0, lookTarget: 0, tapBack: 0, slowBlink: 0, endless: 0, frameCling: 1, rateK: 0, ...(k === 'clay' ? { slide: 1.5 } : {}) };   // v2.54：舊項目全部釘在 v2.53 的拉法（無限拉關、黏窗框開、黏土 slide 1.5）   // v2.63 C6：舊項目一律 rubVary 0（整份比對過，T33、T39、T41 會變；T33 量的就是放手小跳）   // v2.64 C5：舊項目一律 lookTarget 0（量的是 v2.63 的張望）   // v2.64 D8：舊項目一律 tapBack 0、slowBlink 0
  const PRE47 = { ...PRESETS }; for (const k in PRESETS) PRESETS[k] = { ...PRESETS[k], pressPull: 0, dragCalm: 0, memSmooth: 0, stretchCap: 0, memCap: 0, tremble: 1, struggle: 1, lump: 0, strand: 0, tugEdge: 0, split: 0, edgeCling: 0, sillCap: 3.2 }; PRESETS.clay = { ...PRESETS.clay, alpha: .4, lag: .12, pressSink: .8 };
  const P1 = { ...PRESETS.clay, ...OFF24, brain: 0 }, OFF23 = { eyes: 0, sleep: 0, echo: 0, introSwim: 0 }, P0 = { ...P1, ...OFF23 }, P27 = { ...PRESETS }, PSAVE = {}; for (const k in PRESETS) PSAVE[k] = { ...PRESETS[k], ...OFF27 }; for (const k in PRESETS) PRESETS[k] = { ...PRESETS[k], ...OFF24, slide: 0, drag: 0, dentFade: 10, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, ...OFF23, brain: 0, decoReal: 0, shake: 0, cling: 0, pairMax: 0, tear: 0, flipMem: 0, homeClamp: 0, clingTidy: 0 };
  const P27R = { ...P27 }; for (const k in P27) { P27[k] = { ...P27[k], brain: 0, decoReal: 0, shake: 0, cling: 0, pairMax: 0, tear: 0, flipMem: 0, homeClamp: 0, clingTidy: 0 }; PSAVE[k].brain = 0; PSAVE[k].shake = 0; PSAVE[k].cling = 0; PSAVE[k].pairMax = 0; PSAVE[k].tear = 0; PSAVE[k].flipMem = 0; PSAVE[k].homeClamp = 0; PSAVE[k].clingTidy = 0; }   // v2.38：兩指上限與撕開只在 T54 開   // v2.36：黏牆只在 T53 開，舊項目量原本的行為   // v2.31：搖晃沉澱只在 T48 開；P27R 是沒改過的，跑完還給 PRESETS
  // reset 也要停掉遊走：setup() 把家放回中間，但上一輪留下的遊走還在走，家會繼續往遊走目標移，60 步內身體就飄開（量過飄 58 點，
  // 兩指捏的手指按到身體外面，只有一指抓到）。2026-11-01 v2.14 發現，之前連跑過是遊走剛好停著
  function reset() { mat = { ...PRESETS.clay, emo: 0, life2: 0 }; setup();   // emo 0：情緒（逃跑、閃開）會把身體移走，回歸測試量的是物理；情緒在 T33 測；life2 0：v2.19 活物感另外在 T34 測
  WANDER.moving = false; WANDER.next = t + 5; steps(60); }
  // 固定亂數＋歸零時鐘，T11、T12 用：結果可重現。setup() 不重設時鐘；時鐘動過要還原，不然上一輪 T2 的 relaxUntil 留在未來，下一輪的記形會被當成「揉回原形」
  function seeded(seed) { let a = seed >>> 0; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const realRandom = Math.random;
  // 2026-11-16：整份測試不再用真的亂數。原本 T1 到 T10、T13 到 T16、T43、T44 沒有固定種子，每一項結束（restoreClock）又換回真的亂數；這些項目留下來的狀態（眨眼、休息、走路的計時）setup() 不會清，
  // 後面有固定種子的項目抽亂數的時間點就被錯開，每輪數字都不一樣（十輪量到 T49 的衝刺速度比 1.11 到 1.38、門檻 1.12，十輪掉一次）。現在每次換亂數都換成下一個固定種子，同一個起點跑出來的數字每輪一樣。
  // 想換一組亂數找問題：跑之前設 window.SELFTEST_SEED = 任何整數。
  const SEED0 = (window.SELFTEST_SEED | 0) || 20261116; let seedN = 0; const reseed = () => { Math.random = seeded(SEED0 + (seedN++) * 7919); }; reseed();
  const saveClock = () => ({ t, lastTouch, nextTwitch, tLife, relaxUntil, wNext: WANDER.next, wMoving: WANDER.moving });
  function restoreClock(c) { ({ t, lastTouch, nextTwitch, tLife, relaxUntil } = c); WANDER.next = c.wNext; WANDER.moving = c.wMoving; reseed(); }
  // 時鐘也從固定的起點開始：蠕動、呼吸照時鐘算，T1 不歸零時鐘，每輪開跑時 t 不同，第一項的數字就不同（固定亂數之後第 3、4 輪 T1 第一幀位移還是 8.49 對 8.92）。跑完還回去
  const clock00 = saveClock(), misc00 = { specialUntil, releaseCount, nextSpecial, ph: BR.phase, tl: BR.tlPrev };
  t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; specialUntil = -1; releaseCount = 0; nextSpecial = 0; BR.phase = 0; BR.tlPrev = 0; WANDER.moving = false; WANDER.next = 5;
  function resetAligned(wanderNext, over) { mat = { ...PRESETS.clay, emo: 0, life2: 0, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; specialUntil = -1; releaseCount = 0; nextSpecial = 0; BR.phase = 0; BR.tlPrev = 0; WANDER.moving = false; WANDER.next = wanderNext; steps(60); }

  // T1 輕按 0.1 秒：第一幀要動；12 秒後不留痕（2026-11-01 黏土改成約 10 秒退）
  reset();
  const cx0 = globalC.xc, cy0 = globalC.yc;
  let ref = [Float64Array.from(X), Float64Array.from(Y)];
  ev('pointerdown', 1, cx0, cy0); steps(1);
  const firstFrame = +maxMove(ref).toFixed(2);
  steps(5); const t1Hold = snap();
  ev('pointerup', 1, cx0, cy0); steps(120); const t1After2 = snap(), t1Sfx = log.splice(0); steps(600);
  res.T1_tap = { firstFrameMove: firstFrame, hold: t1Hold, after2s: t1After2, after12s: snap(), sfx: t1Sfx };

  // T2 按住 1.5 秒：越按越攤，黏土留痕；揉回原形清掉
  reset(); ref = [Float64Array.from(X), Float64Array.from(Y)];
  ev('pointerdown', 1, cx0, cy0); steps(6); const m01 = +maxMove(ref).toFixed(2);
  steps(84); const m15 = +maxMove(ref).toFixed(2); const s15 = snap();
  ev('pointerup', 1, cx0, cy0); steps(60); const afterHold = snap();
  relax(); steps(60); const afterRelax = snap();
  res.T2_hold = { move100ms: m01, move1500ms: m15, during: s15, afterRelease1s: afterHold, afterRelax1s: afterRelax, sfx: log.splice(0) };

  // T3 單指從右邊拉到底、停 1 秒、慢放（放手速度 0，啵要靠拉伸量）
  reset();
  // （這一拉抓的是朝右那條觸手的根部往右拖：觸手被壓縮，是最容易對折的動作，逐幀抓對折）
  // v2.9 起身體形狀一直在變（偽足）：手指放在身體實際的最右邊往內 0.15R，不然有時落在身體外面變成推、沒抓到
  const edgeX = dir => { let b = -1; for (const i of bnd) if (b < 0 || dir * X[i] > dir * X[b]) b = i; return [X[b] - dir * R * 0.15, Y[b]]; };
  const [sx, sy] = edgeX(1); ev('pointerdown', 1, sx, sy); fold = 0; overlap = 0;
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx + k * (R * 2.2 / 60), sy + k * (R * 0.8 / 60)); steps(1); trk(); }
  for (let k = 0; k < 60; k++) { steps(1); trk(); } const t3Peak = snap();
  ev('pointerup', 1, sx + R * 2.2, sy + R * 0.8); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  res.T3_pull = { during: t3Peak, after3s: snap(), foldFrames: fold, overlapFrames: overlap, sfx: log.splice(0) };

  // T4 兩指對拉
  reset(); fold = 0; overlap = 0;
  { const [lx, ly] = edgeX(-1), [rx, ry] = edgeX(1);
  ev('pointerdown', 1, lx, ly); ev('pointerdown', 2, rx, ry);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, lx - k * (R * 1.5 / 60), ly); ev('pointermove', 2, rx + k * (R * 1.5 / 60), ry); steps(1); trk(); }
  for (let k = 0; k < 30; k++) { steps(1); trk(); } var t4 = snap();
  ev('pointerup', 1, lx - R * 1.5, ly); ev('pointerup', 2, rx + R * 1.5, ry); for (let k = 0; k < 180; k++) { steps(1); trk(); } }
  res.T4_twoFinger = { during: t4, after3s: snap(), foldFrames: fold, overlapFrames: overlap, sfx: log.splice(0) };

  // T5 亂甩 120 幀
  reset(); let fx = cx0, fy = cy0; ev('pointerdown', 1, fx, fy); let worst = 0; fold = 0; overlap = 0;
  for (let k = 0; k < 120; k++) { fx = cx0 + (Math.random() - .5) * R * 4; fy = cy0 + (Math.random() - .5) * R * 4; ev('pointermove', 1, fx, fy); steps(1); worst = Math.max(worst, classify()[0]); trk(); }
  ev('pointerup', 1, fx, fy); for (let k = 0; k < 180; k++) { steps(1); trk(); }
  { const l = log.splice(0); res.T5_flail = { worstDuring: worst, foldFrames: fold, overlapFrames: overlap, after3s: snap(), pulls: l.filter(e => e[0] === 'pull').length, release: l.find(e => e[0] === 'release') }; }

  // T6 從外面推進來：第一次推到要有 press 音
  reset(); const px0 = cx0 - R * 2.4, py0 = cy0; ev('pointerdown', 1, px0, py0);
  for (let k = 1; k <= 60; k++) { ev('pointermove', 1, px0 + k * (R * 2.0 / 60), py0); steps(1); }
  const t6 = snap(); ev('pointerup', 1, px0 + R * 2.0, py0); steps(120);
  res.T6_push = { during: t6, after2s: snap(), sfx: log.splice(0) };

  // T7 放著 20 秒
  reset(); let worstIdle = 0, minA = 9, maxA = 0;
  for (let k = 0; k < 1200; k++) { update(DT); if (k % 20 === 0) { worstIdle = Math.max(worstIdle, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }   // idle: any crossing at all counts
  res.T7_idle = { worstSelfX: worstIdle, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3), qdev: +qdev().toFixed(2) };

  // T8 pointercancel：不啵、手指清掉
  reset(); ev('pointerdown', 1, cx0, cy0); steps(30); ev('pointercancel', 1, cx0, cy0); steps(30);
  res.T8_cancel = { fingersLeft: fingers.size, sfx: log.splice(0) };

  // T9 快甩放手：峰值速度項
  reset(); ev('pointerdown', 1, cx0, cy0);
  for (let k = 1; k <= 6; k++) { ev('pointermove', 1, cx0 + k * R * 0.25, cy0); steps(1); }
  ev('pointerup', 1, cx0 + R * 1.5, cy0); steps(60);
  res.T9_flick = { sfx: log.splice(0), after: snap() };

  // T10 候選 19（凍住）與候選 2（特別回彈，每次都來）開著，抓放三次也不壞
  reset(); mat.idleFreeze = 1; mat.specialEvery = 1; steps(120); let worst10 = 0, first10 = null;
  const note10 = (phase, r, k) => { const c = classify()[0]; if (c > 0) { worst10 = Math.max(worst10, c); if (!first10) first10 = { phase, r, k, home: [+HOMEX.toFixed(0), +HOMEY.toFixed(0)], body: [+globalC.xc.toFixed(0), +globalC.yc.toFixed(0)], t: +t.toFixed(2) }; } };
  for (let r = 0; r < 3; r++) {
    ev('pointerdown', 1, cx0, cy0);
    for (let k = 1; k <= 20; k++) { ev('pointermove', 1, cx0 + k * R * 0.08, cy0 - k * R * 0.04); steps(1); note10('drag', r, k); }
    ev('pointerup', 1, cx0 + R * 1.6, cy0 - R * 0.8);
    for (let k = 1; k <= 90; k++) { steps(1); note10('release', r, k); }
  }
  { const l = log.splice(0); res.T10_candidates = { worstSelfX: worst10, first: first10, after: snap(), releases: l.filter(e => e[0] === 'release').map(e => e[1]) }; }
  mat = { ...PRESETS.clay };

  // T11 壓縮觸手的 18 個情境（第 41 條的量法）：抓朝右那條觸手根部附近三個位置 × 軸線上下 × 三個拖的方向，逐幀記對折。
  //     基準（v2.4 以前）是 8 個情境對折、282 幀、6 個握著時還在對折；橫檔＋中軸不折返之後 3 個情境、24 幀、0 個握著還在
  //     2026-11-01 黏土觸手記形之後，同一組亂數另跑一次 v2.7 對照（T11_v27）一起記
  function compressionGrid(over) { const clock = saveClock(); Math.random = seeded(20261101); let scenFold = 0, frames = 0, heldRuns = 0, overlapF = 0; const grid = [];   // 固定亂數：18 個情境每次一樣
    for (const gx of [0.65, 0.8, 0.95]) for (const gy of [-0.1, 0.1]) for (const [vx, vy] of [[2.2, 0.8], [2.0, 0], [1.6, -0.6]]) grid.push([gx, gy, vx, vy]);
    for (const [gx, gy, vx, vy] of grid) {
      resetAligned(3, over); const cx1 = globalC.xc, cy1 = globalC.yc, sx = cx1 + gx * R, sy = cy1 + gy * R; let f = 0;
      ev('pointerdown', 1, sx, sy);
      for (let k = 1; k <= 45; k++) { ev('pointermove', 1, sx + vx * R * k / 45, sy + vy * R * k / 45); steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      for (let k = 0; k < 45; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (classify()[0] > 0) heldRuns++;
      ev('pointerup', 1, sx + vx * R, sy + vy * R); for (let k = 0; k < 150; k++) { steps(1); const [s, c] = classify(); if (s) f++; if (c) overlapF++; }
      if (f > 0) scenFold++; frames += f;
    }
    log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay };
    return { scenarios: grid.length, scenariosWithFold: scenFold, foldFrames: frames, heldFoldRuns: heldRuns, overlapFrames: overlapF };
  }
  // v2.9 起預設沒有固定觸手：T11 改跑 v2.7 對照（舊外形），守住面板那顆對照按鈕不壞
  res.T11_compressionGrid = compressionGrid(V27.clay);

  const okArea = s => s.area > 0.98 && s.area < 1.02;
  const rel = l => (l.find(e => e[0] === 'release') || [0, 0])[1];
  // 提案第 41 條（2026-11-01）：抓觸手根部往尖端推會壓縮觸手、對折。橫檔＋中軸不折返之後剩手指正好壓在接點上時的幾幀。
  // T12 遊走與拖尾（第 20 條）：同一組亂數跑兩次（關拖尾當對照、開拖尾），放著 20 秒逐幀比觸手尖端在身體座標裡的位置差，
  //     投影到移動的反方向＝拖了幾點（maxTailPt）；走完停下 3 秒後差要回到 1.5pt 以內（afterStopPt；停下 1 到 2 秒內身體還在回正，量到 3.5pt）；過程零自交、面積不漂
  {
    const clock = saveClock();
    function wanderRun(tail) {
      Math.random = seeded(20261101); resetAligned(0, V27.clay); mat.tail = tail;   // 拖尾量觸手尖端：用 v2.7 對照（舊外形）跑   // 先歸零時鐘再暖身，兩次的亂數才會對齊
      const tips = []; for (let k = 0; k < TENT.length; k++) { let b = -1; for (let i = 0; i < N; i++) if (TID[i] === k && (b < 0 || TU[i] > TU[b])) b = i; if (b >= 0) tips.push(b); }
      const frames = []; let worst = 0, minA = 9, maxA = 0, stopAt = -9, moved = 0;
      for (let f = 0; f < 1200; f++) { update(DT);
        if (f % 4 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); }
        let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
        const ga = Math.atan2(globalC.sn, globalC.cs), ca = Math.cos(ga), sa = Math.sin(ga), wv = Math.hypot(WANDER.vx, WANDER.vy);
        if (WANDER.moving) { stopAt = t; moved++; }
        frames.push({ pos: tips.map(i => { const dx = X[i] - mx, dy = Y[i] - my; return [ca * dx + sa * dy, -sa * dx + ca * dy]; }), moving: WANDER.moving,
          bx: wv > 1e-6 ? -(ca * WANDER.vx + sa * WANDER.vy) / wv : 0, by: wv > 1e-6 ? -(-sa * WANDER.vx + ca * WANDER.vy) / wv : 0, since: t - stopAt });
      }
      return { frames, worst, minA, maxA, moved };
    }
    const ctl = wanderRun(0), run = wanderRun(PRESETS.clay.tail);
    let maxTail = 0, afterStop = 0;
    for (let f = 0; f < run.frames.length; f++) { const a = ctl.frames[f], b = run.frames[f];
      for (let k = 0; k < b.pos.length; k++) { const dx = b.pos[k][0] - a.pos[k][0], dy = b.pos[k][1] - a.pos[k][1];
        if (b.moving) maxTail = Math.max(maxTail, dx * b.bx + dy * b.by); else if (b.since > 3) afterStop = Math.max(afterStop, Math.hypot(dx, dy)); } }
    res.T12_wander = { tail: PRESETS.clay.tail, movingFrames: run.moved, maxTailPt: +maxTail.toFixed(2), afterStopPt: +afterStop.toFixed(2), worstSelfX: run.worst, areaMin: +run.minA.toFixed(3), areaMax: +run.maxA.toFixed(3), controlSame: ctl.moved === run.moved };
    restoreClock(clock);
  }
  // T13 兩指捏（第 24 條）：兩指在身體兩側抓住、相向靠近到起始距離的 35%，要有 squish（press 音）至少兩次；放手後零對折、面積回來（過程的對折幀只記錄）
  reset(); fold = 0; overlap = 0;
  { const d0 = R * 0.9; ev('pointerdown', 1, cx0 - d0 / 2, cy0); ev('pointerdown', 2, cx0 + d0 / 2, cy0); steps(2); log.splice(0);
    for (let k = 1; k <= 40; k++) { const d = d0 * (1 - 0.65 * k / 40); ev('pointermove', 1, cx0 - d / 2, cy0); ev('pointermove', 2, cx0 + d / 2, cy0); steps(1); trk(); }
    for (let k = 0; k < 30; k++) { steps(1); trk(); }
    const during = snap(), squish = log.filter(e => e[0] === 'press').length;
    ev('pointerup', 1, cx0 - d0 * 0.175, cy0); ev('pointerup', 2, cx0 + d0 * 0.175, cy0); steps(180);
    res.T13_pinch = { squishEvents: squish, during, after3s: snap(), foldFrames: fold, overlapFrames: overlap }; log.splice(0); }

  // T14 拉太遠滑脫（候選 25，開著）：拉到上限 1.3 倍停 0.3 秒，手指還按著就要脫手（最重的放手音、沒有粒子被抓著）；之後抬手不再第二次啵
  reset(); mat.slip = 1; log.splice(0);
  { const far = PRESETS.clay.maxPull * 1.3 * R; ev('pointerdown', 1, cx0, cy0);
    for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx0 + far * k / 30, cy0); steps(1); }
    for (let k = 0; k < 20; k++) steps(1);
    const slipped = log.filter(e => e[0] === 'release'), grabbed = Array.from(GRAB).filter(Boolean).length;
    log.splice(0); ev('pointerup', 1, cx0 + far, cy0); steps(60);
    res.T14_slip = { slipRelease: slipped.length, slipGain: slipped.length ? slipped[0][1] : 0, grabbedAfterSlip: grabbed, popAfterLift: log.filter(e => e[0] === 'release').length, after1s: snap() }; log.splice(0); }

  // T15 放手黏連（候選 26，0.12 秒）：慢慢移 0.3R 再抬手，啵要晚 6 幀以上才來、抬手那一刻那塊還被抓著；快甩抬手要當幀就啵
  reset(); mat.stick = 0.12; log.splice(0);
  { ev('pointerdown', 1, cx0, cy0); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx0 + R * 0.3 * k / 30, cy0); steps(1); }
    log.splice(0); ev('pointerup', 1, cx0 + R * 0.3, cy0); let popAt = -1; const heldAtLift = Array.from(GRAB).filter(Boolean).length;
    for (let k = 0; k < 30; k++) { steps(1); if (popAt < 0 && log.some(e => e[0] === 'release')) popAt = k + 1; }
    steps(60); const slow = { popFrame: popAt, heldAtLift, fingersLeft: fingers.size };
    ev('pointerdown', 1, cx0, cy0); for (let k = 1; k <= 6; k++) { ev('pointermove', 1, cx0 + k * R * 0.25, cy0); steps(1); }
    log.splice(0); ev('pointerup', 1, cx0 + R * 1.5, cy0); const fastImmediate = log.some(e => e[0] === 'release'); steps(60);
    res.T15_stick = { slow, fastImmediate, after: snap() }; log.splice(0); }

  // T16 第三批候選全開（21 回家慢、22 餘韻、23 呼吸三項、27 局部面積、33 家 0.46）：抓放三次加放著 5 秒也不壞
  reset(); Object.assign(mat, { homeK: 0.003, afterglow: 0.25, breathT: 6, breathShape: 1, breathDeep: 1, localArea: 1, homeFrac: 0.46 }); steps(120);
  { let worst16 = 0; const note = () => { worst16 = Math.max(worst16, classify()[0]); }; const c16x = globalC.xc, c16y = globalC.yc;
    for (let r = 0; r < 3; r++) {
      ev('pointerdown', 1, c16x, c16y);
      for (let k = 1; k <= 20; k++) { ev('pointermove', 1, c16x + k * R * 0.08, c16y - k * R * 0.04); steps(1); note(); }
      for (let k = 0; k < 20; k++) { steps(1); note(); }
      ev('pointerup', 1, c16x + R * 1.6, c16y - R * 0.8); for (let k = 0; k < 90; k++) { steps(1); note(); }
    }
    let minA16 = 9, maxA16 = 0; for (let k = 0; k < 300; k++) { update(DT); if (k % 10 === 0) { note(); const a = area() / A0; minA16 = Math.min(minA16, a); maxA16 = Math.max(maxA16, a); } }
    res.T16_batch3 = { worstSelfX: worst16, after: snap(), areaMin: +minA16.toFixed(3), areaMax: +maxA16.toFixed(3), releases: log.filter(e => e[0] === 'release').length }; log.splice(0); }

  // T17 拉出一塊（2026-11-01 多米：捏了要留痕、慢慢恢復）：抓身體最右邊的邊、往外拉 0.9R（0.25 秒）、停 0.15 秒放手。
  //     量記形偏移（參考形狀離原形最遠幾點）放手後 1、5、12 秒；同一組亂數跑 v2.7 對照（舊外形）當比較。過程與之後零自交、面積回來
  { const clock = saveClock();
    function tentRun(ctl) {
      Math.random = seeded(20261102); resetAligned(99, ctl ? V27.clay : {});
      let tip = -1; for (const i of bnd) if (TID[i] < 0 && (tip < 0 || X[i] > X[tip])) tip = i;
      const tq = () => +qdev().toFixed(2), selfAny = () => selfX();
      const sx = X[tip] - R * 0.1, sy = Y[tip]; let f = 0;
      ev('pointerdown', 1, sx, sy);
      for (let k = 1; k <= 15; k++) { ev('pointermove', 1, sx + R * 0.9 * k / 15, sy); steps(1); if (selfAny()) f++; }
      for (let k = 0; k < 9; k++) { steps(1); if (selfAny()) f++; }
      const atRelease = tq(); ev('pointerup', 1, sx + R * 0.9, sy);
      const out = { atRelease }; let fr = 0;
      for (let k = 1; k <= 720; k++) { steps(1); if (selfAny()) fr++; if (k === 60) out.after1s = tq(); if (k === 300) out.after5s = tq(); if (k === 720) out.after12s = tq(); }
      log.splice(0); return { ...out, foldFramesHeld: f, foldFramesAfter: fr, end: snap() };
    }
    res.T17_pullMark = { now: tentRun(false), v27: tentRun(true) };
    restoreClock(clock); mat = { ...PRESETS.clay };
  }

  // T18 蠕動不重複：放著 48 秒，每 0.5 秒記一次身體邊界（不含觸手）的蠕動位移（EX−QX），算「有效形狀數」
  //     （樣本共變異的 participation ratio＝(Σλ)²/Σλ²：只在一兩個樣子之間晃接近 1–2，形狀一直在換會變大），跟 v2.7 的固定行進波比。
  //     只記錄、不判手感；另量身體蠕動平均與最大位移幾點、過程零自交、面積不漂
  { const clock = saveClock();
    function idleRun(ctl) {
      Math.random = seeded(20261103); resetAligned(1e9, ctl ? V27.clay : {});   // resetAligned(1e9)：不遊走，只看形狀
      const S = []; let peak = 0, worst = 0, minA = 9, maxA = 0;
      for (let f = 1; f <= 2880; f++) { update(DT);
        if (f % 30 === 0 && f > 120) { const v = []; for (const i of bnd) { if (TID[i] >= 0) continue; const dx = EX[i] - QX[i], dy = EY[i] - QY[i]; v.push(dx, dy); peak = Math.max(peak, Math.hypot(dx, dy)); } S.push(v); worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      const n = S.length, m = S[0].length, mu = new Float64Array(m); for (const v of S) for (let j = 0; j < m; j++) mu[j] += v[j] / n;
      const C = S.map(v => v.map((x, j) => x - mu[j])); let tr = 0, fr = 0, rms = 0;
      for (let a = 0; a < n; a++) { rms += Math.sqrt(S[a].reduce((s, x) => s + x * x, 0) / (m / 2)); for (let b = 0; b < n; b++) { let g = 0; for (let j = 0; j < m; j++) g += C[a][j] * C[b][j]; if (a === b) tr += g; fr += g * g; } }
      return { meanPt: +(rms / n).toFixed(2), peakPt: +peak.toFixed(2), shapes: +(tr * tr / fr).toFixed(2), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) };
    }
    res.T18_idleMorph = { now: idleRun(false), v27: idleRun(true) };
    restoreClock(clock); mat = { ...PRESETS.clay };
  }

  // T19 偽足（2026-11-01 多米：觸手會收回去、又從上面長出來；不是海星）：放著 40 秒，數長了幾條、有沒有長在上半邊，
  //     最遠伸出去幾點（邊界粒子離中心的距離減原形），過程零自交、面積不漂
  { const clock = saveClock(); Math.random = seeded(20261104); resetAligned(1e9); nextTwitch = 1e9;
    const seen = new Set(); let upper = 0, maxOut = 0, worst = 0, minA = 9, maxA = 0; const angs = [];
    for (let f = 1; f <= 2400; f++) { update(DT);
      for (const q of POD.list) if (!seen.has(q)) { seen.add(q); angs.push(+(q.a * 180 / Math.PI).toFixed(0)); if (Math.sin(q.a) < -0.3) upper++; }
      if (f % 10 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a);
        let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
        for (const i of bnd) maxOut = Math.max(maxOut, Math.hypot(X[i] - mx, Y[i] - my) - Math.hypot(Q0X[i], Q0Y[i])); } }
    res.T19_pods = { spawned: seen.size, upper, anglesDeg: angs, maxOutPt: +maxOut.toFixed(1), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T20 水母呼吸（2026-11-01 多米：規律的律動，像水母）：關掉偽足與蠕動，放著 30 秒，逐幀量身體寬高比（二階矩）與重心高度。
  //     收縮＝寬高比的谷底；量週期平均與標準差、寬高比擺幅、收縮佔一個週期的比例（從峰到谷）、上浮幾點
  { const clock = saveClock(); Math.random = seeded(20261105); resetAligned(1e9, { pods: 0, wriggle: 0 }); nextTwitch = 1e9;
    const asp = [], cy = [];
    for (let f = 1; f <= 1800; f++) { update(DT);   // 30 秒：幅度調小之後 15 秒只量得到 3 個週期，標準差被雜訊撐大
      let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } mx /= N; my /= N;
      // 在身體自己的座標裡量（扣掉整身轉動）：身體 5.3 秒一次的慢搖會改變畫面座標的寬高比，跟 3 秒的呼吸疊成假的不規律（量過標準差 0.18 秒）
      const ga = Math.atan2(globalC.sn, globalC.cs), gc = Math.cos(ga), gs = Math.sin(ga);
      let ixx = 0, iyy = 0; for (let i = 0; i < N; i++) { const dx = X[i] - mx, dy = Y[i] - my, bx = gc * dx + gs * dy, by = -gs * dx + gc * dy; ixx += bx * bx; iyy += by * by; }
      asp.push(Math.sqrt(ixx / iyy)); cy.push(my); }
    { const sm = asp.map((_, f) => { let s = 0, n = 0; for (let k = Math.max(0, f - 3); k <= Math.min(asp.length - 1, f + 3); k++) { s += asp[k]; n++; } return s / n; }); asp.splice(0, asp.length, ...sm); }   // 7 幀平均：幅度調小之後，谷底被逐幀雜訊拉偏（週期標準差 0.17 秒），先平滑再找
    const mins = [], maxs = []; for (let f = 2; f < asp.length - 2; f++) { if (asp[f] < asp[f - 1] && asp[f] <= asp[f + 1] && asp[f] < asp[f - 2] && asp[f] <= asp[f + 2]) mins.push(f); if (asp[f] > asp[f - 1] && asp[f] >= asp[f + 1] && asp[f] > asp[f - 2] && asp[f] >= asp[f + 2]) maxs.push(f); }
    const sig = (arr, keep) => { const o = []; for (const f of arr) if (!o.length || f - o[o.length - 1] > 60) o.push(f); else if (keep(f, o[o.length - 1])) o[o.length - 1] = f; return o; };
    const lo = sig(mins, (a, b) => asp[a] < asp[b]), hi = sig(maxs, (a, b) => asp[a] > asp[b]);
    const per = []; for (let k = 2; k < lo.length; k++) per.push((lo[k] - lo[k - 1]) * DT);   // 第一個週期是起步的過渡，不算
    const pm = per.reduce((s, x) => s + x, 0) / Math.max(1, per.length), ps = Math.sqrt(per.reduce((s, x) => s + (x - pm) ** 2, 0) / Math.max(1, per.length));
    const share = []; for (const m of lo) { const h = hi.filter(x => x < m).pop(); if (h !== undefined) share.push((m - h) * DT / pm); }
    const tail = asp.slice(120), cyt = cy.slice(120);
    res.T20_jelly = { contractions: lo.length, periodMean: +pm.toFixed(3), periodStd: +ps.toFixed(3), aspectSwing: +((Math.max(...tail) - Math.min(...tail)) / Math.max(...tail)).toFixed(3),
      contractShare: +(share.reduce((s, x) => s + x, 0) / Math.max(1, share.length)).toFixed(2), liftPt: +(Math.max(...cyt) - Math.min(...cyt)).toFixed(1) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T21 拉很長（2026-11-01 多米：拖拉時沒辦法拖很長，要能自由塑形）：抓身體最下面往下拉 2.5R（1 秒）、停 0.5 秒放手，
  //     量握著、放手後 0.5 秒與 3 秒最下面比原本多出幾個 R，過程與之後零自交、面積回來。往右拉在手機寬度會先撞到畫面邊，所以往下
  { const clock = saveClock(); Math.random = seeded(20261106); resetAligned(1e9); nextTwitch = 1e9;
    const reach = () => { let b = -1e9; for (const i of bnd) b = Math.max(b, Y[i]); return b; };
    let bi = -1; for (const i of bnd) if (bi < 0 || Y[i] > Y[bi]) bi = i;
    const r0 = reach(), sx = X[bi], sy = Y[bi] - R * 0.15; let worst = 0; ev('pointerdown', 1, sx, sy);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx, sy + R * 2.5 * k / 60); steps(1); worst = Math.max(worst, selfX()); }
    for (let k = 0; k < 30; k++) { steps(1); worst = Math.max(worst, selfX()); }
    const held = reach() - r0; ev('pointerup', 1, sx, sy + R * 2.5); steps(30); const a05 = reach() - r0; steps(150); const a3 = reach() - r0;
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T21_longPull = { heldR: +(held / R).toFixed(2), after05sR: +(a05 / R).toFixed(2), after3sR: +(a3 / R).toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T22 攤平（肉餅）：兩指抓左右兩邊各往外拉 0.9R（1 秒）、停 1 秒放手，量放手後 1 秒的寬高比（原本的倍數），零自交、面積回來。
  //     懸空的身體往下壓沒東西頂著，只會把頂端推進身體裡，所以用兩指攤開量
  { const clock = saveClock(); Math.random = seeded(20261107); resetAligned(1e9); nextTwitch = 1e9;
    const aspect = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return (x1 - x0) / (y1 - y0); };
    const a0 = aspect(), [lx, ly] = edgeX(-1), [rx, ry] = edgeX(1); let worst = 0; ev('pointerdown', 1, lx, ly); ev('pointerdown', 2, rx, ry);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, lx - R * 0.9 * k / 60, ly); ev('pointermove', 2, rx + R * 0.9 * k / 60, ry); steps(1); worst = Math.max(worst, selfX()); }
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); }
    const held = aspect() / a0; ev('pointerup', 1, lx - R * 0.9, ly); ev('pointerup', 2, rx + R * 0.9, ry); steps(60); const a1 = aspect() / a0;
    for (let k = 0; k < 120; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T22_flatten = { heldAspectX: +held.toFixed(2), after1sAspectX: +a1.toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T23 一壓就攤平（2026-11-01 多米想看看）：單指按在頂端往內 0.15R、往下壓 1R（1 秒）、停 1 秒放手，
  //     量握著與放手 1 秒的寬高比（原本的倍數）、握著時最低點有沒有穿過桌面（點）、零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261108); resetAligned(1e9, { pressFlat: 1 }); nextTwitch = 1e9;   // v2.12 起預設關，打開來測機制還在
    const box = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return [x0, x1, y0, y1]; };
    const b0 = box(), a0 = (b0[1] - b0[0]) / (b0[3] - b0[2]); let top = -1; for (const i of bnd) if (top < 0 || Y[i] < Y[top]) top = i;
    const sx = X[top], sy = Y[top] + R * 0.15; let worst = 0, below = 0; ev('pointerdown', 1, sx, sy);
    for (let k = 1; k <= 60; k++) { ev('pointermove', 1, sx, sy + R * k / 60); steps(1); worst = Math.max(worst, selfX()); below = Math.max(below, box()[3] - b0[3]); }
    for (let k = 0; k < 60; k++) { steps(1); worst = Math.max(worst, selfX()); below = Math.max(below, box()[3] - b0[3]); }
    const bh = box(), held = ((bh[1] - bh[0]) / (bh[3] - bh[2])) / a0; ev('pointerup', 1, sx, sy + R); steps(60);
    const b1 = box(), a1 = ((b1[1] - b1[0]) / (b1[3] - b1[2])) / a0; for (let k = 0; k < 120; k++) { steps(1); worst = Math.max(worst, selfX()); }
    res.T23_pressFlat = { heldAspectX: +held.toFixed(2), after1sAspectX: +a1.toFixed(2), floorPassPt: +below.toFixed(1), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T24 拉長再從中間拖過身體（2026-11-01 多米：交叉時像快壞掉）：往下拉 2.5R、放手 0.3 秒，抓那條的中間往左上拖過身體（1 秒）、停 0.5 秒放手。
  //     逐幀數自交，ringGuard 開／關各跑一次比
  { const clock = saveClock();
    function crossRun(guard) { Math.random = seeded(20261109); resetAligned(1e9, { ringGuard: guard }); nextTwitch = 1e9;
      let bi = -1; for (const i of bnd) if (bi < 0 || Y[i] > Y[bi]) bi = i; const sx = X[bi], sy = Y[bi] - R * 0.15; let during = 0, frames = 0;
      ev('pointerdown', 1, sx, sy); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, sx, sy + R * 2.5 * k / 40); steps(1); } ev('pointerup', 1, sx, sy + R * 2.5); steps(18);
      const my = sy + R * 1.4; let xs = []; for (const i of bnd) if (Math.abs(Y[i] - my) < R * 0.2) xs.push(X[i]); const mx = xs.length ? (Math.min(...xs) + Math.max(...xs)) / 2 : sx;
      ev('pointerdown', 1, mx, my);
      for (let k = 1; k <= 60; k++) { ev('pointermove', 1, mx - R * 1.6 * k / 60, my - R * 2.6 * k / 60); steps(1); const c = selfX(); during = Math.max(during, c); if (c) frames++; }
      for (let k = 0; k < 30; k++) { steps(1); const c = selfX(); during = Math.max(during, c); if (c) frames++; }
      ev('pointerup', 1, mx - R * 1.6, my - R * 2.6); let after = 0; for (let k = 0; k < 120; k++) { steps(1); const c = selfX(); after = Math.max(after, c); if (c) frames++; }
      log.splice(0); return { worstDuring: during, worstAfter: after, crossFrames: frames, end: snap() }; }
    res.T24_dragAcross = { guard: crossRun(1), noGuard: crossRun(0) };
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T25 按在畫面邊停住（v2.15 改）：v2.12 起停著的手指會跟著鏡頭在世界裡往外跑、形狀一直長，那就是多米 build 61 回報的抽搐來源。
  //     現在抓身體最右邊拖到畫面右緣停 3 秒：伸出去要有（鏡頭有退），停著的 3 秒形狀不能自己再長；放手後鏡頭跟著拉回來、零自交
  { const clock = saveClock(); Math.random = seeded(20261110); resetAligned(1e9); nextTwitch = 1e9;
    const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
    let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const e0 = X[b], sx = X[b] - R * 0.15, sy = Y[b]; let worst = 0, zMin = 1;
    ev('pointerdown', 1, sx, sy); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, sx + (W - 12 - sx) * k / 40, sy); steps(1); worst = Math.max(worst, selfX()); }
    steps(30); const w1 = wd();
    for (let k = 0; k < 150; k++) { steps(1); worst = Math.max(worst, selfX()); zMin = Math.min(zMin, CAM.z); }
    const w2 = wd(); let e1 = -1e9; for (const i of bnd) e1 = Math.max(e1, X[i]); ev('pointerup', 1, W - 12, sy);
    for (let k = 0; k < 720; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
    res.T25_edgeHold = { reachR: +((e1 - e0) / R).toFixed(2), grewWhileStillR: +(w2 - w1).toFixed(2), zoomMin: +zMin.toFixed(2), zoomAfter12s: +CAM.z.toFixed(2), worstSelfX: worst, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T26 鏡頭無限拉遠（v2.13 起；v2.15 改成重複抓）：手指停著不再自己拉長，要拉更長就放手、抓住最右端再拉，拉 6 次。
  //     手指從那一端拖到畫面右緣（手指出不了螢幕），每次停 1 秒帶一點手抖（±0.6 點）。量最長幾個 R、鏡頭縮到多少、整隻每幀都在畫面裡、按著時邊界每幀最大跳動（螢幕點），
  //     放手後零交叉。黏土拉伸 7R、記形 5R：超過約 8.5R 會抖（v2.15 量過拉到 9.5R 跳 13 到 22 點、交叉）
  //     跳動門檻 5 點（原本 3）：2026-11-03 同一套物理換 8 組手抖（種子），量到 1.18 到 4.21 點，3 點卡在正常範圍中間；真的抖是 13 點以上
  { const clock = saveClock(); Math.random = seeded(20261113); resetAligned(1e9); nextTwitch = 1e9;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    let wMax = 0, zMin = 1, off = 0, holdX = 0, worstRel = 0, jMax = 0;
    for (let r = 0; r < 6; r++) {
      let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const wx = X[b] - R * 0.15, wy = Y[b];
      let [qx, qy] = sc(wx, wy); ev('pointerdown', 1, qx, qy); const f = [...fingers.values()][0];
      const q0 = qx; for (let k = 1; k <= 45; k++) { qx = q0 + (W - 12 - q0) * k / 45; ev('pointermove', 1, qx, qy); steps(1); }
      let prev = null, prev2 = null;
      for (let k = 0; k < 60; k++) { ev('pointermove', 1, qx + (Math.random() - 0.5) * 1.2, qy + (Math.random() - 0.5) * 1.2); steps(1);
        const cur = bnd.map(i => sc(X[i], Y[i]));
        if (prev2) for (let m = 0; m < cur.length; m++) jMax = Math.max(jMax, Math.hypot(cur[m][0] - 2 * prev[m][0] + prev2[m][0], cur[m][1] - 2 * prev[m][1] + prev2[m][1]));
        prev2 = prev; prev = cur; if (k % 3 === 0 && selfX()) holdX++;
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); }
        wMax = Math.max(wMax, (x1 - x0) / R); zMin = Math.min(zMin, CAM.z);
        const a = sc(x0, y0), c = sc(x1, y1); if (a[0] < 0 || c[0] > W || a[1] < 0 || c[1] > H) off++; }
      ev('pointerup', 1, qx, qy); for (let k = 0; k < 60; k++) { steps(1); if (k % 6 === 0) worstRel = Math.max(worstRel, selfX()); }
    }
    for (let k = 0; k < 600; k++) { steps(1); if (k % 10 === 0) worstRel = Math.max(worstRel, selfX()); }
    res.T26_zoomUnlimited = { widthMaxR: +wMax.toFixed(2), zoomMin: +zMin.toFixed(2), offScreenFrames: off, holdCrossFrames: holdX, jitterMaxPt: +jMax.toFixed(2), worstReleaseX: worstRel, end: snap() }; log.splice(0);
    restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T29 手指停住不抖（v2.15，多米 build 61：拉到某個程度會抽搐）：抓最右邊往右拉 1、2、3R 各停 2 秒帶手抖，形狀不能自己長、邊界每幀最大跳動
  { const clock = saveClock(); const r29 = [];
    for (const d of [1, 2, 3]) { Math.random = seeded(20261116 + d); resetAligned(1e9); nextTwitch = 1e9;
      const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
      let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const wx = X[b] - R * 0.15, wy = Y[b];
      let [qx, qy] = sc(wx, wy); ev('pointerdown', 1, qx, qy); const f = [...fingers.values()][0];
      for (let k = 1; k <= 60; k++) { qx += (wx + d * R * k / 60 - f.x) * CAM.z; ev('pointermove', 1, qx, qy); steps(1); }
      steps(30); const w1 = wd(); let prev = null, prev2 = null, jMax = 0, xf = 0;
      for (let k = 0; k < 120; k++) { ev('pointermove', 1, qx + (Math.random() - 0.5) * 1.2, qy + (Math.random() - 0.5) * 1.2); steps(1);
        const cur = bnd.map(i => sc(X[i], Y[i]));
        if (prev2) for (let m = 0; m < cur.length; m++) jMax = Math.max(jMax, Math.hypot(cur[m][0] - 2 * prev[m][0] + prev2[m][0], cur[m][1] - 2 * prev[m][1] + prev2[m][1]));
        prev2 = prev; prev = cur; if (selfX()) xf++; }
      r29.push({ pullR: d, widthR: +wd().toFixed(2), grewR: +(wd() - w1).toFixed(2), jitterMaxPt: +jMax.toFixed(2), crossFrames: xf }); ev('pointerup', 1, qx, qy); steps(30); }
    res.T29_stillFinger = r29; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T30 點一下留凹痕（v2.15，多米 build 61：單純點一下也要有效果，也許是出現凹陷）：點身體中間 0.1 秒，凹痕要出現；放手 15 秒還看得到、淡了一些；
  //     按住拉開 1R 的那次凹痕要收掉
  { const clock = saveClock(); Math.random = seeded(20261117); resetAligned(1e9); nextTwitch = 1e9;
    const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(6); const dHeld = DENTS.length ? DENTS[DENTS.length - 1].d : 0; ev('pointerup', 1, cx, cy);
    steps(60); const d1 = DENTS.length ? DENTS[0].d : 0; steps(840); const d15 = DENTS.length ? DENTS[0].d : 0;
    resetAligned(1e9); nextTwitch = 1e9; ev('pointerdown', 1, cx, cy); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx + R * k / 30, cy); steps(1); } steps(30);
    ev('pointerup', 1, cx + R, cy); steps(60);
    res.T30_dent = { heldDepth: +dHeld.toFixed(2), after1s: +d1.toFixed(2), after15s: +d15.toFixed(2), dentsAfterPull: DENTS.length, end: snap() };
    log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T31 按壓（v2.16，多米：按壓動畫像兒戲）：黏土按住身體中間 0.8 秒，整團面積要變大 4% 到 15%（press2=0 是 1.00）；按 3 秒跟 1.5 秒比，
  //     最遠位移不能一直長（黏土記下推開的形狀、再推一次的話會一直攤開）；放手 1 秒凹痕還在。果凍放手要過頭往外彈（p 掉到負的）、1 秒內收乾淨。全程零自交
  { const clock = saveClock(); Math.random = seeded(20261118); const r31 = {}; let xf = 0;
    const hold = (over, n) => { resetAligned(1e9, over); nextTwitch = 1e9; const cx = globalC.xc, cy = globalC.yc, a0 = area(), ref = [Float64Array.from(X), Float64Array.from(Y)];
      ev('pointerdown', 1, cx, cy); const mv = []; let am = 0; for (let k = 1; k <= n; k++) { steps(1); if (classify()[0]) xf++; if (k === 48) am = area() / a0; if (k === 90 || k === 180) mv.push(maxMove(ref)); }
      return { cx, cy, a0, am, mv }; };
    { const h = hold({}, 180); r31.clayArea08 = +h.am.toFixed(3); r31.clayMove15 = +h.mv[0].toFixed(1); r31.clayMove3 = +h.mv[1].toFixed(1);
      ev('pointerup', 1, h.cx, h.cy); steps(60); r31.clayDent1s = DENTS.length ? +DENTS[DENTS.length - 1].d.toFixed(2) : 0; }
    { const h = hold({ press2: 0 }, 48); r31.offArea08 = +h.am.toFixed(3); ev('pointerup', 1, h.cx, h.cy); steps(30); }
    { const h = hold({ ...PRESETS.jelly }, 48); ev('pointerup', 1, h.cx, h.cy); let pMin = 1; for (let k = 0; k < 60; k++) { steps(1); if (classify()[0]) xf++; for (const dn of DENTS) pMin = Math.min(pMin, dn.p); }
      r31.jellyArea08 = +h.am.toFixed(3); r31.jellyOvershoot = +pMin.toFixed(2); r31.jellyDentsAfter1s = DENTS.length; }
    r31.foldFrames = xf; r31.end = snap();
    res.T31_press = r31; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T32 開場與鏡頭跟隨（v2.17，多米：打開時從遠處一跳一跳跑過來；鏡頭不要釘在中間，史萊姆會跑出畫面，鏡頭慢慢跟）：
  //     開場要落地 4 次、落地那幾幀高寬比壓到平常的 0.9 以下、3.2 秒內結束、全程零對折、結束後面積回來；途中碰一下直接到家（0.5 秒內大小回到 1）；
  //     家往右移 0.6 個畫面寬：身體要有一段跑出畫面、4 秒後鏡頭追到 followStop 附近（v2.18 起不拉回正中間）；抓著時鏡頭不動
  { const clock = saveClock(); Math.random = seeded(20261119); const r32 = {}; let xf = 0;
    const asp = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); y1 = Math.max(y1, Y[i]); } return (y1 - y0) / (x1 - x0); };
    resetAligned(1e9); nextTwitch = 1e9; const a0 = asp(); startIntro(); let lands = 0, prev = INTRO.ph, minA = 9, fr = 0;
    while (INTRO.on && fr < 600) { steps(1); fr++; if (classify()[0]) xf++; if (INTRO.ph === 'land' && prev !== 'land') lands++; if (INTRO.ph === 'land') minA = Math.min(minA, asp()); prev = INTRO.ph; }
    steps(120); r32.introLands = lands; r32.introSec = +(fr / 60).toFixed(2); r32.landAspect = +(minA / a0).toFixed(2); r32.afterIntro = snap();
    resetAligned(1e9); nextTwitch = 1e9; startIntro(); steps(40); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 2, cx, cy); ev('pointerup', 2, cx, cy); }
    steps(30); r32.skipOff = !INTRO.on; r32.skipScale = +IV.s.toFixed(3); r32.skipFingers = fingers.size;
    resetAligned(1e9); nextTwitch = 1e9; WANDER.next = 1e9; const v = viewV(), H0 = HOMEX, half = (W - 16) / 2; let outMax = -1e9;
    for (let k = 1; k <= 240; k++) { HOMEX = H0 + W * 0.6 * Math.min(1, k / 150); steps(1); if (classify()[0]) xf++; let x1 = -1e9; for (const i of bnd) x1 = Math.max(x1, (X[i] - CAM.x) * CAM.z + v.x); outMax = Math.max(outMax, x1 - W); }
    r32.followOutPt = +outMax.toFixed(0); r32.followEndOff = +(Math.abs((globalC.xc - CAM.x) * CAM.z) / half).toFixed(2);
    { const cx = (globalC.xc - CAM.x) * CAM.z + v.x, cy = (globalC.yc - CAM.y) * CAM.z + v.y, c0 = CAM.x; ev('pointerdown', 3, cx, cy); steps(60); r32.grabCamMovePt = +Math.abs(CAM.x - c0).toFixed(2); ev('pointerup', 3, cx, cy); steps(60); }
    r32.foldFrames = xf; r32.end = snap();
    res.T32_introFollow = r32; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T33 情緒（v2.18，多米：被拉扯想逃、舒服時呼嚕；v2.61 D1 改成快扯會逃、慢拉不會）：抓右緣用 0.15 秒往右扯 2.2R（每秒約 15R）撐到 2 秒，想逃要滿（strain > 0.8）、舒服掉到負的；放手要開始逃、
  //     2.5 秒後家往左（拉的反方向）移超過 0.4 個畫面寬。中間輕揉 2.5 秒（半徑 0.25R 的小圈），舒服 > 0.3、呼嚕 > 0.3，放手要開心小跳。
  //     1 秒內戳 3 下要閃開（2 秒後移超過 0.15 個畫面寬）。全程零對折、逃完面積回來
  { const clock = saveClock(); Math.random = seeded(20261120); const r33 = {}; let xf = 0; const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b], h0 = HOMEX;
    let q = sc(sx, sy), sMax = 0; ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);   // 手指用累加位移（鏡頭拉的時候會動，世界換螢幕會讓手指退回來）
    for (let k = 1; k <= 120; k++) { const tx = sx + 2.2 * R * Math.min(1, k / 9); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; sMax = Math.max(sMax, MOOD.strain); }
    r33.strainHeld = +sMax.toFixed(2); r33.moodPulled = +MOOD.c.toFixed(2); ev('pointerup', 1, q[0], q[1]); r33.fleeStarted = ESC.on;
    for (let k = 0; k < 150; k++) { steps(1); if (classify()[0]) xf++; } r33.fledW = +((h0 - HOMEX) / W).toFixed(2); steps(120); r33.afterFlee = snap();
    // v2.61 D1（rough）：同一個拉法慢慢拉（2 秒拉 2.2R、停 1 秒）：不想逃、不紅、不加戒、沒脫手；rough 0 照舊會逃（證明量得到）。快扯停 0.1 秒、扯著就放：熟、戒都不動
    const drag33 = (o, frames, hold) => { resetAligned(1e9, { emo: 1, imp: 1, e3: 1, moodColor: .8, ...o }); impReset(); nextTwitch = 1e9; MOOD.strainMax = 0; MC.s = 0; let bi = -1; for (const i of bnd) if (bi < 0 || X[i] > X[bi]) bi = i; const ax = X[bi] - R * 0.15, ay = Y[bi]; let p = sc(ax, ay), sm = 0, red = 0; ev('pointerdown', 1, p[0], p[1]); const f = fingers.get(1);
      for (let k = 1; k <= frames + hold; k++) { const tx = ax + 2.2 * R * Math.min(1, k / frames); p = [p[0] + (tx - f.x) * CAM.z, p[1] + (ay - f.y) * CAM.z]; ev('pointermove', 1, p[0], p[1]); steps(1); if (classify()[0]) xf++; sm = Math.max(sm, MOOD.strain); red = Math.max(red, MC.s); }
      const held = fingers.get(1) === f && f.mode === 'grab', vm = f.vMax || 0; ev('pointerup', 1, p[0], p[1]); const o33 = { strain: +sm.toFixed(2), red: +red.toFixed(2), flee: ESC.on, held, w: +IMP.w.toFixed(3), tr: +IMP.tr.toFixed(3), vMax: +vm.toFixed(1) }; ESC.on = false; steps(30); return o33; };
    r33.slow = drag33({}, 120, 60); r33.slowOld = drag33({ rough: 0 }, 120, 60); r33.yankStop = drag33({}, 9, 6); r33.yankGo = drag33({}, 9, 0);
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; { const cx = globalC.xc, cy = globalC.yc; let pMax = 0, cMax = 0; q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]);
      for (let k = 1; k <= 150; k++) { const a = 2 * Math.PI * 0.5 * k / 60; q = sc(cx + R * 0.25 * Math.sin(a), cy + R * 0.25 * (1 - Math.cos(a))); ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; pMax = Math.max(pMax, PURR); cMax = Math.max(cMax, MOOD.c); }
      ev('pointerup', 1, q[0], q[1]); r33.purrMax = +pMax.toFixed(2); r33.comfortMax = +cMax.toFixed(2); r33.happyHop = INTRO.on && !!INTRO.mini; for (let k = 0; k < 90; k++) { steps(1); if (classify()[0]) xf++; } }
    resetAligned(1e9, { emo: 1 }); nextTwitch = 1e9; { const h1x = HOMEX, h1y = HOMEY, cx = globalC.xc + R * 0.2, cy = globalC.yc; q = sc(cx, cy);
      for (let n = 0; n < 3; n++) { ev('pointerdown', 1, q[0], q[1]); steps(5); ev('pointerup', 1, q[0], q[1]); steps(10); }
      r33.dartStarted = ESC.on; for (let k = 0; k < 120; k++) { steps(1); if (classify()[0]) xf++; } r33.dartW = +(Math.hypot(HOMEX - h1x, HOMEY - h1y) / W).toFixed(2); }
    r33.foldFrames = xf; r33.end = snap();
    res.T33_mood = r33; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T34 活物感（v2.19，多米 build 73：沒有活物感、不像生物）。a 放著不碰 120 秒：休息（沒走、沒探）佔 0.35 到 0.65（v2.18 量到 0.02），有探有走，零自交、面積不漂；
  //     b 按住中間 4 秒：呼吸還在（寬高比起伏是沒碰時的 0.35 以上，lifeHeld 0 時 0.15 以下）；放手 1 秒記形偏移不比 lifeHeld 0 多 1pt 以上（呼吸沒被記進形狀）；
  //     c 晚一拍才縮：按下 0.05 秒面積跟 lifeFlinch 0 差不到 1.5%、0.3 秒時小 4% 以上；連按 5 下（間隔 0.6 秒），第 5 下不到第 1 下的三成；
  //     d 一縮一衝：叫它往右走 1.5 個畫面寬，八成以上的下速度高峰落在這一下開始 0.35 秒內（收縮推它走），方向有變（最大減最小 > 8 度），停在目標 0.5R 內，零自交、面積不漂；
  //     e 碰它右邊 1.8R 的空白處：0.6 秒內有一條偽足朝右（30 度內），按著時呼吸縮放還在變（沒凍住）；
  //     f 抓右緣拉 1.6R 放手：0.25 到 0.45 秒開始甩、0.4 到 0.8 秒往手指離開的方向探（30 度內）。全程零對折
  { const clock = saveClock(); Math.random = seeded(20261121); const r34 = {}; let xf = 0;
    const L2 = o => resetAligned(1e9, { life2: 1, ...o });
    const aspect = () => { let mx = 0, my = 0; for (const i of bnd) { mx += X[i]; my += Y[i]; } mx /= bnd.length; my /= bnd.length; const ga = Math.atan2(globalC.sn, globalC.cs), gc = Math.cos(ga), gs = Math.sin(ga); let ixx = 0, iyy = 0; for (const i of bnd) { const dx = X[i] - mx, dy = Y[i] - my, bx = gc * dx + gs * dy, by = -gs * dx + gc * dy; ixx += bx * bx; iyy += by * by; } return Math.sqrt(ixx / iyy); };
    { L2({ emo: 1 }); const S = { rest: 0, look: 0, go: 0, arrive: 0 }, seen = new Set(); let goes = 0, prev = '', worst = 0, minA = 9, maxA = 0;
      for (let f = 0; f < 7200; f++) { steps(1); S[LIFE.st]++; if (LIFE.st === 'go' && prev !== 'go') goes++; prev = LIFE.st; for (const s of LIFE.sns) seen.add(s);
        if (f % 20 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      r34.idle = { restFrac: +(S.rest / 7200).toFixed(2), lookFrac: +(S.look / 7200).toFixed(2), goFrac: +(S.go / 7200).toFixed(2), goes, sniffs: seen.size, worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) }; }
    const held = o => { L2({ pods: 0, wriggle: 0, ...o }); LIFE.until = 1e9; let lo = 9, hi = 0; for (let k = 0; k < 360; k++) { steps(1); const a = aspect(); lo = Math.min(lo, a); hi = Math.max(hi, a); } const idle = hi - lo;
      const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(60); lo = 9; hi = 0; for (let k = 0; k < 240; k++) { steps(1); if (classify()[0]) xf++; const a = aspect(); lo = Math.min(lo, a); hi = Math.max(hi, a); }
      ev('pointerup', 1, cx, cy); steps(60); return { ratio: +((hi - lo) / idle).toFixed(2), qdev1s: +qdev().toFixed(2) }; };
    { const on = held({}), off = held({ lifeHeld: 0 }); r34.held = { ratio: on.ratio, ratioOff: off.ratio, qdev1s: on.qdev1s, qdev1sOff: off.qdev1s }; }
    const tapA = o => { L2(o); LIFE.until = 1e9; const cx = globalC.xc, cy = globalC.yc, a0 = area(); ev('pointerdown', 1, cx, cy); steps(3); const a05 = area() / a0; steps(15); const a30 = area() / a0; ev('pointerup', 1, cx, cy); steps(60); return { a05, a30 }; };
    { const on = tapA({}), off = tapA({ lifeFlinch: 0 }); L2({}); LIFE.until = 1e9; const amps = [], cx = globalC.xc, cy = globalC.yc;
      for (let n = 0; n < 5; n++) { ev('pointerdown', 1, cx, cy); steps(6); ev('pointerup', 1, cx, cy); steps(30); amps.push(FLN.last); }
      r34.flinch = { at05: +(on.a05 / off.a05).toFixed(3), at30: +(on.a30 / off.a30).toFixed(3), fifthOverFirst: +(amps[4] / amps[0]).toFixed(2) }; }
    { L2({ dash: 0 }); LIFE.until = 1e9; const tx = HOMEX + W * 1.5, ty = HOMEY; Object.assign(GAIT, { on: true, tx, ty, dash: false, ph: -1, prep: 0, v: 0, h: 0, k: 1, str: 1, last: false, off: 0 }); LIFE.st = 'go'; WANDER.moving = true;
      const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
      let [px, py] = cen(), fr = 0, cur = null, lastPh = -2, worst = 0, minA = 9, maxA = 0; const st = [];
      while ((GAIT.on || LIFE.st === 'arrive') && fr < 1800) { steps(1); fr++; const [x, y] = cen(), v = Math.hypot(x - px, y - py) / DT / R; px = x; py = y;
        if (GAIT.on && GAIT.ph >= 0) { if (cur === null || GAIT.ph < lastPh) { cur = { v: 0, ph: 0, h: GAIT.h }; st.push(cur); } lastPh = GAIT.ph; if (v > cur.v) { cur.v = v; cur.ph = GAIT.ph; } }
        if (fr % 6 === 0) { worst = Math.max(worst, selfX()); const a = area() / A0; minA = Math.min(minA, a); maxA = Math.max(maxA, a); } }
      const hs = st.map(s => s.h * 180 / Math.PI);
      r34.gait = { strokes: st.length, peakInContraction: +(st.filter(s => s.ph <= 0.35).length / Math.max(1, st.length)).toFixed(2), peakSpeedR: +Math.max(...st.map(s => s.v)).toFixed(2), headingSpreadDeg: +(Math.max(...hs) - Math.min(...hs)).toFixed(0), endDistR: +(Math.hypot(HOMEX - tx, HOMEY - ty) / R).toFixed(2), sec: +(fr / 60).toFixed(1), worstSelfX: worst, areaMin: +minA.toFixed(3), areaMax: +maxA.toFixed(3) }; }
    { L2({}); LIFE.until = 1e9; const bx = globalC.xc + 1.8 * R, by = globalC.yc; ev('pointerdown', 4, bx, by); let best = 0, ang = 180, lo = 9, hi = 0;
      for (let k = 0; k < 120; k++) { steps(1); lo = Math.min(lo, PSM[3]); hi = Math.max(hi, PSM[3]); if (k < 36) for (const s of LIFE.sns) { const e = sniffEnv(s); if (e > best) { best = e; ang = Math.abs(Math.atan2(Math.sin(s.a), Math.cos(s.a))) * 180 / Math.PI; } } }
      ev('pointerup', 4, bx, by); r34.blank = { sniffEnv06s: +best.toFixed(2), angDeg: +ang.toFixed(0), breathRange: +(hi - lo).toFixed(4) }; }
    { L2({}); LIFE.until = 1e9; let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b], v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);   // 手指用累加位移（鏡頭會動）
      for (let k = 1; k <= 60; k++) { const tx = sx + 1.6 * R * Math.min(1, k / 30); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      const t0 = t; ev('pointerup', 1, q[0], q[1]); let att = -1, attAng = 180;
      for (let k = 0; k < 90; k++) { steps(1); if (classify()[0]) xf++; if (att < 0) for (const s of LIFE.sns) if (sniffEnv(s) > 0.05) { att = t - t0; attAng = Math.abs(Math.atan2(Math.sin(s.a), Math.cos(s.a))) * 180 / Math.PI; } }
      r34.release = { shakeAt: +(SHK.t0 - t0).toFixed(2), attendAt: +att.toFixed(2), attendAngDeg: +attAng.toFixed(0), end: snap() }; }
    r34.foldFrames = xf;
    res.T34_life = r34; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T35 v2.20（多米 build 75：拖的時候只有形變沒有位移；點它的凹回復太久；沒有跟人互動的感覺）。舊項目一律關 v2.20（PRESETS.clay 在最上面換成 OFF220），這裡打開。
  //     a D1 抓右緣往右拉 2R 停 1 秒：重心跟過去 0.55R 到 0.85R（drag 0 不到 0.1R）；被抓那端跟手指的距離跟 drag 0 差不到 0.3R；放手 2 秒往回退不到 0.1R，
  //       面積不比 drag 0 多 1%（黏土拉 2R 放手 2 秒面積本來就還沒回來，drag 0 量到 1.035）；
  //     b D2 點一下 0.12 秒：放手 0.6 秒凹痕 < 0.05；按 1 秒：放手 1.5 秒 < 0.05；捏走的形狀跟 dentFade 10 差不到 0.5pt；
  //     c 印象：輕揉 6 秒熟漲 0.1 以上；扯到想逃戒漲 0.2 以上；不碰 3 分鐘戒剩一半（0.45 到 0.55）；
  //     d C1 熟 0.8、手指停在右邊 2R：6 秒內偽足或身體碰到手指；戒 0.8、手指停在右邊 0.8R：5 秒後離手指遠 0.5R 以上；
  //     e C2 熟 0.5、手指在右邊 2.5R 慢慢往下移 1.5 秒再停：停下 0.5 秒內撲；不熟時手指快甩過去：嚇一下（縮）；
  //     f C4 輕揉 2.5 秒放手：排了討摸，5 秒內再揉呼嚕 0.6 秒內來（第一次 1 秒以上）；g C5 戒 0.8 時被碰縮的量是戒 0 的 1.5 倍以上。全程零對折
  { const clock = saveClock(); Math.random = seeded(20261102); const r35 = {}; let xf = 0;
    const V20 = { slide: 0, drag: P0.drag, dentFade: P0.dentFade, imp: 1, life2: 1 };
    const L3 = o => { resetAligned(1e9, { ...V20, ...o }); impReset(); LIFE.st = 'rest'; LIFE.until = 1e9; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const edgeTo = (x, y) => { let d = 1e9; for (const i of bnd) d = Math.min(d, Math.hypot(X[i] - x, Y[i] - y)); return d; };
    const rightPt = () => { let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; return b; };
    const rub = (id, frames) => { const cx = globalC.xc + R * 0.3, cy = globalC.yc; let q = sc(cx, cy); ev('pointerdown', id, q[0], q[1]); const f = fingers.get(id);
      let tp = -1; for (let k = 0; k < frames; k++) { const tx = cx + Math.sin(k / 16) * R * 0.25; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', id, q[0], q[1]); steps(1); if (classify()[0]) xf++; if (tp < 0 && PURR > 0.2) tp = k / 60; }
      ev('pointerup', id, q[0], q[1]); return tp; };
    // a 拖著走
    const pull = o => { L3(o); const c0 = cen(), b = rightPt(), sx = X[b] - R * 0.15, sy = Y[b]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);
      for (let k = 1; k <= 90; k++) { const tx = sx + 2 * R * Math.min(1, k / 30); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      const c1 = cen(), gap = (f1.fx - X[b]) / R; ev('pointerup', 1, q[0], q[1]); let worst = 0; for (let k = 0; k < 120; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      const c2 = cen(); return { followR: +((c1[0] - c0[0]) / R).toFixed(2), grabGapR: +gap.toFixed(2), backAfter2sR: +((c1[0] - c2[0]) / R).toFixed(2), worstSelfX: worst, end: snap() }; };
    { const on = pull({}), off = pull({ drag: 0 }); r35.drag = { on, off }; }
    // b 凹痕
    const dent = (o, hold, wait) => { L3({ imp: 0, ...o }); const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 2, cx, cy); steps(hold); ev('pointerup', 2, cx, cy);
      const dn = DENTS[DENTS.length - 1]; steps(wait); return { d: DENTS.includes(dn) ? +dn.d.toFixed(3) : 0, qdev: qdev() }; };
    { const tap = dent({}, 7, 36), hold = dent({}, 60, 90), tapOld = dent({ dentFade: 10 }, 7, 36);
      r35.dent = { tapAt06: tap.d, holdAt15: hold.d, tapOldAt06: tapOld.d, qdevDiffPt: +Math.abs(tap.qdev - tapOld.qdev).toFixed(2) }; }
    // c 印象怎麼漲、怎麼退
    { L3({ emo: 1 }); rub(3, 360); const trRub = IMP.tr; L3({ emo: 1, rough: 0 }); /* v2.61 D1：慢拉、快扯都不加戒了，這裡量的是戒怎麼退，用舊規則加 */ const b = rightPt(), sx = X[b] - R * 0.15, sy = Y[b]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f1 = fingers.get(1);
      for (let k = 1; k <= 150; k++) { const tx = sx + 3 * R * Math.min(1, k / 20); q = [q[0] + (tx - f1.x) * CAM.z, q[1] + (sy - f1.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      ev('pointerup', 1, q[0], q[1]); steps(30); const wPull = IMP.w; impStep(180); r35.imp = { trAfterRub6s: +trRub.toFixed(2), wAfterStrain: +wPull.toFixed(2), wAfter3minRatio: +(IMP.w / wPull).toFixed(2) }; impReset(); }
    // d C1 手指停在旁邊
    { L3({}); IMP.tr = 0.8; const b = rightPt(), fx = X[b] + 2 * R, fy = Y[b], q = sc(fx, fy); ev('pointerdown', 5, q[0], q[1]); const f = fingers.get(5); let hit = -1, minE = 1e9;
      for (let k = 0; k < 360; k++) { steps(1); if (classify()[0]) xf++; minE = Math.min(minE, edgeTo(f.fx, f.fy)); if (hit < 0 && t - f.hitT < 0.02) hit = k / 60; }
      ev('pointerup', 5, q[0], q[1]); steps(30); const come = { hitS: +hit.toFixed(2), minEdgeR: +(minE / R).toFixed(2) };
      L3({}); IMP.w = 0.8; const b2 = rightPt(), gx = X[b2] + 0.8 * R, gy = Y[b2], q2 = sc(gx, gy), c0 = cen(); ev('pointerdown', 5, q2[0], q2[1]); for (let k = 0; k < 300; k++) { steps(1); if (classify()[0]) xf++; }
      const c1 = cen(); ev('pointerup', 5, q2[0], q2[1]); steps(30);
      r35.c1 = { come, backGainR: +((Math.hypot(gx - c1[0], gy - c1[1]) - Math.hypot(gx - c0[0], gy - c0[1])) / R).toFixed(2), end: snap() }; }
    // e C2 逗它
    { L3({}); IMP.tr = 0.5; const b = rightPt(); let q = sc(X[b] + 2.5 * R, Y[b]); ev('pointerdown', 6, q[0], q[1]);
      for (let k = 0; k < 90; k++) { q = [q[0], q[1] + R * CAM.z * 1.2 / 60]; ev('pointermove', 6, q[0], q[1]); steps(1); if (classify()[0]) xf++; }
      let pounce = -1; for (let k = 0; k < 120; k++) { steps(1); if (classify()[0]) xf++; if (pounce < 0 && LURE.pounced) pounce = k / 60; } ev('pointerup', 6, q[0], q[1]); steps(30);
      L3({}); const b2 = rightPt(); q = sc(X[b2] + 1.5 * R, Y[b2]); ev('pointerdown', 7, q[0], q[1]); steps(30); const fl0 = FLN.t0;
      for (let k = 0; k < 12; k++) { q = [q[0], q[1] + R * CAM.z * 6 / 60]; ev('pointermove', 7, q[0], q[1]); steps(1); } steps(20); const startled = FLN.t0 > fl0; ev('pointerup', 7, q[0], q[1]); steps(30);
      r35.c2 = { pounceS: +pounce.toFixed(2), startled }; }
    // f C4 討摸
    { L3({ emo: 1 }); const first = rub(8, 150); L3({ emo: 1 }); IMP.tr = 0.5; rub(8, 150); const asked = !!LIFE.ask; steps(90); const second = rub(8, 60);
      r35.c4 = { firstPurrS: +first.toFixed(2), asked, secondPurrS: +second.toFixed(2) }; }
    // g C5 戒高時縮得大
    { const fl = w => { L3({}); IMP.w = w; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(30); ev('pointerup', 1, cx, cy); steps(30); return FLN.last; };
      const a0 = fl(0), a8 = fl(0.8); r35.c5 = { flinchRatio: +(a8 / a0).toFixed(2) }; }
    r35.foldFrames = xf; impReset();
    res.T35_v220 = r35; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T36 v2.21 拉力（多米 build 77 錄影：往右下拉，史萊姆也要一併往右下靠；量過果凍拉 2.5R 整團只跟 0.56R）。
  //     a 果凍抓右下緣往右下拉 2.5R 停：整團跟過去 1.5R 以上、被拉長的量 0.9R 以下（slide 0 不到 0.7R）；b 黏土猛一扯（4 幀）那一下拉得比慢拉長 0.3R 以上；
  //     c 黏土兩指往兩邊各拉 1.5R：寬過 4.5R、整團移不到 0.2R；d 果凍往右甩 0.4 秒放手：再滑 0.3R 以上。全程零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261103); const r36 = {}; let worst = 0;
    const PS = { ...PSAVE };
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L4 = (m, o) => { resetAligned(1e9, { ...PS[m], emo: 0, life2: 0, ...o }); };
    const pullDR = (m, o, frames) => { L4(m, o); let b = -1; for (const i of bnd) if (b < 0 || X[i] + Y[i] > X[b] + Y[b]) b = i;
      const c0 = cen(), sx = X[b] - 4, sy = Y[b] - 4; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let maxSt = 0; const d = 2.5 * R / Math.SQRT2;
      for (let k = 1; k <= frames + 40; k++) { const u = Math.min(1, k / frames); q = [q[0] + (sx + d * u - f.x) * CAM.z, q[1] + (sy + d * u - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); maxSt = Math.max(maxSt, f.stretch); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      const c1 = cen(), st = f.stretch; ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      return { moveR: +(Math.hypot(c1[0] - c0[0], c1[1] - c0[1]) / R).toFixed(2), stretchR: +st.toFixed(2), maxStretchR: +maxSt.toFixed(2), end: snap() }; };
    r36.jelly = pullDR('jelly', {}, 30); r36.jellyOff = pullDR('jelly', { slide: 0 }, 30);
    r36.claySlow = pullDR('clay', {}, 30); r36.clayYank = pullDR('clay', {}, 4);
    { L4('clay', {}); let l = -1, r = -1; for (const i of bnd) { if (l < 0 || X[i] < X[l]) l = i; if (r < 0 || X[i] > X[r]) r = i; }
      const c0 = cen(), lx = X[l] + 4, ly = Y[l], rx = X[r] - 4, ry = Y[r]; let a = sc(lx, ly), b = sc(rx, ry); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); const f1 = fingers.get(1), f2 = fingers.get(2);
      for (let k = 1; k <= 70; k++) { const u = Math.min(1, k / 40) * 1.5 * R; a = [a[0] + (lx - u - f1.x) * CAM.z, a[1] + (ly - f1.y) * CAM.z]; b = [b[0] + (rx + u - f2.x) * CAM.z, b[1] + (ry - f2.y) * CAM.z]; ev('pointermove', 1, a[0], a[1]); ev('pointermove', 2, b[0], b[1]); steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      let x0 = 1e9, x1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } const c1 = cen();
      r36.twoFinger = { widthR: +((x1 - x0) / R).toFixed(2), moveR: +(Math.hypot(c1[0] - c0[0], c1[1] - c0[1]) / R).toFixed(2) };
      ev('pointerup', 1, a[0], a[1]); ev('pointerup', 2, b[0], b[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); } }
    { L4('jelly', {}); const sx = globalC.xc, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1);
      for (let k = 1; k <= 24; k++) { q = [q[0] + (sx + 4 * R * k / 60 - f.x) * CAM.z, q[1] + (sy - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); }
      const c1 = cen(); ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 90; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); } const c2 = cen();
      r36.fling = { glideR: +((c2[0] - c1[0]) / R).toFixed(2), end: snap() }; }
    r36.worstSelfX = worst;
    res.T36_pull = r36; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T37 v2.22（多米 build 77：還是沒有互動的感覺；繼續做黏液）。a 點一下：放手 0.25 到 0.45 秒開始朝手指傾、「噗」；b 按著不動 2.5 秒：左右蹭 0.03R 以上、「嗯～」；
  //     c 搔癢：扭 3 次以上、3.2 到 5 秒掙脫（撥 4 下才算開始搔癢，之後 3 秒）、有咯咯笑和「嗯嗯」；d E3 輕揉 5 秒熟過 0.5（E3 關不到 0.3）；e E4 熟 0.8、不碰 30 秒內游到前面（0.6R 內）打招呼；
  //     全程零自交（v2.29 黏液取消，f、g、h 拿掉）
  { const clock = saveClock(); Math.random = seeded(20261104); const r37 = {}; let worst = 0;
    const cen = () => { let mx = 0, my = 0; for (let i = 0; i < N; i++) { mx += X[i]; my += Y[i]; } return [mx / N, my / N]; };
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L5 = o => { resetAligned(1e9, { ...P0, emo: 0, holdTickle: 0, ...o }); impReset(); voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; LIFE.st = 'rest'; LIFE.until = 1e9; log.splice(0); };   // v2.63 D3：搔癢不掙脫（holdTickle）預設 1 之後，這一項量的是舊規格（撥久了先抗議再掙脫），釘 0
    const voices = () => log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6));
    { L5({}); IMP.tr = 0.6; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(7); const t0 = t; ev('pointerup', 1, cx, cy); steps(40);
      r37.tap = { leanAfter: +(E2.leanT - t0).toFixed(2), voices: voices() }; }
    { L5({}); IMP.tr = 0.6; const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); let lo = 1e9, hi = -1e9; for (let k = 0; k < 150; k++) { steps(1); const c = cen(); lo = Math.min(lo, c[0]); hi = Math.max(hi, c[0]); }
      ev('pointerup', 1, cx, cy); steps(30); r37.nuzzle = { swayR: +((hi - lo) / R).toFixed(3), voices: voices() }; }
    { L5({}); const sx = globalC.xc, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let sh = 0, esc = -1; const t0 = t;
      for (let k = 0; k < 330; k++) { const tx = sx + Math.sign(Math.sin(k * Math.PI / 5)) * R * 0.15; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', 1, q[0], q[1]); steps(1); if (SHK.t0 > 0 && Math.abs(t - SHK.t0) < 0.009) sh++; if (esc < 0 && f.mode === 'none') esc = t - t0; if (k % 10 === 0) worst = Math.max(worst, selfX()); }
      ev('pointerup', 1, q[0], q[1]); steps(60); r37.tickle = { shakes: sh, escapeS: +esc.toFixed(2), voices: voices() }; }
    const rubTr = o => { L5({ emo: 1, ...o }); const sx = globalC.xc + R * 0.3, sy = globalC.yc; let q = sc(sx, sy); ev('pointerdown', 2, q[0], q[1]); const f = fingers.get(2);
      for (let k = 0; k < 300; k++) { const tx = sx + Math.sin(k / 16) * R * 0.25; q = [q[0] + (tx - f.x) * CAM.z, q[1]]; ev('pointermove', 2, q[0], q[1]); steps(1); } ev('pointerup', 2, q[0], q[1]); steps(10); return +IMP.tr.toFixed(2); };
    r37.e3 = { trOn: rubTr({}), trOff: rubTr({ e3: 0 }) };
    { L5({}); E4.count = 0; IMP.tr = 0.8; LIFE.until = -1; let hello = -1; for (let k = 0; k < 1800 && E4.count < 1; k++) { steps(1); if (hello < 0 && voices().includes('hello')) hello = t; if (k % 30 === 0) worst = Math.max(worst, selfX()); }
      const c = cen(), q = toWorld(W / 2, v.y + H * 0.12); r37.e4 = { count: E4.count, helloAt: +hello.toFixed(1), distR: +(Math.hypot(c[0] - q.x, c[1] - q.y) / R).toFixed(2) }; }
    r37.worstSelfX = worst;
    res.T37_v222 = r37; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T38 v2.23（多米 build 86：黏液不自然、形狀不自然、太容易掉、太多；還是沒有互動感；加表情看看，只要眼睛；睡著、節奏、游過來、收集一起做）。
  //   a 黏液：黏土單指慢拉 2.5R（2 秒）不掉；兩指往兩邊慢慢拉 1.8R 不掉（v2.22 會掉）；猛扯（0.12 秒拉 2.6R 再停）掉 1 滴、有拉絲（neck 8 幀以上）、斷開 0.6 秒後離身體 0.25R 以上（黏土最近，量過 0.34），同一抓再扯、放手都不再掉
  //   b 眼睛：手指按在右邊 2.2R 的空白處 1 秒，眼睛往右看（gx 0.5 以上）；放著 10 秒眨 2 次以上；搔癢出現 > <；揉到呼嚕出現 ∩
  //   c 睡著：不碰 40 到 45 秒睡著、∪；點身體當下醒、縮得比平常大（0.06 以上）、「嗯？」
  //   d 節奏：空白處點 3 下（間隔 0.4 秒）→ 回 3 下、間隔 0.35 到 0.45、第一下在最後一點後 0.9 到 1.6 秒；接著點一樣的 → 回完開心（「噗咿」）；只點一下不回
  //   e 游過來：從家右邊 2R 以外開始，4.5 秒內到家 0.6R 內、打招呼，鏡頭不動（5 點內）；f 收集：四隻輪流換，材質、種子、顏色對，放 3 秒零自交、面積 0.97 到 1.03；換回來印象還在。全程零自交
  { const clock = saveClock(); Math.random = seeded(20261105); const r38 = {}; let worst = 0;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L6 = o => { resetAligned(1e9, { ...P1, holdTickle: 0, ...o }); impReset(); voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; log.splice(0); };   // v2.63 D3：搔癢不掙脫（holdTickle）預設 1 之後，這一項量的是舊規格（撥久了先抗議再掙脫），釘 0
    const voices = () => log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6));
    { L6({}); const q = sc(globalC.xc + R * 2.2, globalC.yc); ev('pointerdown', 2, q[0], q[1]); steps(60); const gx = +EYE.gx.toFixed(2); ev('pointerup', 2, q[0], q[1]); steps(30);
      let bl = 0, lastB = EYE.blinkT; for (let k = 0; k < 600; k++) { steps(1); if (EYE.blinkT !== lastB) { bl++; lastB = EYE.blinkT; } }
      L6({}); const sx = globalC.xc, sy = globalC.yc; let p = sc(sx, sy); ev('pointerdown', 1, p[0], p[1]); const f = fingers.get(1); let sq = 0;
      for (let k = 0; k < 240; k++) { const tx = sx + Math.sign(Math.sin(k * Math.PI / 5)) * R * 0.15; p = [p[0] + (tx - f.x) * CAM.z, p[1]]; ev('pointermove', 1, p[0], p[1]); steps(1); if (EYE.mode === 'squeeze') sq++; }
      ev('pointerup', 1, p[0], p[1]); steps(60);
      L6({}); const rx = globalC.xc + R * 0.3, ry = globalC.yc; p = sc(rx, ry); ev('pointerdown', 2, p[0], p[1]); const g = fingers.get(2); let hp = 0;
      for (let k = 0; k < 300; k++) { const tx = rx + Math.sin(k / 16) * R * 0.25; p = [p[0] + (tx - g.x) * CAM.z, p[1]]; ev('pointermove', 2, p[0], p[1]); steps(1); if (EYE.mode === 'happy') hp++; }
      ev('pointerup', 2, p[0], p[1]); steps(30); r38.eyes = { lookGx: gx, blinks10s: bl, tickleSqueeze: sq, purrHappy: hp }; }
    { L6({}); lastTouch = t; let at = -1; const t0 = t; for (let k = 0; k < 60 * 50 && at < 0; k++) { steps(1); if (SLP.on) at = t - t0; if (k % 60 === 0) worst = Math.max(worst, selfX()); }
      steps(150); const eye = EYE.mode, kk = SLP.k; log.splice(0);
      const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 3, q[0], q[1]); const woke = !SLP.on; steps(30); const fl = FLN.amp; ev('pointerup', 3, q[0], q[1]); steps(60);
      r38.sleep = { at: +at.toFixed(1), eye, k: +kk.toFixed(2), woke, flinch: +fl.toFixed(3), voices: voices() }; }
    const tapsAt = (ivs, id) => { const q = sc(globalC.xc, globalC.yc + R * 1.8), tp = []; for (let i = 0; i <= ivs.length; i++) { if (i) steps(Math.round(ivs[i - 1] * 60) - 3); ev('pointerdown', id, q[0], q[1]); tp.push(t); steps(3); ev('pointerup', id, q[0], q[1]); } return tp; };
    const listen = n => { const b = []; let last = ECHO.beatT; for (let k = 0; k < n; k++) { steps(1); if (ECHO.beatT !== last) { b.push(ECHO.beatT); last = ECHO.beatT; } if (k % 20 === 0) worst = Math.max(worst, selfX()); } return b; };
    { L6({}); const tp = tapsAt([0.4, 0.4], 4), b = listen(240); log.splice(0); tapsAt([0.42, 0.38], 4); const b2 = listen(240), joy = voices().includes('happy');
      L6({}); tapsAt([], 4); const b3 = listen(180);
      r38.echo = { beats: b.length, iv: b.slice(1).map((x, i) => +(x - b[i]).toFixed(2)), firstAfter: b.length ? +(b[0] - tp[tp.length - 1]).toFixed(2) : -1, again: b2.length, joy, single: b3.length }; }
    { L6({}); LIFE.until = -1; const cam0 = CAM.x, home = [CX, CY]; startIntro(); let mx = 0; for (let i = 0; i < N; i++) mx += X[i]; mx /= N; let arr = -1, hello = -1; const t0 = t;
      for (let k = 0; k < 600; k++) { steps(1); if (k % 10 === 0) worst = Math.max(worst, selfX()); if (hello < 0 && voices().includes('hello')) hello = t - t0; if (arr < 0 && Math.hypot(globalC.xc - home[0], globalC.yc - home[1]) < R * 0.6) arr = t - t0; if (hello > 0 && t - t0 > hello + 1) break; }
      r38.swim = { startOffR: +((mx - home[0]) / R).toFixed(2), arriveS: +arr.toFixed(2), helloS: +hello.toFixed(2), camMoved: +Math.abs(CAM.x - cam0).toFixed(1), end: snap() }; }
    { L6({}); const s0 = SLIME, o = []; IMP.tr = 0.7; IMP.w = 0.1; chooseSlime((s0 + 1) % SLIMES.length, false, false);
      for (let i = 0; i < SLIMES.length; i++) { chooseSlime(i, false, false); mat.emo = 0; WANDER.moving = false; LIFE.until = 1e9; let aMin = 9, aMax = 0, x = 0;
        for (let k = 0; k < 180; k++) { steps(1); const a = area() / A0; aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); if (k % 10 === 0) x = Math.max(x, selfX()); }
        o.push({ id: SLIMES[i].id, mat: curMat === SLIMES[i].mat, seed: mat.seed === SLIMES[i].seed, color: getComputedStyle(document.documentElement).getPropertyValue('--body').trim().toUpperCase() === SLIMES[i].c[0], aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), selfX: x }); }
      chooseSlime(s0, false, false); r38.collect = { slimes: o, impBack: +IMP.tr.toFixed(2) }; }
    r38.worstSelfX = worst;
    res.T38_v223 = r38; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T39 v2.24（多米 11-04：手感做到極致；.uiux/04-手感/手感診斷-暫定.md）。舊項目一律回 v2.23（OFF24），v2.24 只在這裡測，用 PSAVE（全開）。
  //   a F1：身體 0.30；b F2：點一下縮到 0.91 以下、外緣朝手指多 0.12R 以上（鼓包加整團靠過去）、按著蹭擺幅 0.15R 以上、手指在右邊空白臉滑 0.15R 以上、按正中兩顆眼睛都不被手指蓋住；
  //   c F3：一般手速的揉 1.7 秒內呼嚕、不搔癢、不逃；很快的小撥 1 秒內搔癢、先抗議、5.5 到 7.5 秒才掙脫；按著不動的呼嚕比揉慢；
  //   d 揉不補抓：外圈沒有點被釘住、輪廓折角 25 度以內；從中間直直往外拉，外圈照樣跟出去；e camGrip：抓著時畫面不滑（手指跟被抓那塊差很少）、放手形狀太靠邊會挪回來；
  //   f 留形不動：拉 1.5R 放手 2 秒還留七成五；g 三種材質暴力玩法（拉、甩、兩指擠、兩指拉、揉）零交叉、面積回來
  { const clock = saveClock(); Math.random = seeded(20261104); const r39 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const L7 = (name, o) => { resetAligned(1e9, { ...PSAVE[name], ...OFF25, seed: 7, holdTickle: 0, ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(20); log.splice(0); };   // v2.63 D3：搔癢不掙脫（holdTickle）預設 1 之後，這一項量的是舊規格（撥久了先抗議再掙脫），釘 0
    const box = () => { let a = 1e9, b = -1e9, c = 1e9, d = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); c = Math.min(c, Y[i]); d = Math.max(d, Y[i]); } return [a, b, c, d]; };
    const kink = () => { const n = bnd.length; let m = 0; for (let k = 0; k < n; k++) { const a = bnd[(k + n - 1) % n], b = bnd[k], c = bnd[(k + 1) % n], u = Math.atan2(Y[b] - Y[a], X[b] - X[a]), w = Math.atan2(Y[c] - Y[b], X[c] - X[b]); m = Math.max(m, Math.abs(Math.atan2(Math.sin(w - u), Math.cos(w - u)))); } return m * 180 / Math.PI; };
    const hidden = (p, fx, fy) => { const qx = p[0] - fx, qy = p[1] - fy, u = qx * .5 + qy * .866, uc = Math.max(0, Math.min(160, u)), rr = 30 + 18 * uc / 160; return Math.hypot(qx - .5 * uc, qy - .866 * uc) < rr; };   // 手指：接觸面半徑 30 點、從右下伸過來、往後變寬到 48 點
    const face = () => { const [lx, ly] = eyeAt(EYE.L), [rx, ry] = eyeAt(EYE.R), S = R * (mat.eyeSize || 1), ga = mat.gazeAmp * (1 - .8 * EYE.dk), ox = (EYE.gx * ga + EYE.dx) * S, oy = (EYE.gy * ga * .75 + EYE.dy) * S; return { l: [lx + ox, ly + oy], r: [rx + ox, ry + oy], ox, oy }; };
    // a F1
    L7('clay', {}); { const b = box(); r39.size = { rOverW: +(R / W).toFixed(3), widthPt: +(b[1] - b[0]).toFixed(0), z: +CAM.z.toFixed(3) }; }
    // b F2 縮、傾（關掉放手後的探，只看傾）
    L7('clay', { lifeAttend: 0 }); { const b0 = box(), c0 = globalC.xc; let q = sc(globalC.xc + R * .6, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(4); ev('pointerup', 1, q[0], q[1]); let sMin = 1, lean = -1e9; for (let k = 0; k < 90; k++) { steps(1); sMin = Math.min(sMin, FLN.s); if (t - E2.leanT > 0) lean = Math.max(lean, box()[1]); } r39.tap = { flinchMin: +sMin.toFixed(3), leanGainR: +((lean - b0[1]) / R).toFixed(3), voices: log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6)) }; }
    // 蹭：按著不動，重心上下擺幅
    L7('clay', {}); { const q = sc(globalC.xc + R * .45, globalC.yc + R * .1); ev('pointerdown', 1, q[0], q[1]); steps(60); let a = 1e9, b = -1e9; for (let k = 0; k < 180; k++) { steps(1); a = Math.min(a, globalC.yc); b = Math.max(b, globalC.yc); } r39.nuzzleSwingR = +((b - a) / R).toFixed(3); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 看：手指按在右邊 2.2R 的空白處
    L7('clay', {}); { const q = sc(globalC.xc + R * 2.2, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(60); r39.gazeR = +(face().ox / R).toFixed(3); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 按正中：兩顆眼睛都不被手指蓋住；關 dodge 當對照
    for (const [nm, o] of [['on', {}], ['off', { dodge: 0, gazeAmp: .06 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); steps(60); const F = face(); (r39.dodge = r39.dodge || {})[nm] = { l: hidden(F.l, f.x, f.y), r: hidden(F.r, f.x, f.y), oy: +(F.oy / R).toFixed(3) }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // c F3 揉（kind：c 圓圈、l 來回；r 點、hz；T 秒）
    const rub = (name, kind, r, hz, T, o = {}) => { L7(name, o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(6); let th = 0, tP = -1, tT = -1, tF = -1, tProt = -1, sp = 0, n = 0, mk = 0;
      for (let k = 0; k < T * 60; k++) { th += 2 * Math.PI * hz * DT; const px = kind === 'c' ? q[0] + r * Math.cos(th) : q[0] + r * Math.sin(th), py = kind === 'c' ? q[1] + r * Math.sin(th) : q[1]; if (r > 0) ev('pointermove', 1, px, py); steps(1); const g = fingers.get(1); if (!g || g.mode !== 'grab') { tF = k * DT; break; } sp += Math.hypot(g.vxS, g.vyS); n++; mk = Math.max(mk, kink()); if (tP < 0 && PURR > .3) tP = k * DT; if (tT < 0 && tickOn()) tT = k * DT; if (tProt < 0 && log.some(x => x[0] === 'voice.protest')) tProt = k * DT; }
      const res1 = { cmS: +(sp / Math.max(1, n) / 60).toFixed(1), purr: +tP.toFixed(2), tickle: +tT.toFixed(2), free: +tF.toFixed(2), protest: +tProt.toFixed(2), kink: +mk.toFixed(0) }; if (fingers.size) ev('pointerup', 1, q[0], q[1]); steps(4); return res1; };
    r39.rub = { c1cm: rub('clay', 'c', 10, 1, 4), c5cm: rub('clay', 'c', 30, 1.5, 4), c12cm: rub('clay', 'c', 50, 2.5, 4), l5cm: rub('clay', 'l', 30, 3, 8), l7cm: rub('clay', 'l', 60, 2, 8), jelly: rub('jelly', 'c', 30, 1.5, 4), mochi: rub('mochi', 'c', 30, 1.5, 4), hold: rub('clay', 'c', 0, 1, 4), tickle: rub('clay', 'l', 20, 4, 9), oldRub: rub('clay', 'c', 30, 1.5, 4, { rubSpeed: 0 }) };
    // 按著不動 4 秒：外框不折（Q 不記遠端的小誤差）；關 pressLocal 當對照
    for (const [nm, o] of [['on', {}], ['off', { pressLocal: 0 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); let mk = 0; for (let k = 0; k < 240; k++) { steps(1); mk = Math.max(mk, kink()); } (r39.hold = r39.hold || {})[nm] = +mk.toFixed(0); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 按一下留痕還在：按 1.5 秒，手指附近的形狀記住了
    L7('clay', {}); { const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(90); let qm = 0; for (let i = 0; i < N; i++) qm = Math.max(qm, Math.hypot(QX[i] - Q0X[i], QY[i] - Q0Y[i])); r39.pressMemPt = +qm.toFixed(1); ev('pointerup', 1, q[0], q[1]); steps(4); }
    // d 揉不補抓
    for (const [nm, o] of [['on', {}], ['off', { reachV: 0 }]]) { L7('clay', o); const q = sc(globalC.xc, globalC.yc + R * .1); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let th = 0, mk = 0; for (let k = 0; k < 180; k++) { th += 2 * Math.PI * 1.5 * DT; ev('pointermove', 1, q[0] + 30 * Math.cos(th), q[1] + 30 * Math.sin(th)); steps(1); mk = Math.max(mk, kink()); } (r39.reach = r39.reach || {})[nm] = { edgePinned: f.mem.filter(m => BIDX[m[0]] >= 0).length, kink: +mk.toFixed(0) }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // 從中間直直往外拉 1.5R（手指真的走得到的距離）：外圈要跟出去
    for (const [nm, ux, uy] of [['right', 1, 0], ['up', 0, -1]]) { L7('clay', {}); const b0 = box(), cx = globalC.xc, cy = globalC.yc; let q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); let wx = 0; for (let k = 1; k <= 90; k++) { const a = Math.min(1, k / 45) * 1.5 * R; q = [q[0] + (cx + ux * a - f.x) * CAM.z, q[1] + (cy + uy * a - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (k % 3 === 0) wx = Math.max(wx, selfX()); } const b1 = box(); r39.reach[nm] = { edgeMovedR: +((ux ? b1[1] - b0[1] : b0[2] - b1[2]) / R).toFixed(2), selfX: wx }; ev('pointerup', 1, q[0], q[1]); steps(4); }
    // e camGrip：抓右緣往右 70、90 點，往下 300 點，停 0.67 秒量手指跟被抓那塊在畫面上差多少
    const gap = (o, dist, dx, dy) => { L7('clay', { lifeAttend: 0, ...o }); let bi = -1, bb = -1e9; for (const i of bnd) { const p = X[i] * dx + Y[i] * dy; if (p > bb) { bb = p; bi = i; } } const q0 = sc(X[bi] - dx * R * .15, Y[bi] - dy * R * .15); let x = q0[0], y = q0[1]; ev('pointerdown', 1, x, y); steps(6); const f = fingers.get(1), mem = f.mem; for (let k = 0; k < 20; k++) { x += dx * dist / 20; y += dy * dist / 20; ev('pointermove', 1, x, y); steps(1); } steps(40); let px = 0, py = 0, w = 0; for (const m of mem) { const a = m[3]; px += (X[m[0]] - m[1]) * a; py += (Y[m[0]] - m[2]) * a; w += a; } const s1 = sc(px / w, py / w), z = CAM.z; ev('pointerup', 1, x, y); steps(90); const b = box(), right = sc(b[1], b[2])[0]; return { gapPt: +Math.hypot(x - s1[0], y - s1[1]).toFixed(1), z: +z.toFixed(3), rightAfter: +right.toFixed(0) }; };
    r39.cam = { r70: gap({}, 70, 1, 0), r90: gap({}, 90, 1, 0), d300: gap({}, 300, 0, 1), oldR100: gap({ camGrip: 0 }, 100, 1, 0), oldD300: gap({ camGrip: 0 }, 300, 0, 1) };
    // f 留形：抓最右邊往右拉 1.5R、停 1 秒放手，量放手 2 秒還留幾成拉出來的寬度
    L7('clay', { lifeAttend: 0 }); { const wd = () => { const b = box(); return (b[1] - b[0]) / R; }, w0 = wd(); let bi = -1; for (const i of bnd) if (bi < 0 || X[i] > X[bi]) bi = i; const sx = X[bi] - R * .15, sy = Y[bi]; let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); for (let k = 1; k <= 90; k++) { const a = sx + 1.5 * R * Math.min(1, k / 30); q = [q[0] + (a - f.x) * CAM.z, q[1]]; ev('pointermove', 1, q[0], q[1]); steps(1); } const wh = wd(); ev('pointerup', 1, q[0], q[1]); steps(120); r39.keep = { heldR: +wh.toFixed(2), keep2s: +((wd() - w0) / (wh - w0)).toFixed(2) }; }
    // g 暴力玩法
    const abuse = name => { L7(name, {}); let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / A0; aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r39.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    res.T39_v224 = r39; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

  // T40 v2.25 F4（診斷第二節：放手 33 毫秒彈完、每秒晃 7 下）。舊項目與 T39 都關慣性（OFF25），這裡開慣性、關 v2.26（OFF26，T41 才開）。F5 觸覺只在 Swift，這裡測不到。
  //   a 放手：抓右緣拉 1R 放手，第一下 120 毫秒以上（關掉不到 50）、放手那一幀跳動 8 點內（關掉 16 到 47）、麻糬果凍晃 3 下以上、黏土 1 秒留形不比關掉差；
  //   b 拖到一半停：整隻衝過頭 8 點以上（關掉 1 點內）、0.15 到 0.6 秒到頂；c 拉力、跟手不變（整團跟隨差 0.05R 內、手指跟被抓那塊差 3 點內）；
  //   d 猛甩放手、兩指放一指、按住放手、揉回原形：零交叉、不炸（QD 離 Q 不超過 2.5R）、放手跳動小；e 放著：QD 收回 Q、不漂；f 減少動態：不過衝；g 三種材質全開暴力玩法零交叉
  { const clock = saveClock(); Math.random = seeded(20261225); const r40 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, eyes: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L8 = (name, o, full) => { resetAligned(1e9, { ...PSAVE[name], ...OFF26, seed: 7, ...(full ? {} : QUIET), ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(30); log.splice(0); };
    const OFF = { inertiaHz: 0, dragSpring: 0 };
    const edgeI = (dx, dy) => { let bi = -1, bb = -1e9; for (const i of bnd) { const p = X[i] * dx + Y[i] * dy; if (p > bb) { bb = p; bi = i; } } return bi; };
    const jumpFrom = (x0, y0) => { let m = 0; for (const i of bnd) m = Math.max(m, Math.hypot(X[i] - x0[i], Y[i] - y0[i])); return m; };
    // 小步取樣（每秒 240 次）
    const sub1 = substep; let sample = null; substep = (a, b, c, d) => { sub1(a, b, c, d); if (sample) sample(); };
    // a 放手
    const ring = (name, o) => { L8(name, o); const bi = edgeI(1, 0), rest = X[bi] - globalC.xc; let q = sc(X[bi] - R * .1, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0]; for (let i = 0; i < 15; i++) { x += R / 15; ev('pointermove', 1, x, q[1]); steps(1); } steps(30);
      const pre = X[bi] - globalC.xc, ser = [], x0 = Float64Array.from(X), y0 = Float64Array.from(Y); sample = () => ser.push(X[bi] - globalC.xc); ev('pointerup', 1, x, q[1]); steps(1); const jump = jumpFrom(x0, y0); steps(59); const at1 = X[bi] - globalC.xc; steps(60); const at2 = X[bi] - globalC.xc; sample = null;
      let i0 = 0; for (let i = 1; i < ser.length; i++) { if (ser[i] < ser[i0]) i0 = i; if (ser[i] > ser[i0] + .8 && i > 2) break; } const ext = []; for (let i = 2; i < ser.length; i++) { const a = ser[i - 2], b = ser[i - 1], c = ser[i]; if ((b - a) * (c - b) < 0 && Math.abs(b - at2) > 1.5) ext.push(i - 1); } let maxV = 0; for (let i = 1; i < ser.length; i++) maxV = Math.max(maxV, Math.abs(ser[i] - ser[i - 1]) * 240);
      return { firstMs: +(i0 / .24).toFixed(0), swings: ext.length, maxV: +maxV.toFixed(0), jump: +jump.toFixed(1), keep1s: +((at1 - rest) / (pre - rest)).toFixed(2) }; };
    r40.ring = { clay: ring('clay', {}), mochi: ring('mochi', {}), jelly: ring('jelly', {}), clayOff: ring('clay', OFF), mochiOff: ring('mochi', OFF), jellyOff: ring('jelly', OFF) };
    // b 拖到一半停
    const stop = (name, o) => { L8(name, o); const bi = edgeI(1, 0); let q = sc(X[bi] - R * .2, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0]; const c0 = globalC.xc, cs = []; let xf = 0; for (let i = 0; i < 99; i++) { if (i < 9) { x += 200 / 9; ev('pointermove', 1, x, q[1]); } steps(1); cs.push(globalC.xc - c0); if (selfX()) xf++; } ev('pointerup', 1, x, q[1]); steps(4); const fin = cs[cs.length - 1], pk = Math.max(...cs); return { overPt: +(pk - fin).toFixed(1), atS: +((cs.indexOf(pk) - 9) / 60).toFixed(2), crossFrames: xf }; };
    r40.stop = { clay: stop('clay', {}), mochi: stop('mochi', {}), jelly: stop('jelly', {}), clayOff: stop('clay', OFF), jellyOff: stop('jelly', OFF) };
    // c 拉力、跟手
    const pull = (name, o, rr, frames) => { L8(name, o); const bi = edgeI(.707, .707); let q = sc(X[bi] - R * .1, Y[bi] - R * .1); const c0x = globalC.xc, c0y = globalC.yc; ev('pointerdown', 1, q[0], q[1]); steps(6); const f = fingers.get(1), mem = f.mem; let x = q[0], y = q[1]; const dd = rr * R * .707 / frames; for (let i = 0; i < frames; i++) { x += dd; y += dd; ev('pointermove', 1, x, y); steps(1); } steps(40); const move = Math.hypot(globalC.xc - c0x, globalC.yc - c0y) / R; let px = 0, py = 0, w = 0; for (const m of mem) { const a = m[3]; px += (X[m[0]] - m[1]) * a; py += (Y[m[0]] - m[2]) * a; w += a; } const s1 = sc(px / w, py / w); const gap = Math.hypot(x - s1[0], y - s1[1]); ev('pointerup', 1, x, y); steps(4); return { moveR: +move.toFixed(2), gap: +gap.toFixed(1) }; };
    r40.pull = { jelly: pull('jelly', {}, 2.5, 30), jellyOff: pull('jelly', OFF, 2.5, 30), clay: pull('clay', {}, 2, 60), clayOff: pull('clay', OFF, 2, 60), mochi: pull('mochi', {}, 2, 30), mochiOff: pull('mochi', OFF, 2, 30) };
    // d 邊緣情況
    const qdMax = () => { let m = 0; for (let i = 0; i < N; i++) m = Math.max(m, Math.hypot(QDX[i] - QX[i], QDY[i] - QY[i])); return m / R; };
    const fling = name => { L8(name, {}); const bi = edgeI(-1, 0); let q = sc(X[bi] + R * .2, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(4); let x = q[0], y = q[1]; for (let i = 0; i < 5; i++) { x -= 60; y += 30; ev('pointermove', 1, x, y); steps(1); } ev('pointerup', 1, x, y); let xf = 0, qm = 0; for (let i = 0; i < 180; i++) { steps(1); if (selfX()) xf++; qm = Math.max(qm, qdMax()); } return { crossFrames: xf, qdMaxR: +qm.toFixed(2), endSelfX: selfX() }; };
    r40.fling = { clay: fling('clay'), mochi: fling('mochi'), jelly: fling('jelly') };
    const twoOne = name => { L8(name, {}); let a = sc(globalC.xc - R * .7, globalC.yc), b = sc(globalC.xc + R * .7, globalC.yc); ev('pointerdown', 1, a[0], a[1]); ev('pointerdown', 2, b[0], b[1]); steps(4); let ax = a[0], bx = b[0]; for (let i = 0; i < 30; i++) { ax -= R * .8 / 30; bx += R * .8 / 30; ev('pointermove', 1, ax, a[1]); ev('pointermove', 2, bx, b[1]); steps(1); } steps(20); const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); ev('pointerup', 2, bx, b[1]); steps(1); const jump = jumpFrom(x0, y0); let xf = 0; for (let i = 0; i < 90; i++) { steps(1); if (selfX()) xf++; } ev('pointerup', 1, ax, a[1]); for (let i = 0; i < 90; i++) { steps(1); if (selfX()) xf++; } return { jump: +jump.toFixed(1), crossFrames: xf }; };
    r40.twoOne = { clay: twoOne('clay'), jelly: twoOne('jelly') };
    const pressUp = name => { L8(name, {}); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(60); const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); ev('pointerup', 1, q[0], q[1]); steps(1); const jump = jumpFrom(x0, y0); let xf = 0; for (let i = 0; i < 120; i++) { steps(1); if (selfX()) xf++; } return { jump: +jump.toFixed(1), crossFrames: xf }; };
    r40.press = { clay: pressUp('clay'), mochi: pressUp('mochi'), jelly: pressUp('jelly') };
    L8('clay', {}); { const bi = edgeI(1, 0); let q = sc(X[bi] - R * .1, Y[bi]); ev('pointerdown', 1, q[0], q[1]); steps(4); let x = q[0]; for (let i = 0; i < 30; i++) { x += R * 2 / 30; ev('pointermove', 1, x, q[1]); steps(1); } ev('pointerup', 1, x, q[1]); steps(30); relax(); let xf = 0; for (let i = 0; i < 120; i++) { steps(1); if (selfX()) xf++; } r40.relax = { crossFrames: xf, qdevPt: +qdev().toFixed(1) }; }
    // e 放著
    L8('clay', {}); { steps(180); const q1 = qdMax(); r40.idleQdPt = +(q1 * R).toFixed(2); }
    // f 減少動態：阻尼比至少 0.7，不過衝
    r40.reduced = ring('jelly', { inertiaZ: .7 });
    sample = null; substep = sub1;
    // g 全開暴力玩法
    const abuse = name => { L8(name, {}, true); let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / A0; aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r40.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    // 放著走路 30 秒：走路是整團平移，參考形狀不該被帶歪
    L8('jelly', { sleep: 0 }, true); LIFE.until = t + .5; { let xf = 0, qm = 0; for (let i = 0; i < 1800; i++) { steps(1); if (selfX()) xf++; qm = Math.max(qm, qdMax()); } r40.walk = { crossFrames: xf, qdMaxR: +qm.toFixed(3) }; }
    res.T40_v225 = r40; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

  // T27 從身體中間往外拉（v2.14，多米 build 59：只有從邊緣才拖得動，從中間往外拉沒反應；量過右邊緣反而退 0.08R）：
  //     從重心往右、往上各拉 2R 花 1 秒、停 1 秒，量那一側外圈跟出去多少；零自交、面積回來
  { const clock = saveClock(); Math.random = seeded(20261114); const r27 = {};
    for (const [name, ux, uy] of [['right', 1, 0], ['up', 0, -1]]) {
      resetAligned(1e9); nextTwitch = 1e9; const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
      let x0 = 1e9, x1 = -1e9, y0 = 1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); y0 = Math.min(y0, Y[i]); }
      const cx = globalC.xc, cy = globalC.yc; let worst = 0, q = sc(cx, cy); ev('pointerdown', 1, q[0], q[1]); const f27 = [...fingers.values()][0];
      // v2.15 起手指在世界裡只跟著螢幕位移 ÷ 鏡頭倍率走：每幀照「世界目標 − 手指現在的世界位置」補螢幕位移
      for (let k = 1; k <= 120; k++) { const a = Math.min(1, k / 60) * 2 * R; q = [q[0] + (cx + ux * a - f27.x) * CAM.z, q[1] + (cy + uy * a - f27.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); if (k % 3 === 0) worst = Math.max(worst, selfX()); }
      let x1b = -1e9, y0b = 1e9; for (const i of bnd) { x1b = Math.max(x1b, X[i]); y0b = Math.min(y0b, Y[i]); }
      ev('pointerup', 1, q[0], q[1]); for (let k = 0; k < 300; k++) { steps(1); if (k % 5 === 0) worst = Math.max(worst, selfX()); }
      r27[name] = { edgeMovedR: +((ux ? x1b - x1 : y0 - y0b) / R).toFixed(2), worstSelfX: worst, end: snap() };
    }
    res.T27_pullFromMiddle = r27; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T28 回彈速度（v2.14，多米 build 59：回彈太快；recover 0.3 時拉 3R 放手 2 秒就退一半）：抓最右邊往右拉 3R、停 2 秒放手，
  //     量放手 2 秒、15 秒還留著幾成拉出來的寬度
  { const clock = saveClock(); Math.random = seeded(20261115); resetAligned(1e9); nextTwitch = 1e9;
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const wd = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); } return (b - a) / R; };
    const w0 = wd(); let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const sx = X[b] - R * 0.15, sy = Y[b];
    let q = sc(sx, sy); ev('pointerdown', 1, q[0], q[1]);
    for (let k = 1; k <= 180; k++) { q = sc(sx + 3 * R * Math.min(1, k / 60), sy); ev('pointermove', 1, q[0], q[1]); steps(1); }
    const wh = wd(); ev('pointerup', 1, q[0], q[1]); steps(120); const w2 = wd(); steps(780); const w15 = wd();
    res.T28_relax = { heldR: +wh.toFixed(2), keep2s: +((w2 - w0) / (wh - w0)).toFixed(2), keep15s: +((w15 - w0) / (wh - w0)).toFixed(2), end: snap() };
    log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; }

  // T3 的對折幀數留著只記錄；交疊（跨群）是設計允許的，永遠只記錄
  res.KNOWN_ISSUES = { T3_compressionFoldFrames: res.T3_pull.foldFrames, T3_foldStillHeld: res.T3_pull.during.fold, T4_foldFrames: res.T4_twoFinger.foldFrames, T4_foldStillHeld: res.T4_twoFinger.during.fold, T5_foldFrames: res.T5_flail.foldFrames, T13_pinchFoldFrames: res.T13_pinch.foldFrames, T26_holdCrossFrames: res.T26_zoomUnlimited.holdCrossFrames };
  // T41 v2.26 F6 F7（診斷第二節：手指劃過身體整團被帶走 74 到 113 點、凹痕整個在手指底下）。舊項目、T39、T40 都關（OFF26），這裡全開。
  //   a 摸：左半劃到右外，手指滑過去（stroke），整團最多被帶 0.3R 內、放開回來 2 點內、零交叉、黏土不記形（關掉帶 0.5R 以上）；
  //   b 拉（抓是主要動作，寧可判成抓）：從身體側邊快速往下拖（v2.26.1，一般手指要加速 0.2 秒到每秒 1100 點）、邊緣往外扯、往右下拉（T36，多米 build 77 錄影的拉法）、中心往外甩、一般拖法（慢慢加速）、猛扯、兩指快拉都還是抓，拉力跟關掉差 0.05R 內；第二根手指緊接著落下，第一根摸回抓；
  //   c 摸到一半停住變抓，接著拉得動；d 從外面劃進來是摸，慢慢推還是推；e 摸三下：2.5 秒內舒服、呼嚕、熟，不縮、不逃；
  //   f 按著：手指外面看得到的變化比關掉多 1500 平方點以上；揉的時候凹痕還在、痕跡半秒內淡完；g 亮光跟著拉伸；h 全開暴力玩法（含一直劃過去）零交叉、留形不變
  { const clock = saveClock(); Math.random = seeded(20261226); const r41 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, eyes: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L10 = (name, o, full) => { resetAligned(1e9, { ...PSAVE[name], seed: 7, ...(full ? {} : QUIET), ...o }); impReset(); IMPD.tr = 0; IMPD.w = 0; voice.last = -9; E4.count = 3; E4.lastT = -99; E4.wait = -1; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = 1e9; Object.assign(MOOD, { c: 0, a: 0, strain: 0, strainMax: 0, scare: 0, taps: [], happyT: -9, wagT: -9, cowerUntil: -9 }); ESC.on = false; PURR = 0; FLN.H = 1; FLN.at = -9; FLN.t0 = -9; FLN.amp = 0; E2.leanT = -9; E2.tk.length = 0; E2.tkT = 0; CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; steps(30); log.splice(0); };
    const OFF = OFF26, MATS = ['clay', 'mochi', 'jelly'], U = Math.SQRT1_2;
    const go = (name, o, lx, ly, dx, dy, peak, rampT, T, full) => { L10(name, o, full); const q = sc(globalC.xc + lx * R, globalC.yc + ly * R); let x = q[0], y = q[1]; const c0x = globalC.xc, c0y = globalC.yc; ev('pointerdown', 1, x, y); const f = fingers.get(1); let first = null, pk = 0, xf = 0; const fr = Math.round(T * 60);
      for (let i = 1; i <= fr; i++) { const vv = peak * Math.min(1, (i / 60) / rampT); x += dx * vv / 60; y += dy * vv / 60; ev('pointermove', 1, x, y); steps(1); if (!first && !f.judge) first = f.mode; pk = Math.max(pk, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); if (selfX()) xf++; }
      const end = f.mode, mv = Math.hypot(globalC.xc - c0x, globalC.yc - c0y); ev('pointerup', 1, x, y); for (let i = 0; i < 120; i++) { steps(1); pk = Math.max(pk, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); if (selfX()) xf++; }
      return { first, end, moveR: +(mv / R).toFixed(2), peakR: +(pk / R).toFixed(3), backPt: +Math.hypot(globalC.xc - c0x, globalC.yc - c0y).toFixed(1), crossFrames: xf, qdev: +qdev().toFixed(2) }; };
    // a 摸
    r41.swipe = {}; for (const k of MATS) { r41.swipe[k] = go(k, {}, -.55, 0, 1, 0, 500, .001, .42); r41.swipe[k + 'Fast'] = go(k, {}, -.55, .2, 1, 0, 1200, .001, .25); r41.swipe[k + 'Off'] = go(k, OFF, -.55, 0, 1, 0, 500, .001, .42); }
    // b 拉
    const pair = (name, ...a) => ({ on: go(name, {}, ...a), off: go(name, OFF, ...a) });
    r41.pull = { edge: pair('jelly', .8, .3, 1, 0, 600, .001, .5), rb: pair('jelly', .7, .7, U, U, 590, .001, .5), center: pair('jelly', 0, 0, 1, 0, 240, .001, .4), dragSlow: pair('clay', -.5, 0, 1, 0, 600, .25, .5), yank: pair('clay', .75, .4, 1, .3, 1500, .001, .12), press: pair('mochi', -.5, 0, 1, 0, 100, .001, 1) };
    { L10('clay', {}); const c = sc(globalC.xc, globalC.yc); let a = c[0] - R * .7, b = c[0] + R * .7; const y = c[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); const f1 = fingers.get(1), f2 = fingers.get(2); for (let i = 0; i < 30; i++) { a -= 12; b += 12; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); steps(1); } let x0 = 1e9, x1 = -1e9; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } r41.twoFinger = { m1: f1.mode, m2: f2.mode, widthR: +((x1 - x0) / R).toFixed(2) }; ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); steps(30); }
    { L10('clay', {}); const c = sc(globalC.xc, globalC.yc); let a = c[0] - R * .7; const y = c[1]; ev('pointerdown', 1, a, y); const f1 = fingers.get(1); for (let i = 0; i < 4; i++) { a += 10; ev('pointermove', 1, a, y); steps(1); } const m0 = f1.mode; ev('pointerdown', 2, c[0] + R * .7, y); steps(1); r41.secondFinger = { before: m0, after: f1.mode, m2: fingers.get(2).mode }; ev('pointerup', 1, a, y); ev('pointerup', 2, c[0] + R * .7, y); steps(30); }
    // c 摸到一半停住
    { L10('clay', {}); const q = sc(globalC.xc - R * .6, globalC.yc); let x = q[0]; ev('pointerdown', 1, x, q[1]); const f = fingers.get(1); for (let i = 0; i < 12; i++) { x += 500 / 60; ev('pointermove', 1, x, q[1]); steps(1); } const mid = f.mode, memMid = f.mem.length; steps(18); const after = f.mode, memAfter = f.mem.length, c0 = globalC.xc; for (let i = 0; i < 30; i++) { x -= 6; ev('pointermove', 1, x, q[1]); steps(1); } steps(20); r41.stopGrab = { mid, memMid, after, memAfter, movedPt: +Math.abs(globalC.xc - c0).toFixed(1) }; ev('pointerup', 1, x, q[1]); steps(30); }
    // d 從外面
    r41.fromOut = go('clay', {}, -1.5, 0, 1, 0, 500, .001, .7); r41.slowPush = go('clay', {}, -1.5, 0, 1, 0, 100, .001, 1.2);
    // e 摸三下（行為全開）
    { L10('clay', {}, true); LIFE.st = 'rest'; LIFE.until = 1e9; SLP.lastAny = t; WANDER.next = 1e9; const t0 = t, f0 = FLN.t0; let first = -1, pm = 0, cm = 0;
      for (let s3 = 0; s3 < 3; s3++) { const q = sc(globalC.xc - R * .6, globalC.yc + R * .1); let x = q[0]; ev('pointerdown', 1, x, q[1]); for (let i = 0; i < 21; i++) { x += 500 / 60; ev('pointermove', 1, x, q[1]); steps(1); pm = Math.max(pm, PURR); cm = Math.max(cm, MOOD.c); if (first < 0 && PURR > .03) first = t - t0; } ev('pointerup', 1, x, q[1]); for (let i = 0; i < 18; i++) { steps(1); pm = Math.max(pm, PURR); if (first < 0 && PURR > .03) first = t - t0; } }
      r41.pet = { firstPurrS: +first.toFixed(2), purrMax: +pm.toFixed(2), cMax: +cm.toFixed(2), tr: +IMP.tr.toFixed(3), esc: ESC.on, flinched: FLN.t0 !== f0 }; steps(70); r41.pet.happy = MOOD.happyT > t0; for (let i = 0; i < 60; i++) steps(1); }
    // f 手指外面看得到多少（手指畫成寬 96、高 140 的橢圓，指尖在按的點上方 30 點）
    const visible = (o, name) => { L10(name, o); draw(); const W2 = cv.width, H2 = cv.height, g0 = ctx.getImageData(0, 0, W2, H2).data.slice(), q = sc(globalC.xc, globalC.yc), d0 = W2 / W; ev('pointerdown', 1, q[0], q[1]); steps(30); draw(); const d1 = ctx.getImageData(0, 0, W2, H2).data; let n = 0; const st = 2; for (let y = 0; y < H2; y += st) for (let x = 0; x < W2; x += st) { const ex = (x / d0 - q[0]) / 48, ey = (y / d0 - q[1] - 40) / 70; if (ex * ex + ey * ey < 1) continue; const k = (y * W2 + x) * 4; if (Math.abs(g0[k] - d1[k]) + Math.abs(g0[k + 1] - d1[k + 1]) + Math.abs(g0[k + 2] - d1[k + 2]) > 12) n++; } ev('pointerup', 1, q[0], q[1]); steps(30); return Math.round(n * st * st / (d0 * d0)); };
    r41.visible = { clay: visible({}, 'clay'), clayOff: visible(OFF, 'clay'), jelly: visible({}, 'jelly'), jellyOff: visible(OFF, 'jelly') };
    { L10('clay', {}); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(12); let x, y; for (let i = 0; i < 60; i++) { const a = i / 60 * 2 * Math.PI * 1.5; x = q[0] + R * .3 * (1 - Math.cos(a)); y = q[1] + R * .3 * Math.sin(a); ev('pointermove', 1, x, y); steps(1); } const dn = DENTS.find(o => o.f === 1); r41.rub = { dentD: dn ? +dn.d.toFixed(2) : 0, trail: TRAIL.length, mode: fingers.get(1).mode }; ev('pointerup', 1, x, y); steps(40); r41.rub.trailAfter = TRAIL.length; }
    // g 亮光
    { L10('clay', {}); const q = sc(X[hiIdx] - R * .05, Y[hiIdx] - R * .05); ev('pointerdown', 1, q[0], q[1]); steps(6); let x = q[0], y = q[1]; for (let i = 0; i < 30; i++) { x -= R * 1.2 * .64 / 30; y -= R * 1.2 * .77 / 30; ev('pointermove', 1, x, y); steps(1); } steps(10); const [a, b, c, d] = dentFrame(HIF), h0 = (a + d) / 2, h1 = Math.hypot((a - d) / 2, (b + c) / 2); r41.hi = { big: +(h0 + h1).toFixed(2), small: +(h0 - h1).toFixed(2) }; ev('pointerup', 1, x, y); steps(30); }
    // h 暴力玩法、留形
    const abuse = name => { L10(name, {}, true); let xf = 0, n = 0, aMin = 9, aMax = 0; const tick = (m, fn) => { for (let i = 0; i < m; i++) { if (fn) fn(i); steps(1); n++; if (selfX()) xf++; const a = area() / A0; aMin = Math.min(aMin, a); aMax = Math.max(aMax, a); } };
      const c = () => sc(globalC.xc, globalC.yc); let q = c(); ev('pointerdown', 1, q[0] + R * .7, q[1]); let x = q[0] + R * .7, y = q[1]; tick(25, () => { x += R * 2.5 / 25; ev('pointermove', 1, x, y); }); tick(30); ev('pointerup', 1, x, y); tick(60);
      q = c(); x = q[0] - R * .6; y = q[1]; ev('pointerdown', 1, x, y); tick(6, () => { x -= R * .35; y += R * .2; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(90);
      q = c(); let a = q[0] - R * .7, b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a += R * .55 / 30; b -= R * .55 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(30); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(60);
      q = c(); a = q[0] - R * .7; b = q[0] + R * .7; y = q[1]; ev('pointerdown', 1, a, y); ev('pointerdown', 2, b, y); tick(30, () => { a -= R * 1.2 / 30; b += R * 1.2 / 30; ev('pointermove', 1, a, y); ev('pointermove', 2, b, y); }); tick(20); ev('pointerup', 1, a, y); ev('pointerup', 2, b, y); tick(90);
      q = c(); ev('pointerdown', 1, q[0], q[1]); let th = 0; tick(240, () => { th += 2 * Math.PI * 2 * DT; ev('pointermove', 1, q[0] + 35 * Math.cos(th), q[1] + 35 * Math.sin(th)); }); ev('pointerup', 1, q[0], q[1]); tick(120);
      for (let k = 0; k < 6; k++) { q = c(); x = q[0] - R * .8; y = q[1] + R * (k * .25 - .6); ev('pointerdown', 1, x, y); tick(24, () => { x += R * 2 / 24; y += R * .1 / 24; ev('pointermove', 1, x, y); }); ev('pointerup', 1, x, y); tick(8); } tick(60);
      return { frames: n, crossFrames: xf, aMin: +aMin.toFixed(3), aMax: +aMax.toFixed(3), endSelfX: selfX() }; };
    r41.abuse = { clay: abuse('clay'), mochi: abuse('mochi'), jelly: abuse('jelly') };
    const keep = o => { L10('clay', o); let bi = bnd[0]; for (const i of bnd) if (X[i] > X[bi]) bi = i; const rest = X[bi] - globalC.xc, q = sc(X[bi] - R * .1, Y[bi]); let x = q[0]; ev('pointerdown', 1, x, q[1]); steps(6); for (let i = 0; i < 15; i++) { x += R / 15; ev('pointermove', 1, x, q[1]); steps(1); } steps(30); const pre = X[bi] - globalC.xc; ev('pointerup', 1, x, q[1]); steps(120); return +((X[bi] - globalC.xc - rest) / (pre - rest)).toFixed(2); };
    r41.keep2s = { on: keep({}), off: keep(OFF) };
    r41.pull.dragSide = pair('clay', -.5, 0, 0, 1, 1100, .2, .4);   // v2.26.1
    res.T41_v226 = r41; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }


  // T42 v2.27（多米 11-05：去眼睛、8 條真觸手、心情變色、觸手互撞）。舊項目都關（OFF27），這裡全開。
  //   a 外形：8 條、整隻在畫面裡、沒有眼睛；b 每條都抓得住、拉得長、抓著不抖（v2.8 真機就是這裡纏住抖）；c 黏土拉長留著、果凍彈回；
  //   d 往根推、繞到身體後面：滑開不對折；e 亂玩 3 種材質 2 組亂數：沒有留下對折或互疊、停得下來；f 撞到別條會彈開；g 心情染色、平常原色、不跳
  { const clock = saveClock(); Math.random = seeded(20261105); const r42 = {};
    const v = viewV(), sc = (x, y) => [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y];
    const QUIET = { emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, intro: 0, introSwim: 0, wander: 0, life: 0, pods: 0 };
    const L = (name, o) => { resetAligned(1e9, { ...P27[name], seed: 7, ...QUIET, ...(o || {}) }); impReset(); IMPD.tr = 0; IMPD.w = 0; CAM.x = viewV().x; MC.c = MC.s = MC.w = MC.z = 0; };
    const tip = k => { let b = -1; for (const i of bnd) if (TID[i] === k && (b < 0 || TU[i] > TU[b])) b = i; return b; };
    const rootOf = k => { let x = 0, y = 0; for (const i of TENT[k].root) { x += X[i]; y += Y[i]; } const n = TENT[k].root.length; return [x / n, y / n]; };
    const jit = (m, on) => { let jm = 0, xf = 0, ax = Float64Array.from(X), ay = Float64Array.from(Y); for (let i = 0; i < m; i++) { if (on) on(i); steps(1); let d = 0; for (let j = 0; j < N; j++) d = Math.max(d, Math.hypot(X[j] - ax[j], Y[j] - ay[j])); ax = Float64Array.from(X); ay = Float64Array.from(Y); if (i > m * .4) jm = Math.max(jm, d); if (classify()[0]) xf++; } return { jm: +jm.toFixed(1), xf }; };
    // a 外形
    L('clay'); { let a = 1e9, b = -1e9, c = 1e9, d = -1e9; for (const i of bnd) { const p = sc(X[i], Y[i]); a = Math.min(a, p[0]); b = Math.max(b, p[0]); c = Math.min(c, p[1]); d = Math.max(d, p[1]); } r42.shape = { tents: TENT.length, N, x0: a | 0, x1: b | 0, y0: c | 0, y1: d | 0, W, H, z: +CAM.z.toFixed(2), selfX: selfX(), eyes: ['clay', 'mochi', 'jelly'].map(k => P27[k].eyes) }; }
    // b 每條都抓得住
    r42.pulls = {}; for (const name of ['clay', 'mochi', 'jelly']) { L(name); let held = 9e9, gap = 0, hj = 0, xf = 0, grab = 0; for (let k = 0; k < TENT.length; k++) { const b = tip(k), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy) || 1, p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const f = fingers.get(1); held = Math.min(held, f.mem.length); const mv = jit(24, () => { x += ux / ul * R * 1.2 / 24; y += uy / ul * R * 1.2 / 24; ev('pointermove', 1, x, y); }); steps(40); const hold = jit(30); const g = sc(X[b], Y[b]); gap = Math.max(gap, Math.hypot(g[0] - x, g[1] - y)); hj = Math.max(hj, hold.jm); xf += mv.xf + hold.xf; if (f.mode === 'grab') grab++; ev('pointerup', 1, x, y); xf += jit(90).xf; } r42.pulls[name] = { minHeld: held, grabbed: grab, maxGap: +gap.toFixed(1), holdJ: hj, foldFrames: xf, end: selfX() }; }
    // b2 從身體中間往觸手的方向拉，要抓得住（一度會馬上滑開：補抓帶到觸手的粒子就被當成抓觸手）
    r42.bodyPull = {}; for (const name of ['clay', 'jelly']) { let lost = 0, mv = 0; for (let k = 0; k < TENT.length; k++) { L(name); const b = tip(k), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy), p = sc(c.xc + ux / ul * R * .3, c.yc + uy / ul * R * .3); let x = p[0], y = p[1]; const c0x = c.xc, c0y = c.yc; ev('pointerdown', 1, x, y); steps(8); const f = fingers.get(1); for (let i = 0; i < 16; i++) { x += ux / ul * R * 1.6 / 16; y += uy / ul * R * 1.6 / 16; ev('pointermove', 1, x, y); steps(1); } if (f.mode !== 'grab') lost++; mv = Math.max(mv, Math.hypot(globalC.xc - c0x, globalC.yc - c0y)); ev('pointerup', 1, x, y); steps(20); } r42.bodyPull[name] = { lost, moved: +mv.toFixed(1) }; }
    // c 長度留著
    const keep = name => { L(name); const b = tip(2), c = globalC, ux = X[b] - c.xc, uy = Y[b] - c.yc, ul = Math.hypot(ux, uy), p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); jit(24, () => { x += ux / ul * R * 1.2 / 24; y += uy / ul * R * 1.2 / 24; ev('pointermove', 1, x, y); }); jit(60); const held = Math.hypot(X[b] - globalC.xc, Y[b] - globalC.yc); ev('pointerup', 1, x, y); jit(120); const a2 = Math.hypot(X[b] - globalC.xc, Y[b] - globalC.yc); return { rest: +ul.toFixed(1), held: +held.toFixed(1), after2s: +a2.toFixed(1), keep: +((a2 - ul) / (held - ul)).toFixed(2) }; };
    r42.keep = { clay: keep('clay'), jelly: keep('jelly') };
    // d 往根推、繞到身體後面
    const cross = name => { L(name); let hj = 0, xf = 0, end = 0; for (let k = 0; k < TENT.length; k += 2) { const b = tip(k), c = globalC, p = sc(X[b], Y[b]), q = sc(c.xc - (X[b] - c.xc), c.yc - (Y[b] - c.yc)); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const dx = (q[0] - x) / 50, dy = (q[1] - y) / 50; const a = jit(50, () => { x += dx; y += dy; ev('pointermove', 1, x, y); }); const h = jit(40); hj = Math.max(hj, h.jm); xf += a.xf + h.xf; ev('pointerup', 1, x, y); xf += jit(120).xf; end += selfX(); } return { holdJ: hj, foldFrames: xf, end }; };
    const around = name => { L(name); let hj = 0, xf = 0, end = 0; for (let k = 0; k < TENT.length; k += 3) { const b = tip(k), c = globalC, a0 = Math.atan2(Y[b] - c.yc, X[b] - c.xc), rr = Math.hypot(X[b] - c.xc, Y[b] - c.yc) * 1.05, p = sc(X[b], Y[b]); let x = p[0], y = p[1]; ev('pointerdown', 1, x, y); const a = jit(70, i => { const an = a0 + (i + 1) / 70 * 2.4, q = sc(c.xc + Math.cos(an) * rr, c.yc + Math.sin(an) * rr); x = q[0]; y = q[1]; ev('pointermove', 1, x, y); }); const h = jit(40); hj = Math.max(hj, h.jm); xf += a.xf + h.xf; ev('pointerup', 1, x, y); xf += jit(120).xf; end += selfX(); } return { holdJ: hj, foldFrames: xf, end }; };
    r42.cross = {}; r42.around = {}; for (const name of ['clay', 'mochi', 'jelly']) { r42.cross[name] = cross(name); r42.around[name] = around(name); }
    // e 亂玩
    const abuse = (name, seed) => { Math.random = seeded(seed); L(name); let same = 0, n = 0; const cnt = () => { if (classify()[0]) same++; n++; }; for (let s = 0; s < 24; s++) { const c = globalC, a0 = Math.random() * 6.28, rr = R * (.3 + Math.random() * 1.3), p = sc(c.xc + Math.cos(a0) * rr, c.yc + Math.sin(a0) * rr); let x = p[0], y = p[1]; const a1 = Math.random() * 6.28, sp = R * (1 + Math.random() * 6) / 60, two = s % 5 === 4, x2 = x + R * .9, y2 = y; ev('pointerdown', 1, x, y); if (two) ev('pointerdown', 2, x2, y2); const m = 20 + Math.random() * 50 | 0; for (let i = 0; i < m; i++) { x += Math.cos(a1) * sp; y += Math.sin(a1) * sp; ev('pointermove', 1, x, y); if (two) ev('pointermove', 2, x2 + Math.cos(a1) * sp * i, y2 - Math.sin(a1) * sp * i); steps(1); cnt(); } for (let i = 0; i < 40; i++) { steps(1); cnt(); } ev('pointerup', 1, x, y); if (two) ev('pointerup', 2, x2, y2); for (let i = 0; i < 30; i++) { steps(1); cnt(); } } const last = jit(240), e = classify(); return { n, foldFrames: same, endJ: last.jm, endFold: e[0], endOverlap: e[1] }; };
    r42.abuse = {}; for (const name of ['clay', 'mochi', 'jelly']) r42.abuse[name] = [abuse(name, 11), abuse(name, 22)];
    // f 撞到別條會彈開：固定一條，拿另一條去撞
    const hit = (name, o, m) => { Math.random = seeded(5); L(name, o); const a = tip(0), b = tip(1), d = tip(3), dp = sc(X[d], Y[d]); ev('pointerdown', 2, dp[0], dp[1]); let p = sc(X[a], Y[a]), x = p[0], y = p[1]; const q = sc(X[b] + (X[b] - X[a]) * .9, Y[b] + (Y[b] - Y[a]) * .9); TBUMP.n = 0; ev('pointerdown', 1, x, y); const tr = [], rec = () => { const r = rootOf(1); tr.push([X[b] - r[0], Y[b] - r[1]]); }; const dx = (q[0] - x) / m, dy = (q[1] - y) / m; jit(m, () => { x += dx; y += dy; ev('pointermove', 1, x, y); rec(); }); jit(30, rec); ev('pointerup', 1, x, y); ev('pointerup', 2, dp[0], dp[1]); jit(60, rec); return { tr, kicks: TBUMP.n, end: selfX() }; };
    r42.bump = {}; for (const name of ['clay', 'jelly']) { const A = hit(name, {}, 40), B = hit(name, { tentBump: 0 }, 40); let dm = 0; for (let i = 0; i < Math.min(A.tr.length, B.tr.length); i++) dm = Math.max(dm, Math.hypot(A.tr[i][0] - B.tr[i][0], A.tr[i][1] - B.tr[i][1])); r42.bump[name] = { kicks: A.kicks, kicksOff: B.kicks, tipDiff: +dm.toFixed(1), end: A.end }; }
    // g 心情染色
    const near = (a, b) => { const p = s => s[0] === '#' ? [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)] : s.match(/\d+/g).map(Number), u = p(a), w = p(b); return Math.max(Math.abs(u[0] - w[0]), Math.abs(u[1] - w[1]), Math.abs(u[2] - w[2])); };
    { const O = { emo: 1, moodColor: .8 }, base = '#FFD96B'; L('clay', O); steps(180); r42.mood = { calmOff: near(tint(base), base), calm: { ...MC } };
      let c0 = globalC, p = sc(c0.xc, c0.yc), th = 0, maxStep = 0, prev = tint(base); ev('pointerdown', 1, p[0] + 30, p[1]); for (let i = 0; i < 240; i++) { th += .12; ev('pointermove', 1, p[0] + 30 * Math.cos(th), p[1] + 30 * Math.sin(th)); steps(1); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.comfy = +MC.c.toFixed(2); r42.mood.comfyOff = near(tint(base), base); r42.mood.purr = +PURR.toFixed(2); ev('pointerup', 1, p[0], p[1]); steps(30);
      L('clay', O); prev = tint(base); c0 = globalC; p = sc(c0.xc + R * .3, c0.yc); let x = p[0]; ev('pointerdown', 1, x, p[1]); steps(8); let spk = 0; for (let i = 0; i < 16; i++) { x += R * 2.6 / 16; ev('pointermove', 1, x, p[1]); steps(1); spk = Math.max(spk, MC.s); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } for (let i = 0; i < 40; i++) { steps(1); spk = Math.max(spk, MC.s); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.strain = +spk.toFixed(2); r42.mood.strainMax = +MOOD.strainMax.toFixed(2); ev('pointerup', 1, x, p[1]); steps(10);
      L('clay', { ...O, sleep: 1, life2: 1 }); prev = tint(base); SLP.lastAny = t; LIFE.st = 'sleep'; LIFE.until = 1e9; SLP.on = true; for (let i = 0; i < 300; i++) { steps(1); const q = tint(base); maxStep = Math.max(maxStep, near(q, prev)); prev = q; } r42.mood.sleep = +MC.z.toFixed(2); SLP.on = false; steps(5);
      L('clay', { ...O, imp: 1 }); IMP.w = .9; IMPD.w = .9; for (let i = 0; i < 90; i++) { IMP.w = .9; IMPD.w = .9; steps(1); } r42.mood.wary = +MC.w.toFixed(2); impReset(); IMPD.w = 0;
      r42.mood.maxStep = maxStep; mat = { ...mat, moodColor: 0 }; MC.c = MC.s = MC.w = MC.z = 0; r42.mood.offEqualsBase = near(tint(base), base); }
    { const cost = o => { L('clay', o); const c = globalC, p = sc(c.xc + R * .4, c.yc); ev('pointerdown', 1, p[0], p[1]); const t0 = performance.now(); for (let i = 0; i < 200; i++) { ev('pointermove', 1, p[0] + 40 * Math.cos(i / 10), p[1] + 40 * Math.sin(i / 10)); steps(1); } const ms = (performance.now() - t0) / 200; ev('pointerup', 1, p[0], p[1]); return +ms.toFixed(2); }; r42.msPerFrame = { off: cost({ limbs: 0 }), on: cost({}) }; }
    res.T42_v227 = r42; log.splice(0); restoreClock(clock); CAM.x = v.x; CAM.y = v.y; CAM.z = 1; FOL.x = v.x; FOL.y = v.y; mat = { ...PRESETS.clay }; }

  const L9 = res.T34_life;
  const V5 = res.T35_v220, P6 = res.T36_pull, V7 = res.T37_v222, X8 = res.T38_v223, Y9 = res.T39_v224, Z0 = res.T40_v225, A1 = res.T41_v226;
  res.PASS = {
    // folds must be gone once the finger is off (a fold the clay remembers would be a real bug)
    noFoldAfterRelease: [res.T1_tap.after2s, res.T2_hold.afterRelease1s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(s => s.fold === 0) && res.T7_idle.worstSelfX === 0,
    areaBack: [res.T1_tap.after2s, res.T3_pull.after3s, res.T4_twoFinger.after3s, res.T5_flail.after3s, res.T6_push.after2s].every(okArea) && res.T7_idle.areaMin > 0.97 && res.T7_idle.areaMax < 1.03,
    firstFrameMoves: res.T1_tap.firstFrameMove > 1,
    // 2026-11-01 多米真機回報後：黏土留痕放著約 10 秒退掉；輕按 0.1 秒留多少只記錄（T1.after2s.qdev）
    tapMarkGone: res.T1_tap.after12s.qdev < 1,
    holdLeavesMark: res.T2_hold.afterRelease1s.qdev > 3,
    // 門檻 1.5（v2.24）：T2 沒把呼吸相位歸零，掃 24 個相位量到 0.87 到 1.01，1 就壓在雜訊上（每輪長度一變就會掛）；揉回原形壞掉時是 19
    relaxClearsMark: res.T2_hold.afterRelax1s.qdev < 1.5,
    slowReleaseStillPops: rel(res.T3_pull.sfx) > 0.7,
    flickPops: rel(res.T9_flick.sfx) > 0.9,
    pushMakesPressSound: res.T6_push.sfx.some(e => e[0] === 'press'),
    cancelIsSilent: !res.T8_cancel.sfx.some(e => e[0] === 'release') && res.T8_cancel.fingersLeft === 0,
    candidatesDontBreak: res.T10_candidates.worstSelfX === 0 && okArea(res.T10_candidates.after) && res.T10_candidates.releases.length === 3,
    // 第 41 條修好的標準：握著時不能還留著對折；短暫幾幀（手指正好壓在接點上）先容忍，數字記在 T11
    // 2026-11-01 的水準：握著還在對折最多 1 個情境（手指正好壓在接點上）、對折幀數 100 以內；v2.4 以前是 6 個、282 幀
    // v2.9 起量的是 v2.7 對照（舊外形）：回到 v2.8 以前的判定，握著還對折最多 1 個情境、對折幀數 100 以內
    compressionFoldsRare: res.T11_compressionGrid.heldFoldRuns <= 1 && res.T11_compressionGrid.foldFrames < 100,
    // 第 20 條：拖尾只是表演，走完要收回來、過程不能自交或漏面積
    wanderTailClean: res.T12_wander.worstSelfX === 0 && res.T12_wander.areaMin > 0.97 && res.T12_wander.areaMax < 1.03 && res.T12_wander.afterStopPt < 1.5 && res.T12_wander.controlSame,
    // 第三批其餘（2026-11-01）：24 兩指捏要有 squish；25 滑脫要真的脫手、只啵一次；26 黏連要晚放、快甩不黏；候選全開也不壞
    pinchSquishes: res.T13_pinch.squishEvents >= 2 && res.T13_pinch.after3s.fold === 0 && okArea(res.T13_pinch.after3s),
    slipLetsGo: res.T14_slip.slipRelease === 1 && res.T14_slip.slipGain >= 0.99 && res.T14_slip.grabbedAfterSlip === 0 && res.T14_slip.popAfterLift === 0,
    stickDelaysPop: res.T15_stick.slow.popFrame >= 6 && res.T15_stick.slow.heldAtLift > 0 && res.T15_stick.slow.fingersLeft === 0 && res.T15_stick.fastImmediate,
    // 捏觸手要留痕、慢慢退；v2.7 對照應該一秒內就幾乎彈回（量法本身還抓得到差別）。過程零自交、面積回來
    // v2.14 起回原形放慢到 0.05（多米 build 59：回彈太快）：12 秒還在慢慢退（少於 1 秒時的 75%），不再要求退完
    pullKeepsMark: res.T17_pullMark.now.after1s > 3 && res.T17_pullMark.now.after12s < res.T17_pullMark.now.after1s * 0.75 && res.T17_pullMark.now.foldFramesAfter === 0 && okArea(res.T17_pullMark.now.end),
    podsGrowAnywhere: res.T19_pods.spawned >= 4 && res.T19_pods.upper > 0 && res.T19_pods.worstSelfX === 0 && res.T19_pods.areaMin > 0.95 && res.T19_pods.areaMax < 1.05 && res.T19_pods.maxOutPt > 0.25 * res.R,
    // 2026-11-01 多米：要能拉很長、攤很扁。往下拉 2.5R 握著要伸出 2R 以上、放手半秒還留 1.5R（之後照 recover 約 10 秒退）；
    // 兩指攤開放手 1 秒寬高比還是原本 1.3 倍以上；都不能自交、面積要回來
    sculptLong: res.T21_longPull.heldR > 2 && res.T21_longPull.after05sR > 1.5 && res.T21_longPull.worstSelfX === 0 && okArea(res.T21_longPull.end),
    sculptFlat: res.T22_flatten.after1sAspectX > 1.3 && res.T22_flatten.worstSelfX === 0 && okArea(res.T22_flatten.end),
    // 一壓就攤平：握著寬高比 1.5 倍以上、放手 1 秒還有 1.3 倍、最低點不穿過桌面超過 3 點；邊不能穿邊：拖過身體時交叉幀數比關掉時少、放手後沒有交叉
    pressFlattens: res.T23_pressFlat.heldAspectX > 1.5 && res.T23_pressFlat.after1sAspectX > 1.3 && res.T23_pressFlat.floorPassPt < 3 && res.T23_pressFlat.worstSelfX === 0 && okArea(res.T23_pressFlat.end),
    noCrossing: res.T24_dragAcross.guard.worstAfter === 0 && res.T24_dragAcross.guard.crossFrames <= res.T24_dragAcross.noGuard.crossFrames,
    // 鏡頭跟著拉遠：按在畫面右緣 3 秒要伸出 2.5R 以上（以前卡在 1.1R），放手 12 秒鏡頭回到 0.95 以上
    // 鏡頭無限拉遠（重複抓）：寬過 7R、鏡頭縮過 0.45、整隻一直在畫面裡、按著時邊界每幀跳動不到 3 點、放手後零交叉、面積回來
    zoomUnlimited: res.T26_zoomUnlimited.widthMaxR > 7 && res.T26_zoomUnlimited.zoomMin < 0.45 && res.T26_zoomUnlimited.offScreenFrames === 0 && res.T26_zoomUnlimited.jitterMaxPt < 5 && res.T26_zoomUnlimited.worstReleaseX === 0 && res.T26_zoomUnlimited.end.selfX === 0 && okArea(res.T26_zoomUnlimited.end),
    // 手指停住：形狀不自己長（< 0.3R）、邊界每幀跳動不到 3 點、零交叉
    stillFingerSteady: res.T29_stillFinger.every(r => r.grewR < 0.3 && r.jitterMaxPt < 3 && r.crossFrames === 0),
    // 點一下：按 0.1 秒凹痕深過 0.5、1 秒後還在、15 秒淡了但還看得到（0.15 以上）；拉開的那次凹痕收掉
    // 按壓：整團變大 4% 到 15%、關掉時不變；按 3 秒的最遠位移不超過 1.5 秒的 1.3 倍；黏土放手 1 秒凹痕還在；果凍過頭彈、1 秒收乾淨；零自交
    pressReal: res.T31_press.clayArea08 > 1.04 && res.T31_press.clayArea08 < 1.15 && res.T31_press.offArea08 < 1.01 && res.T31_press.clayMove3 < res.T31_press.clayMove15 * 1.3 && res.T31_press.clayDent1s > 0.5 && res.T31_press.jellyOvershoot < -0.1 && res.T31_press.jellyDentsAfter1s === 0 && res.T31_press.foldFrames === 0,
    // 開場：落地 4 次、落地壓扁到 0.9 以下、3.2 秒內、碰一下直接到家；鏡頭跟隨：會跑出畫面、4 秒後追到中心附近、抓著時鏡頭不動；全程零對折
    introFollow: res.T32_introFollow.introLands === 4 && res.T32_introFollow.landAspect < 0.9 && res.T32_introFollow.introSec < 3.2 && okArea(res.T32_introFollow.afterIntro) && res.T32_introFollow.skipOff && Math.abs(res.T32_introFollow.skipScale - 1) < 0.01 && res.T32_introFollow.skipFingers === 0 && res.T32_introFollow.followOutPt > 0 && res.T32_introFollow.followEndOff < PRESETS.clay.followStop + 0.1 && res.T32_introFollow.grabCamMovePt < 1 && res.T32_introFollow.foldFrames === 0,
    // 情緒：拉扯想逃（strain > 0.8、舒服變負、放手往反方向逃 0.4 畫面寬以上）、輕揉呼嚕（舒服、呼嚕 > 0.3、放手開心小跳）、連戳 3 下閃開；零對折、面積回來
    moodWorks: (s => !s.slow.flee && s.slow.strain === 0 && s.slow.red <= .2 && s.slow.held && s.slow.w === 0 && s.slowOld.flee && s.yankStop.w === 0 && s.yankStop.tr === 0 && s.yankGo.w === 0 && s.yankGo.tr === 0 && s.yankGo.vMax >= 6)(res.T33_mood) && res.T33_mood.strainHeld > 0.8 && res.T33_mood.moodPulled < 0 && res.T33_mood.fleeStarted && res.T33_mood.fledW > 0.4 && okArea(res.T33_mood.afterFlee) && res.T33_mood.purrMax > 0.3 && res.T33_mood.comfortMax > 0.3 && res.T33_mood.happyHop && res.T33_mood.dartStarted && res.T33_mood.dartW > 0.15 && res.T33_mood.foldFrames === 0,
    // v2.19 活物感：休息 0.35 到 0.65、有探有走；碰著呼吸還在、沒被記進形狀；晚一拍才縮、會習慣；一縮一衝的速度高峰在收縮那段、路線彎、走得到；
    // 碰旁邊空白處會探、不凍住；拉完甩一甩、探手指離開的地方；全程零對折
    // v2.20：拖著走（跟過去 0.55R 到 0.85R、被抓那端照樣跟手、放手不退、零自交、面積回來）；凹痕 0.6 秒、1.5 秒退完，形狀照舊；印象漲退；
    // C1 熟的碰到手指、戒的退開；C2 撲、嚇一下；C4 討摸後呼嚕來得快；C5 戒的縮得大；零對折
    v220: V5.drag.on.followR > 0.55 && V5.drag.on.followR < 0.85 && V5.drag.off.followR < 0.1 && Math.abs(V5.drag.on.grabGapR - V5.drag.off.grabGapR) < 0.3 && V5.drag.on.backAfter2sR < 0.1 && V5.drag.on.worstSelfX === 0 && V5.drag.on.end.area < V5.drag.off.end.area + 0.01
      && V5.dent.tapAt06 < 0.05 && V5.dent.holdAt15 < 0.05 && V5.dent.tapOldAt06 > 0.4 && V5.dent.qdevDiffPt < 0.5
      && V5.imp.trAfterRub6s > 0.1 && V5.imp.wAfterStrain > 0.2 && V5.imp.wAfter3minRatio > 0.45 && V5.imp.wAfter3minRatio < 0.55
      && V5.c1.come.hitS >= 0 && V5.c1.come.hitS < 6 && V5.c1.backGainR > 0.5 && V5.c1.end.selfX === 0
      && V5.c2.pounceS >= 0 && V5.c2.pounceS < 0.5 && V5.c2.startled
      && V5.c4.firstPurrS > 1 && V5.c4.asked && V5.c4.secondPurrS >= 0 && V5.c4.secondPurrS < 0.6 && V5.c5.flinchRatio > 1.5 && V5.foldFrames === 0,
    // v2.21 拉力：果凍單指拉 2.5R 整團跟 1.5R 以上、拉長 0.9R 以下（slide 0 不到 0.7R）；猛一扯比慢拉長 0.3R；兩指往兩邊拉寬過 4.5R、整團不動；甩出去再滑 0.3R；零自交、面積回來
    pullForce: P6.jelly.moveR > 1.5 && P6.jelly.stretchR < 0.9 && P6.jellyOff.moveR < 0.7 && P6.clayYank.maxStretchR > P6.claySlow.maxStretchR + 0.3 && P6.twoFinger.widthR > 4.5 && P6.twoFinger.moveR < 0.2
      && P6.fling.glideR > 0.3 && P6.worstSelfX === 0 && okArea(P6.jelly.end) && okArea(P6.fling.end),
    // v2.22：點一下會傾、會「噗」；按著會蹭、會「嗯～」；搔癢會扭、會笑、撥久會掙脫；E3 熟得快；E4 會游過來打招呼；零自交
    v222: V7.tap.leanAfter > 0.25 && V7.tap.leanAfter < 0.45 && V7.tap.voices.includes('poke') && V7.nuzzle.swayR > 0.03 && V7.nuzzle.voices.includes('mmm')
      && V7.tickle.shakes >= 3 && V7.tickle.escapeS > 3.2 && V7.tickle.escapeS < 5 && V7.tickle.voices.includes('giggle') && V7.tickle.voices.includes('protest')
      && V7.e3.trOn > 0.5 && V7.e3.trOff < 0.3 && V7.e4.count === 1 && V7.e4.helloAt > 0 && V7.e4.distR < 0.6
      && V7.worstSelfX === 0,
    // v2.23：眼睛看手指、會眨、搔癢 > <、呼嚕 ∩；40 秒睡著、碰到嚇醒；照節奏回、你接著回它會開心、點一下不回；游過來到家打招呼、鏡頭不動；四隻都正常、印象分開記
    v223: X8.eyes.lookGx > 0.5 && X8.eyes.blinks10s >= 2 && X8.eyes.tickleSqueeze > 10 && X8.eyes.purrHappy > 10
      && X8.sleep.at >= 39.9 && X8.sleep.at < 45 && X8.sleep.eye === 'sleep' && X8.sleep.woke && X8.sleep.flinch > 0.06 && X8.sleep.voices.includes('ask')
      && X8.echo.beats === 3 && X8.echo.iv.every(x => x > 0.35 && x < 0.45) && X8.echo.firstAfter > 0.9 && X8.echo.firstAfter < 1.6 && X8.echo.again === 3 && X8.echo.joy && X8.echo.single === 0
      && X8.swim.startOffR > 2 && X8.swim.arriveS > 0 && X8.swim.arriveS < 4.5 && X8.swim.helloS > 0 && X8.swim.camMoved < 5 && X8.swim.end.selfX === 0
      && X8.collect.slimes.every(q => q.mat && q.seed && q.color && q.aMin > 0.97 && q.aMax < 1.03 && q.selfX === 0) && X8.collect.impBack === 0.7 && X8.worstSelfX === 0,
    // v2.26：見 T41 開頭的 a 到 h
    v227: (() => { const A = res.T42_v227, s = A.shape, ok3 = f => ['clay', 'mochi', 'jelly'].every(f); return s.tents === 8 && s.selfX === 0 && s.x0 >= 0 && s.x1 <= s.W && s.y0 >= 0 && s.y1 <= s.H && s.z >= .85 && s.eyes.every(e => e === 0)
      && ok3(k => { const p = A.pulls[k]; return p.grabbed === 8 && p.minHeld >= 5 && p.maxGap < 25 && p.holdJ < 6 && p.foldFrames === 0 && p.end === 0; }) && A.bodyPull.clay.lost === 0 && A.bodyPull.jelly.lost === 0 && A.keep.clay.keep > .6 && A.keep.jelly.keep < .4
      && ok3(k => A.cross[k].holdJ < 15 && A.cross[k].foldFrames === 0 && A.cross[k].end === 0 && A.around[k].holdJ < 15 && A.around[k].end === 0)
      && ok3(k => A.abuse[k].every(r => r.foldFrames < r.n * .05 && r.endFold === 0 && r.endJ < 12))
      && A.bump.clay.kicks >= 1 && A.bump.clay.tipDiff > 5 && A.bump.clay.kicksOff === 0 && A.bump.clay.end === 0
      && A.mood.calmOff <= 1 && A.mood.comfy > .5 && A.mood.comfyOff > 20 && A.mood.purr > .1 && A.mood.strain > .4 && A.mood.sleep > .5 && A.mood.wary > .5 && A.mood.maxStep < 25 && A.mood.offEqualsBase === 0; })(),
    v226: ['clay', 'mochi', 'jelly'].every(k => { const a = A1.swipe[k], q = A1.swipe[k + 'Fast'], o = A1.swipe[k + 'Off']; return a.first === 'stroke' && a.end === 'stroke' && a.peakR < .3 && a.backPt < 2 && a.crossFrames === 0 && a.qdev < 1 && q.first === 'stroke' && q.peakR < .3 && q.crossFrames === 0 && o.first === 'grab' && o.peakR > .5; })
      && ['edge', 'rb', 'center', 'dragSlow', 'dragSide', 'yank', 'press'].every(k => { const p = A1.pull[k]; return p.on.first === 'grab' && p.on.end === 'grab' && Math.abs(p.on.moveR - p.off.moveR) < .05 && p.on.crossFrames === 0; })
      && A1.twoFinger.m1 === 'grab' && A1.twoFinger.m2 === 'grab' && A1.twoFinger.widthR > 3.2 && A1.secondFinger.before === 'stroke' && A1.secondFinger.after === 'grab' && A1.secondFinger.m2 === 'grab'
      && A1.stopGrab.mid === 'stroke' && A1.stopGrab.memMid === 0 && A1.stopGrab.after === 'grab' && A1.stopGrab.memAfter > 0 && A1.stopGrab.movedPt > 40
      && A1.fromOut.end === 'stroke' && A1.fromOut.peakR < .35 && A1.fromOut.backPt < 2 && A1.fromOut.crossFrames === 0 && A1.slowPush.end === 'push'
      && A1.pet.firstPurrS > 0 && A1.pet.firstPurrS < 2.5 && A1.pet.purrMax > .2 && A1.pet.tr > 0 && !A1.pet.esc && !A1.pet.flinched && A1.pet.happy
      && A1.visible.clay > A1.visible.clayOff + 1500 && A1.visible.jelly > A1.visible.jellyOff + 1500 && A1.rub.mode === 'grab' && A1.rub.dentD > .5 && A1.rub.trail > 5 && A1.rub.trailAfter === 0
      && A1.hi.big > 1.1 && ['clay', 'mochi', 'jelly'].every(k => A1.abuse[k].crossFrames === 0 && A1.abuse[k].endSelfX === 0) && A1.keep2s.on >= A1.keep2s.off - .03,
    // v2.25：見 T40 開頭的 a 到 g
    v225: ['clay', 'mochi', 'jelly'].every(k => Z0.ring[k].firstMs > 120 && Z0.ring[k + 'Off'].firstMs < 50 && Z0.ring[k].jump < 8 && Z0.ring[k].maxV < Z0.ring[k + 'Off'].maxV / 2) && Z0.ring.mochi.swings >= 3 && Z0.ring.jelly.swings >= 3 && Z0.ring.clay.keep1s >= Z0.ring.clayOff.keep1s - .02 && Z0.ring.jellyOff.jump > 20
      && ['clay', 'mochi', 'jelly'].every(k => Z0.stop[k].overPt > 8 && Z0.stop[k].atS > .15 && Z0.stop[k].atS < .6 && Z0.stop[k].crossFrames === 0) && Z0.stop.clayOff.overPt < 1 && Z0.stop.jellyOff.overPt < 1
      && ['clay', 'mochi', 'jelly'].every(k => Math.abs(Z0.pull[k].moveR - Z0.pull[k + 'Off'].moveR) < .05 && Math.abs(Z0.pull[k].gap - Z0.pull[k + 'Off'].gap) < 3)
      && ['clay', 'mochi', 'jelly'].every(k => Z0.fling[k].crossFrames === 0 && Z0.fling[k].qdMaxR < 2.5 && Z0.fling[k].endSelfX === 0 && Z0.press[k].jump < 8 && Z0.press[k].crossFrames === 0) && Z0.twoOne.clay.crossFrames === 0 && Z0.twoOne.jelly.crossFrames === 0 && Z0.twoOne.jelly.jump < 20 && Z0.relax.crossFrames === 0 && Z0.relax.qdevPt < 5
      && Z0.idleQdPt < .5 && Z0.reduced.swings <= 1 && ['clay', 'mochi', 'jelly'].every(k => Z0.abuse[k].crossFrames === 0 && Z0.abuse[k].endSelfX === 0) && Z0.walk.crossFrames === 0 && Z0.walk.qdMaxR < .2,
    // v2.24：見 T39 開頭的 a 到 g
    v224: Y9.size.rOverW > 0.29 && Y9.size.widthPt > 220 && Y9.size.z > 0.99
      && Y9.tap.flinchMin < 0.91 && Y9.tap.leanGainR > 0.12 && Y9.nuzzleSwingR > 0.15 && Y9.gazeR > 0.15 && !Y9.dodge.on.l && !Y9.dodge.on.r
      && [Y9.rub.c1cm, Y9.rub.c5cm, Y9.rub.c12cm, Y9.rub.l5cm, Y9.rub.l7cm, Y9.rub.jelly, Y9.rub.mochi].every(q => q.purr >= 0 && q.purr < 1.7 && q.tickle < 0 && q.free < 0) && Y9.rub.hold.purr > 1.9 && Y9.rub.oldRub.purr < 0
      && Y9.rub.tickle.tickle >= 0 && Y9.rub.tickle.tickle < 1 && Y9.rub.tickle.free > 5.5 && Y9.rub.tickle.free < 7.5 && Y9.rub.tickle.protest > 0 && Y9.rub.tickle.protest < Y9.rub.tickle.free - 1 && Y9.rub.tickle.kink < 65
      && Y9.reach.on.edgePinned === 0 && Y9.reach.on.kink < 25 && Y9.reach.off.edgePinned > 0 && Y9.hold.on < 25 && Y9.hold.off > 35 && Y9.pressMemPt > 3 && Y9.reach.right.edgeMovedR > 0.8 && Y9.reach.up.edgeMovedR > 0.8 && Y9.reach.right.selfX === 0 && Y9.reach.up.selfX === 0
      && Y9.cam.r70.gapPt < 10 && Y9.cam.r70.z > 0.99 && Y9.cam.r90.gapPt < 10 && Y9.cam.d300.gapPt < 20 && Y9.cam.oldR100.gapPt > 40 && Y9.cam.r90.rightAfter < W - 8 && Y9.cam.oldD300.gapPt > 60
      && Y9.keep.keep2s > 0.75 && ['clay', 'mochi', 'jelly'].every(k => Y9.abuse[k].crossFrames === 0 && Y9.abuse[k].endSelfX === 0),
    lifeV219: L9.idle.restFrac > 0.35 && L9.idle.restFrac < 0.65 && L9.idle.sniffs >= 4 && L9.idle.goes >= 2 && L9.idle.worstSelfX === 0 && L9.idle.areaMin > 0.97 && L9.idle.areaMax < 1.03
      && L9.held.ratio > 0.35 && L9.held.ratioOff < 0.15 && L9.held.qdev1s < L9.held.qdev1sOff + 1
      && Math.abs(L9.flinch.at05 - 1) < 0.015 && L9.flinch.at30 < 0.96 && L9.flinch.fifthOverFirst < 0.3
      && L9.gait.strokes >= 8 && L9.gait.peakInContraction >= 0.8 && L9.gait.headingSpreadDeg > 8 && L9.gait.endDistR < 0.5 && L9.gait.worstSelfX === 0 && L9.gait.areaMin > 0.97 && L9.gait.areaMax < 1.03
      && L9.blank.sniffEnv06s > 0.3 && L9.blank.angDeg < 30 && L9.blank.breathRange > 0.005
      && L9.release.shakeAt > 0.25 && L9.release.shakeAt < 0.45 && L9.release.attendAt > 0.4 && L9.release.attendAt < 0.8 && L9.release.attendAngDeg < 30 && L9.release.end.selfX === 0 && L9.foldFrames === 0,
    dentOnTap: res.T30_dent.heldDepth > 0.5 && res.T30_dent.after1s > 0.5 && res.T30_dent.after15s > 0.15 && res.T30_dent.after15s < res.T30_dent.after1s && res.T30_dent.dentsAfterPull === 0,
    // 從中間往右、往上拉 2R，那一側外圈要跟出去 1.5R 以上（v2.13 是 -0.08R）；零自交、面積回來
    pullFromMiddle: ['right', 'up'].every(k => res.T27_pullFromMiddle[k].edgeMovedR > 1.5 && res.T27_pullFromMiddle[k].worstSelfX === 0 && okArea(res.T27_pullFromMiddle[k].end)),
    // 回彈：放手 2 秒還留八成以上（v2.13 約五成）
    relaxSlow: res.T28_relax.keep2s > 0.8 && res.T28_relax.end.selfX === 0,
    // 按在畫面邊：手指能走多遠就伸多遠（手機寬約 1.2R 以上）、鏡頭有退，停著的 3 秒不能自己長超過 0.3R（v2.14 會一直長）
    edgeHoldStretches: res.T25_edgeHold.reachR > 1.2 && res.T25_edgeHold.zoomMin < 0.95 && res.T25_edgeHold.grewWhileStillR < 0.3 && res.T25_edgeHold.zoomAfter12s > res.T25_edgeHold.zoomMin + 0.1 && res.T25_edgeHold.worstSelfX === 0 && okArea(res.T25_edgeHold.end),
    jellyRegular: Math.abs(res.T20_jelly.periodMean - PRESETS.clay.jellyT) < 0.15 && res.T20_jelly.periodStd < 0.1 && res.T20_jelly.aspectSwing > 0.05 && res.T20_jelly.contractShare < 0.4,
    idleMorphClean: res.T18_idleMorph.now.worstSelfX === 0 && res.T7_idle.worstSelfX === 0 && res.T18_idleMorph.now.areaMin > 0.97 && res.T18_idleMorph.now.areaMax < 1.03,
    batch3DontBreak: res.T16_batch3.worstSelfX === 0 && Math.abs(res.T16_batch3.after.area - 1) < 0.03 && res.T16_batch3.areaMin > 0.97 && res.T16_batch3.areaMax < 1.03 && res.T16_batch3.releases === 3,
  };
  // T43 v2.28 預覽：切換列只換畫面。三種皮畫得出來、切來切去物理不變、平塗和 v2.27 同一條路徑
  { mat = { ...PRESETS.clay, emo: 0, life2: 0 }; setup(); WANDER.moving = false; WANDER.next = t + 999; steps(30);
    const cx = globalC.xc, cy = globalC.yc, r43 = { skins: {} }, pix = () => { draw(); const d = ctx.getImageData(Math.round(cx * DPR), Math.round(cy * DPR), 1, 1).data; return [d[0], d[1], d[2]]; }, X0 = Float64Array.from(X), bg0 = (VIEW.skin = 'flat', pix());
    for (const k of ['A', 'B', 'C', 'flat']) { VIEW.skin = k; let threw = null; try { r43.skins[k] = pix(); } catch (e) { threw = e.message; } if (threw) r43.skins[k] = threw; }
    let dx = 0; for (let i = 0; i < N; i++) dx = Math.max(dx, Math.abs(X[i] - X0[i]));
    r43.moved = +dx.toFixed(6); r43.flatSame = r43.skins.flat.join() === bg0.join(); r43.jelFail = JEL.fail;
    VIEW.skin = 'flat'; res.T43_v228 = r43;
    res.PASS.v228 = !r43.jelFail && r43.moved === 0 && r43.flatSame && ['A', 'B', 'C'].every(k => Array.isArray(r43.skins[k]) && r43.skins[k].join() !== bg0.join()); }
  // T44 v2.28 窗台：有重力、坐得進碗、不飄走、不穿地板。背景藍的舊項目完全不受影響（SILL.on 關）
  { const r = {}, SP = { ...P27.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, emo: 0, life2: 0, seed: 12, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, lookNoDown: 0 };   // v2.63 C5：張望不朝下（lookNoDown）預設 1 之後窗台上張望的方向變了，這一項量的是舊規格，釘 0
    const bottom = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, Y[i]); return m; }, top = () => { let m = 1e9; for (const i of bnd) m = Math.min(m, Y[i]); return m; };
    const fresh = () => { mat = { ...SP }; setup(); WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; };
    const worst = n => { let lo = 1e9, hi = -1e9, x0 = 1e9, x1 = -1e9, sx = 0, ar0 = 9, ar1 = 0, maxFold = 0; for (let k = 0; k < n; k++) { steps(1); lastTouch = t; const b = bottom(); lo = Math.min(lo, b); hi = Math.max(hi, b); for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } const a = area() / A0; ar0 = Math.min(ar0, a); ar1 = Math.max(ar1, a); } return { lo, hi, x0, x1, ar0, ar1 }; };
    // a 掉進碗裡停住
    fresh(); const g = SILL.g, y0 = bottom(); const a1 = worst(240); const b1 = bottom(), cy1 = globalC.yc; const a2 = worst(120);
    r.bowl = { on: SILL.on, inBowl: SILL.inBowl, startedAbove: y0 < g.rim, drift: +Math.abs(globalC.yc - cy1).toFixed(2), x: +(globalC.xc - g.bx).toFixed(1), range: +(a2.hi - a2.lo).toFixed(2), belowFloor: +(a1.hi - g.fl).toFixed(2), area: [+a1.ar0.toFixed(3), +a1.ar1.toFixed(3)], selfX: snap().selfX, air: SILL.air };
    // b 往上拉會拉高，放手掉回碗裡；拉的時候手指底下那塊跟手
    { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy - R * .4); steps(4); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, cy - R * .4 - k * R * 2.2 / 40); steps(1); } steps(20); const lift = cy - globalC.yc, outB = !SILL.inBowl; ev('pointerup', 1, cx, cy - R * 2.6); const a3 = worst(30), mid = SILL.air; const a4 = worst(240); r.pull = { liftR: +(lift / R).toFixed(2), leftBowl: outB, airAfter: mid, backInBowl: SILL.inBowl, belowFloor: +(a4.hi - g.fl).toFixed(2), selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    // c 甩到旁邊：掉到窗台上，不在碗裡，停得住
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 16; k++) { ev('pointermove', 1, cx + k * (W * .44) / 16, cy - k * R * .4 / 16); steps(1); } steps(14); ev('pointerup', 1, cx + W * .44, cy - R * .4); const a5 = worst(60); const a6 = worst(300); r.side = { inBowl: SILL.inBowl, onSill: Math.abs(a6.hi - g.fl) < 2, belowFloor: +(Math.max(a5.hi, a6.hi) - g.fl).toFixed(2), x: +globalC.xc.toFixed(0), inFrame: a6.x0 >= g.l - .5 && a6.x1 <= g.r + .5, selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    // d 走路：高度不變，往目標走
    { const x0 = globalC.xc, tx = sillClampX(x0 + (x0 < W / 2 ? 1 : -1) * R * 1.3); mat.life2 = 1; mat.lifeGait = 1; gaitTo(tx, 0, false); const dir = Math.sign(tx - x0); let lo = 1e9, hi = -1e9, n = 0; while (GAIT.on && n < 600) { lastTouch = t - 3; steps(1); const b = bottom(); lo = Math.min(lo, b); hi = Math.max(hi, b); n++; } r.walk = { frames: n, moved: +((globalC.xc - x0) * dir / R).toFixed(2), footRange: +(hi - lo).toFixed(2), selfX: snap().selfX }; mat.life2 = 0; }
    // e 閒著就爬回碗（v2.30：閒 25 秒，用爬的）
    { lastTouch = t - 30; SILL.lastHome = t - 20; LIFE.st = 'rest'; let n = 0; let peak = 1e9; while (!SILL.inBowl && n < 900) { steps(1); peak = Math.min(peak, bottom()); n++; } while (SILL.route && n < 1200) { steps(1); n++; } const a7 = (lastTouch = t, worst(180)); r.home = { frames: n, inBowl: SILL.inBowl, clearedRim: peak < g.lip, belowFloor: +(a7.hi - g.fl).toFixed(2), selfX: snap().selfX }; }
    // f 跳出碗
    { sillHop(sillClampX(g.bx + g.bw * .5 + R * 1.2), false); const a8 = worst(180); r.hopOut = { inBowl: SILL.inBowl, onSill: Math.abs(bottom() - g.fl) < 2, rose: +(g.rim - a8.lo).toFixed(1), x: +((globalC.xc - g.bx) / R).toFixed(2), selfX: snap().selfX, belowFloor: +(a8.hi - g.fl).toFixed(2) }; }   // v2.31 碗在中間：嚇到是原地跳一下再掉回碗裡（旁邊放不下）
    // g 慢慢放到右窗框旁邊：黏住（v2.30 窗框層，貼著的面重力轉向）；再抓就回窗台層
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc, tx = g.jr - R * .6, ty = g.gy + R * .9; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 70; k++) { ev('pointermove', 1, cx + (tx - cx) * k / 70, cy + (ty - cy) * k / 70); steps(1); } steps(50); ev('pointerup', 1, tx, ty); steps(3); const stuck = SILL.plane === 'frame' && SILL.surf === 'rjamb'; steps(60); lastTouch = t; const held = SILL.surf === 'rjamb', fell = SILL.plane === 'room' && SILL.surf === 'floor' && !SILL.inBowl; ev('pointerdown', 1, globalC.xc, globalC.yc); steps(2); const regrab = SILL.plane === 'room' && SILL.surf == null; ev('pointerup', 1, globalC.xc, globalC.yc); worst(240); r.stick = { stuck, held, fell, regrab, selfX: snap().selfX }; }   // v2.31 只跟碗互動（envFrame 0）：慢慢放在窗框旁邊不黏，掉回窗台；黏窗框在 T46 用 envFrame 1 量
    // h 拉不出房間：往下壓不穿地板、拉到上面不出畫面
    fresh(); worst(180); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx, cy + k * H * .5 / 30); steps(1); } const a10 = worst(30); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, cy + H * .5 - k * H * 1.1 / 40); steps(1); } steps(20); const tp = top(); ev('pointercancel', 1, 0, 0); r.bounds = { belowFloor: +(a10.hi - g.fl).toFixed(2), top: +tp.toFixed(1), selfX: snap().selfX }; }
    // 全程開：活物、情緒都開，放 25 秒不碰，不飛走不穿牆
    mat = { ...SP, emo: 1, life2: 1, lifeGait: 1 }; setup(); { let hi = -1e9, x0 = 1e9, x1 = -1e9, m = 0; for (let k = 0; k < 1500; k++) { steps(1); hi = Math.max(hi, bottom()); for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } m = Math.max(m, Math.abs(globalC.yc - SILL.g.fl)); } r.alive = { belowFloor: +(hi - SILL.g.fl).toFixed(2), x0: +x0.toFixed(0), x1: +x1.toFixed(0), inFrame: x0 >= SILL.g.l - R * .3 && x1 <= SILL.g.r + R * .3, maxFromFloorR: +(m / R).toFixed(2), selfX: snap().selfX, area: +(area() / A0).toFixed(3) }; }
    mat = { ...PRESETS.clay }; setup();
    r.offInBlue = SILL.on === false;
    res.T44_sill = r;
    res.PASS.sill = r.bowl.on && r.bowl.inBowl && r.bowl.startedAbove && !r.bowl.air && r.bowl.drift < 1.5 && Math.abs(r.bowl.x) < 6 && r.bowl.belowFloor <= .01 && r.bowl.area[0] > .9 && r.bowl.area[1] < 1.1 && r.bowl.selfX === 0
      && r.pull.liftR > .6 && r.pull.leftBowl && r.pull.backInBowl && r.pull.belowFloor <= .01 && r.pull.selfX === 0 && Math.abs(r.pull.area - 1) < .06
      && !r.side.inBowl && r.side.onSill && r.side.belowFloor <= .01 && r.side.inFrame && r.side.selfX === 0
      && r.walk.moved > .5 && r.walk.footRange < 6 && r.walk.selfX === 0
      && r.home.inBowl && r.home.clearedRim && r.home.belowFloor <= .01 && r.home.selfX === 0
      && r.hopOut.inBowl && !r.hopOut.onSill && r.hopOut.rose > R * .2 && r.hopOut.selfX === 0
      && !r.stick.stuck && !r.stick.held && r.stick.fell && r.stick.regrab && r.stick.selfX === 0
      && r.bounds.belowFloor <= 6 && r.bounds.top >= -R * .4 && r.alive.belowFloor <= .01 && r.alive.inFrame && r.alive.maxFromFloorR < 6 && r.alive.selfX === 0 && Math.abs(r.alive.area - 1) < .1 && r.offInBlue; }
  res.ALL_PASS = Object.values(res.PASS).every(Boolean);

  // T45 v2.29（多米 11-06：拉扯時眼睛常常不在體內、常常打結、黏液取消）。三種材質、窗台上，六種亂拉：
  // 眼睛任何一幀都在外框裡；記住的形狀沒有翻面的三角形；放手 1 秒後外框沒有交叉；交叉的幀數很少；身體不會爆開；猛扯不會有黏液。
  // 同時量關掉防打結（OFF29）的結果當對照，黏土的留形不能因此變差。
  { const clock = saveClock(); const r = {}, OFF29 = { noFlip: 0, gripUp: .2, homeCap: 0, fingerSolid: 0, softWall: 0 };
    const SP = n => ({ ...P27[n], limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 7, lookNoDown: 0 });   // v2.63 C5：張望不朝下（lookNoDown）預設 1 之後窗台上張望的方向變了，這一項量的是舊規格，釘 0
    const center = () => { const g = SILL.g, dx = W / 2 - g.bx; g.bx = W / 2; PROPS.length = 0; for (let i = 0; i < N; i++) { X[i] += dx; PX[i] += dx; } CX += dx; HOMEX += dx; };   // v2.30 碗移到左邊，這組路徑會把手指帶到畫面外（x<0），真人做不到；量身體本身就把碗放回中間、拿掉擺飾，跟 v2.29 同一件事
    const flips = (AX, AY) => { let f = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if ((AX[b] - AX[a]) * (AY[c] - AY[a]) - (AY[b] - AY[a]) * (AX[c] - AX[a]) <= 0) f++; } return f; };
    const paths = { whirl: (k, cx, cy) => k < 30 ? [[1, cx + R * (.75 + 1.45 * k / 30), cy - R * .6 * k / 30]] : k < 210 ? [[1, cx + R * 2.2 * Math.cos(-.27 + (k - 30) / 180 * Math.PI * 4), Math.max(60, cy + R * 2.2 * Math.sin(-.27 + (k - 30) / 180 * Math.PI * 4))]] : null,
      through: (k, cx, cy) => k < 40 ? [[1, cx, cy - R * .7 + R * 2.7 * k / 40]] : k < 80 ? [[1, cx + R * .6 * Math.sin((k - 40) / 40 * 6), cy + R * 2 - R * 4.5 * (k - 40) / 40]] : k < 120 ? [[1, cx, cy - R * 2.5 + R * 4.1 * (k - 80) / 40]] : null,
      zigzag: (k, cx, cy) => k < 150 ? [[1, cx + R * .6 + R * 1.5 * Math.sin(k / 150 * Math.PI * 10), cy + R * .8 * Math.sin(k / 150 * Math.PI * 7)]] : null,
      cross: (k, cx, cy) => k < 30 ? [[1, cx - R * .7 - R * 1.3 * k / 30, cy - R * .2]] : k < 90 ? [[1, cx - R * 2 + R * 4.2 * (k - 30) / 60, cy - R * .2 + R * .3 * Math.sin((k - 30) / 60 * 9)]] : k < 150 ? [[1, cx + R * 2.2 - R * 4.4 * (k - 90) / 60, cy - R * .2 - R * .5 * Math.sin((k - 90) / 60 * 5)]] : null,
      twoTurn: (k, cx, cy) => { if (k >= 210) return null; const d = k < 30 ? .6 + 1.2 * k / 30 : 1.8, a = k < 30 ? 0 : (k - 30) / 180 * Math.PI * 3; return [[1, cx - R * d * Math.cos(a), cy - R * d * Math.sin(a)], [2, cx + R * d * Math.cos(a), cy + R * d * Math.sin(a)]]; } };
    const run = (name, kind, over) => { Math.random = seeded(4501); mat = { ...SP(name), ...over }; setup(); center(); t = 0; lastTouch = -10; tLife = 0; relaxUntil = -1; steps(200); const cx = globalC.xc, cy = globalC.yc, fn = paths[kind]; const p0 = fn(0, cx, cy); for (const d of p0) ev('pointerdown', d[0], d[1], d[2]);
      let frames = 0, crossF = 0, eyeOut = 0, eyeMin = 1e9, afterX = 0, nan = 0; const look = () => { frames++; if (selfX()) crossF++; const P = boundaryPts(), e = EYE.pose; if (e) { const a = sdRing(P, e[0], e[1]), b = sdRing(P, e[2], e[3]); eyeMin = Math.min(eyeMin, a, b); if (a < 0 || b < 0) eyeOut++; } if (!Number.isFinite(X[0] + Y[0])) nan++; };
      for (let k = 0; ; k++) { const q = fn(k, cx, cy); if (!q) break; for (const d of q) ev('pointermove', d[0], d[1], d[2]); steps(1); look(); }
      for (const d of p0) ev('pointerup', d[0], d[1], d[2]); for (let k = 0; k < 180; k++) { steps(1); look(); if (k >= 60 && selfX()) afterX++; }
      return { frames, crossF, eyeOut, eyeMin: +eyeMin.toFixed(1), afterX, qFlip: TRI.length ? flips(QX, QY) : 0, nan, area: +(area() / A0).toFixed(3) }; };
    r.abuse = {}; for (const n of ['clay', 'mochi', 'jelly']) { r.abuse[n] = {}; for (const kind of Object.keys(paths)) r.abuse[n][kind] = run(n, kind, {}); }
    // 對照：關掉時眼睛會出界（確認量得到）
    r.off = run('clay', 'twoTurn', OFF29);
    // 留形：黏土拉 1.5R 放手 2 秒，開關差不到 0.05
    const keep = over => { Math.random = seeded(4502); mat = { ...SP('clay'), emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, ...over }; setup(); center(); t = 0; lastTouch = -10; tLife = 0; relaxUntil = -1; steps(120); let tip = -1; for (const i of bnd) if (tip < 0 || Y[i] < Y[tip]) tip = i; const y0 = Y[tip], cx = X[tip]; ev('pointerdown', 1, cx, y0 + 2); steps(2); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, y0 + 2 - R * 1.5 * k / 40); steps(1); } steps(30); let top0 = 1e9; for (const i of bnd) top0 = Math.min(top0, Y[i]); ev('pointerup', 1, cx, y0 - R * 1.5); steps(120); let qt = 1e9, q0 = 1e9; for (const i of bnd) { qt = Math.min(qt, QY[i]); q0 = Math.min(q0, Q0Y[i]); } return +((q0 - qt) / R).toFixed(3); };
    r.keep = { on: keep({}), off: keep(OFF29) };
    // 跟手：等速拖 0.5 秒，被抓那塊落後手指多少點（開關差不到 8 點）
    const follow = over => { Math.random = seeded(4503); mat = { ...SP('clay'), emo: 0, life2: 0, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, ...over }; setup(); center(); t = 0; lastTouch = -10; tLife = 0; relaxUntil = -1; steps(120); const cx = globalC.xc, cy = globalC.yc - R * .3; ev('pointerdown', 1, cx, cy); steps(3); const f = fingers.get(1); let gap = 0; for (let k = 1; k <= 30; k++) { ev('pointermove', 1, cx, cy - 300 * k / 60); steps(1); if (k > 20 && f.mem.length) { let mx = 0, my = 0; for (const m of f.mem) { mx += X[m[0]]; my += Y[m[0]]; } mx /= f.mem.length; my /= f.mem.length; gap = Math.max(gap, Math.hypot(mx - f.x, my - f.y)); } } ev('pointerup', 1, cx, cy - 150); steps(5); return +gap.toFixed(1); };
    r.follow = { on: follow({}), off: follow(OFF29) };
    // 猛扯不會有黏液：沒有「滴」的聲音
    log.splice(0); Math.random = seeded(4504); mat = { ...SP('clay') }; setup(); center(); steps(60); { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx + R * .6, cy); steps(2); for (let k = 1; k <= 7; k++) { ev('pointermove', 1, cx + R * .6 + R * 2.6 * k / 7, cy); steps(1); } ev('pointerup', 1, cx + R * 3.2, cy); steps(60); }
    r.noDrops = { dripSounds: log.filter(x => x[0] === 'drip').length, gone: typeof DROPS === 'undefined' && typeof dropSpawn === 'undefined' };
    res.T45_knot = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const each = f => ['clay', 'mochi', 'jelly'].every(n => Object.values(r.abuse[n]).every(f));
    res.PASS.knot = each(a => a.eyeOut === 0 && a.qFlip === 0 && a.afterX === 0 && a.nan === 0 && a.crossF <= a.frames * .12 && Math.abs(a.area - 1) < .12)
      && r.off.eyeOut > 0 && Math.abs(r.keep.on - r.keep.off) < .05 && r.keep.on > .5 && Math.abs(r.follow.on - r.follow.off) < 8 && r.noDrops.dripSounds === 0 && r.noDrops.gone;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T46 v2.30 環境互動（多米 11-06：跨出窗外、爬窗邊、打翻擺飾、爬出爬進碗）。標準清單 v2.30 每一條：路線走得完、換層時不重疊也不跳、手指那幾條、自己跑 2 分鐘不爆。T45 不退步由 PASS.knot 管
  // v2.31（多米 11-07）：碗回中間、擺飾拿掉、牠只跟碗互動。擺飾那幾項刪掉；爬窗框、窗外的路線用 envFrame 1 量（程式還在，預設不走）
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0, envFrame: 1, props: 0, lookNoDown: 0 };   // v2.63 C5：張望不朝下（lookNoDown）預設 1 之後窗台上張望的方向變了，這一項量的是舊規格，釘 0
    const fresh = sd => { Math.random = seeded(sd || 4601); mat = { ...SP }; setup(); WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t; };
    let aborts = 0; const re0 = routeEnd; routeEnd = function (a) { if (a && SILL.route) aborts++; return re0(a); };
    const bottom = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, Y[i]); return m; };
    const go = st => { const a0 = aborts; routeStart(st); let f = 0, mj = 0, px = globalC.xc, py = globalC.yc, pp = SILL.plane, pb = SILL.inBowl; const ch = [], w = {}; while (SILL.route && f < 3000) { steps(1); f++; lastTouch = t; const j = Math.hypot(globalC.xc - px, globalC.yc - py); mj = Math.max(mj, j); px = globalC.xc; py = globalC.yc; if (SILL.plane !== pp || SILL.inBowl !== pb) { ch.push({ from: pp, to: SILL.plane, bowl: SILL.inBowl, y1: +SILL.y1.toFixed(1) }); pp = SILL.plane; pb = SILL.inBowl; } const s = SILL.surf; if (s) { const q = w[s] || (w[s] = { x1: -1e9, x0: 1e9, y0: 1e9, wd: 1e9 }); q.x1 = Math.max(q.x1, SILL.x1); q.x0 = Math.min(q.x0, SILL.x0); q.y0 = Math.min(q.y0, SILL.y0); q.wd = Math.min(q.wd, SILL.x1 - SILL.x0); } } return { sec: +(f / 60).toFixed(1), ok: !SILL.route && aborts === a0, jump: +mj.toFixed(1), ch, w, selfX: selfX() }; };
    const drag = (tx, ty, fr, hold) => { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= fr; k++) { ev('pointermove', 1, cx + (tx - cx) * k / fr, cy + (ty - cy) * k / fr); steps(1); } steps(hold); ev('pointerup', 1, tx, ty); };
    const modeAt = (x, y) => { ev('pointerdown', 1, x, y); steps(1); const f = fingers.get(1), m = f ? f.mode : null; ev('pointerup', 1, x, y); steps(1); return m; };
    fresh(); const g = SILL.g, cross = (c, y) => c.every(q => q.y1 <= y);
    // 路線一條接一條走：窗台、碗、窗框、繞一圈、爬一半掉下來、窗外、回來
    r.routes = {}; const R0 = r.routes, rec = (n, st, after) => { R0[n] = go(st); steps(after == null ? 120 : after); lastTouch = t; R0[n].end = { plane: SILL.plane, bowl: SILL.inBowl, surf: SILL.surf, y1: +bottom().toFixed(1), z: +SILL.zoom.toFixed(2) }; };
    rec('outFront', rtOutFront(null)); rec('intoFront', rtIntoFront()); rec('overBack', rtOverBack(g.jr - R)); rec('frameLoop', rtFrameLoop()); rec('overBack2', rtOverBack(g.jr - R)); rec('climbDrop', rtClimbDrop()); rec('goOut', rtGoOut()); rec('comeBack', rtComeBack()); rec('backIn', rtBackIn());
    { const q = R0; r.routeOK = { allFinish: Object.values(q).every(a => a.ok), jumps: Math.max(...Object.values(q).map(a => a.jump)), selfX: Math.max(...Object.values(q).map(a => a.selfX)),
        outFront: cross(q.outFront.ch, g.lip) && !q.outFront.end.bowl && q.outFront.end.plane === 'room' && Math.abs(q.outFront.end.y1 - g.fl) < 3,
        intoFront: cross(q.intoFront.ch, g.lip) && q.intoFront.end.bowl,
        overBack: cross(q.overBack.ch, g.back + 2) && q.overBack.end.plane === 'frame' && Math.abs(q.overBack.end.y1 - g.bt) < 3,
        loop: q.frameLoop.end.bowl && !!q.frameLoop.w.rjamb && q.frameLoop.w.rjamb.x1 > g.jr - 3 && !!q.frameLoop.w.ceil && q.frameLoop.w.ceil.y0 < g.gy + 3 && !!q.frameLoop.w.ljamb && q.frameLoop.w.ljamb.x0 < g.gx + 12 && cross(q.frameLoop.ch, g.back + 2),
        climb: q.climbDrop.end.plane === 'frame' && Math.abs(q.climbDrop.end.y1 - g.bt) < 3,
        goOut: q.goOut.end.plane === 'out' && Math.abs(q.goOut.end.z - .8) < .03 && Math.abs(q.goOut.end.y1 - g.oy) < 3,
        comeBack: q.comeBack.end.plane === 'frame' && q.comeBack.end.z > .97 && cross(q.comeBack.ch, g.bt + 2),
        backIn: q.backIn.end.bowl && cross(q.backIn.ch, g.back + 2) }; }
    // 手指
    fresh(); go(rtOverBack(g.jr - R)); steps(60); go(rtGoOut()); steps(180); lastTouch = t; { const z = SILL.zoom, sx = W / 2 + (globalC.xc - W / 2) * z, sy = g.oy + (SILL.y0 + 40 - g.oy) * z, b = [modeAt(g.gx - 15, 560), modeAt(200, g.bt + 12)]; ev('pointerdown', 1, sx, sy); let mj = 0, px = globalC.xc, py = globalC.yc; steps(1); const plane0 = SILL.plane, m = fingers.get(1) && fingers.get(1).mode; for (let k = 0; k < 40; k++) { steps(1); mj = Math.max(mj, Math.hypot(globalC.xc - px, globalC.yc - py)); px = globalC.xc; py = globalC.yc; } const z1 = SILL.zoom; ev('pointerup', 1, sx, sy); steps(180); r.outGrab = { blocked: b, m, plane0, z1: +z1.toFixed(2), jump: +mj.toFixed(1), end: SILL.plane }; }
    fresh(); go(rtOverBack(g.gx + R * .8)); steps(90); lastTouch = t; r.frameBlock = { bowl: modeAt(100, 540) };
    const st = (tx, ty, fr, hold) => { fresh(); go(rtOutFront(null)); steps(60); lastTouch = t; drag(tx, ty, fr, hold); steps(1); const sf = SILL.stickT >= 0 ? SILL.surf : null, pl = SILL.plane; steps(240); lastTouch = t; return { sf, pl, plane: SILL.plane, surf: SILL.surf, bowl: SILL.inBowl, y1: +bottom().toFixed(1) }; };
    r.slowStick = st(310, 300, 60, 40); r.flungNoStick = st(310, 300, 6, 0); r.relMid = st(240, 300, 60, 40); r.relBowl = st(g.bx, 280, 60, 40); r.relFront = st(200, 560, 40, 30);
    { fresh(); mat.envFrame = 0; go(rtOutFront(null)); steps(60); lastTouch = t; drag(330, 300, 60, 40); steps(240); lastTouch = t; r.relSide = { plane: SILL.plane, surf: SILL.surf, bowl: SILL.inBowl, y1: +bottom().toFixed(1) }; }   // v2.31 只跟碗互動：放在碗旁邊的窗戶範圍，掉回窗台
    // 自己跑 2 分鐘
    Math.random = seeded(4602); mat = { ...SP, envRoam: 1, catPush: 0 }; setup(); { aborts = 0; const seen = {}; let rest = 0, nan = 0, y1 = -1e9, ar0 = 9, ar1 = 0, xr0 = 1e9, xr1 = -1e9, propNaN = 0; for (let f = 0; f < 7200; f++) { steps(1); const S = SILL; seen[S.plane + (S.inBowl ? '+bowl' : '') + (S.tanV && !S.lift ? '+wall' : '')] = 1; if (!S.route && !GAIT.on) rest++; if (!Number.isFinite(X[f % N] + Y[f % N])) nan++; y1 = Math.max(y1, S.y1); xr0 = Math.min(xr0, S.x0); xr1 = Math.max(xr1, S.x1); if (f % 10 === 0) { const a = area() / A0; ar0 = Math.min(ar0, a); ar1 = Math.max(ar1, a); } for (const p of PROPS) if (!Number.isFinite(p.x + p.y + p.a)) propNaN++; } r.auto = { aborts, rest: +(rest / 7200).toFixed(2), nan, propNaN, overFloor: +(y1 - g.fl).toFixed(2), area: [+ar0.toFixed(2), +ar1.toFixed(2)], x: [+xr0.toFixed(0), +xr1.toFixed(0)], seen: Object.keys(seen), selfX: selfX() }; }
    routeEnd = re0; res.T46_env = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const o = r.routeOK;
    res.PASS.env = o.allFinish && o.jumps < R * .12 && o.selfX === 0 && o.outFront && o.intoFront && o.overBack && o.loop && o.climb && o.goOut && o.comeBack && o.backIn
      && r.outGrab.m === 'grab' && r.outGrab.plane0 === 'room' && r.outGrab.z1 > .97 && r.outGrab.jump < R * .12 && r.outGrab.end === 'room' && r.outGrab.blocked.every(m => m !== 'grab') && r.frameBlock.bowl !== 'grab'
      && r.slowStick.sf === 'rjamb' && r.slowStick.plane === 'frame' && r.flungNoStick.sf == null && r.relMid.bowl && r.relBowl.bowl && r.relFront.plane === 'room' && !r.relFront.bowl && r.relSide.plane === 'room' && !r.relSide.bowl && Math.abs(r.relSide.y1 - g.fl) < 3
      && r.auto.aborts === 0 && r.auto.nan === 0 && r.auto.propNaN === 0 && r.auto.rest > .5 && r.auto.overFloor <= .01 && r.auto.area[0] > .8 && r.auto.area[1] < 1.2 && r.auto.selfX === 0 && r.auto.seen.length >= 2;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T47 走路（多米 11-06：現實裡走路跟牠掛勾）。門檻與上限、從窗外爬回來、捏一下掉、20 秒自己掉、放滿擠掉最舊的、送的石頭與權限那段、存得起來。網頁拿不到真步數，用 bank 假裝
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, walkShow: 1, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0 };
    const clear = () => { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; WALK.bank = 0; WALK.dayN = 0; WALK.day = ''; WALK.opens = 0; WALK.perm = ''; };
    const fresh = sd => { Math.random = seeded(sd || 4701); clear(); mat = { ...SP }; setup(); ESC.on = false; E2.tk.length = 0; E2.tkT = 0; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t; };
    const bottom = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, Y[i]); return m; };
    const arrive = () => { let n = 0; while (SILL.route && n < 900) { steps(1); lastTouch = t; n++; } return n; };
    // 門檻與上限
    fresh(); const g = SILL.g; WALK.bank = 300; const small = walkCheck(), noStuck = !WALK.stuck;
    WALK.bank = 800; const ok = walkCheck(), s0 = WALK.stuck && { big: WALK.stuck.big, plane: SILL.plane, z: SILL.zoom, y1: +bottom().toFixed(1), left: WALK.bank };
    const frames = arrive(); steps(90); lastTouch = t; const a0 = { sec: +(frames / 60).toFixed(1), plane: SILL.plane, bowl: SILL.inBowl, z: +SILL.zoom.toFixed(2), y1: +bottom().toFixed(1), stuck: !!WALK.stuck, selfX: selfX() };   // v2.31：回來那趟直接進碗
    r.trip = { small, noStuck, ok, s0, a0 };
    fresh(); WALK.bank = 3500; walkCheck(); r.big = !!WALK.stuck && WALK.stuck.big; arrive();
    fresh(); { let n = 0; for (let k = 0; k < 5; k++) { WALK.bank = 800; WALK.stuck = null; if (walkCheck()) n++; if (SILL.route) routeEnd(true); } r.cap = { n, left: WALK.bank }; }
    // 捏一下就掉，落在窗框下緣，身體不受影響
    fresh(); WALK.bank = 800; walkCheck(); arrive(); steps(60); lastTouch = t; { const A = area() / A0; ev('pointerdown', 1, globalC.xc, globalC.yc); steps(4); const still = !!WALK.stuck; steps(4); const off = !WALK.stuck, inAir = WALK.fall.length; ev('pointerup', 1, globalC.xc, globalC.yc); steps(120); lastTouch = t; const q = WALK.items[0]; r.pinch = { still, off, inAir, n: WALK.items.length, x: q ? +walkSlotX(q.s).toFixed(0) : null, inRange: q ? Math.abs(walkSlotX(q.s) - g.bx) > g.bw / 2 && walkSlotX(q.s) > g.l && walkSlotX(q.s) < g.r : false, fall: WALK.fall.length, area: +(area() / A0 - A).toFixed(3), selfX: selfX() }; }
    // 爬到一半被抓：路線取消，東西掉下來
    fresh(); WALK.bank = 800; walkCheck(); steps(30); lastTouch = t; { const z = SILL.zoom, sx = W / 2 + (globalC.xc - W / 2) * z, sy = g.oy + (SILL.y0 + 40 - g.oy) * z; ev('pointerdown', 1, sx, sy); steps(10); const plane = SILL.plane, route = !!SILL.route, off = !WALK.stuck; ev('pointerup', 1, sx, sy); steps(150); r.grabMid = { plane, route, off, n: WALK.items.length }; }
    // 放著不碰 20 秒自己掉
    fresh(); WALK.bank = 800; walkCheck(); arrive(); lastTouch = t; { let n = 0, routeF = 0, outF = 0, fingF = 0, kinds = {}; while (WALK.stuck && n < 1500) { steps(1); lastTouch = t; n++; if (SILL.route) { routeF++; const q = SILL.route.steps[SILL.route.i]; if (q) kinds[q.k] = (kinds[q.k] || 0) + 1; } if (SILL.plane === 'out') outF++; if (fingers.size) fingF++; } steps(120); r.idle = { sec: +(n / 60).toFixed(1), n: WALK.items.length, routeF, outF, fingF, kinds, plane: SILL.plane, st: LIFE.st }; }   // routeF、outF、fingF：沒掉的話是哪個條件擋住（v2.31 全程第三輪抓到一次 25 秒沒掉）
    // 放滿了：還是 6 件，最舊的被擠掉
    fresh(); for (let s = 0; s < WALK_SLOTS; s++) WALK.items.push({ k: 'leaf', big: false, s, a: 0, tag: s }); { WALK.bank = 800; walkCheck(); arrive(); ev('pointerdown', 1, globalC.xc, globalC.yc); steps(10); ev('pointerup', 1, globalC.xc, globalC.yc); const leaving = WALK.leave.length; steps(120); r.full = { n: WALK.items.length, leaving, leaveEnd: WALK.leave.length, oldestGone: !WALK.items.some(q => q.tag === 0) }; }
    // 換史萊姆時身上還黏著：不會不見
    fresh(); WALK.bank = 800; walkCheck(); setup(); r.settle = { stuck: !!WALK.stuck, n: WALK.items.length };
    // 送的石頭與權限：第一次不送，第二次送，點了才問，答完不再送
    fresh(); { walkOpen(); const first = WALK.items.length; walkOpen(); const q = WALK.items.find(a => a.gift), second = !!q; steps(5); const d = document.getElementById('walk-ask'), hit = q && walkGiftAt(walkSlotX(q.s), walkY(q)), off = walkGiftAt(10, 10); ev('pointerdown', 1, walkSlotX(q.s), walkY(q)); steps(1); const asked = d.classList.contains('on'), fing = fingers.size; ev('pointerup', 1, walkSlotX(q.s), walkY(q)); walkAnswer(false); const closed = !d.classList.contains('on'), perm = WALK.perm, kept = WALK.items.length; walkOpen(); r.gift = { first, second, hit, off, asked, fing, closed, perm, kept, third: WALK.items.length }; }
    // 存得起來
    { const raw = localStorage.getItem('nienie.walk'), keep = WALK.noSave; clear(); WALK.items.push({ k: 'acorn', big: true, s: 3, a: .2 }); WALK.opens = 5; WALK.perm = 'ok'; WALK.bank = 123; WALK.noSave = false; walkSave(); clear(); walkLoad(); r.save = { n: WALK.items.length, k: WALK.items[0] && WALK.items[0].k, opens: WALK.opens, perm: WALK.perm, bank: WALK.bank }; WALK.noSave = keep; try { if (raw == null) localStorage.removeItem('nienie.walk'); else localStorage.setItem('nienie.walk', raw); } catch (_) {} }
    // 藍底不出門；白天、夜晚畫得出來，六種都畫
    clear(); mat = { ...SP, sill: 0 }; setup(); WALK.bank = 800; r.blue = walkCheck(); clear(); { const v0 = VIEW.bg, sk = VIEW.skin; fresh(); let err = null; try { for (const b of ['day', 'night']) { VIEW.bg = b; for (const k of WKINDS) walkSprite(k); WALK.items.push({ k: 'cap', big: false, s: 1, a: 0 }); WALK.bank = 800; WALK.dayN = 0; walkCheck(); draw(); WALK.stuck = null; if (SILL.route) routeEnd(true); } } catch (e) { err = String(e); } VIEW.bg = v0; VIEW.skin = sk; r.draw = err; }
    fresh(); mat.walkShow = 0; WALK.bank = 5000; r.off = { trip: walkCheck(), stuck: !!WALK.stuck, bank: WALK.bank, route: !!SILL.route };   // v2.58 關著：不出門，步數留著
    clear(); res.T47_walk = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const a = r.trip;
    res.PASS.walk = r.off.trip === false && !r.off.stuck && r.off.bank === 5000 && !r.off.route && a.small === false && a.noStuck && a.ok && a.s0.big === false && a.s0.plane === 'out' && Math.abs(a.s0.z - .8) < .01 && Math.abs(a.s0.y1 - g.oy) < 2 && a.s0.left === 0
      && a.a0.sec < 12 && a.a0.plane === 'room' && a.a0.bowl && a.a0.z > .97 && Math.abs(a.a0.y1 - g.bf) < 3 && a.a0.stuck && a.a0.selfX === 0 && r.big === true && r.cap.n === 3
      && r.pinch.off && r.pinch.inAir === 1 && r.pinch.n === 1 && r.pinch.inRange && r.pinch.fall === 0 && Math.abs(r.pinch.area) < .1 && r.pinch.selfX === 0
      && r.grabMid.plane === 'room' && !r.grabMid.route && r.grabMid.off && r.grabMid.n === 1 && r.idle.sec > 19 && r.idle.sec < 22 && r.idle.n === 1
      && r.full.n === WALK_SLOTS && r.full.leaving === 1 && r.full.leaveEnd === 0 && r.full.oldestGone && !r.settle.stuck && r.settle.n === 1
      && r.gift.first === 0 && r.gift.second && r.gift.hit && !r.gift.off && r.gift.asked && r.gift.fing === 0 && r.gift.closed && r.gift.perm === 'no' && r.gift.kept === 1 && r.gift.third === 1
      && r.save.n === 1 && r.save.k === 'acorn' && r.save.opens === 5 && r.save.perm === 'ok' && r.save.bank === 123 && r.blue === false && r.draw === null;
    clear();   // v2.32：走路測試留下的「今天 3 件」會讓後面的項目興奮（exLevel 看 WALK.dayN，休息變短、不睡），T48 第一次就被咬到，清掉
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T48 v2.31 搖晃沉澱（多米 11-07：互動改成搖手機，像雪花球）與散出來吃回來（第二種玩法）。搖三下就滿、第四下不會更多、牠在碗裡彈但不出碗、物理沒壞；放著約 30 秒沉澱清透（叮一聲、睜眼、發光，只清一次）；沉澱時慢呼吸、閉眼；沉到一半捏牠又濁回去；堆的形狀三種都會出現；亮粉都在身體裡；藍底也能搖；搖會叫醒；關掉就沒有
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, shake: 1, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0, lookNoDown: 0 };   // v2.63 C5：張望不朝下（lookNoDown）預設 1 之後窗台上張望的方向變了，這一項量的是舊規格，釘 0
    const fresh = (sd, over) => { Math.random = seeded(sd || 4801); mat = { ...SP, ...(over || {}) }; setup(); E2.tk.length = 0; E2.tkT = 0; ESC.on = false; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t; };
    const run = (n, f) => { for (let k = 0; k < n; k++) { steps(1); if (f) f(k); } };
    const cl = () => +SNW.cloud.toFixed(3);
    const inside = () => { let n = 0; const c = globalC; let by = -1e9; for (const i of bnd) by = Math.max(by, Y[i]); by -= R * .06; if (SILL.on && SILL.inBowl && SILL.g) by = Math.min(by, SILL.g.lip - R * .04); for (const q of SNW.glit) { const tx = c.xc + q.tx * R, ty = by - q.ty * R, sx = c.xc + q.sx * R, sy = c.yc + q.sy * R, x = tx + (sx - tx) * q.h, y = ty + (sy - ty) * q.h; if (insideBody(x, y)) n++; } return SNW.glit.length ? n / SNW.glit.length : 0; };
    const three = () => { shkShake(1, -.5); steps(10); shkShake(-1, -.5); steps(10); shkShake(1, -.5); };
    // 搖三下滿、第四下不會更多、牠彈了但還在碗裡、物理沒壞、眼睛 ∩
    fresh(); { const A = area() / A0, x0 = globalC.xc, y0 = globalC.yc; let mv = 0; const c0 = cl(); shkShake(1, -.5); run(12, () => { mv = Math.max(mv, Math.hypot(globalC.xc - x0, globalC.yc - y0)); }); const c1 = cl(), happy = EYE.mode; shkShake(-1, -.5); steps(12); shkShake(1, -.5); steps(12); const c3 = cl(); shkShake(-1, -.5); steps(12); const c4 = cl(); shkShake(1, -.5); shkShake(-1, -.5); shkShake(1, -.5); steps(120); r.shake = { c0, c1, c3, c4, c7: cl(), moved: +mv.toFixed(1), inBowl: SILL.inBowl, area: +(area() / A0 - A).toFixed(3), selfX: selfX(), nan: X.some(v => !Number.isFinite(v)), happy, k: +SNW.k.toFixed(2) }; }
    // 放著：沉澱時慢呼吸（10 秒一次）、閉眼；大約 30 秒清透：叮一聲、睜眼、發光；之後不再叮
    fresh(); three(); { log.splice(0); steps(300); const mid = { k: +SNW.k.toFixed(2), open: +EYE.openD.toFixed(2), cloud: cl(), inside: +inside().toFixed(2) }; const p0 = BR.phase; steps(600); const cyc = +(BR.phase - p0).toFixed(2); let n = 0; while (!SNW.cleared && n < 3600) { steps(1); n++; } const sec = +((900 + n) / 60).toFixed(1), ding = log.filter(l => l[0] === 'ding').length, glow = +SNW.glow.toFixed(2); steps(40); const open = +EYE.openD.toFixed(2); steps(600); r.settle = { mid, cyc, sec, ding, glow, open, cloud: cl(), inside: +inside().toFixed(2), dingLater: log.filter(l => l[0] === 'ding').length, k: +SNW.k.toFixed(2), shape: SNW.shape }; }
    // 沉到一半捏牠：又濁回去，清的那一下延後
    fresh(); three(); steps(600); { const c1 = cl(), cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 60; k++) { ev('pointermove', 1, cx + 25 * Math.sin(k / 3), cy + 12 * Math.cos(k / 4)); steps(1); } steps(60); const c2 = cl(); ev('pointerup', 1, cx, cy); steps(60); r.stir = { c1, c2, cleared: SNW.cleared, selfX: selfX() }; }
    // 堆的形狀：搖 60 次，三種都出現，小堆最多
    fresh(); { const cnt = { mound: 0, star: 0, heart: 0 }; for (let k = 0; k < 60; k++) { for (const q of SNW.glit) q.h = 0; shkMeasure(); SNW.cleared = true; shkShake(k % 2 ? 1 : -1, -.5); cnt[SNW.shape]++; steps(5); } r.shapes = cnt; }
    // 藍底（懸空）也能搖，只有亮粉動；搖會叫醒；關掉就什麼都沒有
    fresh(4802, { sill: 0 }); { const A = area() / A0, x0 = globalC.xc, y0 = globalC.yc; shkShake(1, -.5); shkShake(-1, -.5); shkShake(1, -.5); steps(30); r.blue = { cloud: cl(), moved: +Math.hypot(globalC.xc - x0, globalC.yc - y0).toFixed(1), area: +(area() / A0 - A).toFixed(3), nan: X.some(v => !Number.isFinite(v)), inside: +inside().toFixed(2) }; }
    fresh(); { SLP.on = true; SLP.k = 1; LIFE.st = 'sleep'; shkShake(1, -.5); steps(5); r.wake = { awake: !SLP.on }; SLP.k = 0; }
    fresh(4803, { shake: 0 }); { shkShake(1, -.5); steps(30); r.off = { cloud: cl() }; }
    // 散出來吃回來（多米 11-07 第二種玩法）：搖三下亮粉噴出去落在窗台或碗口、肚子裡少了；放著牠自己去撿，50 秒內撿完、全回肚子裡、叮一聲；藍底也一樣
    const eatRun = () => { log.splice(0); three(); steps(60); const l0 = SNW.loose.length, rest0 = SNW.loose.filter(p => p.rest).length, out0 = SNW.glit.filter(q => q.out).length; let n = 0; while (SNW.loose.length && n < 3000) { steps(1); n++; } steps(30); return { l0, rest0, out0, sec: +(n / 60).toFixed(1), left: SNW.loose.length, out: SNW.glit.filter(q => q.out).length, ding: log.filter(l => l[0] === 'ding').length, glow: +SNW.glow.toFixed(2), selfX: selfX(), nan: X.some(v => !Number.isFinite(v)) }; };
    fresh(4804, { shakeMode: 1 }); r.eat = eatRun(); r.eat.inBowl = SILL.inBowl;
    fresh(4805, { shakeMode: 1, sill: 0 }); r.eatBlue = eatRun();
    fresh(4806, { shakeMode: 1 }); { three(); steps(60); const l0 = SNW.loose.length; mat.shakeMode = 0; steps(2); r.eatSwitch = { l0, left: SNW.loose.length, out: SNW.glit.filter(q => q.out).length }; }   // 切回沉澱：外面的直接回肚子
    // 果凍皮畫得出來（濁的時候皮往奶凍混、清的那一下發光）
    { const sk = VIEW.skin, bg = VIEW.bg; let err = null; try { fresh(); VIEW.skin = 'A'; VIEW.bg = 'day'; three(); steps(5); draw(); SNW.glow = 1; draw(); } catch (e) { err = String(e); } VIEW.skin = sk; VIEW.bg = bg; r.draw = err; }
    res.T48_shake = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const a = r.shake, s = r.settle;
    res.PASS.shake = a.c0 === 0 && a.c1 > .35 && a.c3 > .85 && a.c4 - a.c3 < .08 && a.c7 <= 1 && a.moved > 2.5 && a.inBowl && Math.abs(a.area) < .15 && a.selfX === 0 && !a.nan && a.happy === 'happy'
      && s.mid.k > .8 && s.mid.open < .4 && s.mid.cloud > .4 && s.mid.inside > .95 && s.cyc > .6 && s.cyc < 1.3 && s.sec > 24 && s.sec < 40 && s.ding === 1 && s.glow > .9 && s.open > .75 && s.cloud < .03 && s.inside > .95 && s.dingLater === 1 && s.k < .1
      && r.stir.c2 > r.stir.c1 + .05 && !r.stir.cleared && r.stir.selfX === 0 && r.shapes.mound > r.shapes.star && r.shapes.mound > r.shapes.heart && r.shapes.star > 0 && r.shapes.heart > 0
      && r.blue.cloud > .85 && r.blue.moved < 6 && Math.abs(r.blue.area) < .1 && !r.blue.nan && r.blue.inside > .95 && r.wake.awake && r.off.cloud === 0 && r.draw === null
      && [r.eat, r.eatBlue].every(e => e.l0 >= 10 && e.rest0 >= 6 && e.out0 === e.l0 && e.left === 0 && e.sec < 50 && e.out === 0 && e.ding === 1 && e.glow > .6 && e.selfX === 0 && !e.nan) && r.eatSwitch.l0 >= 10 && r.eatSwitch.left === 0 && r.eatSwitch.out === 0;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T49 v2.32 興奮（多米 11-07：運動多牠就比較興奮；提案 興奮提案-暫定.md）。今天帶回 3 件 vs 0 件：藍底放著 90 秒休息少、走路幀數多、每一下衝得遠；休息時長直接抽 200 次比例 0.75／0.5；
  // 回家進碗之後小跳兩下（0 件不跳、路線中途被打斷不跳）；抓著拉、放手的數字兩邊一樣（手感不動，差 3% 以內）；自動：今天 0、1 件 → 0，2 件 → .5，3 件 → 1
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, walkShow: 1, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0, shake: 0 };
    const clear = () => { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; WALK.bank = 0; WALK.dayN = 0; WALK.day = ''; WALK.opens = 0; WALK.perm = ''; WALK.hopN = 0; };
    const fresh = (sd, over) => { Math.random = seeded(sd || 4901); clear(); mat = { ...SP, ...(over || {}) }; setup(); ESC.on = false; E2.tk.length = 0; E2.tkT = 0; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t; };
    // 藍底放著：休息佔幾成、走路（不算衝刺）時家每秒移幾 R、探了幾次
    const idle = sec => { let rest = 0, n = 0, sn = 0, last = null, gf = 0, dist = 0, hx = HOMEX, hy = HOMEY; for (let k = 0; k < sec * 60; k++) { steps(1); n++; if (LIFE.st === 'rest') rest++; if (GAIT.on && !GAIT.dash) { gf++; dist += Math.hypot(HOMEX - hx, HOMEY - hy); } hx = HOMEX; hy = HOMEY; const s = LIFE.sns[LIFE.sns.length - 1]; if (s && s !== last) { last = s; sn++; } } return { rest: +(rest / n).toFixed(3), spd: gf ? +(dist / gf / R * 60).toFixed(3) : 0, gaitF: gf, sniffs: sn, selfX: selfX() }; };
    fresh(4901, { sill: 0, excite: 0 }); r.calm = idle(90);
    fresh(4901, { sill: 0, excite: 3 }); r.hyper = idle(90);
    // 休息時長這根桿子直接量：同一串亂數各抽 200 次，平均要是平常的 0.75 倍（2 件）、0.5 倍（3 件）。放著 90 秒的休息比例會被偶爾的發呆十幾秒拉偏，不拿它比
    const rd = ex => { fresh(4905, { sill: 0, excite: ex }); let sum = 0; for (let k = 0; k < 200; k++) sum += restDur(); return +(sum / 200).toFixed(3); };
    r.restDur = [rd(0), rd(2), rd(3)];
    // 回家進碗之後小跳：3 件跳兩下、0 件不跳；路線中途被打斷（手指一碰就是這個）也不跳
    const trip = (ex, cut) => { fresh(4902, { excite: ex }); WALK.bank = 800; walkCheck(); let n = 0, hops = 0, was = false; while (SILL.route && n < 900) { steps(1); lastTouch = t; n++; if (cut && n === 30) routeEnd(true); } for (let k = 0; k < 300; k++) { steps(1); lastTouch = t; const on = INTRO.on && INTRO.mini; if (on && !was) hops++; was = on; } return { hops, inBowl: SILL.inBowl, left: WALK.hopN, selfX: selfX() }; };
    r.hop3 = trip(3, false); r.hop0 = trip(0, false); r.hopCut = trip(3, true);
    // 手感不動：同一個種子、同樣往右拉 2R 停 0.5 秒再放手，拉長、整團跟過去、放手 2 秒後剩多少，三個種子平均、兩邊差 3% 以內（眼睛關掉：眨眼抽亂數的時間點不同會把整串亂數錯開，同種子也走不同軌跡，量到 5% 雜訊；放手後不讓牠去探手指離開的地方，那條偽足的長度是亂數，量到過 8%）
    const feel = ex => { const acc = { e1: 0, c1: 0, e2: 0, selfX: 0 }, each = []; for (const sd of [4903, 4906, 4907]) { fresh(sd, { sill: 0, excite: ex, eyes: 0 }); LIFE.st = 'rest'; LIFE.until = t + 1e4; const cx = globalC.xc, cy = globalC.yc; const ext = () => { let x1 = -1e9; for (const i of bnd) x1 = Math.max(x1, X[i]); return x1 - cx; }; ev('pointerdown', 1, cx, cy); steps(4); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx + k * R * 2 / 40, cy); steps(1); } steps(30); acc.e1 += ext() / R; acc.c1 += (globalC.xc - cx) / R; ev('pointerup', 1, cx + R * 2, cy); for (let k = 0; k < 120; k++) { LIFE.att = null; LIFE.ask = null; steps(1); } acc.e2 += ext() / R; acc.selfX += selfX(); each.push(ext() / R); } return { e1: +(acc.e1 / 3).toFixed(3), c1: +(acc.c1 / 3).toFixed(3), e2: +(acc.e2 / 3).toFixed(3), sp: +(Math.max(...each) - Math.min(...each)).toFixed(3), selfX: acc.selfX }; };
    r.feel0 = feel(0); r.feel3 = feel(3);
    // 自動：照今天幾件
    fresh(4904, { excite: -1 }); { const lv = []; for (const n of [0, 1, 2, 3]) { WALK.dayN = n; WALK.day = new Date().toDateString(); EXT = -9; lv.push(exLevel()); } r.auto = lv; }
    res.T49_excite = r; restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const near = (a, b, sp) => Math.abs(a - b) <= Math.max(.03 * Math.max(1, Math.abs(a), Math.abs(b)), sp || 0);   // 兩邊的差不能大於 3%，或不能大於同一級三個種子之間自己的差（雜訊底線：三輪量到同一級也差 1 到 4%）
    res.PASS.excite = r.hyper.rest < r.calm.rest - .05 && r.hyper.spd > r.calm.spd * 1.12 && [r.calm, r.hyper].every(x => x.selfX === 0) && Math.abs(r.restDur[1] / r.restDur[0] - .75) < .03 && Math.abs(r.restDur[2] / r.restDur[0] - .5) < .03
      && r.hop3.hops === 2 && r.hop3.inBowl && r.hop3.left === 0 && r.hop0.hops === 0 && r.hopCut.hops === 0 && r.hop3.selfX === 0
      && near(r.feel0.e1, r.feel3.e1) && near(r.feel0.c1, r.feel3.c1) && near(r.feel0.e2, r.feel3.e2, Math.max(r.feel0.sp, r.feel3.sp)) && r.feel0.selfX === 0 && r.feel3.selfX === 0
      && r.auto.join() === '0,0,0.5,1';
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T50 v2.33 一隻為主（多米 11-07：定位是陪伴寵物，只養一隻，留芋圓）。預設 one 1：底部那排四隻藏起來、一開始就是芋圓、芋圓的手感是黏土基準 v1；one 0 四隻回來。
  // 四隻各自的材質、顏色、印象分開記這件事 T38 照樣量（collect），一隻為主不碰它
  { const was = mat.one, el = document.getElementById('slimes'); mat.one = 1; oneSync(); const hid = el.style.display === 'none'; mat.one = 0; oneSync(); const shown = el.style.display !== 'none'; mat.one = was; oneSync();
    res.T50_one = { hid, shown, presetOne: PRESETS.clay.one, def: SLIMES[2].id, defMat: SLIMES[2].mat, startIdx: PRESETS.clay.one >= .5 ? 2 : -1 };
    res.PASS.one = hid && shown && PRESETS.clay.one === 1 && SLIMES[2].id === 'taro' && SLIMES[2].mat === 'clay';
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T51 v2.34 熟留下來（多米 11-07 定位：陪伴寵物要記得你）。熟存得進 localStorage、讀得回來、戒不存；背景 10 分鐘只歸零戒、熟留著，不到 10 分鐘什麼都不動；
  // trKeep 0 回 v2.33 熟跟戒一起歸零；noSave 時不寫。用使用者的 key 量，量完原樣還回去
  { const r = {}, LS0 = localStorage.getItem('nienie.imp'), id = SLIMES[SLIME].id, mat0 = mat;
    try {
      mat = { ...PRESETS.clay, imp: 1, trKeep: 1 }; IMP.tr = .62; IMP.w = .4; IMPSV.noSave = false; IMPSV.last = ''; impSave(true);
      const o = JSON.parse(localStorage.getItem('nienie.imp') || 'null'); r.saved = o && o.tr ? o.tr[id] : null; r.savedW = o && o.w !== undefined;
      for (const k in IMPS) delete IMPS[k]; IMP.tr = 0; impLoad(); r.loaded = IMPS[id] ? IMPS[id].tr : null; r.loadedW = IMPS[id] ? IMPS[id].w : null; r.live = IMP.tr;
      IMP.tr = .62; IMP.w = .4; impBack(3e5); r.short = [IMP.tr, IMP.w];
      impBack(7e5); r.bg = [IMP.tr, IMP.w];
      mat = { ...mat, trKeep: 0 }; IMP.tr = .62; IMP.w = .4; impBack(7e5); r.off = [IMP.tr, IMP.w];
      mat = { ...mat, trKeep: 1 }; IMPSV.noSave = true; IMPSV.last = ''; localStorage.setItem('nienie.imp', 'X'); IMP.tr = .3; impSave(true); r.noSave = localStorage.getItem('nienie.imp') === 'X';
    } catch (e) { r.err = String(e); }
    IMPSV.noSave = true; if (LS0 === null) localStorage.removeItem('nienie.imp'); else localStorage.setItem('nienie.imp', LS0); mat = mat0;
    res.T51_trKeep = r;
    res.PASS.trKeep = !r.err && r.saved === .62 && !r.savedW && r.loaded === .62 && r.loadedW === 0 && r.live === .62 && r.short[0] === .62 && r.short[1] === .4 && r.bg[0] === .62 && r.bg[1] === 0 && r.off[0] === 0 && r.off[1] === 0 && r.noSave;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T52 v2.35 拿掉碗（多米 11-08）：bowl 0 時牠落在窗台正中間、不穿窗台；拉起來放手落回窗台，不會想進碗；閒著走回中間；
  // 走路回家從窗框下緣落到窗台、興奮時落地小跳兩下；envFrame 1 爬上窗框下緣再落回來，換層不跳；搖三下彈了不出窗台；亮粉散出去撿得完；
  // 有畫面時 draw 不出錯；放 1 分鐘全開不飛走不穿地板。T44 到 T49 的碗照樣用 bowl 1 量（面板 1 回 v2.34）
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, walkShow: 1, shake: 1, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bowl: 0, props: 0, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, envFrame: 0, catPush: 0 };
    const clear = () => { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; WALK.bank = 0; WALK.dayN = 0; WALK.day = ''; WALK.opens = 0; WALK.perm = ''; WALK.hopN = 0; };
    const fresh = (sd, over) => { Math.random = seeded(sd || 5201); clear(); mat = { ...SP, ...(over || {}) }; setup(); ESC.on = false; E2.tk.length = 0; E2.tkT = 0; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; };
    const bottom = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, Y[i]); return m; };
    const settle = n => { let hi = -1e9; for (let k = 0; k < n; k++) { steps(1); lastTouch = t; hi = Math.max(hi, bottom()); } return hi; };
    const xR = () => +((globalC.xc - SILL.g.bx) / R).toFixed(2);
    const go = st => { routeStart(st); let f = 0, mj = 0, px = globalC.xc, py = globalC.yc; while (SILL.route && f < 3000) { steps(1); f++; lastTouch = t; mj = Math.max(mj, Math.hypot(globalC.xc - px, globalC.yc - py)); px = globalC.xc; py = globalC.yc; } steps(60); lastTouch = t; return { f, mj: +mj.toFixed(1), plane: SILL.plane, surf: SILL.surf, y1: +bottom().toFixed(1), xR: xR(), selfX: selfX() }; };
    // a 一開始落在窗台正中間
    fresh(); const g = SILL.g, y0 = bottom(); const hi0 = settle(240); const cy1 = globalC.yc; settle(60);
    r.land = { inBowl: SILL.inBowl, want: SILL.want, plane: SILL.plane, surf: SILL.surf, air: SILL.air, startedAbove: y0 < g.fl - 2, onSill: Math.abs(bottom() - g.fl) < 2, belowFloor: +(hi0 - g.fl).toFixed(2), xR: xR(), drift: +Math.abs(globalC.yc - cy1).toFixed(2), selfX: selfX(), area: +(area() / A0).toFixed(3) };
    // b 往上拉、放手：落回窗台，不想進碗
    { const cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 1, cx, cy - R * .4); steps(4); for (let k = 1; k <= 40; k++) { ev('pointermove', 1, cx, cy - R * .4 - k * R * 2.2 / 40); steps(1); } steps(20); const lift = cy - globalC.yc; ev('pointerup', 1, cx, cy - R * 2.6); steps(2); const want = SILL.want; const hi1 = settle(300);
      r.pull = { liftR: +(lift / R).toFixed(2), want, inBowl: SILL.inBowl, onSill: Math.abs(bottom() - g.fl) < 2, belowFloor: +(hi1 - g.fl).toFixed(2), selfX: selfX(), area: +(area() / A0).toFixed(3) }; }
    // c 走到窗台一邊，閒著就走回中間（甩過去的距離每次不一樣，改用走的）
    fresh(5202, { envRoam: 1 }); settle(240); { gaitTo(sillClampX(g.bx + R * 1.6), HOMEY, false); let n = 0; while (GAIT.on && n < 900) { steps(1); lastTouch = t - 3; n++; } settle(120); }
    { const x0 = xR(); lastTouch = t - 30; SILL.lastHome = t - 20; LIFE.st = 'rest'; let n = 0, started = false, hi2 = -1e9; while (n < 1800) { steps(1); n++; hi2 = Math.max(hi2, bottom()); if (SILL.route) started = true; if (started && !SILL.route) break; } steps(30);
      r.home = { x0, started, sec: +(n / 60).toFixed(1), xR: xR(), inBowl: SILL.inBowl, onSill: Math.abs(bottom() - g.fl) < 2, belowFloor: +(hi2 - g.fl).toFixed(2), selfX: selfX() }; }
    // d 走路回家：從窗框下緣落到窗台中間，很興奮時落地小跳兩下（落點 0.09R，小跳兩下會往旁邊挪 0.2R 上下，所以判準 0.5R；坐在窗台上呼吸，重心上下 1.5 點左右，落地漂移判準 3 點）
    fresh(5203, { excite: 3 }); settle(240); WALK.bank = 800; const ok = walkCheck(); { let n = 0, hops = 0, prev = WALK.hopN, hi3 = -1e9; while ((SILL.route || n < 30) && n < 1500) { steps(1); lastTouch = t; n++; } for (let k = 0; k < 240; k++) { if (WALK.hopN < prev) hops++; prev = WALK.hopN; steps(1); lastTouch = t; hi3 = Math.max(hi3, bottom()); } settle(60);
      r.walk = { ok, sec: +(n / 60).toFixed(1), plane: SILL.plane, surf: SILL.surf, z: +SILL.zoom.toFixed(2), inBowl: SILL.inBowl, onSill: Math.abs(bottom() - g.fl) < 2, xR: xR(), stuck: !!WALK.stuck, hops, left: WALK.hopN, belowFloor: +(hi3 - g.fl).toFixed(2), selfX: selfX() }; }
    // e envFrame 1：爬上窗框下緣、再落回窗台中間
    fresh(5204, { envFrame: 1 }); settle(240); r.overBack = go(rtOverBack(g.jr - R)); r.backIn = go(rtBackIn()); r.frameBt = +g.bt.toFixed(1);
    // f 搖三下：彈了、還在窗台上
    fresh(5205); settle(240); { const x0 = globalC.xc, y0b = globalC.yc; let mv = 0, x0m = 1e9, x1m = -1e9, hiS = -1e9; shkShake(1, -.5); steps(10); shkShake(-1, -.5); steps(10); shkShake(1, -.5); const c3 = +SNW.cloud.toFixed(2); for (let k = 0; k < 240; k++) { steps(1); mv = Math.max(mv, Math.hypot(globalC.xc - x0, globalC.yc - y0b)); hiS = Math.max(hiS, bottom()); for (const i of bnd) { x0m = Math.min(x0m, X[i]); x1m = Math.max(x1m, X[i]); } } settle(180);
      r.shake = { cloud: c3, moved: +mv.toFixed(1), inSill: x0m >= g.l - 1 && x1m <= g.r + 1, belowFloor: +(hiS - g.fl).toFixed(2), onSill: Math.abs(bottom() - g.fl) < 2, inBowl: SILL.inBowl, selfX: selfX(), area: +(area() / A0).toFixed(3), nan: X.some(v => !Number.isFinite(v)) }; }
    // g 散出來吃回來：亮粉落在窗台上，撿得完
    fresh(5206, { shakeMode: 1 }); settle(240); { shkShake(1, -.5); steps(10); shkShake(-1, -.5); steps(10); shkShake(1, -.5); steps(60); const l0 = SNW.loose.length; let n = 0, inB = 0; while (SNW.loose.length && n < 3000) { steps(1); n++; for (const p of SNW.loose) if (p.inBowl) inB++; } steps(30);
      r.eat = { l0, sec: +(n / 60).toFixed(1), left: SNW.loose.length, inBowl: inB, selfX: selfX(), nan: X.some(v => !Number.isFinite(v)) }; }
    // h 有畫面時畫得出來（白天、夜晚）
    { const bg0 = VIEW.bg; let err = null; try { for (const b of ['day', 'night']) { VIEW.bg = b; draw(); } } catch (e) { err = String(e); } VIEW.bg = bg0; r.draw = { err, scene: !!sceneFor('day') }; }
    // i 全開放 1 分鐘：不飛走、不穿窗台、不進碗
    fresh(5207, { envRoam: 1, emo: 1 }); { let hi = -1e9, x0 = 1e9, x1 = -1e9, inB = 0, nan = 0; for (let k = 0; k < 3600; k++) { steps(1); hi = Math.max(hi, bottom()); if (SILL.inBowl) inB++; for (const i of bnd) { x0 = Math.min(x0, X[i]); x1 = Math.max(x1, X[i]); } if (k % 60 === 0 && X.some(v => !Number.isFinite(v))) nan++; }
      r.alive = { belowFloor: +(hi - g.fl).toFixed(2), inFrame: x0 >= g.l - R * .3 && x1 <= g.r + R * .3, inBowl: inB, nan, selfX: selfX(), area: +(area() / A0).toFixed(3) }; }
    clear(); res.T52_noBowl = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const okA = x => x > .85 && x < 1.15;
    res.PASS.noBowl = !r.land.inBowl && !r.land.want && r.land.plane === 'room' && r.land.surf === 'floor' && !r.land.air && r.land.startedAbove && r.land.onSill && r.land.belowFloor <= .5 && Math.abs(r.land.xR) < .1 && r.land.drift < 3 && r.land.selfX === 0 && okA(r.land.area)
      && r.pull.liftR > .8 && !r.pull.want && !r.pull.inBowl && r.pull.onSill && r.pull.belowFloor <= .5 && r.pull.selfX === 0
      && Math.abs(r.home.x0) > .6 && r.home.started && Math.abs(r.home.xR) < .3 && !r.home.inBowl && r.home.onSill && r.home.belowFloor <= .5 && r.home.selfX === 0
      && r.walk.ok && r.walk.plane === 'room' && r.walk.surf === 'floor' && r.walk.z > .97 && !r.walk.inBowl && r.walk.onSill && Math.abs(r.walk.xR) < .5 && r.walk.stuck && r.walk.hops === 2 && r.walk.left === 0 && r.walk.belowFloor <= .5 && r.walk.selfX === 0
      && r.overBack.plane === 'frame' && r.overBack.surf === 'bar' && Math.abs(r.overBack.y1 - r.frameBt) < 3 && r.overBack.mj < R * .12 && r.overBack.selfX === 0
      && r.backIn.plane === 'room' && r.backIn.surf === 'floor' && Math.abs(r.backIn.y1 - g.fl) < 2 && Math.abs(r.backIn.xR) < .3 && r.backIn.mj < R * .12 && r.backIn.selfX === 0
      && r.shake.cloud > .85 && r.shake.moved > 2.5 && r.shake.inSill && r.shake.belowFloor <= .5 && r.shake.onSill && !r.shake.inBowl && r.shake.selfX === 0 && okA(r.shake.area) && !r.shake.nan
      && r.eat.l0 > 0 && r.eat.left === 0 && r.eat.inBowl === 0 && r.eat.selfX === 0 && !r.eat.nan
      && !r.draw.err && r.draw.scene
      && r.alive.belowFloor <= .5 && r.alive.inFrame && r.alive.inBowl === 0 && r.alive.nan === 0 && r.alive.selfX === 0 && okA(r.alive.area);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T53 v2.36 黏牆（多米 11-07：像章魚黏在牆上，捏下來會抵抗、緊黏牆壁，還是被揣下來）。只跟碗互動（envFrame 0）也黏得上；吸盤那圈釘在牆上；8 到 15 秒自己下來；
  // 往外拉不到門檻一顆都不剝，過了門檻一顆一顆剝、眼睛 > <、最後一起放掉被揣下來；剝到一半放手彈回牆上繼續黏；黏牆關掉不黏；門檻熟 1R、戒 1.5R
  { const clock = saveClock(); const r = {}, SP = { ...P27.clay, cling: 1, shake: 0, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0, envFrame: 0 };
    const fresh = (sd, over) => { Math.random = seeded(sd || 5201); mat = { ...SP, ...(over || {}) }; setup(); g = SILL.g; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t; };
    let g = null; const nan = () => X.some(v => !Number.isFinite(v)) || Y.some(v => !Number.isFinite(v));
    const stick = () => { const cx = globalC.xc, cy = globalC.yc, tx = g.jr - R * .6, ty = g.gy + R * .9; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 70; k++) { ev('pointermove', 1, cx + (tx - cx) * k / 70, cy + (ty - cy) * k / 70); steps(1); } steps(50); ev('pointerup', 1, tx, ty); steps(3); };
    const pinOff = () => { let m = 0; if (CLING.ax) for (let i = 0; i < N; i++) if (CLING.ax[i] === CLING.ax[i]) m = Math.max(m, Math.hypot(X[i] - CLING.ax[i], Y[i] - CLING.ay[i])); return +m.toFixed(3); };
    // 黏上、吸盤、待著、自己下來
    fresh(5201); stick(); const surf = SILL.surf; steps(60); r.stick = { surf, on: CLING.on, n: CLING.n, pinOff: pinOff(), plane: SILL.plane, selfX: selfX() };
    steps(240); const still5 = CLING.on && SILL.stickT >= 0 && SILL.surf === 'rjamb'; steps(660); r.stay = { still5, down: SILL.stickT < 0 && !CLING.on, selfX: selfX(), nan: nan() };
    // 往外拉：不到門檻不剝；過了門檻一顆一顆剝，最後被揣下來
    fresh(5202); stick(); steps(60); { const n0 = CLING.n, cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 2, cx, cy); steps(3); for (let k = 1; k <= 30; k++) { ev('pointermove', 2, cx - R * .6 * k / 30, cy); steps(1); } steps(20); const small = CLING.n;
      let dec = 0, last = CLING.n, sq = false, popF = -1; for (let k = 1; k <= 180; k++) { ev('pointermove', 2, cx - R * .6 - R * 2.4 * Math.min(1, k / 90), cy); steps(1);   /* 1.5 秒拉到 3R，停在那裡再撐 1.5 秒 */ if (CLING.n < last) { dec++; last = CLING.n; } if (EYE.sqU > t) sq = true; if (!CLING.on && popF < 0) popF = k; }
      steps(30); const away = +((g.jr - globalC.xc) / R).toFixed(2); ev('pointerup', 2, cx - R * 3, cy); steps(120);
      r.peel = { n0, small, dec, sq, popF, popped: popF > 0, away, selfX: selfX(), nan: nan() }; }   // 揣下來之後在窗戶上緣附近慢慢放手，會照 v2.30 黏到天花板，所以看揣下來那一刻
    // 剝到一半放手：彈回牆上繼續黏
    fresh(5203); stick(); steps(60); { const n0 = CLING.n, cx = globalC.xc, cy = globalC.yc; ev('pointerdown', 3, cx, cy); steps(3); for (let k = 1; k <= 30; k++) { ev('pointermove', 3, cx - R * 1.9 * k / 30, cy); steps(1); if (CLING.n < n0) break; }
      let k2 = 0; while (CLING.on && CLING.n >= n0 && k2 < 120) { steps(1); k2++; } const nRel = CLING.n; ev('pointerup', 3, cx - R * 1.9, cy); steps(60);
      r.mid = { n0, nRel, on: CLING.on, n: CLING.n, surf: SILL.surf, stuck: SILL.stickT >= 0, plane: SILL.plane, selfX: selfX() }; }
    // 黏牆關掉：只跟碗互動時放在窗框旁邊不黏（v2.31）
    fresh(5204, { cling: 0 }); stick(); steps(60); r.off = { stuck: SILL.stickT >= 0, on: CLING.on };
    // 門檻跟印象：熟 1R、戒 1.5R
    { mat.imp = 1; IMP.tr = 1; IMP.w = 0; const a = clingP0() / R; IMP.tr = 0; IMP.w = 1; const b = clingP0() / R; IMP.tr = 0; IMP.w = 0; mat.imp = 0; r.p0 = [+a.toFixed(2), +b.toFixed(2)]; }
    res.T53_cling = r; restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    res.PASS.cling = r.stick.surf === 'rjamb' && r.stick.on && r.stick.n >= 4 && r.stick.pinOff < .5 && r.stick.selfX === 0
      && r.stay.still5 && r.stay.down && r.stay.selfX === 0 && !r.stay.nan
      && r.peel.small === r.peel.n0 && r.peel.dec >= 3 && r.peel.sq && r.peel.popped && r.peel.away > 1.5 && r.peel.selfX === 0 && !r.peel.nan
      && r.mid.on && r.mid.nRel < r.mid.n0 && r.mid.n === r.mid.nRel && r.mid.surf === 'rjamb' && r.mid.stuck && r.mid.selfX === 0
      && !r.off.stuck && !r.off.on && r.p0[0] === 1 && r.p0[1] === 1.5;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T54 v2.38 極限拉扯（多米 11-09：極限拉扯下變形還是會有 bug）。窗台上照 app 的預設（v2.38 的四個開關都開），四種拉到極限的拉法：
  // 往右下角拉到窗台下面（拉力把家帶出房間，v2.37 壓成一條線、面積剩 9%）、猛扯到左上角停住再放手（v2.37 黏上窗框被塞進去、交叉留 1.4 秒）、
  // 兩指往上下拉到畫面頂和底（v2.37 交叉、放手記住的形狀翻面）、拉到底再往回推過身體（v2.37 內部翻 440 個）。
  // 外框全程零交叉、面積不掉到七成以下、放手 4 秒內部翻面剩 10 個以內、記住的形狀沒有翻面；四個開關關掉（v2.37）至少有兩種量得到壞掉；兩指拉太開會撕開；慢慢放在窗框旁邊照樣黏得上
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, eyes: 0, shake: 0, decoReact: 0 }, OFF38 = { flipMem: 0, pairMax: 0, tear: 0, homeClamp: 0, clingTidy: 0 };
    const flips = (AX, AY) => { let f = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if ((AX[b] - AX[a]) * (AY[c] - AY[a]) - (AY[b] - AY[a]) * (AX[c] - AX[a]) <= 0) f++; } return f; };
    // 照 app 的組法（芋圓、圓的外形、窗台）：selftest 的畫面是舊的八條腿（VIEW.body 'tent'），不換的話量到的是固定觸手
    const fresh = (sd, over) => { Math.random = seeded(sd); PAIR.tearT = -9; PAIR.over = 0; IMP.tr = .3; IMP.w = 0; MOOD.c = 0; MOOD.a = 0; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; mat = { ...SP, ...(over || {}) }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; WANDER.moving = false; WANDER.next = 1e9; SLP.on = false; SLP.k = 0; SLP.lastAny = -99; LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; LIFE.sns.length = 0; Object.assign(BRAIN, { seed: 54 }); brainReset(); steps(240); lastTouch = t; };   // 11-16：大腦、休息計時、睡著也歸零。原本不歸零，這一項的數字跟「上一個開著大腦的項目留下什麼」有關：只跑 T54 兩次，第二次 twoVert 多 1 幀交叉（v2.45 也一樣）
    const hold = a => { a.still = true; return a; };
    const paths = {
      corner: (k, cx, cy) => { const sx = cx + R * .7, sy = cy, tx = W - 4, ty = H - 4; return k <= 90 ? [[1, sx + (tx - sx) * k / 90, sy + (ty - sy) * k / 90]] : k <= 180 ? hold([[1, tx, ty]]) : null; },
      yank: (k, cx, cy) => { const sx = cx - R * .6, sy = cy - R * .2; return k <= 6 ? [[1, sx + (4 - sx) * k / 6, sy + (4 - sy) * k / 6]] : k <= 66 ? hold([[1, 4, 4]]) : null; },
      twoVert: (k, cx, cy) => { const d = Math.min(1, k / 60), a = [[1, cx, cy - R * .5 - (cy - R * .5 - 4) * d], [2, cx, cy + R * .3 + (H - 4 - cy - R * .3) * d]]; return k <= 60 ? a : k <= 150 ? hold(a) : null; },
      pullBack: (k, cx, cy) => { const sx = cx + R * .7, sy = cy, tx = W - 4, ty = H * .9; return k <= 50 ? [[1, sx + (tx - sx) * k / 50, sy + (ty - sy) * k / 50]] : k <= 120 ? [[1, tx + (4 - tx) * (k - 50) / 70, ty + (H * .15 - ty) * (k - 50) / 70]] : null; } };
    const run = (kind, sd, over) => { fresh(sd, over); const cx = globalC.xc, cy = globalC.yc, fn = paths[kind], p0 = fn(0, cx, cy); for (const d of p0) ev('pointerdown', d[0], d[1], d[2]);
      let crossF = 0, aMin = 9, nanF = 0, last = p0; const t0 = t; const look = () => { if (selfX()) crossF++; aMin = Math.min(aMin, area() / A0); if (!Number.isFinite(X[0] + Y[0])) nanF++; };
      for (let k = 1; ; k++) { const q = fn(k, cx, cy); if (!q) break; last = q; for (const d of q) ev('pointermove', d[0], d[1], d[2]); steps(1); look(); }
      const torn = PAIR.tearT >= t0; for (const d of last) ev('pointerup', d[0], d[1], d[2]); for (let j = 0; j < 240; j++) { steps(1); look(); }
      return { crossF, area: +aMin.toFixed(3), flip4s: flips(X, Y), qFlip: flips(QX, QY), nan: nanF, torn, surf: SILL.surf }; };
    r.on = {}; r.off = {}; for (const kind of Object.keys(paths)) { r.on[kind] = [run(kind, 5401), run(kind, 5402)]; r.off[kind] = run(kind, 5401, OFF38); }
    // 慢慢放在右窗框旁邊照樣黏得上（扭著不黏只擋扭著、超出窗框的）：照 T53 的設定與放法，只多開 clingTidy
    { Math.random = seeded(5201); PAIR.tearT = -9; mat = { ...P27.clay, cling: 1, clingTidy: 1, shake: 0, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, seed: 12, emo: 0, life2: 1, lifeGait: 1, imp: 0, e1: 0, e2: 0, e3: 0, e4: 0, sleep: 0, echo: 0, envRoam: 0, catPush: 0, envFrame: 0 }; setup(); ESC.on = false; E2.tk.length = 0; E2.tkT = 0; WANDER.moving = false; WANDER.next = t + 1e5; lastTouch = t; steps(240); lastTouch = t;
      const g = SILL.g, cx = globalC.xc, cy = globalC.yc, tx = g.jr - R * .6, ty = g.gy + R * .9; ev('pointerdown', 1, cx, cy); steps(3); for (let k = 1; k <= 70; k++) { ev('pointermove', 1, cx + (tx - cx) * k / 70, cy + (ty - cy) * k / 70); steps(1); } steps(50); ev('pointerup', 1, tx, ty); steps(3); r.cling = { surf: SILL.surf, on: CLING.on }; steps(120); }
    res.T54_extreme = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const good = a => a.crossF === 0 && a.area > .7 && a.flip4s <= 10 && a.qFlip === 0 && a.nan === 0;   // 放手 4 秒內部翻面量到 0 到 7 個（962 個裡），看不出來
    const bad = a => a.crossF > 10 || a.area < .5 || a.qFlip > 0;
    res.PASS.extreme = Object.values(r.on).every(v => v.every(good)) && Object.values(r.off).filter(bad).length >= 2
      && r.on.twoVert.every(a => a.torn) && r.cling.surf === 'rjamb' && r.cling.on;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  const BMEM0 = { cell: BMEM.cell.slice(), side: BMEM.side }; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0;   // v2.43：T55 到 T57 不帶使用者存的記性，T57 結尾還回去
  // T55 v2.41 大腦（多米 11-14：像真實世界的動物，有牠自己的一套行為邏輯）。窗台上照 app 的預設（芋圓、熟 0.7），舊項目一律關大腦。
  // a 放著不碰 300 秒：醒著的時間裡休息佔 0.35 到 0.75、有張望有走、睏高了會睡、睡飽自己醒（v2.40 睡了不會自己醒）、沒有 0.5 秒內就換事情、想動不會一直滿格；
  // b 喘（跑完、被大力拉）那一下：睏漲、想動退；c 睏 0.9 開始：15 秒內就睡；睏 0 開始：60 秒內不睡；d brain 0：需求不動、不會自己醒（回 v2.40）
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, e4c = E4.count, e4t = E4.lastT, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, decoReact: 0, lookNoDown: 0 };   // v2.63 C5：張望不朝下（lookNoDown）預設 1 之後窗台上張望的方向變了，這一項量的是舊規格，釘 0
    const run = (over, sec, pre) => { Math.random = seeded(55); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 0; E4.lastT = -99; Object.assign(BRAIN, { seed: 55, naps: 0, selfWake: 0 }); BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; if (pre) pre();
      const c = {}; let short = 0, last = '', lastI = 0, eTop = 0, n = 0, napAt = -1;
      for (let i = 0; i < sec * 60; i++) { update(DT); const a = BRAIN.act; c[a] = (c[a] || 0) + 1; if (a !== last) { if (last && i - lastI < 30) short++; last = a; lastI = i; } if (BRAIN.e > .98) eTop++; if (napAt < 0 && SLP.on) napAt = +(i / 60).toFixed(1); n++; }
      const awake = n - (c['睡覺'] || 0), fr = k => +((c[k] || 0) / Math.max(1, awake)).toFixed(3), [sx, cr] = classify();
      return { rest: fr('休息'), look: fr('張望'), go: fr('走'), greet: fr('來找你'), sleep: +((c['睡覺'] || 0) / n).toFixed(3), naps: BRAIN.naps, selfWake: BRAIN.selfWake, napAt, short, eTop: +(eTop / n).toFixed(3), z: +BRAIN.z.toFixed(3), selfX: sx + cr, area: +(area() / A0).toFixed(3) }; };
    r.a = run({}, 300);
    { Math.random = seeded(55); mat = { ...SP }; setup(); t = 0; lastTouch = -10; tLife = 0; steps(30); const z0 = BRAIN.z, e0 = BRAIN.e; BRX.exert = .8; update(DT); r.b = { dz: +(BRAIN.z - z0).toFixed(3), de: +(BRAIN.e - e0).toFixed(3) }; }
    r.cTired = run({}, 15, () => { BRAIN.z = .9; });
    r.cFresh = run({}, 60, () => { BRAIN.z = 0; });
    r.d = run({ brain: 0 }, 60);
    res.T55_brain = r; log.splice(0); restoreClock(clock); E4.count = e4c; E4.lastT = e4t; mat = { ...PRESETS.clay }; setup();
    res.PASS.brain = r.a.rest >= .35 && r.a.rest <= .75 && r.a.look > .03 && r.a.go > .03 && r.a.naps >= 1 && r.a.selfWake >= 1 && r.a.short === 0 && r.a.eTop < .3 && r.a.selfX === 0
      && r.b.dz > .1 && r.b.de < -.1 && r.cTired.naps === 1 && r.cTired.napAt >= 0 && r.cFresh.naps === 0 && r.d.naps === 0 && r.d.selfWake === 0 && Math.abs(r.d.z - .3) < 1e-9;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T56 v2.42 心情與前兆（大腦第 2 片）。窗台上照 app 的預設（芋圓、熟 0.7）。
  // a 開心那一下心情 +0.12 上下、戒漲 0.3 心情掉 0.3 以上、心情差時怕跟著高；b 被戳：心情好朝你傾過來搖偽足、縮得小，心情差往反方向傾、縮得大；
  // c 心情 0.9 放 300 秒退到 0.45 到 0.7（半衰 300 秒，退回 0.1）；d 前兆：睏 0.9 開始，先「想睡了」1.5 秒以上才睡；brPre 0 馬上睡；
  // e mood 0：心情固定 0.15、被戳的倍數 1（回 v2.41）
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, e4c = E4.count, e4t = E4.lastT, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, decoReact: 0 };
    const fresh = over => { Math.random = seeded(56); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 0; E4.lastT = -99; Object.assign(BRAIN, { seed: 56, naps: 0, selfWake: 0 }); brainReset(); BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; steps(60); };
    const poke = () => { E2.leanS = 0; MOOD.wagT = -9; e2Release({ tDown: t - .1, stretch: 0, fx: globalC.xc + R, fy: globalC.yc }); return { lean: E2.leanS, wag: MOOD.wagT > t, fl: +brainFlinch().toFixed(2) }; };
    fresh({}); { const m0 = BRAIN.m; MOOD.happyT = t; steps(1); r.happyD = +(BRAIN.m - m0).toFixed(3); const m1 = BRAIN.m; IMP.w += .3; steps(1); r.waryD = +(BRAIN.m - m1).toFixed(3); IMP.w = 0; BRAIN.m = -.6; steps(1); r.fBad = +BRAIN.f.toFixed(2); }
    fresh({}); BRAIN.m = .6; r.pokeGood = poke(); BRAIN.m = -.6; r.pokeBad = poke();
    fresh({}); BRAIN.m = .9; steps(300 * 60); r.after300 = +BRAIN.m.toFixed(3);
    const nap = over => { fresh(over); BRAIN.z = .9; let preAt = -1, napAt = -1; for (let i = 0; i < 20 * 60 && napAt < 0; i++) { steps(1); if (preAt < 0 && BRAIN.pre && BRAIN.pre.k === 'sleep') preAt = i / 60; if (SLP.on) napAt = i / 60; } return { preAt: +preAt.toFixed(2), napAt: +napAt.toFixed(2) }; };
    r.pre = nap({}); r.preOff = nap({ brPre: 0 });
    fresh({ mood: 0 }); BRAIN.m = .9; steps(2); r.off = { m: BRAIN.m, fl: brainFlinch(), poke: poke() };
    res.T56_mood = r; log.splice(0); restoreClock(clock); E4.count = e4c; E4.lastT = e4t; mat = { ...PRESETS.clay }; setup();
    res.PASS.mood = r.happyD > .1 && r.happyD < .14 && r.waryD < -.3 && r.fBad > .15
      && r.pokeGood.lean === 1 && r.pokeGood.wag && r.pokeGood.fl < .9 && r.pokeBad.lean === -1 && !r.pokeBad.wag && r.pokeBad.fl > 1.2
      && r.after300 > .45 && r.after300 < .7
      && r.pre.preAt >= 0 && r.pre.napAt - r.pre.preAt >= 1.5 && r.pre.napAt - r.pre.preAt < 3 && r.preOff.preAt < 0 && r.preOff.napAt >= 0
      && r.off.m === .15 && r.off.fl === 1 && r.off.poke.lean === 1 && !r.off.poke.wag;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T57 v2.43 記性（大腦第 3 片）。窗台上照 app 的預設（芋圓、熟 0.7）。測試不准碰使用者存的記性（IMPSV.noSave 擋存檔，BMEM 跑完還回去）。
  // a 開心那一下所在那格 +0.1、戒漲 0.3 那格掉 0.4 以上；b 最左邊那格 0.8、睏 0.9：走到左邊才睡（v2.42 在正中間睡）；
  // c 正中間那格 -0.8：放 120 秒待在那格的時間不到三成五、而且不到對照的一半（11-15 實量：都是 0 時 0.87，-0.8 時 0.22。那 0.22 是開頭還沒走開的 8 秒，加上一次「來找你」把牠帶回畫面正中間、打完招呼又待了十幾秒才走）；d 記你：從左邊放手 12 次 side 小於 -0.5，放 120 秒至少一次把左邊靠過來（「來找你」先關掉：兩個搶同一個需求，來找你還有額度時靠過來大約四次才贏一次，120 秒排不到。「想被摸」直接給 0.9：分頁不在前面時它不漲，瀏覽器面板收著那輪會量到 0 次）；
  // e 隔兩天：喜歡的不動、-0.8 剩 -0.13、-0.2 歸零；f brMem 0：那格不動、家在正中間、不靠過來
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, e4c = E4.count, e4t = E4.lastT, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, decoReact: 0, brJit: 0 };   // v2.61 C7：門檻是照固定作息、種子 57 那一次量的（120 秒裡睡醒的時刻亂了就變 0.36 對 0.35）；11-25 另外量 12 個種子，討厭那格平均待 0.43（關）對 0.42（開），躲的本事沒變
    const fresh = (over, cells, side) => { Math.random = seeded(57); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 0; E4.lastT = -99; Object.assign(BRAIN, { seed: 57, naps: 0, selfWake: 0 }); brainReset(); BMEM.cell = (cells || [0, 0, 0, 0, 0]).slice(); BMEM.side = side || 0; BMEM.leans = 0; BMEM.offerAt = -99; BMEM.dirty = false; steps(60); };
    const mid = () => memCellAt(SILL.g.bx);
    fresh({}); { const k = memCellAt(globalC.xc); MOOD.happyT = t; steps(2); const a = BMEM.cell[k]; IMP.w += .3; steps(2); r.learn = { k, happy: +a.toFixed(3), scare: +(BMEM.cell[k] - a).toFixed(3) }; IMP.w = 0; }
    const napAt = (over, cells) => { fresh(over, cells); BRAIN.z = .9; let x = null; for (let i = 0; i < 30 * 60 && x == null; i++) { steps(1); if (SLP.on) x = globalC.xc; } return x == null ? null : +((x - SILL.g.bx) / R).toFixed(2); };
    r.napFav = napAt({}, [.8, 0, 0, 0, 0]); r.napOff = napAt({ brMem: 0 }, [.8, 0, 0, 0, 0]);
    const stay = cells => { fresh({}, cells); const m = mid(); let c = 0, n = 0; for (let i = 0; i < 120 * 60; i++) { steps(1); n++; if (SILL.plane === 'room' && memCellAt(globalC.xc) === m) c++; } return +(c / n).toFixed(3); };
    r.stayCtrl = stay([0, 0, 0, 0, 0]); { const c = [0, 0, 0, 0, 0]; c[mid()] = -.8; r.stayAvoid = stay(c); }
    fresh({}); for (let i = 0; i < 12; i++) memTouch({ ax: globalC.xc - R * .8 }); r.side = +BMEM.side.toFixed(3);
    { const sd = BMEM.side; fresh({}, null, sd); E4.count = 99; BRAIN.s = .9; steps(120 * 60); r.offer = { leans: BMEM.leans, left: Math.abs(E2.leanA - Math.PI) < 1e-9 }; }
    r.decay = memDecay({ cell: [.8, -.8, -.2, 0, 0], side: .5 }, 2).cell.map(v => +v.toFixed(3));
    fresh({ brMem: 0 }, [.8, 0, 0, 0, 0], -.8); { const k = memCellAt(globalC.xc), a = BMEM.cell[k]; MOOD.happyT = t; steps(2); memTouch({ ax: globalC.xc + R }); steps(60 * 60); r.off = { same: BMEM.cell[k] === a, side: BMEM.side, leans: BMEM.leans, homeMid: Math.abs(memHomeX() - SILL.g.bx) < 1e-9 }; }
    res.T57_mem = r; log.splice(0); restoreClock(clock); E4.count = e4c; E4.lastT = e4t; BMEM.cell = BMEM0.cell; BMEM.side = BMEM0.side; BMEM.dirty = false; mat = { ...PRESETS.clay }; setup();
    res.PASS.mem = Math.abs(r.learn.happy - .1) < .01 && r.learn.scare < -.4
      && r.napFav != null && r.napFav < -.5 && r.napOff != null && Math.abs(r.napOff) < .3
      && r.stayCtrl > .5 && r.stayAvoid < .35 && r.stayAvoid < r.stayCtrl * .5
      && r.side < -.5 && r.offer.leans >= 1 && r.offer.left
      && r.decay[0] === .8 && Math.abs(r.decay[1] + .133) < .001 && r.decay[2] === 0
      && r.off.same && r.off.side === -.8 && r.off.leans === 0 && r.off.homeMid;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T58 v2.44 擺飾變真第 1 片（多米 11-15：跟環境物件互動）。窗台上照 app 的預設（芋圓、擺飾 1）。
  // a 開關：decoReal 0 沒有東西、風鈴不是擺錘；1 有蠟燭和玻璃罐，放 5 秒不動
  // b 不推牠：同一個種子放 20 秒，開和關牠每個點的位置差不到千分之一點（這一片東西碰不到牠；11-15 實量差 0.00000009 點）
  // c 點罐子：晃 0.05 到 0.6 弧度、有玻璃聲、2 秒後站正；d 罐子大力一推：掉下窗台、聽得到落地、22 秒內回原位站正
  // h 手指抓的是按到的那一點：抓罐子上面往左推 40 點會倒；捏著倒掉的罐子上端提起來再放下，它站正；抓下面往左拖 30 點是平移（歪不到 0.25 弧度）
  // e 蠟燭推倒：躺在窗台上（沒掉下去）、火熄；27 秒後回原位站正、火亮
  // f 風鈴：點一下晃 0.05 到 0.7 弧度、至少叮一聲、15 秒後停在正中；搖一下會動；抓著往左拖 70 點，下端跟到左邊（角度大於 0.4）
  // g 全部弄亂以後放 60 秒：沒有東西停在半空、沒有 NaN
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, bg0 = VIEW.bg, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, deco: 1, decoReal: 1, decoBody: 0, decoReact: 0 };
    const fresh = over => { Math.random = seeded(58); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; Object.assign(BRAIN, { seed: 58, naps: 0, selfWake: 0 }); brainReset(); BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; steps(60); log.splice(0); };
    const up = p => Math.abs(Math.atan2(Math.sin(p.a), Math.cos(p.a))), tapAt = (id, x, y) => { ev('pointerdown', id, x, y); steps(3); ev('pointerup', id, x, y); };
    const heard = k => log.filter(a => a[0] === k).length, home = p => !p.gone && p.alpha > .99 && up(p) < .02 && Math.hypot(p.x - p.hx, p.y - p.hy) < 1.5;
    fresh({}); steps(20 * 60);   // 先空跑一次：前一項留下來的狀態會讓第一次跟之後幾次差 3、4 點（同樣的設定跑兩次也差），比的是第二次以後
    fresh({ decoReal: 0 }); r.off = { n: PROPS.length, bell: HANG.bell.on }; steps(20 * 60); const X0 = Float64Array.from(X), Y0 = Float64Array.from(Y);
    fresh({}); r.on = { ims: PROPS.map(q => q.im).join(), bell: HANG.bell.on, teru: HANG.teru.on }; steps(5 * 60); r.rest = PROPS.every(home); steps(15 * 60); { let d = 0; for (let i = 0; i < N; i++) d = Math.max(d, Math.abs(X[i] - X0[i]), Math.abs(Y[i] - Y0[i])); r.bodyDiff = d; }
    fresh({}); { const J = PROPS[1]; tapAt(1, J.x + 14, J.y); let mx = 0; for (let i = 0; i < 120; i++) { steps(1); mx = Math.max(mx, up(J)); } r.tap = { max: +mx.toFixed(3), glass: heard('knock.glass'), home: home(J), mode: fingers.size }; }
    { const J = PROPS[1]; log.splice(0); J.va = 12; J.lastHit = t; let gone = false, back = null; for (let i = 0; i < 22 * 60; i++) { steps(1); if (J.gone) gone = true; else if (gone && back == null && J.alpha >= 1) back = +(i / 60).toFixed(1); } r.fall = { gone, back, sound: heard('knock.glass'), home: home(J) }; }
    fresh({}); { const J = PROPS[1], x0 = J.x, y0 = J.y - 25; ev('pointerdown', 4, x0, y0); steps(2); for (let i = 1; i <= 20; i++) { ev('pointermove', 4, x0 - 2 * i, y0); steps(1); } steps(20); ev('pointerup', 4, x0 - 40, y0); steps(120); r.push = { lying: +up(J).toFixed(2), onSill: !J.gone };
      J.x = 330; J.y = SILL.g.fl - 30; J.a = 1.57; J.vx = J.vy = J.va = 0; J.lastHit = t; steps(60); const c = Math.cos(J.a), sn = Math.sin(J.a), gx = J.x + sn * 26, gy = J.y - c * 26; ev('pointerdown', 5, gx, gy); steps(2); const held = !!J.held; for (let i = 1; i <= 40; i++) { ev('pointermove', 5, gx - 20 * i / 40, gy - 70 * i / 40); steps(1); } steps(30); for (let i = 1; i <= 20; i++) { ev('pointermove', 5, gx - 20, gy - 70 + 40 * i / 20); steps(1); } ev('pointerup', 5, gx - 20, gy - 30); steps(120); r.fix = { held, up: +up(J).toFixed(3), onSill: !J.gone && Math.abs(J.y + J.base - SILL.g.fl) < 2 };
      const x1 = J.x, y1 = J.y + 18; ev('pointerdown', 6, x1, y1); steps(2); let mx = 0; for (let i = 1; i <= 30; i++) { ev('pointermove', 6, x1 - i, y1); steps(1); mx = Math.max(mx, up(J)); } ev('pointerup', 6, x1 - 30, y1); steps(60); r.slide = { tilt: +mx.toFixed(2), moved: +(x1 - J.x).toFixed(0) }; }
    { const C = PROPS[0]; VIEW.bg = 'night'; steps(4 * 60); const lit0 = t - C.upT > 3; C.va = 15; C.lastHit = t; steps(120); r.tip = { lit0, lying: +up(C).toFixed(2), onSill: !C.gone && C.y < SILL.g.fl, lit: t - C.upT > 3 }; steps(27 * 60); r.tip.home = home(C); steps(4 * 60); r.tip.litAgain = t - C.upT > 3; VIEW.bg = bg0; }
    fresh({}); { const B = HANG.bell; tapAt(2, B.x - 8, B.y + B.h * .6); let mx = 0; for (let i = 0; i < 180; i++) { steps(1); mx = Math.max(mx, Math.abs(B.a)); } const dings = heard('knock.bell'); steps(15 * 60); r.bell = { max: +mx.toFixed(3), dings, still: B.a === 0 && B.va === 0 };
      shkShake(1, 0); steps(6); r.bell.shake = +Math.abs(B.va).toFixed(2); steps(15 * 60);
      ev('pointerdown', 3, B.x, B.y + B.h * .7); steps(2); for (let i = 1; i <= 10; i++) { ev('pointermove', 3, B.x - i * 7, B.y + B.h * .7); steps(1); } steps(20); r.bell.drag = +B.a.toFixed(2); ev('pointerup', 3, B.x - 70, B.y + B.h * .7); steps(2); r.bell.freed = B.held == null; }
    { const J = PROPS[1], C = PROPS[0]; J.va = 12; C.va = -15; C.vx = -R; J.lastHit = C.lastHit = t; HANG.bell.va = 5; steps(60 * 60); let nan = 0, air = 0; for (const q of PROPS) { if (![q.x, q.y, q.a, q.vx, q.vy, q.va].every(isFinite)) nan++; if (!q.gone && !q.held && q.y + q.base < SILL.g.fl - 3 && Math.abs(q.vy) < 1 && up(q) < .02) air++; } if (!isFinite(HANG.bell.a)) nan++; let bn = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bn++; r.mess = { nan, air, bodyNan: bn, selfX: selfX() }; }
    res.T58_deco = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; mat = { ...PRESETS.clay }; setup();
    res.PASS.deco = r.off.n === 0 && !r.off.bell && r.on.ims === 'd_candle,d_jar' && r.on.bell && !r.on.teru && r.rest && r.bodyDiff < .001
      && r.tap.max > .05 && r.tap.max < .6 && r.tap.glass >= 1 && r.tap.home && r.tap.mode === 0
      && r.fall.gone && r.fall.back != null && r.fall.sound >= 1 && r.fall.home
      && r.push.lying > 1 && r.push.onSill && r.fix.held && r.fix.up < .05 && r.fix.onSill && r.slide.tilt < .25 && r.slide.moved > 20
      && r.tip.lit0 && r.tip.lying > 1 && r.tip.onSill && !r.tip.lit && r.tip.home && r.tip.litAgain
      && r.bell.max > .05 && r.bell.max < .7 && r.bell.dings >= 1 && r.bell.still && r.bell.shake > .5 && r.bell.drag > .4 && r.bell.freed
      && r.mess.nan === 0 && r.mess.air === 0 && r.mess.bodyNan === 0 && r.mess.selfX === 0;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T59 v2.45 擺飾變真第 2 片：牠帶動東西，東西不推牠。窗台上照 app 的預設（芋圓、擺飾 1）。
  // a 不推牠：同一個種子、同一串手指動作（把牠甩向罐子），「牠碰得到擺飾」開和關，牠每個點的位置差不到 1 點（11-15 實量：開跟關差 0.006 到 0.08，同樣開著跑兩次也差 0.02，甩那一下會把本來就有的極小誤差放大，每次放大多少不一定；東西真的推到牠的話會差好幾點）；開著那次罐子被撞走（倒、移開 30 點以上或掉下去），關著那次罐子沒動
  // b 牠那一塊每秒 20 點：罐子不動；每秒 100 點：罐子被帶走 3 點以上，蠟燭（比較重）被帶得比罐子少；c 每秒 300 點：罐子倒、掉或移 15 點以上，蠟燭也被帶動，但沒罐子多（量的是過程中最遠、最歪的時候）
  // d 把牠拖去碰風鈴：風鈴晃超過 0.1 弧度、至少叮一聲；e 放著 60 秒：沒有 NaN、沒有東西停在半空、牠沒打結
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, deco: 1, decoReal: 1, decoBody: 1, decoPush: 1, decoReact: 0 };
    const fresh = over => { Math.random = seeded(59); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; Object.assign(BRAIN, { seed: 59, naps: 0, selfWake: 0 }); brainReset(); BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; steps(60); log.splice(0); };
    const up = q => Math.abs(Math.atan2(Math.sin(q.a), Math.cos(q.a))), heard = k => log.filter(a => a[0] === k).length;
    const throwR = () => { const gx = globalC.xc, gy = globalC.yc; ev('pointerdown', 1, gx, gy); steps(3); for (let i = 1; i <= 10; i++) { ev('pointermove', 1, gx + i * 14, gy); steps(1); } ev('pointerup', 1, gx + 140, gy); steps(180); };
    // 牠在家時坐在布墊上，底比蠟燭頂還高；離開布墊才會落到窗台面，下面直接把牠放到窗台面
    // 只測「帶動」這個機制：身體不跑物理，整團平移蓋住那件東西，再用固定速度往外移，看東西被帶走多少（拖牠的話，身體跟手指的落後會讓速度對不上，量不準）
    const carry = (k, v, n) => { fresh({ bumpSoft: 0 }); /* v2.61 C7：這裡沒有手指，牠自己碰到的只晃不倒；量的是「帶動」那套算式，關掉 */ const q = PROPS[k], dir = k ? 1 : -1, sh = dir * 85; let bot = -1e9; for (let i = 0; i < N; i++) bot = Math.max(bot, Y[i]); const dn = SILL.g.fl - 2 - bot; for (let i = 0; i < N; i++) { X[i] += sh; PX[i] += sh; Y[i] += dn; PY[i] += dn; } decoBody(1 / 60); let mv = 0, tl = 0; const see = () => { if (!q.gone) { mv = Math.max(mv, Math.abs(q.x - q.hx)); tl = Math.max(tl, up(q)); } }; for (let f = 0; f < n; f++) { for (let i = 0; i < N; i++) { X[i] += dir * v / 60; PX[i] += dir * v / 60; } decoBody(1 / 60); for (let u = 0; u < 4; u++) propsStep(1 / 240); see(); } for (let f = 0; f < 90; f++) { decoBody(1 / 60); for (let u = 0; u < 4; u++) propsStep(1 / 240); see(); } return { mv: +mv.toFixed(1), up: +tl.toFixed(2), gone: q.gone }; };
    fresh({}); throwR();   // 先空跑一次（見 T58）
    fresh({ decoBody: 0 }); throwR(); const X0 = Float64Array.from(X), Y0 = Float64Array.from(Y); { const J = PROPS[1]; r.off = { moved: +Math.abs(J.x - J.hx).toFixed(1), up: +up(J).toFixed(2), gone: J.gone }; }
    fresh({}); throwR(); { let d = 0; for (let i = 0; i < N; i++) d = Math.max(d, Math.abs(X[i] - X0[i]), Math.abs(Y[i] - Y0[i])); const J = PROPS[1]; r.on = { bodyDiff: d, moved: +Math.abs(J.x - J.hx).toFixed(1), up: +up(J).toFixed(2), gone: J.gone, sound: heard('knock.glass') }; }
    r.jar20 = carry(1, 20, 30); r.jar100 = carry(1, 100, 12); r.can100 = carry(0, 100, 12); r.jar300 = carry(1, 300, 4); r.can300 = carry(0, 300, 4);
    fresh({}); { const B = HANG.bell, gx = globalC.xc, gy = globalC.yc; let mx = 0; ev('pointerdown', 3, gx, gy); for (let i = 1; i <= 40; i++) { ev('pointermove', 3, gx + (B.x - gx) * i / 40, gy + (B.y + B.h * .8 - gy) * i / 40); steps(1); mx = Math.max(mx, Math.abs(B.a)); } for (let i = 0; i < 60; i++) { steps(1); mx = Math.max(mx, Math.abs(B.a)); } ev('pointerup', 3, B.x, B.y + B.h * .8); steps(120); r.bell = { max: +mx.toFixed(2), dings: heard('knock.bell') }; }
    { steps(60 * 60); let nan = 0, air = 0; for (const q of PROPS) { if (![q.x, q.y, q.a, q.vx, q.vy, q.va].every(isFinite)) nan++; if (!q.gone && !q.held && q.y + q.base < SILL.g.fl - 3 && Math.abs(q.vy) < 1 && up(q) < .02) air++; } if (!isFinite(HANG.bell.a)) nan++; let bn = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bn++; r.idle = { nan, air, bodyNan: bn, selfX: selfX() }; }
    res.T59_decoBody = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    res.PASS.decoBody = r.on.bodyDiff < 1 && (r.on.gone || r.on.up > 1 || r.on.moved > 30) && !r.off.gone && r.off.moved < 1 && r.off.up < .02
      && r.jar20.mv < 1.5 && r.jar20.up < .05 && r.jar100.mv > 3 && r.can100.mv < r.jar100.mv && (r.jar300.gone || r.jar300.up > 1 || r.jar300.mv > 15) && (r.can300.gone || r.can300.up > .05 || r.can300.mv > 2) && (r.jar300.gone || r.can300.mv < r.jar300.mv)
      && r.bell.max > .1 && r.bell.dings >= 1
      && r.idle.nan === 0 && r.idle.air === 0 && r.idle.bodyNan === 0 && r.idle.selfX === 0;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T60 v2.46 擺飾變真第 3 片：牠知道東西動了。窗台上照 app 的預設（芋圓、熟 0.7、擺飾 1）。T58、T59 把 decoReact 關掉，數字跟 v2.45 一樣。
  // a 開關：decoReact 0 時把罐子推下去，牠沒看、沒嚇；b 嚇和習慣：開著連推三次，第一次怕漲 0.2 到 0.46、有縮一下，之後每次不到前一次的六成
  // c 嚇醒：睡著時蠟燭倒下，半秒內醒；d 看：點一下罐子，牠看過去、好奇漲 0.1 以上；好奇 0.7 時點風鈴，牠伸偽足探
  // e 蠟燭：夜晚家在蠟燭那一側（離正中間 20 點以上），60 秒內牠走到家；白天家回正中間
  // f 推：好奇 0.9、心情 0.5 時 14 秒內牠去推一件東西，東西倒、掉或挪 20 點以上，牠沒被嚇；推過 2 次、或開關關掉就不推
  // g 放著 60 秒：沒有 NaN、牠沒打結
  { const clock = saveClock(); const TARO = SLIMES[2], r = {}, bg0 = VIEW.bg, SP = { ...P27R[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, envRoam: 0, deco: 1, decoReal: 1, decoBody: 1, decoPush: 1, decoReact: 1, decoCat: 1, decoScare: 1 };
    const fresh = over => { Math.random = seeded(60); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = .7; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; Object.assign(BRAIN, { seed: 60, naps: 0, selfWake: 0 }); brainReset(); for (const k in DR.n) DR.n[k] = 0; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; steps(60); log.splice(0); };
    const up = q => Math.abs(Math.atan2(Math.sin(q.a), Math.cos(q.a))), calm = () => { BRAIN.z = 0; BRAIN.e = 0; BRAIN.q = .2; LIFE.st = 'rest'; LIFE.until = t + 999; };   // 測反應時牠待在原地休息
    const shove = q => { q.va = q.im === 'd_candle' ? 15 : 12; q.lastHit = t; q.fingT = t; let sc = 0, fl = 0; for (let i = 0; i < 180; i++) { steps(1); sc = Math.max(sc, MOOD.scare); fl = Math.max(fl, 1 - FLN.s); } return { amt: DR.last ? +DR.last.amt.toFixed(3) : 0, sc: +sc.toFixed(3), fl: +fl.toFixed(3) }; };
    fresh({ decoReact: 0 }); calm(); { const J = PROPS[1]; const s = shove(J); r.off = { scare: DR.n.scare, look: DR.n.look, sc: s.sc, fell: J.gone || up(J) > 1 }; }
    fresh({}); calm(); { const J = PROPS[1]; r.hab = []; for (let k = 0; k < 3; k++) { calm(); r.hab.push(shove(J)); calm(); steps(26 * 60); } r.habN = DR.n.scare; }
    fresh({}); calm(); { const C = PROPS[0]; BRAIN.z = .9; SLP.on = true; LIFE.st = 'sleep'; steps(240); const k0 = SLP.k; C.va = 15; C.lastHit = t; C.fingT = t; let woke = -1; for (let i = 0; i < 120; i++) { steps(1); if (!SLP.on && woke < 0) woke = i; } r.wake = { k0: +k0.toFixed(2), woke, n: DR.n.wake }; }
    fresh({}); calm(); { const J = PROPS[1], B = HANG.bell, q0 = BRAIN.q; ev('pointerdown', 1, J.x + 14, J.y); steps(3); ev('pointerup', 1, J.x + 14, J.y); steps(2); r.look = { n: DR.n.look, dq: +(BRAIN.q - q0).toFixed(3), eye: DR.lookT > t, scare: DR.n.scare }; steps(300);
      calm(); BRAIN.q = .7; LIFE.until = t + 5; ev('pointerdown', 2, B.x - 8, B.y + B.h * .6); steps(3); ev('pointerup', 2, B.x - 8, B.y + B.h * .6); let sn = 0; for (let i = 0; i < 90; i++) { steps(1); sn = Math.max(sn, LIFE.sns.length); } r.probe = { n: DR.n.probe, sn }; }
    fresh({}); { const g = SILL.g; VIEW.bg = 'night'; steps(5 * 60); const hx = memHomeX(); let at = -1; for (let i = 0; i < 60 * 60 && at < 0; i++) { steps(1); if (Math.abs(globalC.xc - hx) < R * .35) at = +(i / 60).toFixed(1); } VIEW.bg = 'day'; steps(2); r.candle = { shift: +(g.bx - hx).toFixed(1), at, day: +(g.bx - memHomeX()).toFixed(1) }; VIEW.bg = bg0; }
    fresh({}); { const go = () => { BRAIN.q = .9; BRAIN.m = .5; BRAIN.z = 0; BRAIN.e = 0; LIFE.st = 'rest'; LIFE.until = t + .1; }; go(); const ok0 = drCatOK(); let mv = 0, tl = 0, gone = false; for (let i = 0; i < 14 * 60; i++) { steps(1); for (const q of PROPS) { if (q.gone) gone = true; else { mv = Math.max(mv, Math.abs(q.x - q.hx)); tl = Math.max(tl, up(q)); } } }
      r.cat = { ok0, n: DR.n.cat, fall: DR.n.catFall, mv: +mv.toFixed(0), up: +tl.toFixed(2), gone, scare: DR.n.scare }; steps(30 * 60); DR.catT = -99; go(); DR.cats = 2; r.cat.capped = !drCatOK(); DR.cats = 0; r.cat.again = drCatOK(); mat.decoCat = 0; r.cat.off = !drCatOK(); mat.decoCat = 1; }
    // h 抓著牠的時候罐子掉下去（多米 11-16：只睜大眼）：怕、縮、心情、習慣都沒動，只有睜大眼的記號亮起來；放手 2 秒後再推一次，照第一次的量嚇到
    fresh({}); calm(); { const J = PROPS[1], gx = globalC.xc, gy = globalC.yc, m0 = BRAIN.m; ev('pointerdown', 7, gx, gy); steps(20); const fl0 = FLN.t0; J.va = 12; J.lastHit = t; J.fingT = t; let sc = 0; for (let i = 0; i < 120; i++) { steps(1); sc = Math.max(sc, MOOD.scare); }
      r.held = { fell: J.gone || up(J) > 1, scare: DR.n.scare, sc: +sc.toFixed(3), flinch: FLN.t0 !== fl0, wide: DR.wideT != null, hab: DR.hab.d_jar || 0, dm: +(BRAIN.m - m0).toFixed(3) }; ev('pointerup', 7, gx, gy); calm(); steps(26 * 60); calm(); r.held.after = shove(J).amt; }
    { calm(); LIFE.until = t + 1; steps(60 * 60); let nan = 0, bn = 0; for (const q of PROPS) if (![q.x, q.y, q.a, q.vx, q.vy, q.va].every(isFinite)) nan++; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bn++; r.idle = { nan, bodyNan: bn, selfX: selfX() }; }
    res.T60_decoReact = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();   // calm() 把「休息到什麼時候」設在很久以後；不還原的話下一輪 T54 的牠一直不動，數字跟第一輪不同（11-16 量到第二輪起 twoVert 多 2 幀交叉）
    res.PASS.decoReact = r.off.scare === 0 && r.off.look === 0 && r.off.sc < .01 && r.off.fell
      && r.hab[0].amt > .2 && r.hab[0].amt < .46 && r.hab[0].fl > .05 && r.hab[1].amt < r.hab[0].amt * .6 && r.hab[2].amt < r.hab[1].amt * .6 && r.habN === 3
      && r.wake.k0 > .8 && r.wake.woke >= 0 && r.wake.woke < 30 && r.wake.n === 1
      && r.look.n === 1 && r.look.dq >= .1 && r.look.eye && r.look.scare === 0 && r.probe.n === 1 && r.probe.sn >= 1
      && r.candle.shift > 20 && r.candle.at >= 0 && Math.abs(r.candle.day) < 1
      && r.cat.ok0 && r.cat.n === 1 && r.cat.fall >= 1 && (r.cat.gone || r.cat.up > 1 || r.cat.mv > 20) && r.cat.scare === 0 && r.cat.capped && r.cat.again && r.cat.off
      && r.held.fell && r.held.scare === 0 && r.held.sc < .01 && !r.held.flinch && r.held.wide && r.held.hab === 0 && r.held.after > .2
      && r.idle.nan === 0 && r.idle.bodyNan === 0 && r.idle.selfX === 0;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T61 v2.47 拉長不抽、不留刺（多米 11-16 手機錄影 build 127：拉一拉有些地方變尖、拉太長莫名抽動）。用真正的預設值（黏土 alpha 0.18、lag 0.22、pressSink 0.2）在窗台上：
  // 抓頭頂往上拉 1.5R、3R、4.5R 按著不動 3 秒，扣掉整團平移後每顆粒子一幀的速度變化（跳動）平均要小於 0.5 點、身體裡翻面的三角形不超過 10 個；
  // 同樣的拉法把三個修正關掉（pressPull、dragCalm、memSmooth 0）當對照，跳動至少是開著的 3 倍（量到 0.84 到 2.64 對 0.05 到 0.16）；
  // 放手 2 秒後面積回 1±0.08、沒有 NaN、外框不交叉；連拉六次（照錄影的玩法）放手後記住的形狀沒有翻面
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE47.clay, stretchCap: 0, memCap: 0, tremble: 1, struggle: 1, lump: 0, strand: 0, tugEdge: 0, split: 0, edgeCling: 0, sillCap: 3.2, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0 };   // v2.48 的上下限關著：這一項量的是 v2.47 那三個修正；v2.51 的五樣也關著（11-22）
    const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(61); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 61 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const ext = (dx, dy) => { let b = -1, bv = -1e9; for (const i of bnd) { const v = (X[i] - globalC.xc) * dx + (Y[i] - globalC.yc) * dy; if (v > bv) { bv = v; b = i; } } return b; };
    // 跑 n 幀：扣掉整團平移後每顆粒子速度變化的最大值，回傳［每幀的平均、最大］；順便記翻面三角形最多幾個
    let flips = 0; const jit = n => { let jm = 0, js = 0, mvx = 0, mvy = 0; const vx = new Float64Array(N), vy = new Float64Array(N); for (let i = 0; i < N; i++) { vx[i] = X[i] - PX[i]; vy[i] = Y[i] - PY[i]; mvx += vx[i]; mvy += vy[i]; } mvx /= N; mvy /= N; for (let i = 0; i < N; i++) { vx[i] -= mvx; vy[i] -= mvy; }
      for (let s = 0; s < n; s++) { const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N; let j = 0; for (let i = 0; i < N; i++) { const nx = X[i] - x0[i] - ax, ny = Y[i] - y0[i] - ay, d = Math.hypot(nx - vx[i], ny - vy[i]); if (d > j) j = d; vx[i] = nx; vy[i] = ny; } if (j > jm) jm = j; js += j; flips = Math.max(flips, flipCount(X, Y)); } return [js / n, jm]; };
    const hold = (over, dist) => { fresh(over); flips = 0; const b = ext(0, -1), [sx, sy] = scr(X[b], Y[b] + R * .25), ex = sx + R * .3 * dist, ey = sy - R * dist; ev('pointerdown', 1, sx, sy); steps(6); for (let s = 1; s <= 24; s++) { ev('pointermove', 1, sx + (ex - sx) * s / 24, sy + (ey - sy) * s / 24); steps(1); }
      const [mean, max] = jit(180), fl = flips; ev('pointerup', 1, ex, ey); steps(120); let nan = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) nan++; return { mean: +mean.toFixed(2), max: +max.toFixed(1), flips: fl, area: +(area() / A0).toFixed(3), selfX: selfX(), nan }; };
    const OFF = { pressPull: 0, dragCalm: 0, memSmooth: 0 };
    r.on = [1.5, 3, 4.5].map(d => hold({}, d)); r.off = [1.5, 3, 4.5].map(d => hold(OFF, d));
    // 連拉六次
    { fresh({}); for (const [dx0, dy0, dist, n, hd] of [[0, -1, 2.2, 30, 60], [1, -.6, 1.8, 25, 60], [-1, -1, 2, 25, 60], [.3, -1, 2.6, 20, 90], [-1, .2, 2, 15, 60], [0, -1, 3, 12, 120]]) { const l = Math.hypot(dx0, dy0), dx = dx0 / l, dy = dy0 / l, i = ext(dx, dy), [sx, sy] = scr(X[i] - dx * R * .25, Y[i] - dy * R * .25), ex = sx + dx * dist * R, ey = sy + dy * dist * R;
        ev('pointerdown', 1, sx, sy); steps(6); for (let s = 1; s <= n; s++) { ev('pointermove', 1, sx + (ex - sx) * s / n, sy + (ey - sy) * s / n); steps(1); } steps(hd); ev('pointerup', 1, ex, ey); steps(90); }
      steps(120); let nan = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) nan++; r.six = { qFlips: flipCount(QX, QY), xFlips: flipCount(X, Y), selfX: selfX(), area: +(area() / A0).toFixed(3), nan }; }
    res.T61_pullCalm = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    res.PASS.pullCalm = r.on.every(o => o.mean < .5 && o.flips <= 10 && o.nan === 0 && o.selfX === 0 && Math.abs(o.area - 1) < .08)
      && r.on.every((o, i) => r.off[i].mean > o.mean * 3)
      && r.six.qFlips === 0 && r.six.selfX === 0 && r.six.nan === 0 && Math.abs(r.six.area - 1) < .08;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T62 v2.48 每一小塊的硬上下限與手指讓（多米 11-16：常常拉一拉就破圖，超出某個範圍就抽搐打結、變成不規則的尖；要從源頭解決）。用真正的預設值在窗台上，對照是把 stretchCap、memCap 關掉（v2.47）：
  // a 抓頭頂往下壓 2R 按著 2 秒（把那塊拖進身體、壓向窗台）：每幀跳動平均小於 3 點、真的翻過去的三角形不超過 8 個；對照的跳動至少 3 倍（量到 18 對 0.9、翻 59 對 1）
  // b 抓頭頂往上拉 3R 按著 2 秒：網格的邊最長不超過原形的 3.6 倍（對照超過 5 倍，量到 9.3）；放手 2 秒後參考形狀（記形加偽足）最長的邊不超過 3 倍（對照超過 4 倍，量到 5.5：偽足疊在拉長的形狀上）、
  //   記住的形狀不超過 2.6 倍、沒有翻面、沒有 NaN；c 拉長還是留得住：放手 2 秒後記住的形狀高度至少 2.3R
  // 更廣的量法是 fuzz.js（固定種子的亂捏，30 組約一分鐘），不在這裡跑
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE47.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, split: 0 }, OFF = { stretchCap: 0, memCap: 0 };   // v2.62：split 0，往上猛扯會扯斷成兩隻（qH 量到 1.81），這一項量的是扯斷之前的上下限
    const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(62); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 62 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const inv = () => { let n = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) n++; } return n; };
    const strain = (AX, AY) => { let m = 0; for (let e = 0, k = 0; e < EDG.length; e += 2, k++) { const i = EDG[e], j = EDG[e + 1], l = Math.hypot(AX[i] - AX[j], AY[i] - AY[j]) / EDL[k]; if (l > m) m = l; } return +m.toFixed(2); };
    const jit = n => { let js = 0, jm = 0, im = 0, sm = 0, vx = null, vy = null, cnt = 0; for (let s = 0; s < n; s++) { const x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N; const nx = new Float64Array(N), ny = new Float64Array(N); let j = 0; for (let i = 0; i < N; i++) { nx[i] = X[i] - x0[i] - ax; ny[i] = Y[i] - y0[i] - ay; if (vx) { const d = Math.hypot(nx[i] - vx[i], ny[i] - vy[i]); if (d > j) j = d; } } vx = nx; vy = ny; if (s > 20) { js += j; cnt++; if (j > jm) jm = j; } im = Math.max(im, inv()); if (s > 60) sm = Math.max(sm, strain(X, Y)); } return { mean: +(js / cnt).toFixed(2), max: +jm.toFixed(1), inv: im, strain: sm }; };
    const pull = (over, ang, dist) => { fresh(over); const c = globalC, [sx, sy] = scr(c.xc, c.yc - R * .6), ex = sx + Math.cos(ang) * R * dist, ey = sy + Math.sin(ang) * R * dist; ev('pointerdown', 1, sx, sy); steps(4); for (let s = 1; s <= 10; s++) { ev('pointermove', 1, sx + (ex - sx) * s / 10, sy + (ey - sy) * s / 10); steps(1); } const o = jit(120); ev('pointerup', 1, ex, ey); steps(120);
      let nan = 0, q0 = 1e9, q1 = -1e9; for (let i = 0; i < N; i++) { if (!isFinite(X[i]) || !isFinite(Y[i])) nan++; q0 = Math.min(q0, QY[i]); q1 = Math.max(q1, QY[i]); } return { ...o, exStrain: strain(EX, EY), qStrain: strain(QX, QY), qFlips: flipCount(QX, QY), qH: +((q1 - q0) / R).toFixed(2), nan }; };
    r.downOn = pull({}, Math.PI / 2, 2); r.downOff = pull(OFF, Math.PI / 2, 2); r.upOn = pull({}, -Math.PI / 2, 3); r.upOff = pull(OFF, -Math.PI / 2, 3);
    res.T62_limits = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    res.PASS.limits = r.downOn.mean < 3 && r.downOn.inv <= 8 && r.downOff.mean > r.downOn.mean * 3 && r.downOn.nan === 0
      && r.upOn.strain <= 3.6 && r.upOff.strain > 5 && r.upOn.exStrain <= 3 && r.upOff.exStrain > 4 && r.upOn.qStrain <= 2.6 && r.upOn.qFlips === 0 && r.upOn.nan === 0 && r.upOn.qH >= 2.3;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }

  // T63 v2.52（多米 11-22，《虛擬手感》3-3 到 3-5 的交辦 A、B、C 組）。用真正的預設值（PRE47）在窗台上跑：
  //   a 生效值（A1、A2）：黏條開著身體只拉到 strandAt（v2.53 回到 2.4、記形 2.6；1.6 留成選項，g 測它），黏條關掉照材料自己的 7、記形 5，sillCap 3.2 回 v2.50；mat 本身沒被改、滑桿旁邊有字
  //   b 黏條關著從頭頂往上拉到畫面頂（A1 要守住的）：放手 2 秒後沒有 NaN、外框不交叉、記住的形狀沒有翻面、面積回 1±0.08；按住時翻面不超過 5 個；身體不比 3.2R 的對照短
  //   c 流（A4）：flow 0 放 10 秒記住的形狀不變；flow 0.2 放 10 秒，高度剩六成到七成五、寬度多兩成五以上、面積不漂、沒有翻面、外框不交叉；手指按著的 3 秒裡流不作用（跟按下那一刻把 flow 關掉的那次一樣）
  //   d 保險計數與物理毫秒（A5）：拉一段放手後有格數、四個比例都在 0 到 100
  //   e 灰盒（B6）：打開後牠自己的動作關掉、擺飾收起來、材料旋鈕不動，關掉原樣還回來；灰盒下拉一段沒有 NaN
  //   f 調節台（B 組，desk.js 有載入才測）：換存檔位那一格身體一點都沒動（不彈）；匯出再匯入一字不差。跑完把使用者存的東西原樣還回去
  //   g 捏邊緣往外拉（strandAt 2.4 → 1.6）：兩個外形種子、從頭頂的邊往上拉 2.5R、按住 0.75 秒、放手，外框最尖不超過 110 度、翻面不超過 3 個；
  //     對照 strandAt 2.4（v2.51）至少有一個種子折超過 120 度（量到 135 到 174 度、翻面 5 到 65 個）
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE47.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, brain: 0, envRoam: 0 };
    const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(63); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 63 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const areaNow = () => { let a = 0; const n = bnd.length; for (let k = 0; k < n; k++) { const i = bnd[k], j = bnd[(k + 1) % n]; a += X[i] * Y[j] - X[j] * Y[i]; } return Math.abs(a) / 2; };
    const nanN = () => { let n = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) n++; return n; };
    const inv = () => { let n = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) n++; } return n; };
    const sharp = () => { const n = bnd.length; let m = 0; for (let i = 0; i < n; i++) { const a = bnd[(i + n - 1) % n], b = bnd[i], c = bnd[(i + 1) % n], ux = X[b] - X[a], uy = Y[b] - Y[a], vx = X[c] - X[b], vy = Y[c] - Y[b], an = Math.abs(Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)) * 57.3; if (an > m) m = an; } return Math.round(m); };
    const qBox = () => { let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9; for (let i = 0; i < N; i++) { x0 = Math.min(x0, QX[i]); x1 = Math.max(x1, QX[i]); y0 = Math.min(y0, QY[i]); y1 = Math.max(y1, QY[i]); } return [+((x1 - x0) / R).toFixed(3), +((y1 - y0) / R).toFixed(3)]; };
    const qArea = () => { let a = 0, b = 0; const n = bnd.length; for (let k = 0; k < n; k++) { const i = bnd[k], j = bnd[(k + 1) % n]; a += QX[i] * QY[j] - QX[j] * QY[i]; b += Q0X[i] * Q0Y[j] - Q0X[j] * Q0Y[i]; } return +(a / b).toFixed(3); };
    const rest = n => { for (let k = 0; k < n; k++) { LIFE.st = 'rest'; LIFE.until = t + 99; WANDER.moving = false; steps(1); } };
    // a
    fresh({ strand: 1 }); r.a = { on: [effPull(), effMem(), mat.maxPull, mat.memMax], note: !!effNote('maxPull') }; mat.strand = 0; r.a.off = [effPull(), effMem(), effNote('maxPull')]; mat.sillCap = 3.2; r.a.cap = [effPull(), effMem()];
    // b
    const pullUp = over => { fresh({ strand: 0, split: 0, ...over }); const A0 = areaNow(), c = globalC, [sx, sy] = scr(c.xc, c.yc - R * .6), ey = 30; ev('pointerdown', 1, sx, sy); steps(4); for (let s = 1; s <= 40; s++) { ev('pointermove', 1, sx, sy + (ey - sy) * s / 40); steps(1); } let iv = 0; for (let k = 0; k < 60; k++) { steps(1); iv = Math.max(iv, flipCount(X, Y)); }
      let top = 1e9, bot = -1e9; for (const i of bnd) { top = Math.min(top, Y[i]); bot = Math.max(bot, Y[i]); } const heldR = +((bot - top) / R).toFixed(2); ev('pointerup', 1, sx, ey); steps(120);
      return { pullR: +((sy - ey) / R).toFixed(2), heldR, invHeld: iv, nan: nanN(), selfX: ringCrossed() ? 1 : 0, qFlips: flipCount(QX, QY), area: +(areaNow() / A0).toFixed(3), eff: effPull() }; };
    r.b = { a1: pullUp({}), cap: pullUp({ sillCap: 3.2 }) };
    // c
    const idle = (over, n) => { fresh(over); const b0 = qBox(); rest(n); return { b0, b1: qBox(), qArea: qArea(), qFlips: flipCount(QX, QY), selfX: ringCrossed() ? 1 : 0 }; };
    const held = cut => { fresh({ flow: .2 }); rest(60); const c = globalC, [sx, sy] = scr(c.xc, c.yc); ev('pointerdown', 1, sx, sy); if (cut) mat.flow = 0; steps(180); const b = qBox(); ev('pointerup', 1, sx, sy); return b; };
    r.c = { f0: idle({ flow: 0 }, 600), f2: idle({ flow: .2 }, 600) };
    // 先空跑一次再量：fresh 清不乾淨「上一段有沒有碰過牠」（上一段是放著不碰的，下一段按下去的反應差 0.01R 左右；跟流無關，流那一步在按住時一次都沒被呼叫）。
    // 兩次要比的都接在「剛按過一次」後面，才是同一個起點（11-22 整套跑第一次時這一項就是差在這裡：1.328 對 1.319）
    held(false); r.c.heldOn = held(false); r.c.heldCut = held(true);
    // d
    fresh({}); GRD.reset(); { const c = globalC, [sx, sy] = scr(c.xc, c.yc - R * .5); ev('pointerdown', 1, sx, sy); for (let s = 1; s <= 30; s++) { ev('pointermove', 1, sx + R * 2 * s / 30, sy + R * 1.5 * s / 30); steps(1); } steps(30); ev('pointerup', 1, sx + R * 2, sy + R * 1.5); steps(60); } r.d = { ...GRD.pct(), phys: typeof PHYS.ms === 'number' };
    // e
    fresh({}); { const before = { life2: mat.life2, alpha: mat.alpha, deco: mat.deco }, snd0 = SND; labGrey(true); const g = { life2: mat.life2, alpha: mat.alpha, deco: mat.deco }; const c = globalC, [sx, sy] = scr(c.xc, c.yc - R * .5); ev('pointerdown', 1, sx, sy); for (let s = 1; s <= 30; s++) { ev('pointermove', 1, sx + R * 1.5 * s / 30, sy); steps(1); } ev('pointerup', 1, sx + R * 1.5, sy); steps(60); const nan = nanN(); labGrey(false); r.e = { before, g, nan, back: { life2: mat.life2, alpha: mat.alpha, deco: mat.deco }, snd: SND === snd0 }; }
    // f
    if (typeof deskSnap === 'function') { let keep = null; try { keep = localStorage.getItem('nienie.feel'); } catch (_) {} const S0 = DESK.slots.slice(), L0 = DESK.log.slice(), B0 = DESK.base0; fresh({}); DESK.base0 = deskSnap(); DESK.slots = [deskSnap(), null, null]; mat.alpha = .3; DESK.slots[1] = deskSnap();
      const x0 = Float64Array.from(X), p0 = Float64Array.from(PX); deskApply(DESK.slots[0]); let mv = 0; for (let i = 0; i < N; i++) mv = Math.max(mv, Math.abs(X[i] - x0[i]), Math.abs(PX[i] - p0[i]));
      const t1 = deskText(); mat.alpha = .5; DESK.slots = [null, null, null]; deskImport(t1); r.f = { moved: mv, same: t1 === deskText(), alpha: mat.alpha }; DESK.slots = S0; DESK.log = L0; DESK.base0 = B0; try { if (keep === null) localStorage.removeItem('nienie.feel'); else localStorage.setItem('nienie.feel', keep); } catch (_) {} }
    else r.f = { skipped: true, moved: 0, same: true };
    // g
    const tug = (sd, at) => { fresh({ seed: sd, strandAt: at, strand: 1, tugEdge: .42, homeFloor: 0 });   // v2.55：量的是 strandAt 2.4 會折、1.6 不折，homeFloor 也會讓 2.4 少折一些（82 對 120 以上），對照組要關掉
      const c = globalC; let bi = -1; for (const i of bnd) if (bi < 0 || Y[i] < Y[bi]) bi = i; const [sx, sy] = scr(X[bi], Y[bi] + R * .15), ey = Math.max(30, sy - R * 2.5); ev('pointerdown', 1, sx, sy); steps(4); let iv = 0, sh = 0; const see = () => { iv = Math.max(iv, inv()); sh = Math.max(sh, sharp()); };
      for (let s = 1; s <= 40; s++) { ev('pointermove', 1, sx, sy + (ey - sy) * s / 40); steps(1); see(); } for (let k = 0; k < 45; k++) { steps(1); see(); } const f = fingers.get(1), tg = !!(f && f.tug); ev('pointerup', 1, sx, ey); for (let k = 0; k < 90; k++) { steps(1); see(); } return { inv: iv, sharp: sh, tug: tg }; };
    r.g = { s4: tug(4, 1.6), s7: tug(7, 1.6), s4old: tug(4, 2.4), s7old: tug(7, 2.4) };
    res.T63_v252 = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    const okPct = v => v >= 0 && v <= 100;
    res.PASS.v252 = r.a.on[0] === 2.4 && r.a.on[1] === 2.6 && r.a.on[2] === 7 && r.a.on[3] === 5 && r.a.note && r.a.off[0] === 7 && r.a.off[1] === 5 && r.a.off[2] === null && r.a.cap[0] === 3.2 && r.a.cap[1] === 2.6
      && r.b.a1.eff === 7 && r.b.a1.nan === 0 && r.b.a1.selfX === 0 && r.b.a1.qFlips === 0 && Math.abs(r.b.a1.area - 1) < .08 && r.b.a1.invHeld <= 5 && r.b.a1.heldR >= r.b.cap.heldR
      && Math.abs(r.c.f0.b1[1] - r.c.f0.b0[1]) < .01 && r.c.f2.b1[1] < r.c.f0.b1[1] * .75 && r.c.f2.b1[1] > r.c.f0.b1[1] * .6 && r.c.f2.b1[0] > r.c.f0.b1[0] * 1.25 && Math.abs(r.c.f2.qArea - 1) < .02 && r.c.f2.qFlips === 0 && r.c.f2.selfX === 0
      && Math.abs(r.c.heldOn[0] - r.c.heldCut[0]) < .005 && Math.abs(r.c.heldOn[1] - r.c.heldCut[1]) < .005
      && r.d.frames >= 100 && okPct(r.d.hi) && okPct(r.d.lo) && okPct(r.d.flip) && okPct(r.d.give) && r.d.phys
      && r.e.g.life2 === 0 && r.e.g.deco === 0 && r.e.g.alpha === r.e.before.alpha && r.e.back.life2 === r.e.before.life2 && r.e.back.deco === r.e.before.deco && r.e.nan === 0 && r.e.snd
      && r.f.moved === 0 && r.f.same
      && r.g.s4.sharp <= 110 && r.g.s7.sharp <= 110 && r.g.s4.inv <= 3 && r.g.s7.inv <= 3 && Math.max(r.g.s4old.sharp, r.g.s7old.sharp) > 120;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T65 v2.54 無限拉（多米 11-22：拉五公分只長三公分）。v2.54b 補點、快扯變硬開著之後，拉著時細長三角形翻一點的最多 44 個（畫面看不出、記形不擋），門檻從 10 放到 60。v2.54 的預設：往上拉 4R、斜拉 5.5R，被抓的那塊跟手指差不到 0.5R、身體拉到 5R 以上、
  // 拉著時沒有翻面和交叉、放手 2 秒還留 3.5R 以上；同一套關掉無限拉（v2.53）身體只到 3.3R 以下（對照，證明量得到差別）。另外看黏窗框關掉：放在右窗框旁不黏
  // v2.58：補點之後每次跑的差別很大（同一個起點，斜拉差 0.6R 到 3R 都有），單次數字不能當結論，改成五個種子各跑一次看平均；加 pullGive 0 當對照（斜拉要比開著差，證明量得到）。
  // 斜拉拉到畫面角落，手指有效位置離兩面牆各 0.35R，最好也差 0.5R，所以門檻是平均 1R。20 個種子量過：往上平均 0.30 最差 0.51，斜拉平均 0.74 最差 1.00；放手後最短 2.5R（外框交叉解開時會縮）
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE54.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, life2: 0, remeshCalm: 0 };   // v2.56 補點後站穩關著（在 T67）
    let SD = 0; const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(65 + SD * 1000); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 65 + SD * 1000 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(120); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const wld = (sx, sy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(sx - q.left - v.x) / CAM.z + CAM.x, (sy - q.top - v.y) / CAM.z + CAM.y]; };
    const inv = () => { let n = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) n++; } return n; };
    const len = (ux, uy) => { let a = -1e9, b = 1e9; for (const i of bnd) { const p = X[i] * ux + Y[i] * uy; a = Math.max(a, p); b = Math.min(b, p); } return +((a - b) / R).toFixed(2); };
    const pull = (over, dx, dy, dist) => { fresh(over); const L = Math.hypot(dx, dy), ux = dx / L, uy = dy / L, c = globalC; let bi = 0, bd = -1e9; for (const i of bnd) { const p = (X[i] - c.xc) * ux + (Y[i] - c.yc) * uy; if (p > bd) { bd = p; bi = i; } }
      const [sx, sy] = scr(X[bi] - ux * R * .3, Y[bi] - uy * R * .3), pr = R * CAM.z; ev('pointerdown', 1, sx, sy); steps(4); let ex = sx, ey = sy;
      for (let s = 1; s <= 40; s++) { ex = Math.max(4, Math.min(innerWidth - 4, sx + ux * dist * pr * s / 40)); ey = Math.max(4, Math.min(innerHeight - 4, sy + uy * dist * pr * s / 40)); ev('pointermove', 1, ex, ey); steps(1); }
      let flips = 0, xs = 0; for (let k = 0; k < 60; k++) { steps(1); flips = Math.max(flips, inv()); if (k % 10 === 0 && selfX() > 0) xs++; }
      const f = [...fingers.values()][0]; let px = 0, py = 0, w = 0; for (const m of f.mem) { px += X[m[0]] * m[3]; py += Y[m[0]] * m[3]; w += m[3]; } const [fx, fy] = wld(ex, ey);
      const o = { gap: +(Math.hypot(px / w - fx, py / w - fy) / R).toFixed(2), held: len(ux, uy), flips, xs }; ev('pointerup', 1, ex, ey); steps(120); o.after = len(ux, uy); o.endX = selfX(); return o; };
    r.up = []; r.diag = []; r.diagG0 = []; for (SD = 0; SD < 5; SD++) { r.up.push(pull({}, 0, -1, 4)); r.diag.push(pull({}, .5, -1, 5.5)); r.diagG0.push(pull({ pullGive: 0 }, .5, -1, 5.5)); } SD = 0; r.upOld = pull({ endless: 0, slide: 1.5 }, 0, -1, 4);
    // 黏窗框關著：把牠舉到右窗框旁邊慢慢放，不黏窗框（v2.53 會黏 rjamb）
    { fresh({}); const g = SILL.g, c = globalC, [sx, sy] = scr(c.xc, c.yc), [tx, ty] = scr(g.jr - R * 1.05, g.gy + g.gh * .45); ev('pointerdown', 1, sx, sy); steps(4);
      for (let s = 1; s <= 60; s++) { ev('pointermove', 1, sx + (tx - sx) * s / 60, sy + (ty - sy) * s / 60); steps(1); } steps(40); ev('pointerup', 1, tx, ty); steps(30); r.jamb = { surf: SILL.surf, cling: CLING.on, side: CLING.side }; }
    res.T65_endless = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    { const av = (a, q) => a.reduce((s, o) => s + o[q], 0) / a.length, all = [...r.up, ...r.diag]; r.avg = { up: +av(r.up, 'gap').toFixed(2), diag: +av(r.diag, 'gap').toFixed(2), diagG0: +av(r.diagG0, 'gap').toFixed(2) };
      res.PASS.endless = r.avg.up < .45 && r.up.every(o => o.gap < .7) && r.avg.diag < 1 && r.diag.every(o => o.gap < 1.3) && r.avg.diagG0 > r.avg.diag + .2 && all.every(o => o.held >= 5 && o.flips <= 60 && o.endX === 0) && all.reduce((s, o) => s + o.xs, 0) <= 4
        && av(r.up, 'after') >= 3.4 && av(r.diag, 'after') >= 3.4 && all.every(o => o.after >= 2.2) && r.upOld.held < 3.6 && !(r.jamb.cling && /jamb|ceil/.test(r.jamb.side)); }
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T66 v2.55 抓著時家不壓進窗台（homeFloor，11-23）。v2.54 黏土拖動門檻 4、無限拉之後，抓頭頂往內 0.25R 往上拉 2.5R、3R、3.5R 按住 3 秒：
  // 記形把身體記長了，家還停在原本矮矮那一團的中心，回家彈簧把長身體往下拉進窗台，一秒多後下半扁成一條，底部（離窗台 0.5R 內）翻面 24 到 97 個。
  // 開著：每個距離底部翻面不超過 3 個、拉著時外框不交叉、放手後沒有 NaN；同一套 homeFloor 0 當對照，至少一個距離底部翻面 20 個以上（證明量得到）
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE54.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, remeshCalm: 0, rubVary: 0 };   // v2.56 補點後站穩關著（在 T67）；v2.63 C6 釘 rubVary 0（揉完反應輪流之後數字會變，量的是舊規格）
    const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(61); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 61 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const inv = fl => { let n = 0, lo = 0; for (let k = 0; k < TRI.length; k += 3) { const a = TRI[k], b = TRI[k + 1], c = TRI[k + 2]; if (.5 * ((X[b] - X[a]) * (Y[c] - Y[a]) - (Y[b] - Y[a]) * (X[c] - X[a])) < -.02 * TRA[k / 3]) { n++; if (fl - (Y[a] + Y[b] + Y[c]) / 3 < R * .5) lo++; } } return [n, lo]; };
    const hold = (over, dist) => { fresh(over); const fl = SILL.g.fl; let b = -1, bv = 1e9; for (const i of bnd) if (Y[i] < bv) { bv = Y[i]; b = i; } const [sx, sy] = scr(X[b], Y[b] + R * .25), ex = sx + R * .3 * dist * CAM.z, ey = sy - R * dist * CAM.z;
      ev('pointerdown', 1, sx, sy); steps(6); for (let s = 1; s <= 24; s++) { ev('pointermove', 1, sx + (ex - sx) * s / 24, sy + (ey - sy) * s / 24); steps(1); }
      let all = 0, low = 0, xs = 0; for (let k = 0; k < 180; k++) { steps(1); const [n, lo] = inv(fl); all = Math.max(all, n); low = Math.max(low, lo); if (k % 15 === 0 && selfX() > 0) xs++; }
      ev('pointerup', 1, ex, ey); steps(90); let nan = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) nan++; return { all, low, xs, nan }; };
    r.on = [2.5, 3, 3.5].map(d => hold({}, d)); r.off = [2.5, 3, 3.5].map(d => hold({ homeFloor: 0 }, d));
    res.T66_homeFloor = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    res.PASS.homeFloor = r.on.every(o => o.low <= 3 && o.xs === 0 && o.nan === 0) && r.off.some(o => o.low >= 20); }
  // T67 v2.56 補點後站穩（remeshCalm，11-23）。v2.55 之後拉長按住，補點那一刻換了一批點，之後十來幀身體各處來回彈（拉 3R 按住，補點後 12 幀每幀跳 8 到 10 點）。
  // 用真正的預設值、T66 的拉法往上拉 2.5R、3R、3.5R 按住 3 秒，量 T61 的跳動（扣掉整團平移後每顆粒子一幀的速度變化，補點那一幀粒子換了不算）：
  // 開著每個距離平均不超過 5（v2.55 量過到 11；同一個距離跑跑之間 1.9 到 4.4，雜訊大）、三個加起來不到 remeshCalm 0 的 0.85 倍；放手 2 秒後身體長度不比關掉短一成以上（站穩不能吃掉拉長）、沒有 NaN、外框不交叉
  // v2.58：新舊各量 12 次，開著的平均 2.66 對 2.84（沒有變差），但每次跑的比值 0.3 到 1.4 都有，單次會掉；改成三個種子一起算：開著每個不超過 8、平均不超過 4，全部加起來不到關掉的 0.95 倍
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE54.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0, rubVary: 0 };   // v2.63 C6：揉完反應輪流（rubVary）預設 1 之後放手不一定小跳，這一項量的是舊規格，釘 0
    let SD = 0; const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(61 + SD * 1000); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 61 + SD * 1000 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const tall = () => { let a = 1e9, b = -1e9; for (const i of bnd) { a = Math.min(a, Y[i]); b = Math.max(b, Y[i]); } return (b - a) / R; };
    const hold = (over, dist) => { fresh(over); let b = -1, bv = 1e9; for (const i of bnd) if (Y[i] < bv) { bv = Y[i]; b = i; } const [sx, sy] = scr(X[b], Y[b] + R * .25), ex = sx + R * .3 * dist * CAM.z, ey = sy - R * dist * CAM.z;
      ev('pointerdown', 1, sx, sy); steps(6); for (let s = 1; s <= 24; s++) { ev('pointermove', 1, sx + (ex - sx) * s / 24, sy + (ey - sy) * s / 24); steps(1); }
      let vx = null, vy = null; const prime = () => { vx = new Float64Array(N); vy = new Float64Array(N); let mx = 0, my = 0; for (let i = 0; i < N; i++) { vx[i] = X[i] - PX[i]; vy[i] = Y[i] - PY[i]; mx += vx[i]; my += vy[i]; } mx /= N; my /= N; for (let i = 0; i < N; i++) { vx[i] -= mx; vy[i] -= my; } };
      prime(); let js = 0, nj = 0, rm = 0;
      for (let k = 0; k < 180; k++) { const n0 = N, x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); if (N !== n0) { rm++; prime(); continue; }
        let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N; let j = 0; for (let i = 0; i < N; i++) { const nx = X[i] - x0[i] - ax, ny = Y[i] - y0[i] - ay, d = Math.hypot(nx - vx[i], ny - vy[i]); if (d > j) j = d; vx[i] = nx; vy[i] = ny; } js += j; nj++; }
      const held = tall(); ev('pointerup', 1, ex, ey); steps(120); let nan = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) nan++;
      return { mean: +(js / Math.max(1, nj)).toFixed(2), remesh: rm, held: +held.toFixed(2), rel: +tall().toFixed(2), selfX: selfX(), nan }; };
    r.on = []; r.off = []; for (SD = 0; SD < 3; SD++) for (const d of [2.5, 3, 3.5]) { r.on.push(hold({}, d)); r.off.push(hold({ remeshCalm: 0 }, d)); }
    res.T67_remeshCalm = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    const sum = a => a.reduce((s, o) => s + o.mean, 0);
    res.PASS.remeshCalm = r.on.every(o => o.mean <= 8 && o.nan === 0 && o.selfX === 0) && sum(r.on) / r.on.length <= 4 && r.on.reduce((s, o) => s + o.rel, 0) >= .9 * r.off.reduce((s, o) => s + o.rel, 0) && sum(r.on) < .95 * sum(r.off) && r.on.some(o => o.remesh > 0);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T68 v2.58 放手後要靜下來（remeshHome，QC-0007 #46）。真正的預設值，六個種子各隨機連拉六次（抓外框附近、拉到窗戶裡隨機一點、按住、放手），最後一次放手後第 6 到 8 秒量 T61 的跳動：
  // 開著沒有 NaN、回原形的目標沒有翻面；同一套 remeshHome 0 當對照，平均是開著的兩倍以上（證明量得到）
  // 絕對門檻（11-24 補）：六個種子至少四個不超過 1.5、五個不超過 4（memUntie 開著 60 個種子量三批：平均 0.28、0.54，超過 1 的有 4、6 個，超過 5 的 0、2 個；v2.57 平均 22）。還有六十分之一左右會大抖，沒有全好
  { const clock = saveClock(), bg0 = VIEW.bg, r = {}; VIEW.bg = 'day';
    const SP = { ...PRE54.clay, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shakeMode: 0 };
    const fresh = over => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(61); mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed: 61 }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; steps(90); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const rough = (over, sd) => { fresh(over); const rr = seeded(sd * 7919), P = Array.from({ length: 6 }, () => [rr(), rr(), rr(), rr(), 10 + Math.floor(rr() * 20), 20 + Math.floor(rr() * 70)]); let rm = 0;
      for (const [a1, a2, a3, a4, nm, hh] of P) { const bi = bnd[Math.floor(a1 * bnd.length) % bnd.length], c = globalC, k = .15 + .3 * a2, [sx, sy] = scr(X[bi] + (c.xc - X[bi]) * k, Y[bi] + (c.yc - Y[bi]) * k), ex = 10 + a3 * (innerWidth - 20), ey = 60 + a4 * innerHeight * .5; ev('pointerdown', 1, sx, sy); steps(4); for (let s = 1; s <= nm; s++) { ev('pointermove', 1, sx + (ex - sx) * s / nm, sy + (ey - sy) * s / nm); steps(1); } steps(hh); rm = Math.max(rm, REM.n); ev('pointerup', 1, ex, ey); steps(25); }
      steps(360); let vx = null, vy = null, js = 0, nj = 0; for (let k = 0; k < 120; k++) { const n0 = N, x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); if (N !== n0) { vx = null; continue; } let ax = 0, ay = 0; for (let i = 0; i < N; i++) { ax += X[i] - x0[i]; ay += Y[i] - y0[i]; } ax /= N; ay /= N; const nx = new Float64Array(N), ny = new Float64Array(N); let j = 0; for (let i = 0; i < N; i++) { nx[i] = X[i] - x0[i] - ax; ny[i] = Y[i] - y0[i] - ay; if (vx) j = Math.max(j, Math.hypot(nx[i] - vx[i], ny[i] - vy[i])); } if (vx) { js += j; nj++; } vx = nx; vy = ny; }
      let nan = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) nan++; return { mean: +(js / Math.max(1, nj)).toFixed(2), rm, nan, h0: flipCount(H0X, H0Y) }; };
    const sds = [4, 8, 20, 34, 38, 12]; r.on = sds.map(d => rough({}, d)); r.off = sds.map(d => rough({ remeshHome: 0, memUntie: 0 }, d));
    const avg = a => a.reduce((q, o) => q + o.mean, 0) / a.length; r.avg = [+avg(r.on).toFixed(2), +avg(r.off).toFixed(2)];
    res.T68_settle = r; log.splice(0); restoreClock(clock); VIEW.bg = bg0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    res.PASS.settle = r.on.filter(o => o.mean <= 1.5).length >= 4 && r.on.filter(o => o.mean <= 4).length >= 5 && r.avg[1] >= 2 * r.avg[0] && r.on.every(o => o.nan === 0 && o.h0 === 0) && r.on.some(o => o.rm > 0);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T69 v2.59 窗景：12 扇每種都拆得出來、底圖不透明、會動的真的在動、減少動態停得住；只有夜晚的兩扇算夜晚；原本那扇還是三層；畫一遍不丟錯，身體折射看得到的畫布是新窗
  { const bg0 = VIEW.bg, w0 = VIEW.win, f0 = WIN.fixed, r = { n: 0, still: [], clear: [], stop: [], draw: [], err: '' };
    try { const g = sceneGeo(), shot = v => { const c = document.createElement('canvas'); c.width = 80; c.height = 98; const x = c.getContext('2d'); x.drawImage(cv, g.gx, g.gy, g.gw, g.gh * .56, 0, 0, 80, 98); return x.getImageData(0, 0, 80, 98).data; };
      const diff = (a, b) => { let q = 0; for (let i = 0; i < a.length; i++) q += Math.abs(a[i] - b[i]); return q; };
      for (const d of WINS) for (const k of d.only ? ['night'] : ['day', 'night']) { const id = d.id + '.' + k, v = await winCompile(d, k, g); r.n++;
        const at = T => { WIN.fixed = T; ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, cv.width, cv.height); winDraw(v); return shot(v); }, a = at(3), b = at(6.1), c = at(3);
        if (!diff(a, b)) r.still.push(id); if (diff(a, c)) r.stop.push(id); let hole = 0; for (let i = 3; i < a.length; i += 4) if (a[i] < 250) hole++; if (hole > 98) r.clear.push(id + ' ' + hole); }
      VIEW.bg = 'day'; VIEW.win = 'Tiandeng'; r.only = viewBg(); VIEW.win = 'Daotian'; r.back = viewBg(); VIEW.bg = 'blue'; VIEW.win = 'Tiandeng'; r.blue = viewBg();
      WIN.fixed = 3; for (const id of ['', 'Daotian', 'Jingyu']) { VIEW.bg = 'day'; VIEW.win = id; let sc = sceneFor('day'); for (let i = 0; i < 100 && id && !(sc && sc.win && sc.win.id === id); i++) { await new Promise(o => setTimeout(o, 30)); sc = sceneFor('day'); } draw(); r.draw.push(id ? !!(sc.win && sc.win.id === id && sc.wall) : !!(sc.base && sc.sky && sc.wall)); }
    } catch (e) { r.err = String(e); }
    VIEW.bg = bg0; VIEW.win = w0; WIN.fixed = f0; res.T69_windows = r;
    res.PASS.windows = r.err === '' && r.n === 22 && !r.still.length && !r.stop.length && !r.clear.length && r.only === 'night' && r.back === 'day' && r.blue === 'blue' && r.draw.length === 3 && r.draw.every(Boolean);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T71 v2.61 W3（C1 輕碰慢慢醒、C2 聽節奏也靠過來、C4 打開先看你、B4 眼睛看真手指、C7 換隻記憶不串），窗台、芋圓、真正的預設；每條關掉開關都要回到舊的（證明量得到）
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, E0 = { count: E4.count, lastT: E4.lastT }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0 };
    const fresh = (over, tr) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(71); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); IMP.tr = tr || 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; Object.assign(BRAIN, { seed: 71 }); brainReset(); };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const tap = (over, tr) => { fresh(over, tr); steps(120); SLP.on = true; LIFE.st = 'sleep'; BRAIN.z = .9; steps(300); IMP.tr = tr; log.splice(0); const f0 = FLN.t0, q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(8); ev('pointerup', 1, q[0], q[1]); steps(40); return { on: SLP.on, startle: log.some(x => x[0] === 'voice.startle'), flinch: FLN.t0 !== f0 }; };
    r.wake = { mid: tap({}, .5), deep: tap({}, .95), strange: tap({}, 0), off: tap({ wakeSoft: 0 }, .95) };
    const near = (over, tr) => { fresh(over, tr); steps(240); LIFE.st = 'rest'; LIFE.until = 1e9; cutSniffs(); steps(60); let at = -1; const q = sc(globalC.xc + R * 2, globalC.yc - R * .8); ev('pointerdown', 1, q[0], q[1]); for (let i = 0; i < 90 && at < 0; i++) { steps(1); if (LIFE.sns.some(x => !(x.cut > 0))) at = +((i + 1) / 60).toFixed(2); } ev('pointerup', 1, q[0], q[1]); return at; };
    r.near = { on0: near({}, 0), on8: near({}, .8), off: near({ nearFast: 0 }, .8) };
    const eye = over => { fresh(over, 0); steps(240); let q = sc(globalC.xc - R * 1.2, globalC.yc - R * 1.6); ev('pointerdown', 1, q[0], q[1]); steps(60); q = sc(globalC.xc + R * 1.2, globalC.yc - R * 1.6); ev('pointermove', 1, q[0], q[1]); let n = 0; while (EYE.gx < 0 && n < 60) { steps(1); n++; } ev('pointerup', 1, q[0], q[1]); return n; };
    r.eye = { on: eye({}), off: eye({ eyeTrue: 0 }) };
    const greet = over => { fresh(over, 0); greetArm(true); let at = -1; for (let i = 0; i < 90 && at < 0; i++) { steps(1); if (EYE.user > t) at = +((i + 1) / 60).toFixed(2); } return at; };
    r.greet = { on: greet({}), off: greet({ greetLook: 0 }) };
    // 換隻用的是 PRESETS：前面的項目把大腦、印象、記性釘掉了，這一段換回真正的預設，換完要真的開著（MMon、MDon）、跑 2 秒再看，不然恆真（11-25 反駁查到）。換回來那隻有戒 .7：沒換好記性的話，戒從 0 變回 .7 會被當成剛被嚇（那格 -1、心情 -.69）
    { const PP = { ...PRESETS }; for (const k in PRESETS) PRESETS[k] = { ...PRE54[k], intro: 0, introSwim: 0, shake: 0 }; const BS = { ...BMEMS }, IS = { ...IMPS }; fresh({}, 0); steps(60); for (const k of ['peach', 'taro']) { delete BMEMS[k]; delete IMPS[k]; } const live = () => MMon() && MDon(); BMEM.cell = [0, .6, 0, 0, -.4]; BMEM.side = -.5; IMP.w = .7; memSync(); BRAIN.m = .15; VIEW.bg = VIEW0.bg; const c0 = BMEM.cell.slice(); chooseSlime(3, false, false); const z = BMEM.cell.every(v => v === 0) && BMEM.side === 0; steps(120); const z2 = BMEM.cell.every(v => Math.abs(v) < .02), on3 = live(); chooseSlime(2, false, false); let m0 = 1; for (let i = 0; i < 120; i++) { steps(1); m0 = Math.min(m0, BRAIN.m); } r.mem = { live: on3 && live(), clean: z && z2, cell: BMEM.cell.map(v => +v.toFixed(2)), back: BMEM.cell.every((v, i) => Math.abs(v - c0[i]) < .02) && Math.abs(BMEM.side + .5) < .01, m: +m0.toFixed(2), w: +IMP.w.toFixed(2) }; for (const k in BMEMS) delete BMEMS[k]; Object.assign(BMEMS, BS); for (const k in IMPS) delete IMPS[k]; Object.assign(IMPS, IS); for (const k in PP) PRESETS[k] = PP[k]; }
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; Object.assign(E4, E0); GREET.st = ''; res.T71_w3 = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    res.PASS.w3 = !r.wake.mid.on && !r.wake.mid.startle && !r.wake.mid.flinch && r.wake.deep.on && !r.wake.deep.startle && r.wake.strange.startle && r.wake.off.startle && r.near.on0 > 0 && r.near.on0 <= .45 && r.near.on8 > 0 && r.near.on8 <= .45 && r.near.off > .9
      && r.eye.on * 2 < r.eye.off && r.greet.on > 0 && r.greet.on <= .6 && r.greet.off < 0 && r.mem.live && r.mem.clean && r.mem.back && r.mem.w > .6 && Math.abs(r.mem.m - .15) < .02; }

  // T70 v2.61 破皮（A7）。前面 69 項把皮釘成平塗、不讀畫面，看不到破皮。這項換成預設的清透皮、窗台、芋圓，真的畫出來，每 2 格讀 JEL.h2（畫面一半大、模糊過的遮罩，門檻 0.46 跟著色器同一個）：
  // 裂：0.004R² 以上的皮有兩塊以上（碰到螢幕邊的最多算一塊）；洞：0.002R² 以上、四面都是皮；突變：外框上一點離上一次的皮超過「這兩格外框最多走的」加 4 點加 0.12R。一組手勢只要有一格就算那組中。
  // 手勢：最糟四種各 10 次（抓中間往右、往左快扯到螢幕邊；抓中間往右下快扯 3R；兩指水平快拉到螢幕邊；種子固定），隨手拉（身上任一點、任一方向、0.5R 到螢幕邊、每秒 3 到 25R、按住 0.3 到 3 秒）。
  // 門檻：預設（皮 1、拉的三顆 0）只擋裂，最糟 40 組最多 2 組，洞和突變只記錄（換皮不會少，補量 27／40）；三顆全開最糟 40 組破（裂、洞、突變任一）0 組，隨手拉破的不超過 1%（無條件進位）。
  // 對照：同一批的前 20 組改皮 0（v2.60 的外框畫法）要裂 2 組以上，證明量得到（20 組量到 7，40 組 12 到 15）。回家力道：網頁自己的值用來擋，手機的值（KPIOS）只記錄。
  // 數字每次差幾組（物理裡有不吃種子的計時）。預設跑短版，約 8 到 9 分鐘；先設 window.T70LONG = 1 跑長版，約 40 分鐘（估）：對照和手機力道也跑滿 40 組，隨手拉 300 次，手機力道隨手拉 100 次。短版隨手拉的次數可用 window.T70N 改。
  { const clock = saveClock(), view0 = { ...VIEW }, sl0 = SLIME, kp0 = window.KPIOS, long = !!window.T70LONG, r = { long, sec: {}, err: '' }, T0 = performance.now();
    Object.assign(VIEW, { skin: 'A', body: 'round', face: 1, bg: 'day', win: '' });
    const si = SLIMES.findIndex(q => q.id === 'taro'), s = SLIMES[si], OLD = { skinU: 0, pullHold: 0, pullWhole: 0, pullSoft: 0 }, DEF = { ...OLD, skinU: 1 }, ALL = { skinU: 1, pullHold: 1, pullWhole: 1, pullSoft: 1 };
    const SP = { ...PRE54[s.mat], seed: s.seed, ...s.p, shakeMode: 0, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0 };
    const fresh = (over, seed, x0) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(seed); SLIME = si; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0;
      if (x0 != null) { const dx = x0 - CX; for (let i = 0; i < N; i++) { X[i] += dx; PX[i] += dx; } HOMEX += dx; }
      steps(120); log.splice(0); };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const DIR = { R: [1, 0], L: [-1, 0], DR: [.7071, .7071] }, toEdge = (x, y, ux, uy) => { let k = 1e9; if (ux > 1e-6) k = Math.min(k, (W - 4 - x) / ux); if (ux < -1e-6) k = Math.min(k, (4 - x) / ux); if (uy > 1e-6) k = Math.min(k, (H - 4 - y) / uy); if (uy < -1e-6) k = Math.min(k, (4 - y) / uy); return k; };
    // 讀畫面：遮罩、皮幾塊、洞幾個、離皮多遠。只算身體那一框（外擴 1 格）
    let mw = 0, mh = 0, buf = null, cur = null, prev = null, lab = null, stk = null, box = null, pbox = null, disp = 0, lastMax = 0, o = null, fr = 0;
    const read = () => { draw(); const gl = JEL.gl; if (!gl || gl.isContextLost() || !JEL.float) throw new Error('T70：WebGL 沒開，畫不出果凍皮'); if (mw !== JEL.h2.w || mh !== JEL.h2.h) { mw = JEL.h2.w; mh = JEL.h2.h; buf = new Float32Array(mw * mh * 4); lab = new Int8Array(mw * mh); stk = new Int32Array(mw * mh); prev = null; }
      gl.bindFramebuffer(gl.FRAMEBUFFER, JEL.h2.f); gl.readPixels(0, 0, mw, mh, gl.RGBA, gl.FLOAT, buf); gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      cur = new Uint8Array(mw * mh); let x0 = mw, x1 = -1, y0 = mh, y1 = -1; for (let y = 0; y < mh; y++) for (let x = 0, p = (mh - 1 - y) * mw * 4, q = y * mw; x < mw; x++, p += 4, q++) if (buf[p] > .46) { cur[q] = 1; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
      box = x1 < 0 ? null : [Math.max(0, x0 - 1), Math.max(0, y0 - 1), Math.min(mw - 1, x1 + 1), Math.min(mh - 1, y1 + 1)]; };
    const comps = v => { const [bx0, by0, bx1, by1] = box, out = [], px2 = (W / mw) * (H / mh) / (R * R); for (let y = by0; y <= by1; y++) lab.fill(0, y * mw + bx0, y * mw + bx1 + 1);   // v 1：皮（八連通）；0：皮以外（四連通），碰到框邊的不是洞
      for (let y = by0; y <= by1; y++) for (let x = bx0; x <= bx1; x++) { const st = y * mw + x; if (cur[st] !== v || lab[st]) continue; let n = 0, top = 0, be = 0, se = 0; stk[top++] = st; lab[st] = 1;
        while (top) { const p = stk[--top], px = p % mw, py = (p / mw) | 0; n++; if (px === bx0 || px === bx1 || py === by0 || py === by1) be = 1; if (px === 0 || py === 0 || px === mw - 1 || py === mh - 1) se = 1;
          for (let oy = -1; oy <= 1; oy++) for (let ox = -1; ox <= 1; ox++) { if ((!ox && !oy) || (!v && ox && oy)) continue; const ax = px + ox, ay = py + oy; if (ax < bx0 || ay < by0 || ax > bx1 || ay > by1) continue; const q = ay * mw + ax; if (cur[q] === v && !lab[q]) { lab[q] = 1; stk[top++] = q; } } }
        if (v || !be) out.push([n * px2, se]); } return out; };
    const dist = (m, b) => { const [bx0, by0, bx1, by1] = b, w = bx1 - bx0 + 1, hh = by1 - by0 + 1, d = new Float32Array(w * hh), D = 1.4142; for (let y = 0; y < hh; y++) for (let x = 0; x < w; x++) { const i = y * w + x; let v = m[(y + by0) * mw + x + bx0] ? 0 : 1e6; if (v) { if (x > 0) v = Math.min(v, d[i - 1] + 1); if (y > 0) { v = Math.min(v, d[i - w] + 1); if (x > 0) v = Math.min(v, d[i - w - 1] + D); if (x < w - 1) v = Math.min(v, d[i - w + 1] + D); } } d[i] = v; }
      for (let y = hh - 1; y >= 0; y--) for (let x = w - 1; x >= 0; x--) { const i = y * w + x; let v = d[i]; if (!v) continue; if (x < w - 1) v = Math.min(v, d[i + 1] + 1); if (y < hh - 1) { v = Math.min(v, d[i + w] + 1); if (x < w - 1) v = Math.min(v, d[i + w + 1] + D); if (x > 0) v = Math.min(v, d[i + w - 1] + D); } d[i] = v; } return d; };
    const look = () => { read(); if (!o.n++ && (!box || comps(1).every(c => c[0] < 1))) o.blank = 1;   // 第一次讀就沒有身體：畫不出來，不算過
      if (box) { let big = 0, eb = 0; for (const [a, e] of comps(1)) if (a >= .004) { if (!e) big++; else if (!eb) { eb = 1; big++; } } if (big > 1) o.split++; if (comps(0).some(c => c[0] >= .002)) o.hole++; }
      if (prev && box && pbox) { const b = [Math.min(box[0], pbox[0]), Math.min(box[1], pbox[1]), Math.max(box[2], pbox[2]), Math.max(box[3], pbox[3])], dc = dist(cur, b), dp = dist(prev, b), w = b[2] - b[0] + 1; let far = 0; for (let y = b[1]; y <= b[3]; y++) for (let x = b[0]; x <= b[2]; x++) { const q = y * mw + x; if (cur[q] === prev[q]) continue; const d = (cur[q] ? dp : dc)[(y - b[1]) * w + x - b[0]]; if (d > far) far = d; } const pop = (far * 2 - disp - 4) / R; if (pop > o.popMax) o.popMax = pop; if (pop > .12) o.pop++; }
      prev = cur; pbox = box; disp = 0; };
    const step = n => { for (let k = 0; k < n; k++) { const n0 = N, r0 = REM.n, l0 = REM.last, x0 = Float64Array.from(X), y0 = Float64Array.from(Y); steps(1); fr++; if (N !== n0 || REM.n !== r0 || REM.last !== l0) disp += lastMax; else { let d = 0; for (const i of bnd) d = Math.max(d, Math.hypot(X[i] - x0[i], Y[i] - y0[i])); lastMax = d * CAM.z; disp += lastMax; }
      if (fr % 2 === 0) look(); } };
    const mv = (id, x, y) => ev('pointermove', id, Math.max(4, Math.min(W - 4, x)), Math.max(4, Math.min(H - 4, y)));
    const pull = (sx, sy, ux, uy, d, sp, hold, rel) => { ev('pointerdown', 1, sx, sy); step(4); const n = Math.max(2, Math.ceil(d / R / sp * 60)); for (let k = 1; k <= n; k++) { mv(1, sx + ux * d * k / n, sy + uy * d * k / n); step(1); } step(hold); ev('pointerup', 1, sx + ux * d, sy + uy * d); step(rel); };
    const go = { pull(c, over) { const [ux, uy] = DIR[c.dir], rr = seeded(c.seed * 7919 + 13), g = SILL.g, jt = () => (rr() - .5) * R * .16; fresh(over, c.seed, ux < 0 ? g.r - R * 1.05 : g.l + R * 1.05); let [x, y] = scr(globalC.xc, globalC.yc); x += jt(); y += jt(); pull(x, y, ux, uy, Math.min(c.d * R, toEdge(x, y, ux, uy)), 25, 180, 240); },
      opp(c, over) { fresh(over, c.seed); const [cx, cy] = scr(globalC.xc, globalC.yc), a = cx + R * .35, b = cx - R * .35, d1 = W - 4 - a, d2 = b - 4; ev('pointerdown', 1, a, cy); ev('pointerdown', 2, b, cy); step(4); const n = Math.max(2, Math.ceil(Math.max(d1, d2) / R / 20 * 60)); for (let k = 1; k <= n; k++) { mv(1, a + d1 * k / n, cy); mv(2, b - d2 * k / n, cy); step(1); } step(180); ev('pointerup', 1, a + d1, cy); step(6); ev('pointerup', 2, b - d2, cy); step(234); },
      rnd(c, over) { const rr = seeded(c.seed * 104729 + 17), g = SILL.g; fresh(over, c.seed, g.l + R * 1.05 + rr() * (g.r - g.l - R * 2.1)); let x = 0, y = 0; for (let k = 0; k < 60; k++) { const a = rr() * 6.2832, q = Math.sqrt(rr()) * R, wx = globalC.xc + Math.cos(a) * q, wy = globalC.yc + Math.sin(a) * q; if (insideBody(wx, wy)) { [x, y] = scr(wx, wy); break; } }
        const a = rr() * 6.2832, ux = Math.cos(a), uy = Math.sin(a), te = toEdge(x, y, ux, uy), d = Math.min(te, R * .5 + rr() * Math.max(0, te - R * .5)), sp = 3 * Math.pow(25 / 3, rr()), hd = Math.round(18 + rr() * 162); pull(x, y, ux, uy, d, sp, hd, 180); } };
    const worst = []; for (let k = 0; k < 10; k++) worst.push({ id: 'R' + k, k: 'pull', dir: 'R', d: 99, seed: 31175 + k * 1000 }, { id: 'DR' + k, k: 'pull', dir: 'DR', d: 3, seed: 31175 + k * 1000 }, { id: 'O' + k, k: 'opp', seed: 31201 + k * 1000 }, { id: 'L' + k, k: 'pull', dir: 'L', d: 99, seed: 31101 + k * 1000 });
    const casual = n => Array.from({ length: n }, (_, k) => ({ id: 'N' + k, k: 'rnd', seed: 45000 + k }));
    const batch = async (nm, cells, over, kp) => { const b0 = performance.now(), q = { n: 0, brk: 0, split: 0, hole: 0, pop: 0, blank: 0, nan: 0, popMax: 0, skin: null, who: '' }; if (kp) window.KPIOS = 1; else delete window.KPIOS;
      for (const c of cells) { o = { n: 0, split: 0, hole: 0, pop: 0, blank: 0, popMax: 0 }; prev = pbox = null; disp = lastMax = fr = 0; go[c.k](c, over); for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); let bad = 0; for (let i = 0; i < N; i++) if (!isFinite(X[i]) || !isFinite(Y[i])) bad++;
        q.n++; if (o.split || o.hole || o.pop) { q.brk++; q.who += ' ' + c.id + (o.split ? '裂' : '') + (o.hole ? '洞' : '') + (o.pop ? '突' : ''); } if (o.split) q.split++; if (o.hole) q.hole++; if (o.pop) q.pop++; q.blank += o.blank; if (bad) q.nan++; q.popMax = Math.max(q.popMax, o.popMax); await new Promise(a => setTimeout(a, 0)); }
      q.popMax = +q.popMax.toFixed(2); if (typeof SKIN !== 'undefined') q.skin = SKIN.used; r[nm] = q; r.sec[nm] = Math.round((performance.now() - b0) / 1000); };
    try { WALK.items.length = 0; WALK.fall.length = 0; WALK.leave.length = 0; WALK.stuck = null; fresh(DEF, 70); draw(); const nr = long ? 300 : window.T70N || 20, few = long ? worst : worst.slice(0, 20);
      await batch('old', few, OLD, 0); await batch('def', worst, DEF, 0); await batch('all', worst, ALL, 0);
      await batch('defR', casual(nr), DEF, 0); await batch('allR', casual(nr), ALL, 0);
      await batch('defP', long ? worst : worst.slice(0, 12), DEF, 1); await batch('allP', long ? worst : worst.slice(0, 12), ALL, 1);
      if (long) { await batch('defRP', casual(100), DEF, 1); await batch('allRP', casual(100), ALL, 1); }
    } catch (e) { r.err = String(e); }
    if (kp0 === undefined) delete window.KPIOS; else window.KPIOS = kp0;
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); SLIME = sl0; Object.assign(VIEW, view0); r.sec.total = Math.round((performance.now() - T0) / 1000);
    res.T70_skin = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; if (typeof drReset === 'function') drReset();
    const ran = ['old', 'def', 'all', 'defR', 'allR', 'defP', 'allP'].every(k => r[k] && r[k].blank === 0 && r[k].nan === 0);
    res.PASS.skinWhole = r.err === '' && ran && r.old.split >= (long ? 6 : 2) && r.def.split <= 2 && r.all.brk === 0 && r.allR.brk <= Math.ceil(r.allR.n * .01);
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T72 v2.61 補守（11-25 反駁查到：預設開著、壞掉自測不會知道的）。窗台、芋圓、真正的預設；每條都另外跑一次關掉，要看得出不一樣（證明量得到）
  // a tapSoft：慢點 6 下，每一下縮得比上一下小（每下前把 FLN.H 放回 1，等於隔了很久，看的是 TAPK 那個上限）、戒 0；關掉戒會漲、不變小。b petSlow：每秒 3、6 公分分開摸，2 秒內呼嚕；關掉同樣摸 2.5 秒不會。c rough：快扯記成扯（yank）、想逃、撐著會出抗議聲；慢拉不會；戒都不加；關掉慢拉也會想逃。
  // d brJit：只跑大腦那條算式，睡醒的間隔開著散、關著幾乎一樣。e bumpSoft：牠自己（沒有手指）帶過去的罐子不倒、歪的慢慢收回來不跳；關掉會倒；手指推照舊倒。f snd61：抓著時雨 0.3，關掉 0.6。
  // g wakeSoft：從外面推進來碰熟睡的熟牠，每秒 3、3.5R 慢慢醒不嚇，每秒 5R 照舊嚇醒；很熟的睡著被按著不往手指推、不蹭、不出聲。h 重建時往回拔（tugS）歸零。
  // i ?pull= 鎖住時存 1 到存 3、匯入、盲比紀錄都不帶網址的值（用 srcdoc 開一頁、假的 localStorage，不碰使用者存的）；沒鎖住時照舊
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, T0 = performance.now(), M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, E0 = { count: E4.count, lastT: E4.lastT }, B0 = { ...BRAIN }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, sndB5: 0 };   // v2.63 B5：sndB5 1 時嚇到那一聲排到縮的那一格（晚 0.05 秒），g 推醒那條一醒就查有沒有 startle，會查不到；這一項量的是改之前的規格，釘 0
    const fresh = (over, tr) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(72); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = tr || 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E2.leanT = -9; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; Object.assign(BRAIN, { seed: 72 }); brainReset(); log.splice(0); };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; }, heard = k => log.some(x => x[0] === k), up = q => Math.abs(Math.atan2(Math.sin(q.a), Math.cos(q.a)));
    const taps = over => { fresh(over, .3); steps(300); IMP.w = 0; const amp = []; for (let k = 0; k < 6; k++) { const q = sc(globalC.xc, globalC.yc), t1 = t; FLN.H = 1; ev('pointerdown', 1, q[0], q[1]); steps(6); ev('pointerup', 1, q[0], q[1]); steps(66); amp.push(FLN.t0 > t1 ? +FLN.amp.toFixed(4) : 0); } return { amp, w: +IMP.w.toFixed(3) }; };
    r.tap = { on: taps({}), off: taps({ tapSoft: 0 }) };
    const pet = (over, cm) => { fresh(over, 0); steps(240); const v = cm / 1.8 * R / 60, m = Math.max(1, Math.round(R * 1.1 / v)); let at = -1, n = 0; while (n < 150 && at < 0) { const q = sc(globalC.xc + R * .5, globalC.yc - R * .55); ev('pointerdown', 1, q[0], q[1]); for (let i = 1; i <= m && n < 150; i++) { ev('pointermove', 1, q[0], q[1] + v * i); steps(1); n++; if (at < 0 && PURR > .3) at = +(n / 60).toFixed(2); } ev('pointerup', 1, q[0], q[1] + v * m); steps(6); n += 6; } return at; };
    r.pet = { on: [pet({}, 3), pet({}, 6)], off: [pet({ petSlow: 0 }, 3), pet({ petSlow: 0 }, 6)] };
    const drag = (over, frames) => { fresh(over, .3); steps(240); IMP.w = 0; const tr0 = IMP.tr, q = sc(globalC.xc, globalC.yc - R * .6); let sm = 0, prot = -1; ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); steps(3); for (let k = 1; k <= frames + 180; k++) { if (k <= frames) ev('pointermove', 1, q[0], q[1] - R * 3.5 * k / frames); steps(1); sm = Math.max(sm, MOOD.strain); if (prot < 0 && heard('voice.protest')) prot = +(k / 60).toFixed(2); } const yank = !!f.yank, w = IMP.w; ev('pointerup', 1, q[0], q[1] - R * 3.5); const flee = ESC.on; steps(5); return { yank, strain: +sm.toFixed(2), prot, flee, w: +Math.max(w, IMP.w).toFixed(3), tr: +(IMP.tr - tr0).toFixed(3) }; };
    r.rough = { fast: drag({}, 9), slow: drag({}, 120), off: drag({ rough: 0 }, 120) };
    const rhythm = over => { fresh(over, .3); steps(60); t = 100; const iv = []; let last = 100; for (let k = 0; k < 10; k++) { let g = 0; SLP.on = false; while (BRAIN.z <= BRAIN.zAt && g++ < 4000) { t += .1; LIFE.st = 'rest'; brainStep(.1, false); } SLP.on = true; LIFE.st = 'sleep'; while (SLP.on && g++ < 8000) { t += .1; brainStep(.1, false); } if (k > 1) iv.push(t - last); last = t; } SLP.on = false; const a = iv.reduce((x, y) => x + y, 0) / iv.length; return { iv: iv.map(x => Math.round(x)), cv: +(Math.sqrt(iv.reduce((x, y) => x + (y - a) ** 2, 0) / iv.length) / a).toFixed(3) }; };
    r.jit = { on: rhythm({}), off: rhythm({ brJit: 0 }) };
    const DC = { deco: 1, decoReal: 1, decoBody: 1, decoReact: 0 };
    const bump = over => { fresh({ ...DC, ...over }, .7); steps(60); const q = PROPS[1]; let bot = -1e9, tl = 0, jump = 0; for (let i = 0; i < N; i++) bot = Math.max(bot, Y[i]); const dn = SILL.g.fl - 2 - bot; for (let i = 0; i < N; i++) { X[i] += 85; PX[i] += 85; Y[i] += dn; PY[i] += dn; } decoBody(1 / 60); log.splice(0);
      const go = v => { for (let i = 0; i < N; i++) { X[i] += v / 60; PX[i] += v / 60; } decoBody(1 / 60); for (let u = 0; u < 4; u++) { t += 1 / 240; propsStep(1 / 240); } if (!q.gone) tl = Math.max(tl, up(q)); };
      for (let f = 0; f < 6; f++) go(450); for (let f = 0; f < 90; f++) go(0); const o = { up: +tl.toFixed(2), gone: q.gone, topple: heard('fx.topple') };
      Object.assign(q, { a: .45, va: 0, vx: 0, vy: 0, x: q.hx, y: q.hy, tip: false, gone: false, softX: q.hx, fingT: null, catT: null }); for (let u = 0; u < 120; u++) { q.softT = t; const b = q.a; t += 1 / 240; propsStep(1 / 240); jump = Math.max(jump, Math.abs(q.a - b)); } o.jump = +jump.toFixed(3); o.end = +up(q).toFixed(2); return o; };
    r.bump = { on: bump({}), off: bump({ bumpSoft: 0 }) };
    { const hand = soft => { fresh(DC, .7); steps(60); for (const z of PROPS) Object.assign(z, { x: z.hx, y: z.hy, a: 0, vx: 0, vy: 0, va: 0, tip: false, softT: null, fingT: null, catT: null }); const q = PROPS[1], p = sc(q.x, q.y - q.h * .3), tr = []; q.softX = q.x; t = 10; ev('pointerdown', 4, p[0], p[1]); const held = !!q.held, go = () => { for (let u = 0; u < 4; u++) { if (soft) q.softT = t; t += 1 / 240; propsStep(1 / 240); } tr.push(q.a, q.x); }; for (let i = 1; i <= 12; i++) { ev('pointermove', 4, p[0] - i * R * .12, p[1]); go(); } ev('pointerup', 4, p[0] - R * 1.44, p[1]); for (let i = 0; i < 60; i++) go(); return { held, tr, up: Math.max(...tr.filter((v, i) => i % 2 === 0).map(Math.abs)) }; }; const A = hand(false), B = hand(true); r.bump.hand = { held: A.held && B.held, up: +B.up.toFixed(2), same: Math.max(...A.tr.map((v, i) => Math.abs(v - B.tr[i]))) }; }   // 牠剛碰過（軟的 1.6 秒內）跟沒碰過，手指推起來要一模一樣（只跑擺飾，身體不跑：同種子兩次身體會差一點點）
    if (SFX) { const k0 = ['ctx', 'bgmG', 'bgmT', 'mode', 'amb', 'muted', 'ambMeta', 'ambSrc', 'pending', 'st', 'v'].map(k => [k, SFX[k]]);
      const duck = over => { fresh(over, 0); steps(30); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); let g = -1; Object.assign(SFX, { ctx: { currentTime: 0 }, bgmG: { gain: { setTargetAtTime: x => { g = x; } } }, bgmT: 1, mode: 0, amb: 'rain', muted: true, ambMeta: null, ambSrc: null, pending: [] }); try { steps(2); } catch (e) { g = String(e); } for (const [k, x] of k0) SFX[k] = x; ev('pointerup', 1, q[0], q[1]); return g; };
      r.snd = { on: duck({}), off: duck({ snd61: 0 }) }; }
    const push = (over, tr, sp) => { fresh(over, tr); steps(180); SLP.on = true; LIFE.st = 'sleep'; BRAIN.z = .9; steps(180); IMP.tr = tr; log.splice(0); const q = sc(globalC.xc, globalC.yc - R * 3.6); ev('pointerdown', 1, q[0], q[1]); const on0 = SLP.on; let k = 0; for (; k < 150 && SLP.on; k++) { if (q[1] + sp * R * k / 60 < H) ev('pointermove', 1, q[0], q[1] + sp * R * k / 60); steps(1); } const o = { on0, at: +(k / 60).toFixed(2), slow: !SLP.on && SLP.slow, startle: heard('voice.startle') }; ev('pointerup', 1, 0, 0); return o; };
    r.push = { v3: push({}, .5, 3), v35: push({}, .5, 3.5), fast: push({}, .5, 5), off: push({ wakeSoft: 0 }, .5, 3) };
    { fresh({}, .95); steps(120); SLP.on = true; LIFE.st = 'sleep'; BRAIN.z = .9; steps(240); IMP.tr = .95; log.splice(0); Math.random = () => .1; const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); let lean = false, nuz = 0, n = 0; for (let k = 0; k < 66 && SLP.on; k++) { steps(1); if (!SLP.on) break; n++; lean = lean || E2.leanT > 0; nuz = Math.max(nuz, Math.abs(E2.nuzO || 0) / R); } r.sleepHold = { n, lean, nuz: +nuz.toFixed(3), mmm: heard('voice.mmm') }; ev('pointerup', 1, q[0], q[1]); }
    { fresh({}, 0); steps(120); const q = sc(globalC.xc + R * .7, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(2); for (let k = 1; k <= 9; k++) { ev('pointermove', 1, q[0] + R * 2.4 * k / 9, q[1]); steps(1); } steps(90); const b = +(MOOD.tugS || 0).toFixed(2); setup(); r.tug = { before: b, after: +(MOOD.tugS || 0).toFixed(2) }; }
    // i：srcdoc 的頁沒有網址參數，所以把讀 ?pull= 那一句換成固定字串；localStorage 換成假的、動畫停掉
    const deskPage = async (pull, feel) => { let h = await (await fetch(location.pathname, { cache: 'no-store' })).text(); const key = "new URLSearchParams(location.search).get('pull')"; if (h.split(key).length !== 2) throw new Error('T72：找不到讀 ?pull= 的那一句'); h = h.replace(key, () => JSON.stringify(pull));
      const fake = "<script>{const m={'nienie.feel':" + JSON.stringify(JSON.stringify(feel)).replace(/</g, '\\u003c') + "};Object.defineProperty(window,'localStorage',{value:{getItem:k=>k in m?m[k]:null,setItem:(k,v)=>{m[k]=String(v)},removeItem:k=>{delete m[k]}}});window.__ls=m;window.requestAnimationFrame=()=>0}</" + 'script>';
      h = h.replace(/<meta charset[^>]*>/i, m => m + fake); if (!h.includes(fake)) throw new Error('T72：假的 localStorage 沒放進去');
      const fr = document.createElement('iframe'); fr.style.cssText = 'position:fixed;left:-2000px;top:0;width:393px;height:852px;visibility:hidden'; fr.srcdoc = h; const ld = new Promise((a, b) => { fr.onload = a; setTimeout(() => b(new Error('T72：15 秒沒開起來')), 15000); }); document.body.appendChild(fr); await ld; return fr; };
    try { const P0 = { ...PRESETS }; Object.assign(PRESETS, PRE62); const ps = deskStamp(), k = deskPick(); Object.assign(PRESETS, P0);
      const K3 = (a, b, c) => ({ ...k, pullHold: a, pullWhole: b, pullSoft: c }), slot = (...a) => ({ base: 'clay', pv: FEELVER, ps, k: K3(...a) }), feel = { v: 2, pv: FEELVER, ps, base: 'clay', k: K3(1, 0, 0), s: [slot(1, 1, 0), slot(0, 0, 1), null], log: [] };
      const act = async pull => { const fr = await deskPage(pull, feel), E = fr.contentWindow.eval, S3 = "DESK.slots.map(s=>s?PULL3.map(k=>+s.k[k]>=.5?1:0).join(''):'-').join(',')", o = {};
        o.mat = E("PULL3.map(k=>mat[k]).join('')"); o.s0 = E(S3); o.diff = E('deskDiff(DESK.slots[0],DESK.slots[1]).join()'); E("document.querySelector('[data-save=\"2\"]').click()"); o.save = E(S3);
        const txt = E('deskText()'); o.live = /pullHold/.test(txt.slice(txt.indexOf('#nienie-feel'), txt.indexOf('"s":['))); E('deskImport(' + JSON.stringify(txt) + ')'); o.imp = E(S3);
        E('deskImport(' + JSON.stringify(txt.replace(/,"pull(Hold|Whole|Soft)":\d/g, '')) + ')'); o.bare = E(S3); o.stage = E("(o=>PULL3.map(k=>o.k[k]).join(''))(JSON.parse(__ls['nienie.feel']))"); fr.remove(); return o; };
      r.pull = { zero: await act('0'), one: await act('1'), plain: await act(null) };
    } catch (e) { r.err = String(e); for (const f of document.querySelectorAll('iframe[srcdoc]')) f.remove(); }
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; E2.leanT = -9; r.sec = Math.round((performance.now() - T0) / 1000); res.T72_guard = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    const down = a => a.every((v, i) => v > 0 && (!i || v < a[i - 1])), lock = (z, m) => z.mat === m && z.s0 === '110,001,-' && !/停住|整隻|收回去/.test(z.diff) && z.save === '110,001,100' && !z.live && z.imp === '110,001,100' && z.bare === '110,001,100' && z.stage === '100';
    const F = r.pull && r.pull.plain;
    r.ok = { tap: down(r.tap.on.amp) && r.tap.on.amp[5] < r.tap.on.amp[0] * .8 && r.tap.on.w === 0 && r.tap.off.w > 0 && r.tap.off.amp[5] > r.tap.off.amp[0] * .9, pet: r.pet.on.every(v => v > 0 && v <= 2) && r.pet.off.every(v => v < 0),
      rough: r.rough.fast.yank && r.rough.fast.strain > .5 && r.rough.fast.prot > 0 && r.rough.fast.flee && r.rough.fast.w === 0 && !r.rough.slow.yank && r.rough.slow.strain === 0 && r.rough.slow.prot < 0 && !r.rough.slow.flee && r.rough.slow.w === 0 && r.rough.off.strain > .5 && r.rough.off.flee,
      jit: r.jit.on.cv > .15 && r.jit.off.cv < .05, bump: r.bump.on.up < .3 && !r.bump.on.gone && !r.bump.on.topple && r.bump.on.jump <= .03 && r.bump.on.end < .2 && r.bump.off.topple, hand: r.bump.hand.held && r.bump.hand.up > 1 && r.bump.hand.same < 1e-6,
      snd: !!r.snd && r.snd.on === .3 && r.snd.off === .6, push: ['v3', 'v35'].every(q => r.push[q].on0 && r.push[q].slow && !r.push[q].startle) && r.push.fast.startle && r.push.off.startle, sleepHold: r.sleepHold.n > 60 && !r.sleepHold.lean && r.sleepHold.nuz === 0 && !r.sleepHold.mmm, tug: r.tug.before > .3 && r.tug.after === 0,
      pull: !r.err && lock(r.pull.zero, '000') && lock(r.pull.one, '111') && F.mat === '100' && /停住/.test(F.diff) && F.save === '110,001,100' && F.live && F.imp === '110,001,100' && F.bare === '000,000,000' };
    res.PASS.guard61 = Object.values(r.ok).every(Boolean); res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T73 v2.61 慢拉往裡穿過去時跟手照舊變少（11-25：rough 讓慢拉的 strain 一直是 0，跟手（dragFollow）讀 strain，按住時不放鬆，家停在手指上面，抓對側邊往右下慢拉的洞變久一倍）。窗台、芋圓、真正的預設，真的畫出來，每 2 格讀一次 JEL.h2 的洞（0.002R² 以上、四面都是皮，跟 T70 同一個門檻）。
  // 手勢：從窗台左邊抓對側邊往右下慢拉 3R（每秒 4R），按住 3 秒，放手 1.5 秒；4 顆種子，同一批跑三種：預設、rough 0、預設但跟手改回讀 strain（修之前）。
  // 擋：按住末的跟手跟 rough 0 一樣、家被帶走的距離每顆種子差 0.1R 內；修之前那種四顆合計至少多 1R（量到每顆 0.84 對 0.46，證明量得到）；放手後洞 0；洞讀數合計不超過 rough 0 的 1.6 倍加 8；慢拉照樣 strain 0、不逃。身長只記錄。
  { const clock = saveClock(), view0 = { ...VIEW }, sl0 = SLIME, I0 = { tr: IMP.tr, w: IMP.w }, df0 = dragFollow, r = { err: '' }, T0 = performance.now();
    Object.assign(VIEW, { skin: 'A', body: 'round', face: 1, bg: 'day', win: '' });
    const si = SLIMES.findIndex(q => q.id === 'taro'), s = SLIMES[si], SP = { ...PRE54[s.mat], seed: s.seed, ...s.p, shakeMode: 0, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0 };
    const scr = (wx, wy) => { const v = viewV(), q = cv.getBoundingClientRect(); return [(wx - CAM.x) * CAM.z + v.x + q.left, (wy - CAM.y) * CAM.z + v.y + q.top]; };
    const holes = () => { draw(); const gl = JEL.gl; if (!gl || gl.isContextLost() || !JEL.float) throw new Error('T73：WebGL 沒開，畫不出果凍皮'); const w = JEL.h2.w, hh = JEL.h2.h, b = new Float32Array(w * hh * 4), m = new Uint8Array(w * hh), st = [], a1 = (W / w) * (H / hh) / (R * R); gl.bindFramebuffer(gl.FRAMEBUFFER, JEL.h2.f); gl.readPixels(0, 0, w, hh, gl.RGBA, gl.FLOAT, b); gl.bindFramebuffer(gl.FRAMEBUFFER, null);
      let skin = 0, n = 0; for (let i = 0; i < w * hh; i++) if (b[i * 4] > .46) { m[i] = 1; skin++; } if (skin * a1 < 1) throw new Error('T73：畫不出身體');
      for (let i = 0; i < w * hh; i++) { if (m[i]) continue; let c = 0, edge = false; st.push(i); m[i] = 2; while (st.length) { const p = st.pop(), x = p % w, y = (p / w) | 0; c++; if (!x || !y || x === w - 1 || y === hh - 1) edge = true; if (x && !m[p - 1]) { m[p - 1] = 2; st.push(p - 1); } if (x < w - 1 && !m[p + 1]) { m[p + 1] = 2; st.push(p + 1); } if (y && !m[p - w]) { m[p - w] = 2; st.push(p - w); } if (y < hh - 1 && !m[p + w]) { m[p + w] = 2; st.push(p + w); } } if (!edge && c * a1 >= .002) n++; }
      return n; };
    const one = (over, seed) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(seed); SLIME = si; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; impReset(); ESC.on = false; DENTS.length = 0; Object.assign(BRAIN, { seed }); brainReset(); MOOD.strain = 0; MOOD.scare = 0; GREET.st = ''; GREET.until = -9; EYE.user = -9;
      { const dx = SILL.g.l + R * 1.05 - CX; for (let i = 0; i < N; i++) { X[i] += dx; PX[i] += dx; } HOMEX += dx; } steps(120);
      const u = .7071, rr = seeded(seed * 7919 + 13); let bi = bnd[0], bd = -1e9; for (const i of bnd) { const p = -(X[i] + Y[i]); if (p > bd) { bd = p; bi = i; } } let [x, y] = scr(X[bi] + u * R * .15, Y[bi] + u * R * .15); x -= u * (rr() - .5) * R * .16; y += u * (rr() - .5) * R * .16;
      const o = { hold: 0, rel: 0, strain: 0, esc: false }, d = 3 * R, n = 45; ev('pointerdown', 1, x, y); steps(4); for (let k = 1; k <= n; k++) { ev('pointermove', 1, Math.min(W - 4, x + u * d * k / n), Math.min(H - 4, y + u * d * k / n)); steps(1); }
      for (let k = 1; k <= 180; k++) { steps(1); o.strain = Math.max(o.strain, MOOD.strain); if (k % 2 === 0 && holes()) o.hold++; } const f = fingers.get(1); o.held = !!f && f.mode === 'grab'; o.follow = +dragFollow().toFixed(3); o.home = +(Math.hypot(DRAG.ox - DRAG.bx, DRAG.oy - DRAG.by) / R).toFixed(2); let a = 1e9, b = -1e9, c = 1e9, e = -1e9; for (const i of bnd) { a = Math.min(a, X[i]); b = Math.max(b, X[i]); c = Math.min(c, Y[i]); e = Math.max(e, Y[i]); } o.len = +(Math.hypot(b - a, e - c) / R).toFixed(2);
      ev('pointerup', 1, x + u * d, y + u * d); for (let k = 1; k <= 90; k++) { steps(1); o.esc = o.esc || ESC.on; if (k % 2 === 0 && holes()) o.rel++; } return o; };
    const all = async (nm, over, old) => { if (old) dragFollow = () => { const q = MOOD.tugS; MOOD.tugS = MOOD.strain; try { return df0(); } finally { MOOD.tugS = q; } }; const L = []; try { for (const sd of [52138, 57138, 62138, 67138]) { L.push(one(over, sd)); await new Promise(a => setTimeout(a, 0)); } } finally { dragFollow = df0; } const sum = k => L.reduce((p, q) => p + q[k], 0); r[nm] = { hold: sum('hold'), rel: sum('rel'), strain: Math.max(...L.map(q => q.strain)), esc: L.some(q => q.esc), held: L.every(q => q.held), follow: L.map(q => q.follow), home: L.map(q => q.home), len: L.map(q => q.len) }; };
    try { await all('on', {}, 0); await all('off', { rough: 0 }, 0); await all('old', {}, 1); } catch (e) { r.err = String(e); }
    dragFollow = df0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); SLIME = sl0; Object.assign(VIEW, view0); IMP.tr = I0.tr; IMP.w = I0.w; r.sec = Math.round((performance.now() - T0) / 1000);
    res.T73_slowPull = r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    res.PASS.slowPull = r.err === '' && r.on.held && r.on.strain === 0 && !r.on.esc && r.off.strain > .5 && r.on.home.every((v, i) => Math.abs(v - r.off.home[i]) <= .1) && r.on.follow.every((v, i) => Math.abs(v - r.off.follow[i]) <= .03) && r.old.home.reduce((p, q, i) => p + q - r.on.home[i], 0) >= 1 && r.on.rel === 0 && r.on.hold <= r.off.hold * 1.6 + 8;
    res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T75 v2.63 C4 切回來也先看你（greetLook；OVERNIGHT 第 2 項，手機照這條搬）。T71 只量了打開那條；這項發真的事件（document.hidden 先蓋掉）：分頁藏起來再回來（visibilitychange）、視窗切走再切回來（blur、focus，分頁沒藏）。窗台、芋圓、真正的預設，熟 .6。
  // 擋：醒著回來 0.6 秒內看你（EYE.user 排上）、眨一下、眼睛朝前；睡著回來當下就醒、走慢慢醒（SLP.slow）、不嚇（沒有 startle、不縮、不睜大）、不出「嗯？」，0.6 秒內看你；blur／focus 那條一樣 0.6 秒內看你。
  // 對照：greetLook 0 醒著 1 秒內不看、睡著的照睡（證明量得到）。
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w, at: IMP.hiddenAt }, blur0 = GREET.blurT, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0 };
    let hid = false; Object.defineProperty(document, 'hidden', { configurable: true, get: () => hid });
    const fresh = (over, tr) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(75); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = tr || 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; GREET.blurT = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; Object.assign(BRAIN, { seed: 75 }); brainReset(); };
    const back = (over, sleep, how) => { fresh(over, .6); steps(240); if (sleep) { SLP.on = true; LIFE.st = 'sleep'; BRAIN.z = .9; steps(300); } const k0 = +SLP.k.toFixed(2); log.splice(0); EYE.user = -9; const f0 = FLN.t0;
      if (how === 'focus') { dispatchEvent(new Event('blur')); dispatchEvent(new Event('focus')); } else { hid = true; document.dispatchEvent(new Event('visibilitychange')); hid = false; document.dispatchEvent(new Event('visibilitychange')); }
      const now = !SLP.on; let at = -1, blink = 1, wide = 0, gaze = 9, k6 = -1;
      for (let i = 0; i < 60; i++) { steps(1); const s = +((i + 1) / 60).toFixed(2); if (at < 0 && EYE.user > t) at = s; if (at > 0) { blink = Math.min(blink, EYE.blink); if (s - at >= .3) gaze = Math.min(gaze, Math.hypot(EYE.gx, EYE.gy)); } wide = Math.max(wide, EYE.wideD); if (i === 35) k6 = +SLP.k.toFixed(2); }
      steps(60);
      return { at, k0, wokeNow: now, asleep: SLP.on, slow: SLP.slow, k6, startle: log.some(x => x[0] === 'voice.startle'), ask: log.some(x => x[0] === 'voice.ask'), flinch: FLN.t0 !== f0, blink: +blink.toFixed(2), wide: +wide.toFixed(2), gaze: +gaze.toFixed(2) }; };
    try { r.awake = back({}, false, 'vis'); r.sleep = back({}, true, 'vis'); r.focus = back({}, false, 'focus'); r.offAwake = back({ greetLook: 0 }, false, 'vis'); r.offSleep = back({ greetLook: 0 }, true, 'vis'); r.err = ''; } catch (e) { r.err = String(e); }
    delete document.hidden; IMP.hiddenAt = I0.at; GREET.blurT = blur0;
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    const lookOK = q => q.at > 0 && q.at <= .6 && q.blink <= .1 && q.gaze <= .25;
    r.ok = !r.err && lookOK(r.awake) && !r.awake.startle && lookOK(r.focus)
      && r.sleep.k0 > .8 && r.sleep.wokeNow && !r.sleep.asleep && r.sleep.slow && lookOK(r.sleep) && !r.sleep.startle && !r.sleep.ask && !r.sleep.flinch && r.sleep.wide < 1.05
      && r.offAwake.at < 0 && r.offSleep.asleep && r.offSleep.at < 0;
    res.T75_greetBack = r; res.PASS.greetBack = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T76 v2.63 C9 揉夠了放手，牠在你手邊睡著（nap；OVERNIGHT 第 5 項，手機照這條搬）。窗台、芋圓、真正的預設，熟 .5；揉之前先把牠搬到窗台右邊盡頭（離布墊約 0.9R，窗台只有 3R 寬；看得出有沒有走回去）。
  // 擋：a 一般捏 30 秒（按 1 秒、拉 1R、揉 4 秒輪三次再揉 4.5 秒，呼嚕累計不到 napPurr）放手，10 秒內不睡；b 揉夠（揉 35 秒、放手 2 秒、再揉 35 秒）放手，10 秒內睡著，睡著那一刻重心離最後摸的地方 0.5R 內、
  // 沒走路線、放手後重心挪不到 0.3R、離布墊還在 0.5R 外（回到布墊是 0.3R 內），累計歸零；c 接著（睡了至少 3 秒）輕碰 0.13 秒、隔 1.5 秒、最多 3 下：每下都不嚇（沒有 startle、不縮），最後是慢慢醒（SLP.slow；很熟的前兩下只翻身，照 wakeSoft）。
  // 對照：nap 0 同樣揉夠，10 秒內沒有在手邊睡著（照舊）。armedBefore：前面的項目有沒有讓 nap 動起來過（整份跑時要是 0，舊項目才不受影響）
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = { armedBefore: NAP.armN }, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, rubVary: 0 };   // v2.63 C6：揉完反應輪流（rubVary）預設 1 之後放手不一定小跳，這一項量的是舊規格，釘 0
    const fresh = (over, tr) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(76); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = tr || 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: 76, naps: 0 }); brainReset();
      steps(60); moveHome(sillClampX(SILL.g.bx + R * 2) - globalC.xc, 0, DT); steps(30); };   // 搬離布墊：布墊是 SILL.g.bx（記性關掉喜歡的位置，memHomeX 就是它）
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const rub = sec => { const cx = globalC.xc, cy = globalC.yc; let q = sc(cx, cy - R * .25); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1);   // 跟 T33 同一個揉法（半徑 0.25R 的小圈，每秒半圈），圈心放在重心上
      for (let k = 1; k <= sec * 60; k++) { const a = 2 * Math.PI * .5 * k / 60; q = sc(cx + R * .25 * Math.sin(a), cy - R * .25 * Math.cos(a)); ev('pointermove', 1, q[0], q[1]); steps(1); }
      const lx = f.x, ly = f.y; ev('pointerup', 1, q[0], q[1]); return { lx, ly }; };
    const mix = () => { for (let c = 0; c < 3; c++) { let q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(60); ev('pointerup', 1, q[0], q[1]); steps(30);
        let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const ax = X[b] - R * .15, ay = Y[b]; q = sc(ax, ay); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1);
        for (let k = 1; k <= 90; k++) { const tx = ax + R * Math.min(1, k / 60); q = [q[0] + (tx - f.x) * CAM.z, q[1] + (ay - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); } ev('pointerup', 1, q[0], q[1]); steps(60);
        rub(4); steps(30); }
      return rub(4.5); };
    const watch = p => { const x0 = globalC.xc, cum = +NAP.cum.toFixed(1); let napAt = -1, d = -1, cu = -1, cumAfter = -1, route = false, mv = 0;
      for (let i = 0; i < 600; i++) { steps(1); if (SILL.route) route = true; mv = Math.max(mv, Math.abs(globalC.xc - x0)); if (napAt < 0 && SLP.on) { napAt = +((i + 1) / 60).toFixed(2); d = +(Math.hypot(globalC.xc - p.lx, globalC.yc - p.ly) / R).toFixed(2); cu = +(Math.abs(globalC.xc - SILL.g.bx) / R).toFixed(2); cumAfter = +NAP.cum.toFixed(2); } }
      return { cum, napAt, d, cushion: cu, route, mv: +(mv / R).toFixed(2), cumAfter, asleep: SLP.on, naps: NAP.n, why: BRAIN.why, tr: +IMP.tr.toFixed(2) }; };
    const taps = () => { const o = { asleep0: SLP.on, k0: +SLP.k.toFixed(2), taps: [] };
      for (let n = 0; n < 3 && SLP.on; n++) { log.splice(0); const f0 = FLN.t0, q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(8); ev('pointerup', 1, q[0], q[1]); steps(90); o.taps.push({ on: SLP.on, slow: SLP.slow, startle: log.some(x => x[0] === 'voice.startle'), flinch: FLN.t0 !== f0 }); }
      o.woke = !SLP.on; o.slow = SLP.slow; return o; };
    const enough = () => { rub(35); steps(120); return rub(35); };
    try { fresh({}, .5); r.a = watch(mix());
      fresh({}, .5); r.b = watch(enough()); if (r.b.napAt > 0) steps(Math.max(0, Math.round((3 - (10 - r.b.napAt)) * 60))); r.c = taps();
      fresh({ nap: 0 }, .5); r.off = watch(enough()); r.err = ''; } catch (e) { r.err = String(e); }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    r.ok = !r.err && r.a.napAt < 0 && r.a.cum < SP.napPurr && r.b.cum >= SP.napPurr && r.b.napAt > 0 && r.b.napAt <= 10 && r.b.d <= .5 && !r.b.route && r.b.mv < .3 && r.b.cushion > .5 && r.b.cumAfter < .5
      && r.c.asleep0 && r.c.taps.length > 0 && r.c.taps.every(x => !x.startle && !x.flinch) && r.c.woke && r.c.slow && !(r.off.napAt > 0 && r.off.d <= .5);
    res.T76_nap = r; res.PASS.nap = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T77 v2.63 D3 怕的不從手裡滑走、搔癢不掙脫（holdScared、holdTickle；OVERNIGHT 第 7 項，手機照這條搬）。窗台、芋圓、真正的預設。
  // 擋：a 戒 0.65 以上（每次拉之前補回）連拉 10 次（先按住 0.2 秒；拉不開 1.2R 或沒抓到的那次不算、重抓，最多 25 次）：抓頂端往上拉到身體被拉開 1.2R（SB，不夠就再往上移，每秒 4.8R，比快扯慢；窗台上往右只拉得開 0.7R 就到畫面邊）、撐 2 秒：脫手 0 次、有抗議聲、放手後走開（ESC）5 次以上；
  //     b 撥（半徑 20 點、每秒 4 趟的來回，T39 搔癢同一個撥法）20 秒：手指一直抓著、沒有掙脫，搔癢佔一半以上、扭（SHK）和咯咯各 10 次以上，搔癢這邊不換成抗議聲；
  //     c 兩指往上下拉到畫面頂和底（T54 twoVert 同一個拉法，拉開超過 621 點）：照舊撕開；
  //     d 對照：holdScared 0 同樣拉 10 次會滑走（5 次以上）；holdTickle 0 同樣撥會掙脫（4 到 9 秒，先抗議）；兩顆都 0 兩指照樣撕開
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0 , bond: 0 };   // v2.63 D6：戒 0.65 拉著時前面幾格算溫柔、要先哄，關掉時（pullOff）拉開的數字會差一點；這一項量的是 D3，釘 bond 0
    const base = Math.floor(seeded(77)() * 1e6);   // 只跑幾項時 st.py 換掉 seeded(77) 的種子，每一輪不同
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd + base); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = .3; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; PAIR.tearT = -9; PAIR.over = 0; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: sd }); brainReset(); steps(60); };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const pulls = over => { fresh(over, 77); const o = { n: 0, slip: 0, never: 0, miss: 0, protest: 0, flee: 0, sbMin: 9, sbMax: 0, eyeSq: 0, w: 0, why: [] };
      for (let a = 0; a < 25 && o.n < 10; a++) { IMP.w = Math.max(IMP.w, .65); IMPD.w = IMP.w; let b = -1; for (const i of bnd) if (b < 0 || Y[i] < Y[b]) b = i; const ax = X[b], ay = Y[b] + R * .15; let q = sc(ax, ay); log.splice(0); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); steps(12);   // 先按住 0.2 秒不動：一按就以每秒 4.8R 移，會被判成摸（stroke），不是抓
        if (!f || fingers.get(1) !== f || f.mode !== 'grab') { o.miss++; ev('pointerup', 1, q[0], q[1]); steps(180); continue; }
        let ty = ay, hold = -1, slipped = false, sq = false;
        for (let k = 0; k < 600; k++) { const s0 = SB(f); if (hold < 0 && s0 >= 1.2) hold = k; if (hold >= 0 && k - hold >= 120) break; if (s0 < 1.2) ty -= R * .08;
          q = [q[0] + (ax - f.x) * CAM.z, Math.max(4, q[1] + (ty - f.y) * CAM.z)]; ev('pointermove', 1, q[0], q[1]); steps(1);
          if (fingers.get(1) !== f || f.mode !== 'grab') { slipped = true; o.why.push((fingers.get(1) === f ? f.mode : 'gone') + '@' + (k - Math.max(0, hold)) + (hold < 0 ? 'pre' : '')); break; }
          if (hold >= 0) { o.sbMin = Math.min(o.sbMin, SB(f)); if (EYE.mode === 'squeeze') sq = true; } o.sbMax = Math.max(o.sbMax, SB(f)); }
        if (hold < 0 && !slipped) { o.never++; ev('pointerup', 1, q[0], q[1]); steps(180); continue; }   // 10 秒內拉不開 1.2R（手指到畫面頂了）：這次不算，再抓一次
        o.n++; if (slipped) o.slip++; if (sq) o.eyeSq++; o.protest += log.filter(x => x[0] === 'voice.protest').length; o.w = +IMP.w.toFixed(2);
        ev('pointerup', 1, q[0], q[1]); let fl = ESC.on && !slipped; for (let j = 0; j < 180; j++) { steps(1); if (ESC.on && !slipped) fl = true; } if (fl) o.flee++; }
      o.sbMin = +o.sbMin.toFixed(2); o.sbMax = +o.sbMax.toFixed(2); return o; };
    const tickle = over => { fresh(over, 7701); log.splice(0); const q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1); steps(6); let th = 0, tk = 0, n = 0, sh = 0, sh0 = SHK.t0, free = -1, first = -1, sq = 0;
      for (let k = 0; k < 20 * 60; k++) { th += 2 * Math.PI * 4 * DT; ev('pointermove', 1, q[0] + 20 * Math.sin(th), q[1]); steps(1); const g = fingers.get(1); if (g !== f || f.mode !== 'grab') { free = +(k * DT).toFixed(2); break; } n++; if (tickOn()) { tk++; if (first < 0) first = +(k * DT).toFixed(2); } if (SHK.t0 !== sh0) { sh++; sh0 = SHK.t0; } if (EYE.mode === 'squeeze') sq++; }
      const vs = log.filter(x => String(x[0]).startsWith('voice.')).map(x => x[0].slice(6)), cnt = k => vs.filter(x => x === k).length;
      const o = { free, held: free < 0, first, tickFrac: +(tk / Math.max(1, n)).toFixed(2), shakes: sh, giggle: cnt('giggle'), protest: cnt('protest'), eyeSqFrac: +(sq / Math.max(1, n)).toFixed(2) }; ev('pointerup', 1, q[0], q[1]); steps(60); return o; };
    const tear = over => { fresh(over, 7702); steps(180); lastTouch = t; const cx = globalC.xc, cy = globalC.yc, t0 = t; let dMax = 0;
      const at = k => { const d = Math.min(1, k / 60); return [[1, cx, cy - R * .5 - (cy - R * .5 - 4) * d], [2, cx, cy + R * .3 + (H - 4 - cy - R * .3) * d]]; };
      let p = at(0); for (const d of p) ev('pointerdown', d[0], d[1], d[2]);
      for (let k = 1; k <= 150; k++) { p = at(k); for (const d of p) ev('pointermove', d[0], d[1], d[2]); steps(1); const a = fingers.get(1), b = fingers.get(2); if (a && b && a.mode === 'grab' && b.mode === 'grab') dMax = Math.max(dMax, Math.hypot(a.x - b.x, a.y - b.y)); }
      const torn = PAIR.tearT >= t0; for (const d of p) ev('pointerup', d[0], d[1], d[2]); steps(60); return { torn, dMax: Math.round(dMax), lim: Math.round(mat.pairMax * R * mat.tearK) }; };
    try { r.pull = pulls({}); r.tickle = tickle({}); r.tear = tear({});
      r.pullOff = pulls({ holdScared: 0 }); r.tickleOff = tickle({ holdTickle: 0 }); r.tearOff = tear({ holdScared: 0, holdTickle: 0 }); r.err = ''; } catch (e) { r.err = String(e); }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; PAIR.tearT = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    r.ok = !r.err && r.pull.n === 10 && r.pull.slip === 0 && r.pull.protest >= 1 && r.pull.flee >= 5
      && r.tickle.held && r.tickle.first >= 0 && r.tickle.tickFrac >= .5 && r.tickle.shakes >= 10 && r.tickle.giggle >= 10 && r.tickle.protest === 0
      && r.tear.torn && r.tear.dMax > 621
      && r.pullOff.slip >= 5 && r.tickleOff.free >= 4 && r.tickleOff.free <= 9 && r.tickleOff.protest >= 1 && r.tearOff.torn;
    res.T77_hold = r; res.PASS.hold = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T78 v2.63 C5 張望不朝窗台下面（lookNoDown；OVERNIGHT 第 8 項，手機照這條搬）。窗台、芋圓、真正的預設（PRE54）。
  // 「朝下」照 11-24 稽核 P4 的量法：張望偽足的方向 sin > 0.3（畫面 y 往下，正下方左右約 72 度內），那條伸出去會被窗台板擋住（P4 量到身體底緣 0 點）。
  // 擋：a 坐在窗台上、沒摸過，直接抽 255 次張望方向（pickDir）：lookNoDown 1 朝下 0 次；0 朝下 25% 到 55%（稽核放著 80 分鐘量到 104／255，41%）；兩邊抽完 255 次後下一個亂數一樣（1 不多抽、不少抽亂數）
  //     b 戒 0.9、最後摸在身體頂上（戒的往反方向探，就是朝下）：抽 255 次，1 朝下 0 次；0 朝下 30% 以上；兩邊下一個亂數一樣
  //     c 放著不碰 6 分鐘（大腦、心情照常，休息、睡、張望自己來），真的伸出去的張望偽足：1 朝下 0 次、張望 8 次以上；0 張望 8 次以上時朝下至少 1 次；1 跟 0 都零自交
  //     d 懸空（窗台關）時不折：lookNoDown 1 抽 255 次照樣有朝下（25% 以上）
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, pd0 = pickDir, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, lookTarget: 0 };   // v2.64：T78 量的是 v2.63 的張望方向，釘 lookTarget 0
    const base = Math.floor(seeded(78)() * 1e6);   // 只跑幾項時 st.py 換掉 seeded(78) 的種子，每一輪不同
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd + base); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = 0; IMPD.tr = 0; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; PAIR.tearT = -9; PAIR.over = 0; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: sd }); brainReset(); steps(60); };
    const down = a => Math.sin(a) > .3;
    const draw255 = (over, sd, prep) => { fresh(over, sd); if (prep) prep(); Math.random = seeded(sd + base + 1); let n = 0, cosR = 0, cosL = 0; for (let k = 0; k < 255; k++) { const a = pickDir(); if (down(a)) n++; if (Math.cos(a) > .3) cosR++; if (Math.cos(a) < -.3) cosL++; } return { sill: SILL.on, down: n, frac: +(n / 255).toFixed(2), right: cosR, left: cosL, next: Math.random() }; };
    const wary = () => { let b = -1; for (const i of bnd) if (b < 0 || Y[i] < Y[b]) b = i; IMP.has = true; IMP.lx = X[b]; IMP.ly = Y[b]; IMP.w = .9; IMPD.w = .9; IMP.tr = 0; };
    const idle = (over, sd) => { fresh(over, sd); const got = []; let pend = []; pickDir = () => { const a = pd0(); pend.push(a); return a; };
      const seen = new Set(), o = { looks: 0, down: 0, up: 0, side: 0, xs: 0, acts: {} };
      try { for (let k = 0; k < 60 * 360; k++) { steps(1); for (const s of LIFE.sns) if (!seen.has(s)) { seen.add(s); if (pend.includes(s.a)) { got.push(s.a); pend = pend.filter(x => x !== s.a); } } pend.length = 0;
          if (k % 30 === 0) { o.acts[BRAIN.act] = (o.acts[BRAIN.act] || 0) + 1; if (selfX()) o.xs++; } } }
      finally { pickDir = pd0; }
      o.looks = got.length; o.down = got.filter(down).length; o.up = got.filter(a => Math.sin(a) < -.3).length; o.side = o.looks - o.down - o.up; return o; };
    try { r.a = draw255({}, 78); r.aOff = draw255({ lookNoDown: 0 }, 78); r.b = draw255({}, 7801, wary); r.bOff = draw255({ lookNoDown: 0 }, 7801, wary); r.d = draw255({ sill: 0 }, 7802);
      r.c = idle({}, 7803); r.cOff = idle({ lookNoDown: 0 }, 7803); r.err = ''; } catch (e) { r.err = String(e); }
    pickDir = pd0;
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; impReset(); Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; PAIR.tearT = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    r.ok = !r.err && r.a.sill && r.a.down === 0 && r.aOff.frac >= .25 && r.aOff.frac <= .55 && r.a.next === r.aOff.next && r.a.left > 0 && r.a.right > 0
      && r.b.down === 0 && r.bOff.frac >= .3 && r.b.next === r.bOff.next
      && r.c.looks >= 8 && r.c.down === 0 && r.c.xs === 0 && r.cOff.xs === 0 && (r.cOff.looks < 8 || r.cOff.down >= 1)
      && !r.d.sill && r.d.frac >= .25;
    for (const k of ['a', 'aOff', 'b', 'bOff', 'd']) delete r[k].next;
    res.T78_lookNoDown = r; res.PASS.lookNoDown = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T79 v2.63 C6 揉牠反應輪流（rubVary；OVERNIGHT 第 9 項，手機照這條搬）。窗台、芋圓、真正的預設（PRE54），大腦、心情開著。
  // 溫柔的手（照 11-24 稽核 P1 的溫柔飼主）：在身體上揉 4 到 10 秒（半徑 0.22 到 0.37R、一圈 1.1 到 1.9 秒），放手，等 3 到 8 秒，再揉，10 分鐘。手的亂數自己一串，不動 Math.random。
  // 每一次揉（落指到下一次落指）記牠做了哪些事，照第一次出現排成一串：縮、嗯、∩、小跳、開心那一聲、多攤、朝手指靠、嘆氣、討摸。
  // 擋：a rubVary 1：揉 30 次以上、放手開心（rubHappy）20 次以上；最常見那一串 40% 以內；小跳（rubHappy 的）兩兩間隔都 ≥ 40 秒；四種都出現過；零自交
  //     b 叫聲洗牌袋：vbagPick 對 4 個檔抽 400 次，每 4 個一輪剛好各一次、前後兩個都不同（輪與輪交界也不同）；揉的那 10 分鐘傳給音效的檔號，同一種前後兩個同一顆 0 次（音效檔有載到才量）
  //     c 對照 rubVary 0：最常見那一串 60% 以上（改之前 5 分鐘 21 次 20 次同一串）、放手開心 20 次以上，九成以上開心那一聲和小跳一起（小跳在窗台半空、走路線時不跳）；不傳檔號（照舊亂抽）
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, sp0 = sfxPlay, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, tapBack: 0, slowBlink: 0 };   // v2.64 D8：頂回來、慢眨預設 1 之後這一項的數字會變（整份比對過），量的是舊規格，釘 0
    const base = Math.floor(seeded(79)() * 1e6);   // 只跑幾項時 st.py 換掉 seeded(79) 的種子，每一輪不同
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd + base); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = .3; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; PAIR.tearT = -9; PAIR.over = 0; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: sd }); brainReset(); RUBV.s = (sd + base) >>> 0; RUBV.n = {}; for (const k in VBAG) delete VBAG[k]; steps(60); };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const bufN = SFX && SFX.buf && SFX.buf['voice.happy'] ? SFX.buf['voice.happy'].length : 0;
    const owner = (over, sd) => { fresh(over, sd); const hr = seeded(sd + base + 7), W0 = innerWidth, H0 = innerHeight, cl = (v, a, b) => Math.max(a, Math.min(b, v));
      const takes = []; sfxPlay = (k, g, rr, tk) => { if (String(k).startsWith('voice.')) takes.push([k, tk]); sp0(k, g, rr); };
      const seqs = [], hopT = [], o = { rubs: 0, happy: 0, xs: 0, hops: 0, happyHop: 0 };
      let cur = null, li = log.length, fl0 = FLN.t0, eyeH = false, intro0 = false, sp = RUBV.spT, ln = E2.leanT, ht = RUBV.hopT, n0 = { ...RUBV.n };
      const tag = k => { if (cur && !cur.includes(k)) cur.push(k); };
      const step = () => { steps(1);
        for (; li < log.length; li++) { const k = String(log[li][0]); if (k === 'voice.mmm') tag('嗯'); else if (k === 'voice.happy') tag('開心'); else if (k === 'voice.ask') tag('討摸'); else if (k === 'fx.sigh') tag('嘆氣'); }
        if (FLN.t0 !== fl0) { fl0 = FLN.t0; tag('縮'); }
        const eh = EYE.mode === 'happy'; if (eh && !eyeH) tag('∩'); eyeH = eh;
        const io = INTRO.on && INTRO.mini; if (io && !intro0) { tag('小跳'); o.hops++; } intro0 = io;
        if (RUBV.spT !== sp) { sp = RUBV.spT; tag('多攤'); } if (E2.leanT !== ln) { ln = E2.leanT; tag('靠'); } if (RUBV.hopT !== ht) { ht = RUBV.hopT; hopT.push(+t.toFixed(2)); }
        if (t % 1 < DT && selfX()) o.xs++; };
      const T1 = 600;
      while (t < T1) {
        let x = globalC.xc + (hr() - .5) * .7 * R, y = globalC.yc + (-.15 + (hr() - .5) * .5) * R; for (let i = 0; i < 10 && !insideBody(x, y); i++) { x += (globalC.xc - x) * .25; y += (globalC.yc - y) * .25; }
        const [sx, sy] = sc(x, y), dur = 4 + 6 * hr(), rad = (.22 + .15 * hr()) * R * CAM.z, per = 1.1 + .8 * hr();
        if (cur) seqs.push(cur.join('、')); cur = []; o.rubs++;
        ev('pointerdown', 1, cl(sx, 4, W0 - 4), cl(sy, 4, H0 - 4));
        for (let i = 0; i < Math.round(dur * 60); i++) { const u = i / 60, k = Math.min(1, u / .25), an = 2 * Math.PI * u / per; ev('pointermove', 1, cl(sx + Math.sin(an) * rad * k, 4, W0 - 4), cl(sy + (1 - Math.cos(an)) * rad * .5 * k, 4, H0 - 4)); step(); }
        ev('pointerup', 1, sx, sy); const w = 3 + 5 * hr(); for (let i = 0; i < Math.round(w * 60); i++) step(); }
      if (cur) seqs.push(cur.join('、'));
      sfxPlay = sp0;
      const cnt = {}; for (const q of seqs) cnt[q] = (cnt[q] || 0) + 1; const top = Object.entries(cnt).sort((a, b) => b[1] - a[1]);
      o.kinds = top.length; o.top = top.slice(0, 4).map(([k, v]) => [k, v]); o.topFrac = +(top[0][1] / seqs.length).toFixed(2);
      o.happy = Object.values(RUBV.n).reduce((a, b) => a + b, 0) - Object.values(n0).reduce((a, b) => a + b, 0); o.n = { ...RUBV.n };
      o.happyV = seqs.filter(q => q.includes('開心')).length; o.happyHop = seqs.filter(q => q.includes('開心') && q.includes('小跳')).length;
      o.hopGaps = hopT.slice(1).map((x, i) => +(x - hopT[i]).toFixed(1)); o.hopGapMin = o.hopGaps.length ? Math.min(...o.hopGaps) : null;
      const vt = takes.filter(x => x[1] != null); o.takes = vt.length; o.takesAll = takes.length; let rep = 0; const lastK = {}; for (const [k, tk] of vt) { if (lastK[k] === tk) rep++; lastK[k] = tk; } o.takeRep = rep;
      return o; };
    const bag = () => { for (const k in VBAG) delete VBAG[k]; RUBV.s = 7919; const q = []; for (let i = 0; i < 400; i++) q.push(vbagPick('test', 4)); let rounds = 0, adj = 0; for (let i = 0; i < 400; i += 4) if (new Set(q.slice(i, i + 4)).size === 4) rounds++; for (let i = 1; i < 400; i++) if (q[i] === q[i - 1]) adj++; delete VBAG.test; return { rounds, adj, head: q.slice(0, 12).join('') }; };
    try { r.bufN = bufN; r.bag = bag(); r.on = owner({}, 79); r.off = owner({ rubVary: 0 }, 79); r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    sfxPlay = sp0;
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; impReset(); Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; PAIR.tearT = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    r.ok = !r.err && r.bag.rounds === 100 && r.bag.adj === 0
      && r.on.rubs >= 30 && r.on.happy >= 20 && r.on.topFrac <= .4 && (r.on.hopGapMin == null || r.on.hopGapMin >= 40) && ['hop', 'spread', 'lean', 'sigh'].every(k => r.on.n[k] > 0) && r.on.xs === 0
      && (!r.bufN || (r.on.takes > 0 && r.on.takeRep === 0))
      && r.off.rubs >= 30 && r.off.topFrac >= .6 && r.off.happyV >= 20 && r.off.happyHop >= r.off.happyV * .9 &&r.off.takes === 0;
    res.T79_rubVary = r; res.PASS.rubVary = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T80 v2.63 B6 拉回去再拉要有絲聲、按下去不蓋掉別的聲音（sndB6；OVERNIGHT 第 10 項，手機照這條搬）。藍底、黏土真正的預設（PRE54），音效接真的引擎（引擎抽的亂數用真的，不動測試的種子）。
  // a 同一抓：右邊緣往內 0.15R 抓、往右拉 2R（0.5 秒）、停、縮回 1R、停、再拉到 2R、停、放。每一段數細絲斷的聲音（sfxPlay pull）和音量，拉絲 loop（SFX.pullV.level）每段最大
  // b 一指拉到 2R 一直小幅來回（loop 在響），另一指按身體：按下前 10 格平均、按下後 30 格最小；揉也一樣（一指在身體上畫圈、另一指按）
  // c 引擎：排一顆放手的餘韻（tail）、一顆別的（像手機撕開的滴），按下去：開 tail 清掉、別的留著；關兩顆都清
  // 擋：a 開：第二次往外拉有絲斷聲、音量都 > 0、loop 那段 > 0（音效有載到才量 loop）；關：第二次往外拉 0 根（改之前）
  //     b 開：按下後拉絲、揉的 loop 最小值 > 0（音效有載到才量）；c 開 tail 0、別的 1，關 0、0
  { const clock = saveClock(), r = {}, sp0 = sfxPlay, P80 = { ...PRE54.clay, emo: 0, life2: 0, intro: 0, introSwim: 0, brain: 0 };
    let loaded = false;
    try { if (SFX && SFX.manifest) { SFX.init(); for (let i = 0; i < 120 && !loaded; i++) { loaded = ['pull.loop', 'rub.loop61', 'rub.loop'].every(k => SFX.buf[k] && SFX.buf[k].length > 0); if (!loaded) await new Promise(q => setTimeout(q, 50)); } } } catch (_) {}
    const eng = (k, g, rr, tk) => { log.push([k, +(+g).toFixed(3), +(+(rr || 1)).toFixed(3)]); if (!SFX || !SFX.ctx) return; const m = Math.random; Math.random = realRandom0; try { origPlay(k, g, rr, tk); } finally { Math.random = m; } };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P80, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; steps(60); if (SFX) SFX.pending = []; };
    const lv = () => [SFX && SFX.pullV ? SFX.pullV.level : 0, SFX && SFX.rubV ? SFX.rubV.level : 0];
    const edgeR = () => { let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; return sc(X[b] - R * .15, Y[b]); };
    const repull = over => { fresh(over, 80); const [sx, sy] = edgeR(), u = R * CAM.z, ph = []; let x = sx, li = log.length;
      ev('pointerdown', 1, sx, sy);
      const seg = (name, to, n) => { const o = { name, pulls: 0, g: [], loop: 0, stMax: 0, stMin: 9 }, x0 = x;
        for (let k = 1; k <= n; k++) { if (to != null) { x = x0 + (to - x0) * k / n; ev('pointermove', 1, x, sy); } steps(1);
          for (; li < log.length; li++) if (log[li][0] === 'pull') { o.pulls++; o.g.push(log[li][1]); }
          const f = fingers.get(1); if (f) { o.stMax = Math.max(o.stMax, +(f.stretch || 0).toFixed(2)); o.stMin = Math.min(o.stMin, +(f.stretch || 0).toFixed(2)); }
          o.loop = Math.max(o.loop, +lv()[0].toFixed(3)); }
        ph.push(o); };
      seg('out1', sx + 2 * u, 30); seg('hold1', null, 20); seg('back', sx + u, 30); seg('hold2', null, 20); seg('out2', sx + 2 * u, 30); seg('hold3', null, 20);
      ev('pointerup', 1, x, sy); steps(30); return ph; };
    // b：按下前 10 格、按下後 30 格
    const pressOver = (over, kind) => { fresh(over, 81); const u = R * CAM.z, o = { kind }; let x, y, k = 0;
      const move = () => { k++; if (kind === 'pull') { ev('pointermove', 1, x + Math.sin(k / 60 * 2 * Math.PI * 2) * .15 * u, y); } else { const a = k / 60 * 2 * Math.PI / 1.2; ev('pointermove', 1, x + Math.sin(a) * .3 * u, y + (1 - Math.cos(a)) * .3 * u); } steps(1); };
      if (kind === 'pull') { [x, y] = edgeR(); ev('pointerdown', 1, x, y); const x0 = x; for (let i = 1; i <= 30; i++) { ev('pointermove', 1, x0 + 2 * u * i / 30, y); steps(1); } x = x0 + 2 * u; }
      else { [x, y] = sc(globalC.xc, globalC.yc - R * .15); ev('pointerdown', 1, x, y); }
      for (let i = 0; i < 30; i++) move();
      const before = []; for (let i = 0; i < 10; i++) { move(); before.push(lv()[kind === 'pull' ? 0 : 1]); }
      const [px, py] = sc(globalC.xc - R * .35, globalC.yc + R * .2); ev('pointerdown', 2, px, py); o.press2 = fingers.get(2) ? fingers.get(2).mode : 'none';
      const after = []; for (let i = 0; i < 30; i++) { move(); after.push(lv()[kind === 'pull' ? 0 : 1]); }
      ev('pointerup', 2, px, py); ev('pointerup', 1, x, y); steps(30);
      o.before = +(before.reduce((a, b) => a + b, 0) / before.length).toFixed(3); o.afterMin = +Math.min(...after).toFixed(3); o.afterMean = +(after.reduce((a, b) => a + b, 0) / after.length).toFixed(3);
      return o; };
    const queue = b6 => { if (!SFX || !SFX.ctx) return null; SFX.pending = [{ at: 1e9, key: 'settle.bubble', p: { g: .1 }, tail: true }, { at: 1e9, key: 'fx.drip', p: { g: .1 } }]; const b0 = SFX.b6; SFX.b6 = b6; eng('press', .5); SFX.b6 = b0;
      const o = { tail: SFX.pending.filter(e => e.tail).length, other: SFX.pending.filter(e => !e.tail).length }; SFX.pending = []; return o; };
    try { sfxPlay = eng; r.loaded = loaded;
      r.on = repull({}); r.off = repull({ sndB6: 0 });
      r.bPull = pressOver({}, 'pull'); r.bRub = pressOver({}, 'rub'); r.bPullOff = pressOver({ sndB6: 0 }, 'pull'); r.bRubOff = pressOver({ sndB6: 0 }, 'rub');
      r.qOn = queue(1); r.qOff = queue(0); r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    sfxPlay = sp0; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); if (SFX) SFX.pending = [];
    log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    const seg = (a, n) => a ? a.find(o => o.name === n) : null, o2 = seg(r.on, 'out2'), f2 = seg(r.off, 'out2');
    r.ok = !r.err && !!o2 && o2.pulls >= 1 && o2.g.every(g => g > 0) && (!r.loaded || o2.loop > 0) && seg(r.on, 'out1').pulls >= 1 && !!f2 && f2.pulls === 0
      && (!r.loaded || (r.bPull.afterMin > 0 && r.bRub.afterMin > 0))
      && (!r.qOn || (r.qOn.tail === 0 && r.qOn.other === 1 && r.qOff.tail === 0 && r.qOff.other === 0));
    res.T80_sndB6 = r; res.PASS.sndB6 = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T81 v2.63 B2 按聲跟著力道、B5 嚇到開心不要啦按的聲音跟動作同一格（sndB2、sndB5；OVERNIGHT 第 11 項，手機照這條搬）。藍底、黏土真正的預設（PRE54，大腦關）。
  // a B2：身體中間按下去，發真的 PointerEvent 帶接觸大小或壓力：指尖輕點（半徑 18）對指腹重壓（半徑 42）；壓力 0.15 對 0.9（沒有面積）；都沒有（跟其他測試一樣）。記按下那一聲的音量（sfxPlay press）；sndB2 0 對照
  // b B5 同一格：每一格（一次 update）編號，聲音事件記在它出現的那一格（按下、放手在兩次 update 之間發，算下一格，就是畫面第一次畫出來那一格），動作也記第一次看得到的那一格：
  //   按：press 聲、手指第一次按下去（f.pressOn）；嚇到：睡著時抓下去：startle 聲、縮（FLN.t0 換）；開心：摸一摸放手（rubVary 0，摸夠了、舒服設好，0.3 秒一聲的門清掉）：happy 聲、挺高（MOOD.happyT 換）；
  //   不要啦：右邊緣往右拉 3R 撐住（rough、slide 關）：protest 聲、扯到想逃（MOOD.strain 過 0.5）
  // c B5 音檔開頭：四種（voice.startle、voice.happy、voice.protest、press.wet）每個檔開頭到 −6 dB 的毫秒、最大聲的毫秒，切前、切後（音效有載到才量）
  // 擋：a 開：重 ≥ 輕 × 1.5（面積、壓力兩條都是）、都沒有是 0.7；關：全部 0.7
  //     b 開：四種都差 0 格；關：嚇到的聲音比縮早 2 格以上（改之前先叫、0.05 秒後才縮）
  //     c 開：切後每個檔到 −6 dB 都在 30 毫秒內（音效有載到才量）
  { const clock = saveClock(), r = {}, P81 = { ...PRE54.clay, intro: 0, introSwim: 0, brain: 0, rubVary: 0 }, I0 = { tr: IMP.tr, w: IMP.w };
    const B5KEYS = ['voice.startle', 'voice.happy', 'voice.protest', 'press.wet'];
    let loaded = false;
    try { if (SFX && SFX.manifest) { SFX.init(); for (let i = 0; i < 120 && !loaded; i++) { loaded = B5KEYS.every(k => SFX.buf[k] && SFX.buf[k].length > 0 && SFX.bufB5 && SFX.bufB5[k] && SFX.bufB5[k].length === SFX.buf[k].length); if (!loaded) await new Promise(q => setTimeout(q, 50)); } } } catch (_) {}
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const pe = (type, id, x, y, o) => cv.dispatchEvent(new PointerEvent(type, { pointerId: id, clientX: x, clientY: y, bubbles: true, pointerType: 'touch', isPrimary: id === 1, ...(o || {}) }));
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P81, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = .3; IMP.w = 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; FLN.say = null; GREET.st = ''; GREET.until = -9; EYE.user = -9; steps(60); };
    // 每一格編號；聲音事件記在出現的那一格
    let FN = 0, li = 0; const EVS = []; const stepF = () => { steps(1); FN++; for (; li < log.length; li++) EVS.push([FN, log[li][0], log[li][1]]); };
    const start = () => { FN = 0; li = log.length; EVS.length = 0; };
    const first = k => { const e = EVS.find(x => x[1] === k); return e ? e[0] : null; };
    const tapG = (over, o) => { fresh(over, 81); const [x, y] = sc(globalC.xc, globalC.yc), n0 = log.length; pe('pointerdown', 1, x, y, o); const e = log.slice(n0).find(q => q[0] === 'press'); steps(6); pe('pointerup', 1, x, y, o); steps(30); return e ? e[1] : null; };
    const b2 = over => ({ light: tapG(over, { width: 36, height: 36 }), heavy: tapG(over, { width: 84, height: 84 }), pLight: tapG(over, { pressure: .15 }), pHeavy: tapG(over, { pressure: .9 }), none: tapG(over, {}) });
    const sync = over => { const o = {}; let act;
      // 按
      fresh(over, 82); start(); { const [x, y] = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); act = null; for (let k = 0; k < 20; k++) { stepF(); const f = fingers.get(1); if (act == null && f && f.pressOn) act = FN; } ev('pointerup', 1, x, y); steps(30); o.press = { snd: first('press'), act }; }
      // 嚇到：睡著時抓下去
      fresh(over, 83); steps(60); SLP.on = true; LIFE.st = 'sleep'; SLP.k = 1; IMP.tr = 0; IMPD.tr = 0; start(); { const f0 = FLN.t0, [x, y] = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); act = null; for (let k = 0; k < 30; k++) { stepF(); if (act == null && FLN.t0 !== f0) act = FN; } ev('pointerup', 1, x, y); steps(30); o.startle = { snd: first('voice.startle'), act, woke: !SLP.on }; }
      // 開心：摸一摸放手（rubHappy：摸夠了 gentleT > 1、舒服 MOOD.c > 0.35）
      fresh(over, 84); { const [x, y] = sc(globalC.xc, globalC.yc), u = R * CAM.z; ev('pointerdown', 1, x, y); for (let k = 1; k <= 90; k++) { const a = 2 * Math.PI * k / 90; ev('pointermove', 1, x + Math.sin(a) * .2 * u, y + (1 - Math.cos(a)) * .1 * u); steps(1); }
        const f = fingers.get(1); if (f) f.gentleT = Math.max(f.gentleT || 0, 2); MOOD.c = Math.max(MOOD.c, .6); voice.last = -9; start(); const h0 = MOOD.happyT; ev('pointerup', 1, x, y); act = null; for (let k = 0; k < 30; k++) { stepF(); if (act == null && MOOD.happyT !== h0) act = FN; } o.happy = { snd: first('voice.happy'), act }; }
      // 不要啦：右邊緣往右拉 3R 撐住，扯到想逃（rough、slide 關：扯到想逃要猛扯、拖著走會一直跟上，這裡只量聲音和動作是不是同一格）
      fresh({ rough: 0, slide: 0, ...over }, 85); { let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const [x, y] = sc(X[b] - R * .15, Y[b]), u = R * CAM.z; ev('pointerdown', 1, x, y); steps(12); start(); act = null; let xx = x;
        for (let k = 0; k < 300; k++) { if (k < 45) { xx = x + 3 * u * (k + 1) / 45; ev('pointermove', 1, xx, y); } stepF(); if (act == null && MOOD.strain > .5) act = FN; if (act != null && first('voice.protest') != null) break; }
        ev('pointerup', 1, xx, y); steps(30); o.protest = { snd: first('voice.protest'), act }; }
      for (const k in o) o[k].d = o[k].snd != null && o[k].act != null ? o[k].snd - o[k].act : null;
      return o; };
    const lead = () => { if (!loaded || !SFX.onsetOf) return null; const o = {}; for (const k of B5KEYS) { const a = SFX.buf[k].map(SFX.onsetOf), b = SFX.bufB5[k].map(SFX.onsetOf); o[k] = { before: a.map(q => q.on), peak: a.map(q => q.pk), after: b.map(q => q.on), peakAfter: b.map(q => q.pk) }; } return o; };
    try { r.loaded = loaded; r.b2 = b2({}); r.b2Off = b2({ sndB2: 0 }); r.on = sync({}); r.off = sync({ sndB5: 0 }); r.lead = lead(); r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FLN.say = null;
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    const B = r.b2 || {}, F = r.b2Off || {}, on = r.on || {};
    r.ok = !r.err && B.heavy >= B.light * 1.5 && B.pHeavy >= B.pLight * 1.5 && B.none === .7 && ['light', 'heavy', 'pLight', 'pHeavy', 'none'].every(k => F[k] === .7)
      && ['press', 'startle', 'happy', 'protest'].every(k => on[k] && on[k].d === 0) && !!r.off && r.off.startle.d <= -2
      && (!r.lead || B5KEYS.every(k => r.lead[k].after.every(ms => ms <= 30)));
    res.T81_sndB2B5 = r; res.PASS.sndB2B5 = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T82 v2.63 D4 牠縮那一下有一小聲和一下輕震（flinchFx；OVERNIGHT 第 12 項，手機照這條搬）。藍底、黏土真正的預設（PRE54，大腦關）。網頁沒有震動，震動看 hapEv 的紀錄（HAP.log），手機在同一個時機打真的。
  // 每一格（一次 update）編號，聲音（sfxPlay）和震動（HAP.log）記在它出現的那一格，縮記 FLN.t0 換掉的那一格。
  // a 點一下按著，縮了之後 0.1 秒放手：縮那格有 flinch 聲、有震；放手後沒有 release（「噗」不重複）。縮之後 0.5 秒才放：release 照響
  // b 快點（按 0.1 秒就放，通常比縮早）：「噗」加起來只有一聲，縮那格照樣震
  // c 連點 12 下、每下隔 4 秒（每下按到縮了再 0.1 秒放）：每一下縮多大、有沒有聲、有沒有震。縮變小、事件跟著少或停
  // d flinchFx 0：沒有 flinch 聲、沒有震，放手的 release 照舊
  // 擋：a 開：同格、放手 0 聲 release、0.5 秒放有 release；b 開：噗 ≤ 1、縮那格有震；c 開：後 4 下的事件數 ≤ 前 4 下、後 4 下縮的平均比前 4 下小、最後一下的事件 ≤ 第一下；d：flinch 聲 0、震 0、release 有
  { const clock = saveClock(), r = {}, P82 = { ...PRE54.clay, intro: 0, introSwim: 0, brain: 0, tapBack: 0, slowBlink: 0 }, I0 = { tr: IMP.tr, w: IMP.w };   // v2.64 D8：頂回來、慢眨預設 1 之後這一項的數字會變（整份比對過），量的是舊規格，釘 0
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P82, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = .3; IMP.w = 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; FLN.say = null; GREET.st = ''; GREET.until = -9; EYE.user = -9; steps(60); };
    let FN = 0, li = 0, hi = 0; const EVS = [];
    const stepF = () => { steps(1); FN++; for (; li < log.length; li++) EVS.push([FN, log[li][0], log[li][1]]); for (; hi < HAP.log.length; hi++) EVS.push([FN, 'hap.' + HAP.log[hi][0], HAP.log[hi][1]]); };
    const start = () => { FN = 0; li = log.length; hi = HAP.log.length; EVS.length = 0; };
    const at = (k, f) => EVS.filter(e => e[1] === k && (f == null || e[0] === f));
    // 按下去，等到縮（最多 0.5 秒），縮了之後 holdAfter 格放手；pre 格先按著（快點：按 pre 格就放、不等縮）
    const tap = (quick, holdAfter) => { const [x, y] = sc(globalC.xc, globalC.yc), f0 = FLN.t0; ev('pointerdown', 1, x, y); let fl = null, upF = null;
      for (let k = 0; k < 60; k++) { stepF(); if (fl == null && FLN.t0 !== f0) fl = FN; if (upF == null && ((quick && FN >= 6) || (!quick && fl != null && FN - fl >= holdAfter))) { ev('pointerup', 1, x, y); upF = FN; } if (upF != null && fl != null && FN - Math.max(upF, fl) >= 24) break; }
      if (upF == null) { ev('pointerup', 1, x, y); upF = FN; } for (let k = 0; k < 24; k++) stepF();
      return { fl, up: upF, amp: fl != null ? +FLN.amp.toFixed(4) : 0, snd: at('flinch').map(e => e[0]), hap: at('hap.flinch').map(e => e[0]), hapG: at('hap.flinch').map(e => e[2]), rel: at('release').length, relF: at('release').map(e => e[0]) }; };
    const one = (over, quick, holdAfter, sd) => { fresh(over, sd); start(); const o = tap(quick, holdAfter); o.same = o.fl != null && o.snd.length === 1 && o.snd[0] === o.fl && o.hap.length === 1 && o.hap[0] === o.fl; o.poof = o.rel + o.snd.length; return o; };
    const series = (over) => { fresh(over, 86); const o = [];
      for (let n = 0; n < 12; n++) { start(); const q = tap(false, 6); o.push({ amp: q.amp, ev: q.snd.length + q.hap.length, snd: q.snd.length, hap: q.hap.length, rel: q.rel }); for (let k = 0; k < 240 - FN; k++) steps(1); }
      return o; };
    try { HAP.log = [];
      r.a = one({}, false, 6, 82); r.aLate = one({}, false, 30, 82); r.b = one({}, true, 0, 83); r.bOff = one({ flinchFx: 0 }, true, 0, 83); r.d = one({ flinchFx: 0 }, false, 6, 82);
      r.c = series({}); r.cOff = series({ flinchFx: 0 }); r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    HAP.log = null; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FLN.say = null;
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    const c = r.c || [], sum = (a, k) => a.reduce((s, q) => s + q[k], 0), first4 = c.slice(0, 4), last4 = c.slice(-4);
    r.cSum = c.length ? { evFirst4: sum(first4, 'ev'), evLast4: sum(last4, 'ev'), ampFirst4: +(sum(first4, 'amp') / 4).toFixed(4), ampLast4: +(sum(last4, 'amp') / 4).toFixed(4) } : null;
    r.ok = !r.err && r.a.same && r.a.rel === 0 && r.aLate.same && r.aLate.rel === 1 && r.b.poof <= 1 && r.b.hap.length === 1 && r.b.hap[0] === r.b.fl
      && !!r.cSum && r.cSum.evLast4 <= r.cSum.evFirst4 && r.cSum.ampLast4 < r.cSum.ampFirst4 && c[11].ev <= c[0].ev && c[0].ev === 2
      && r.d.snd.length === 0 && r.d.hap.length === 0 && r.d.rel === 1 && r.bOff.snd.length === 0 && r.bOff.hap.length === 0 && r.bOff.rel === 1
      && (r.cOff || []).every(q => q.ev === 0);
    res.T82_flinchFx = r; res.PASS.flinchFx = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T83 v2.63 B1 拉、B3 慢慢拉 0.4 秒內就聽得到、摸得到（pullFx；OVERNIGHT 第 13 項，手機照這條搬）。藍底、黏土真正的預設（PRE54，大腦關），音效接真的引擎（有載到才量 loop 的真音量）。
  // 網頁沒有震動：手機的連續震動照 hapContStep 算（拉力、呼嚕、開關遲滯，跟 SlimeController、SlimeHaptics 同一套），開了記 hapEv('pull')。拉絲聲看引擎這一格要多大（SFX.pullT），載到了也看 loop 真的音量（SFX.pullV.level）。
  // a 身體中間抓下去，往右每秒 0.5R 拉 4 秒：從按下到第一個震動事件幾秒、拉絲聲 > 0 幾秒；pullFx 0 對照
  // b 快拉每秒 4R 拉 1 秒：一樣量；第 0.5 秒的震動強度開關兩邊差不多（底 0.08 比原本的小，原本起來之後就是原本的）
  // c 揉（只記錄）：抓著畫半徑 0.3R 的圈、每秒 1R、3 秒：震動開了幾次、開著幾秒、拉絲聲最大多少
  // 擋：a 開：震動 ≤ 0.4 秒、拉絲聲 ≤ 0.4 秒（有載到時 loop 音量也是）；關：兩個都 > 0.4 秒或沒來。b 開不比關晚、0.5 秒時強度差 < 0.01（量到 0.1824 對 0.1816：底沒參與，差的是同一頁先後跑留下的狀態，跟 T66、T67 一樣）
  { const clock = saveClock(), r = {}, P83 = { ...PRE54.clay, intro: 0, introSwim: 0, brain: 0 }, I0 = { tr: IMP.tr, w: IMP.w };
    let loaded = false;
    try { if (SFX && SFX.manifest) { SFX.init(); for (let i = 0; i < 120 && !loaded; i++) { loaded = ['pull.loop'].every(k => SFX.buf[k] && SFX.buf[k].length > 0); if (!loaded) await new Promise(q => setTimeout(q, 50)); } } } catch (_) {}
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P83, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = .3; IMP.w = 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; GREET.st = ''; GREET.until = -9; EYE.user = -9; steps(60); };
    const drive = (over, path, sec, sd) => { fresh(over, sd); const [x0, y0] = sc(globalC.xc, globalC.yc), u = R * CAM.z, t0 = t, h0 = HAP.log.length; ev('pointerdown', 1, x0, y0);
      const o = { hap: null, snd: null, loop: null, lv05: null, on: 0, onT: 0, sndMax: 0, stAt: null }; let x = x0, y = y0;
      for (let k = 1; k <= Math.round(sec * 60); k++) { [x, y] = path(k / 60, x0, y0, u); ev('pointermove', 1, x, y); steps(1); const tt = +(t - t0).toFixed(4);
        const hs = HAP.log.slice(h0).filter(e => e[0] === 'pull'); if (o.hap == null && hs.length) o.hap = +(hs[0][2] - t0).toFixed(4);
        if (o.snd == null && (SFX && SFX.pullT > 0)) o.snd = tt; if (o.loop == null && SFX && SFX.pullV && SFX.pullV.level > 0) o.loop = tt;
        if (k === 30) o.lv05 = +(HPC.lv || 0).toFixed(4); if (HPC.on) o.onT += 1 / 60; o.sndMax = Math.max(o.sndMax, SFX && SFX.pullT || 0); const f = fingers.get(1); if (o.stAt == null && f && f.stretch > .41) o.stAt = tt; }
      o.on = HAP.log.slice(h0).filter(e => e[0] === 'pull').length; o.onT = +o.onT.toFixed(2); o.sndMax = +o.sndMax.toFixed(3);
      ev('pointerup', 1, x, y); steps(40); return o; };
    const line = v => (s, x0, y0, u) => [x0 + v * u * s, y0];
    const circ = (s, x0, y0, u) => { const a = s / .3; return [x0 + .3 * u * Math.sin(a), y0 + .3 * u * (1 - Math.cos(a))]; };
    try { HAP.log = []; r.loaded = loaded;
      r.slow = drive({}, line(.5), 4, 83); r.slowOff = drive({ pullFx: 0 }, line(.5), 4, 83);
      r.fast = drive({}, line(4), 1, 84); r.fastOff = drive({ pullFx: 0 }, line(4), 1, 84);
      r.rub = drive({}, circ, 3, 85); r.rubOff = drive({ pullFx: 0 }, circ, 3, 85); r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    HAP.log = null; for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    const late = v => v == null || v > .4;
    r.ok = !r.err && r.slow.hap != null && r.slow.hap <= .4 && r.slow.snd != null && r.slow.snd <= .4 && (!r.loaded || (r.slow.loop != null && r.slow.loop <= .4))
      && late(r.slowOff.hap) && late(r.slowOff.snd)
      && r.fast.hap != null && r.fastOff.hap != null && r.fast.hap <= r.fastOff.hap && Math.abs(r.fast.lv05 - r.fastOff.lv05) < .01;
    res.T83_pullFx = r; res.PASS.pullFx = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T84 v2.63 D6 怕的要哄、熟要有得長（bond；OVERNIGHT 第 14 項，手機照這條搬）。藍底、黏土真正的預設（PRE54，大腦、睡覺、手邊睡、來找你關：等三分鐘那段不准睡著、不准自己游過來）。
  // a 戒 0.9、交情 0：按著不動 3 秒放手：放手那格不呼嚕（PURR < 0.05）、舒服 ≤ 0.35（放手不會開心）、3 秒內沒有嘆氣；按 6 秒：嘆氣在 2.9 到 3.3 秒、呼嚕（PURR > 0.3）和「嗯～」都在嘆氣之後、6 秒時在呼嚕
  // b 戒 0.9，放著不碰 3 分鐘（戒退一半到 0.45 左右），同樣按 3 秒：照常呼嚕（PURR > 0.3）、沒有嘆氣
  // c bond 0、戒 0.9 按 3 秒：照舊開心（PURR > 0.3）、沒有嘆氣（改之前的樣子）
  // d 交情 1、熟 0.3、不戒：抓身體中間右邊 0.5R，第一下縮 0、朝手指靠（E2.leanT 在縮那格、方向朝右、整團往右挪過）；放手 1 秒內再抓：照常縮（不是第一下）；交情 0 第一下照常縮；bond 0 交情 1 照常縮
  // e 熟 1、交情 0，按著不動 60 秒：交情在 0.0085 到 0.0105（每分鐘 0.01）；熟 0.3 按 3 秒：交情還是 0（熟沒滿不長）
  // f 交情 0.5：連點三下（戒漲、熟扣）、快扯一下放手：交情一點都沒少
  // g 存檔：bond 1 交情 0.42 存進 nienie.imp 的 bd；bond 0（沒有交情）存的 JSON 沒有 bd、跟改之前一樣。量完原樣還回去
  // h 畫面文字（document.body.innerText）沒有交情、天數、等級、第幾天、Lv、幾級
  { const clock = saveClock(), r = {}, P84 = { ...PRE54.clay, intro: 0, introSwim: 0, brain: 0, sleep: 0, nap: 0, e4: 0, lookTarget: 0 }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = BOND.v;
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd, tr, w, bd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P84, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = tr; IMP.w = w; BOND.v = bd; IMPD.tr = IMP.tr; IMPD.w = w; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; FLN.say = null; GREET.st = ''; GREET.until = -9; EYE.user = -9; steps(60); log.splice(0); };
    // 按著不動 sec 秒：每格記 PURR、舒服；聲音事件記在第幾秒
    const hold = (sec, dx) => { log.splice(0); const [x, y] = sc(globalC.xc + (dx || 0) * R, globalC.yc), t0 = t, s0 = SOO.sighT, o = { sigh: null, sighLog: false, purr: null, mmm: null, happy: null, w0: +IMP.w.toFixed(3) }; ev('pointerdown', 1, x, y);
      for (let k = 1; k <= Math.round(sec * 60); k++) { steps(1); const tt = +(t - t0).toFixed(4);
        const ls = log.splice(0); if (o.sigh == null && SOO.sighT !== s0) { o.sigh = tt; o.sighLog = ls.some(e => e[0] === 'fx.sigh'); }
        for (const e of ls) { if (e[0] === 'voice.mmm' && o.mmm == null) o.mmm = tt; if (e[0] === 'voice.happy' && o.happy == null) o.happy = tt; }
        if (o.purr == null && PURR > .3) o.purr = tt; }
      o.PURR = +PURR.toFixed(3); o.c = +MOOD.c.toFixed(3); o.w = +IMP.w.toFixed(3); ev('pointerup', 1, x, y); steps(1); log.splice(0); return o; };
    // 抓下去等到縮（最多 0.5 秒），記縮多大、那格有沒有排朝手指靠、0.6 秒內整團往手指挪了多少（E2.leanO 最大）
    const touch = (dx) => { const [x, y] = sc(globalC.xc + dx * R, globalC.yc), f0 = FLN.t0; ev('pointerdown', 1, x, y); const o = { amp: null, lean: false, leanO: 0, dir: 0 };
      for (let k = 0; k < 36; k++) { steps(1); if (o.amp == null && FLN.t0 !== f0) { o.amp = +FLN.amp.toFixed(4); o.lean = Math.abs(E2.leanT - t) < 1e-9 && E2.leanS === 1; o.dir = +Math.cos(E2.leanA).toFixed(3); } o.leanO = Math.max(o.leanO, (E2.leanO || 0) / R); }
      o.leanO = +o.leanO.toFixed(3); ev('pointerup', 1, x, y); steps(1); log.splice(0); return o; };
    const taps3 = () => { const [x, y] = sc(globalC.xc, globalC.yc); for (let i = 0; i < 3; i++) { ev('pointerdown', 1, x, y); steps(4); ev('pointerup', 1, x, y); steps(12); } steps(60); };
    const yank = () => { const [x, y] = sc(globalC.xc, globalC.yc), u = R * CAM.z; ev('pointerdown', 1, x, y); steps(3); for (let k = 1; k <= 20; k++) { ev('pointermove', 1, x + 8 * u * k / 60, y); steps(1); } steps(30); ev('pointerup', 1, x + 8 * u * 20 / 60, y); steps(120); };
    try {
      fresh({}, 84, .3, .9, 0); r.a3 = hold(3);
      fresh({}, 84, .3, .9, 0); r.a6 = hold(6);
      fresh({}, 84, .3, .9, 0); steps(180 * 60); r.b = hold(3);
      fresh({ bond: 0 }, 84, .3, .9, 0); r.c = hold(3);
      fresh({}, 85, .3, 0, 1); r.d1 = touch(.5); steps(60); r.d2 = touch(.5);
      fresh({}, 85, .3, 0, 0); r.d0 = touch(.5);
      fresh({ bond: 0 }, 85, .3, 0, 1); r.dOff = touch(.5);
      fresh({}, 86, 1, 0, 0); hold(60); r.e60 = +BOND.v.toFixed(5);
      fresh({}, 86, .3, 0, 0); hold(3); r.eLow = BOND.v;
      fresh({}, 87, .8, 0, .5); taps3(); r.fTap = { bd: BOND.v, w: +IMP.w.toFixed(3), tr: +IMP.tr.toFixed(3) }; yank(); r.fYank = { bd: BOND.v, w: +IMP.w.toFixed(3), tr: +IMP.tr.toFixed(3) };
      { const LS0 = localStorage.getItem('nienie.imp'), id = SLIMES[SLIME].id, BS = { ...BONDS }, mat0 = mat;
        try { for (const k in BONDS) delete BONDS[k]; mat = { ...P84, trKeep: 1 }; BOND.v = .42; IMPSV.noSave = false; IMPSV.last = ''; impSave(true); const o = JSON.parse(localStorage.getItem('nienie.imp') || 'null'); r.gOn = o && o.bd ? o.bd[id] : null;
          for (const k in BONDS) delete BONDS[k]; mat = { ...P84, trKeep: 1, bond: 0 }; IMPSV.last = ''; impSave(true); const o2 = JSON.parse(localStorage.getItem('nienie.imp') || 'null'); r.gOff = o2 ? Object.keys(o2).join(',') : null;
          for (const k in BONDS) delete BONDS[k]; localStorage.setItem('nienie.imp', JSON.stringify({ v: 1, tr: { [id]: .5 }, bd: { [id]: .37 } })); BOND.v = 0; impLoad(); r.gLoad = BONDS[id];
        } finally { IMPSV.noSave = true; IMPSV.last = ''; if (LS0 === null) localStorage.removeItem('nienie.imp'); else localStorage.setItem('nienie.imp', LS0); for (const k in BONDS) delete BONDS[k]; Object.assign(BONDS, BS); mat = mat0; } }
      { const txt = document.body.innerText || ''; r.hHits = (txt.match(/交情|天數|等級|第\s*\d+\s*天|Lv\.?\s*\d|\d+\s*級/g) || []); r.hLen = txt.length; }
      r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FLN.say = null;
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); BOND.v = B0; restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    const okA = !r.err && r.a3.PURR < .05 && r.a3.c <= .35 && r.a3.sigh == null && r.a3.happy == null && r.a3.mmm == null
      && r.a6.sigh != null && r.a6.sighLog && r.a6.sigh >= 2.9 && r.a6.sigh <= 3.3 && r.a6.purr != null && r.a6.purr > r.a6.sigh && (r.a6.mmm == null || r.a6.mmm > r.a6.sigh) && r.a6.PURR > .3;
    const okB = !r.err && r.b.w0 < .5 && r.b.PURR > .3 && r.b.sigh == null, okC = !r.err && r.c.PURR > .3 && r.c.sigh == null;
    const okD = !r.err && r.d1.amp === 0 && r.d1.lean && r.d1.dir > .9 && r.d1.leanO > 0 && r.d2.amp > 0 && r.d0.amp > 0 && r.dOff.amp > 0;
    const okE = !r.err && r.e60 >= .0085 && r.e60 <= .0105 && r.eLow === 0, okF = !r.err && r.fTap.bd === .5 && r.fYank.bd === .5;
    const okG = !r.err && r.gOn === .42 && r.gOff === 'v,tr' && r.gLoad === .37, okH = !r.err && r.hHits.length === 0 && r.hLen > 0;
    r.part = { a: okA, b: okB, c: okC, d: okD, e: okE, f: okF, g: okG, h: okH }; r.ok = okA && okB && okC && okD && okE && okF && okG && okH;
    res.T84_bond = r; res.PASS.bond = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T85 v2.63 B9 聲音跟著手走：動一點一顆（sndGrain；OVERNIGHT 第 15 項，手機照這條搬）。藍底、黏土真正的預設（PRE54，大腦關）。顆粒看 sfxPlay('grain') 的紀錄，每一格編號。
  // a 抓著身體中間畫半徑 0.3R 的圈，每秒 0.5R 揉 4 秒、停住按著 1 秒：揉的時候每秒幾顆、停了之後第幾格還有顆粒；每秒 1R 同樣（顆粒數約兩倍、平均音量大一點）；每秒 8R（每秒不超過 20 顆；60 格一秒時實際 15 顆）
  // b sndGrain 0 同樣每秒 0.5R：沒有顆粒；接著 0、1 各再揉一次，其他聲音逐筆一樣（顆粒不碰別的聲音、不抽 Math.random）
  // c 循環聲：開著時頁面給引擎 0.5（揉、拉循環聲一半），關著 1
  // 擋：a 0.5R 有顆粒、停手 0.1 秒（6 格）之後 0 顆；1R 對 0.5R 的顆粒數比 1.6 到 2.4、平均音量 2R 比較大；8R 每秒 ≤ 20；b 0 顆、其他聲音逐筆一樣；c 0.5 和 1
  { const clock = saveClock(), r = {}, P85 = { ...PRE54.clay, intro: 0, introSwim: 0, brain: 0, sndGrain: 1 }, I0 = { tr: IMP.tr, w: IMP.w };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd); mat = { ...P85, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = .3; IMP.w = 0; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; FLN.say = null; GREET.st = ''; GREET.until = -9; EYE.user = -9; GR.s = 20261126; steps(60); log.splice(0); };
    const rub = (over, v, sd) => { fresh(over, sd); const [x0, y0] = sc(globalC.xc, globalC.yc), u = R * CAM.z, rr = .3, EV = []; let x = x0, y = y0; ev('pointerdown', 1, x0, y0);
      const n1 = 240, n2 = 60; let gr = null;
      for (let k = 1; k <= n1 + n2; k++) { if (k <= n1) { const a = v * (k / 60) / rr; x = x0 + rr * u * Math.sin(a); y = y0 + rr * u * (1 - Math.cos(a)); ev('pointermove', 1, x, y); } steps(1); if (k === 2) gr = SFX ? SFX.gr : null; for (const e of log.splice(0)) EV.push([k, e[0], e[1]]); }
      ev('pointerup', 1, x, y); steps(30); for (const e of log.splice(0)) EV.push([n1 + n2 + 1, e[0], e[1]]);
      const G = EV.filter(e => e[1] === 'grain'), moving = G.filter(e => e[0] <= n1), after = G.filter(e => e[0] > n1 + 6 && e[0] <= n1 + n2);
      return { n: moving.length, perS: +(moving.length / 4).toFixed(2), gMean: moving.length ? +(moving.reduce((s, e) => s + e[2], 0) / moving.length).toFixed(3) : 0, stop6: G.filter(e => e[0] > n1 && e[0] <= n1 + 6).length, after: after.length, gr, other: EV.filter(e => e[1] !== 'grain' && e[0] <= n1 + n2).map(e => e.join(':')) }; };   // 放手那格之後不比：揉完開心那一下輪流（rubVary 的洗牌袋跨次留著），每次本來就不同
    try {
      r.v1 = rub({}, .5, 85); r.v2 = rub({}, 1, 85); r.v8 = rub({}, 8, 85); r.off = rub({ sndGrain: 0 }, .5, 85); r.off2 = rub({ sndGrain: 0 }, .5, 85); r.on2 = rub({}, .5, 85);
      r.ratio = r.v1.n ? +(r.v2.n / r.v1.n).toFixed(2) : 0; r.sameOther = JSON.stringify(r.off2.other) === JSON.stringify(r.on2.other); r.nOther = r.on2.other.length;   // 第一次揉接在前一項後面，前面留的狀態不同；比 off2、on2（同樣接在一次 off 後面）
      if (!r.sameOther) r.otherDiff = [r.off2.other.join(' '), r.on2.other.join(' ')];
      for (const k of ['v1', 'v2', 'v8', 'off', 'off2', 'on2']) delete r[k].other;
      r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FLN.say = null;
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    r.ok = !r.err && r.v1.n > 0 && r.v1.after === 0 && r.v2.after === 0 && r.ratio >= 1.6 && r.ratio <= 2.4 && r.v2.gMean > r.v1.gMean && r.v8.perS <= 20
      && r.off.n === 0 && r.sameOther && (r.v1.gr == null || (r.v1.gr === .5 && r.off.gr === 1));
    res.T85_sndGrain = r; res.PASS.sndGrain = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T86 v2.63 未做 83 調節台換材質、回到預設不彈一下（deskSmooth；OVERNIGHT 第 17 項，手機照這條搬）。真正的預設（PRE62，大腦關：量的 1.5 秒裡不准自己走開）、真正的畫面（VIEW0：窗台）和藍底各一次。
  // 每次這隻（SLIME）重新開始、放 4 秒，然後 a 換成果凍、b 換成麻糬、c 換果凍放 4 秒再回到預設（setMat(這隻的材質)：調節台按鈕叫的就是這個；不按按鈕，按鈕會寫使用者的存檔）、n 不換（對照），
  // 之後 1.5 秒每一格外框每一點移了多少（半徑），取最大。deskSmooth 0 同樣再跑一次（改之前）。
  // 擋：窗台（真正的畫面）1 的時候每一種最大 ≤ 0.15R、三種的最大 ≤ 0 那邊最大的三成，0 的時候換果凍、換麻糬至少 0.5R（量得到彈）；
  // 藍底材質之間身體大小不同（0.27、0.3，窗台一律 0.27），要真的重建，外形換成新的那一下還在：每一種 ≤ 0.25R、三種的最大 ≤ 0 那邊最大的三成；每一次結束自交 0
  { const clock = saveClock(), r = {}, PS = { ...PRESETS }, V86 = { ...VIEW }, I0 = { tr: IMP.tr, w: IMP.w };
    const mv = (a, b) => { let m = 0; const n = Math.min(a[0].length, b[0].length); for (let i = 0; i < n; i++) m = Math.max(m, Math.hypot(a[0][i] - b[0][i], a[1][i] - b[1][i])); return m / R; };
    const sb = () => [bnd.map(i => X[i]), bnd.map(i => Y[i])];
    const one = (bg, ds, act) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Object.assign(VIEW, VIEW0, { bg });
      for (const k in PRE62) PRESETS[k] = { ...PRE62[k], brain: 0, intro: 0, introSwim: 0, deskSmooth: ds };
      Math.random = seeded(86); mat = { ...mat, deskSmooth: ds }; chooseSlime(SLIME, false, false); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; WANDER.moving = false; WANDER.next = 99; steps(240);
      if (act === 'c') { setMat('jelly'); steps(240); }
      if (act === 'a' || act === 'c') setMat(act === 'a' ? 'jelly' : SLIMES[SLIME].mat); else if (act === 'b') setMat('mochi');
      let p = sb(), m = 0; for (let k = 0; k < 90; k++) { steps(1); const c = sb(); m = Math.max(m, mv(c, p)); p = c; }
      return { m: +m.toFixed(3), x: selfX() }; };
    try {
      for (const bg of ['day', 'blue']) for (const ds of [1, 0]) for (const act of ['n', 'a', 'b', 'c']) r[bg + ds + act] = one(bg, ds, act);
      const mx = k => Math.max(...['a', 'b', 'c'].map(a => r[k + a].m));
      r.sillOn = mx('day1'); r.sillOff = mx('day0'); r.blueOn = mx('blue1'); r.blueOff = mx('blue0'); r.selfX = Object.values(r).filter(v => v && typeof v === 'object').reduce((s, v) => s + v.x, 0);
      r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(PRESETS, PS); Object.assign(VIEW, V86); log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    r.ok = !r.err && r.sillOn <= .15 && r.sillOn <= .3 * r.sillOff && r.day0a.m >= .5 && r.day0b.m >= .5 && r.blueOn <= .25 && r.blueOn <= .3 * r.blueOff && r.selfX === 0;
    res.T86_deskSmooth = r; res.PASS.deskSmooth = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T87 v2.64 C5 張望有對象（lookTarget；BATCH3 第 3 項，手機照這條搬）。窗台、芋圓、真正的預設（PRE54，大腦、心情照常），窗景「河邊的櫻」（花瓣一直掉），窗景的時鐘跟著模擬走（WIN.fixed = t）。
  // 放著 30 分鐘，每 5 分鐘輕點牠一下（點在身體中間，按 0.1 秒放），其餘不碰。手指不准碰到窗台上的東西。
  // 擋：a lookTarget 1：看完有反應 12 次以上（規劃 C5 的驗法）；對象至少兩種（碰過的地方、窗景、風鈴、擺飾）；每一次反應的偽足方向都朝著對象（差 0.15 弧度內，朝下被 lookNoDown 鏡射的照鏡射後的比）；
  //       每一次反應那一格真的有動作（碰過的地方：E2 那一傾；其他：多一條點一下的偽足）；零自交
  //     b lookTarget 0 同樣 30 分鐘：一次都沒挑對象、沒有反應（ltPick、ltReact 沒跑）；零自交
  //     c 沒有對象時照舊：懸空（窗台關）和窗台上沒有擺飾、沒有窗景、沒摸過，各抽 255 次張望方向，1 跟 0 每一個方向都一樣、抽完後下一個亂數也一樣
  { const clock = saveClock(), TARO = SLIMES[2], sl0 = SLIME, view0 = { ...VIEW }, wf0 = WIN.fixed, r = {}, M0 = { cell: BMEM.cell.slice(), side: BMEM.side }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = { ...BRAIN }, E0 = { count: E4.count, lastT: E4.lastT }, SP = { ...PRE54[TARO.mat], seed: TARO.seed, ...TARO.p, limbs: 0, tentSlip: 0, tentBump: 0, tentAxis: .85, eyes: 1, sill: 1, bodySize: .27, intro: 0, introSwim: 0, shake: 0, tapBack: 0, slowBlink: 0 };   // v2.64 D8：頂回來、慢眨預設 1 之後這一項的數字會變（整份比對過），量的是舊規格，釘 0
    const base = Math.floor(seeded(87)() * 1e6);   // 只跑幾項時 st.py 換掉 seeded(87) 的種子，每一輪不同
    const fresh = (over, sd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd + base); SLIME = 2; mat = { ...SP, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.lastAny = -99; SLP.on = false; SLP.k = 0; impReset(); IMP.tr = .3; IMPD.tr = IMP.tr; IMPD.w = 0; ESC.on = false; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; E4.count = 99; GREET.st = ''; GREET.until = -9; EYE.user = -9; DR.lookT = -9; voice.last = -9; PAIR.tearT = -9; PAIR.over = 0; BMEM.cell = [0, 0, 0, 0, 0]; BMEM.side = 0; Object.assign(BRAIN, { seed: sd }); brainReset(); LT.s = (sd + base) >>> 0; LT.n = { ask: 0, pick: 0, react: 0, drop: 0 }; LT.log.length = 0; steps(60); };
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const dA = (a, b) => Math.abs(Math.atan2(Math.sin(a - b), Math.cos(a - b)));
    const winLoad = async id => { VIEW.bg = 'day'; VIEW.win = id; let s = sceneFor('day'); for (let i = 0; i < 400 && id && !(s && s.win && s.win.id === id); i++) { await new Promise(o => setTimeout(o, 30)); s = sceneFor('day'); } return !id || !!(s && s.win && s.win.id === id); };
    const owner = (over, sd) => { fresh(over, sd); const o = { xs: 0, taps: 0, seen: 0, did: 0, aimBad: 0, maxBad: 0 }; let li = 0;
      for (let k = 0; k < 60 * 1800; k++) { WIN.fixed = t;
        if (k % (60 * 300) === 60 * 150) { const [x, y] = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, x, y); steps(6); ev('pointerup', 1, x, y); o.taps++; continue; }
        steps(1);
        for (; li < LT.log.length; li++) { const q = LT.log[li]; o.seen++; const f = SILL.on && Math.sin(q.ta) > 0 && mat.lookNoDown >= .5 ? -q.ta : q.ta, b = dA(q.a, f); if (b > .15) o.aimBad++; o.maxBad = Math.max(o.maxBad, +b.toFixed(3));
          if (q.k === 'touch' ? Math.abs(E2.leanT - q.t) < .02 : LIFE.sns.some(s => s.L === .3 && s.T1 === .12 && Math.abs(s.t0 - q.t) < .02)) o.did++; }
        if (k % 30 === 0 && selfX()) o.xs++; }
      WIN.fixed = wf0; o.n = { ...LT.n }; o.kinds = ['touch', 'win', 'bell', 'prop'].filter(k => LT.n[k] > 0); o.head = LT.log.slice(0, 6).map(q => q.k + '@' + Math.round(q.t)); return o; };
    const draw255 = (over, sd) => { fresh(over, sd); Math.random = seeded(sd + base + 1); const a = []; for (let k = 0; k < 255; k++) a.push(pickDir()); return { sill: SILL.on, a, pick: LT.n.pick, next: Math.random() }; };
    try {
      r.win = await winLoad('Yinghua');
      r.on = owner({}, 87); r.off = owner({ lookTarget: 0 }, 87);
      await winLoad(''); VIEW.bg = view0.bg;
      const same = (x, y) => x.a.length === y.a.length && x.a.every((v, i) => v === y.a[i]) && x.next === y.next;
      const f1 = draw255({ sill: 0 }, 8701), f0 = draw255({ sill: 0, lookTarget: 0 }, 8701), s1 = draw255({ deco: 0 }, 8702), s0 = draw255({ deco: 0, lookTarget: 0 }, 8702);
      r.c = { floatSame: same(f1, f0), floatSill: f1.sill, sillSame: same(s1, s0), sillOn: s1.sill, pick: f1.pick + s1.pick };
      r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    WIN.fixed = wf0;
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0);
    Object.assign(VIEW, view0); SLIME = sl0; BMEM.cell = M0.cell; BMEM.side = M0.side; BMEM.dirty = false; IMP.tr = I0.tr; IMP.w = I0.w; impReset(); Object.assign(E4, E0); Object.assign(BRAIN, B0); GREET.st = ''; GREET.until = -9; PAIR.tearT = -9; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup(); LIFE.st = 'rest'; LIFE.until = -1; LIFE.att = null; SLP.on = false; SLP.k = 0; drReset();
    r.ok = !r.err && r.win && r.on.n.react >= 12 && r.on.kinds.length >= 2 && r.on.aimBad === 0 && r.on.seen === r.on.n.react && r.on.did === r.on.seen && r.on.xs === 0
      && r.off.n.ask === 0 && r.off.n.pick === 0 && r.off.n.react === 0 && r.off.seen === 0 && r.off.xs === 0
      && r.c.floatSame && !r.c.floatSill && r.c.sillSame && r.c.sillOn && r.c.pick === 0;
    res.T87_lookTarget = r; res.PASS.lookTarget = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T88 v2.64 D8 點牠牠頂回來、呼嚕時慢眨眼（tapBack、slowBlink；BATCH3 第 4 項，手機照這條搬）。藍底、黏土真正的預設（PRE54；大腦、睡覺、手邊睡、來找你、張望有對象關：
  // 量的幾秒裡不准睡、不准游過來、張望不准拿走 E2 那一傾）。熟 0.3、戒 0.2（低於 0.4，朝你傾）、交情 0.3。兩組（開、關）同一個種子、同一格比。
  // a 點身體中間右邊 0.5R（按 0.1 秒放），之後 4 秒不碰：tapBack 1 頂回來 1 次，排在傾完（第一傾開始 +0.7 秒）之後 0.4 秒（±0.03）；頂的方向朝你點的地方（0.3 弧度內）；
  //   頂的那 0.7 秒外框最右邊比 tapBack 0 同一格多伸出 0.05R 以上（真的有推）；頂完 0.3 秒起到 1.5 秒每格都在看你（t < EYE.user、眼睛偏 0.1 以內），tapBack 0 同一段沒有一格在看你；
  //   4 秒後戒、熟、交情、舒服跟 tapBack 0 一模一樣；熟、交情也跟頂之前一樣（頂完你不碰，戒、熟都不動）
  // b 同樣點一下，頂完 0.5 秒再點一下（照現有的回應：又一傾、又排一次頂）：看著你那段被你接走（ans 1 以上），第二下照樣傾；戒、熟、交情跟 tapBack 0 同一刻點兩下一模一樣（沒有另外的獎勵）
  // c 熟 0.5，揉 30 秒（T76 的揉法）：slowBlink 1 慢眨 1 次以上，每次開始那格在呼嚕；整段換成睜眼的形狀（不是新的表情）、閉著（眨眼量 0）0.4 秒以上、前後睜開；
  //   慢眨以外呼嚕時照舊 ∩；slowBlink 0 沒有慢眨，呼嚕時一直 ∩（被擠成 > < 的不算）
  // d 兩顆開著但沒點、沒呼嚕（放著 20 秒、按 0.6 秒放、往右拉 1R 放、再放著 4 秒）：每一點位置、下一個亂數都跟兩顆 0 一樣（不排、不抽亂數）
  { const clock = saveClock(), r = {}, P88 = { ...PRE54.clay, eyes: 1, intro: 0, introSwim: 0, brain: 0, sleep: 0, nap: 0, e4: 0, lookTarget: 0 }, I0 = { tr: IMP.tr, w: IMP.w }, B0 = BOND.v;
    const base = Math.floor(seeded(88)() * 1e6);   // 只跑幾項時 st.py 換掉 seeded(88) 的種子，每一輪不同
    const sc = (x, y) => { const v = viewV(); return [(x - CAM.x) * CAM.z + v.x, (y - CAM.y) * CAM.z + v.y]; };
    const fresh = (over, sd, tr, w, bd) => { for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); Math.random = seeded(sd + base); mat = { ...P88, ...over }; setup(); t = 0; lastTouch = -10; nextTwitch = 3; tLife = 0; relaxUntil = -1; SLP.on = false; SLP.lastAny = -99; impReset(); IMP.tr = tr; IMP.w = w; BOND.v = bd; IMPD.tr = IMP.tr; IMPD.w = w; ESC.on = false; WANDER.moving = false; WANDER.next = 99; voice.last = -9; FLN.say = null; GREET.st = ''; GREET.until = -9; EYE.user = -9; E2.tk.length = 0; E2.tkT = 0; DENTS.length = 0; steps(60); log.splice(0);
      TB.n = { arm: 0, fire: 0, drop: 0, ans: 0 }; TB.log.length = 0; SBL.n = 0; SBL.log.length = 0; };
    const maxX = () => { let m = -1e9; for (const i of bnd) m = Math.max(m, X[i]); return m; };
    // 點一下 + 之後 4 秒不碰；tap2At：到這一刻再點一下（b 用）。每格記：外框最右、在不在看你、眼睛偏多少
    const run = (over, tap2At) => { fresh(over, 88, .3, .2, .3); const o = { fr: [], leans: [], tap2: null }, x0 = globalC.xc + .5 * R, y0 = globalC.yc; let lastLean = E2.leanT;
      const rec = () => { steps(1); if (E2.leanT !== lastLean) { lastLean = E2.leanT; o.leans.push(+E2.leanT.toFixed(4)); } o.fr.push({ t, x: maxX(), look: t < EYE.user, g: Math.hypot(EYE.gx, EYE.gy) }); };
      const tap = () => { const [x, y] = sc(globalC.xc + .5 * R, globalC.yc); ev('pointerdown', 1, x, y); for (let k = 0; k < 6; k++) rec(); ev('pointerup', 1, x, y); return t; };
      o.rel = tap(); o.pre = null; const tEnd = o.rel + 4;
      while (t < tEnd - 1e-9) { if (tap2At != null && o.tap2 == null && t >= tap2At - 1e-9) { o.tap2 = tap(); continue; } if (TB.n.fire === 0) o.pre = { w: IMP.w, tr: IMP.tr, bd: BOND.v }; rec(); }
      o.end = { w: IMP.w, tr: IMP.tr, bd: BOND.v, c: MOOD.c }; o.n = { ...TB.n }; o.log = TB.log.slice(); o.tx = x0; o.ty = y0; o.cx = globalC.xc; return o; };
    // c：揉 sec 秒，每格記呼嚕、表情、眨眼量
    const rubRun = (over, sec) => { fresh(over, 8803, .5, 0, .3); const fr = [], cx = globalC.xc, cy = globalC.yc; let q = sc(cx, cy - R * .25); ev('pointerdown', 1, q[0], q[1]);
      for (let k = 1; k <= sec * 60; k++) { const a = 2 * Math.PI * .5 * k / 60; q = sc(cx + R * .25 * Math.sin(a), cy - R * .25 * Math.cos(a)); ev('pointermove', 1, q[0], q[1]); steps(1); fr.push({ t, P: PURR, m: EYE.mode, b: EYE.blink }); }
      ev('pointerup', 1, q[0], q[1]); return { fr, n: SBL.n, log: SBL.log.slice(), T: sblT() }; };
    const plain = over => { fresh(over, 8804, .3, .2, .3); steps(1200); let q = sc(globalC.xc, globalC.yc); ev('pointerdown', 1, q[0], q[1]); steps(36); ev('pointerup', 1, q[0], q[1]); steps(120);
      let b = -1; for (const i of bnd) if (b < 0 || X[i] > X[b]) b = i; const ax = X[b] - R * .15, ay = Y[b]; q = sc(ax, ay); ev('pointerdown', 1, q[0], q[1]); const f = fingers.get(1);
      for (let k = 1; k <= 30; k++) { const tx = ax + R * k / 30; q = [q[0] + (tx - f.x) * CAM.z, q[1] + (ay - f.y) * CAM.z]; ev('pointermove', 1, q[0], q[1]); steps(1); } ev('pointerup', 1, q[0], q[1]); steps(240);
      let h = 0; for (let i = 0; i < N; i++) h += X[i] * (i % 7 + 1) + Y[i] * (i % 5 + 2); return { h, next: Math.random(), arm: TB.n.arm, sb: SBL.n }; };
    try {
      const A1 = run({}), A0 = run({ tapBack: 0 });
      const ev1 = A1.log[0], fire = ev1 ? ev1.t : -1, leanEnd = A1.leans.length ? A1.leans[0] + .7 : -1;
      let push = -9, look1 = 0, lookN = 0, gMax = 0, look0 = 0;
      for (let k = 0; k < A1.fr.length && k < A0.fr.length; k++) { const q1 = A1.fr[k], q0 = A0.fr[k], u = q1.t - fire; if (fire < 0) break;
        if (u >= 0 && u < .7) push = Math.max(push, (q1.x - q0.x) / R);
        if (u >= .3 && u < 1.5) { lookN++; if (q1.look && q1.g < .1) look1++; gMax = Math.max(gMax, q1.g); if (q0.look) look0++; } }
      const same = (x, y) => ['w', 'tr', 'bd', 'c'].every(k => Math.abs(x[k] - y[k]) < 1e-12);
      r.a = { rel: +A1.rel.toFixed(3), lean0: A1.leans[0], fire, gap: +(fire - leanEnd).toFixed(3), afterTap: +(fire - A1.rel).toFixed(3), aim: ev1 ? ev1.a : null,
        push: +push.toFixed(3), look1, lookN, gMax: +gMax.toFixed(3), look0, n1: A1.n, n0: A0.n, end1: A1.end, end0: A0.end, pre1: A1.pre, endSame: same(A1.end, A0.end), keepTrBd: !!A1.pre && Math.abs(A1.end.tr - A1.pre.tr) < 1e-12 && Math.abs(A1.end.bd - A1.pre.bd) < 1e-12 };
      r.a.aimDiff = ev1 ? +Math.abs(ev1.a).toFixed(3) : -1;   // 點在重心正右邊 0.5R，朝手指就是朝右（0 弧度）；頂的那一刻重心有挪，差幾度
      const B1 = run({}, fire + .5), B0r = run({ tapBack: 0 }, fire + .5);
      r.b = { tap2: B1.tap2 && +B1.tap2.toFixed(3), n1: B1.n, n0: B0r.n, leans1: B1.leans, leans0: B0r.leans, end1: B1.end, end0: B0r.end, endSame: same(B1.end, B0r.end), lean2: B1.tap2 != null && B1.leans.some(x => x > B1.tap2) };
      const C1 = rubRun({}, 30), C0 = rubRun({ slowBlink: 0 }, 30);
      const inW = (c, tt) => c.log.some(s => tt >= s - 1e-9 && tt < s + c.T);
      const blinks = C1.log.map(s => { const w = C1.fr.filter(q => q.t >= s - 1e-9 && q.t < s + C1.T - 1e-9), st = w[0] || {}; return { s, P: +(st.P || 0).toFixed(2), allOpen: w.every(q => q.m === 'open'), closed: +(w.filter(q => q.b === 0).length / 60).toFixed(2), openMid: w.some(q => q.t - s > .3 && q.t - s < .8 && q.b === 1), openEnd: w.length ? w[w.length - 1].b : -1, full: w.length }; });
      const offHappy = c => c.fr.filter(q => q.P > .3 && q.m !== 'happy' && q.m !== 'squeeze' && !inW(c, q.t)).map(q => +q.t.toFixed(3));
      r.c = { n1: C1.n, n0: C0.n, blinks, purrFr1: C1.fr.filter(q => q.P > .3).length, purrFr0: C0.fr.filter(q => q.P > .3).length, notHappy1: offHappy(C1), notHappy0: offHappy(C0), log1: C1.log.map(x => +x.toFixed(4)) };
      plain({ tapBack: 0, slowBlink: 0 });   // 先空跑一次：前面 c 留下的狀態（setup 不歸零的那些）會讓第一次不一樣，兩組都接在 plain 後面才比得了
      const D1 = plain({}), D0 = plain({ tapBack: 0, slowBlink: 0 });
      r.d = { same: D1.h === D0.h && D1.next === D0.next, h1: D1.h, h0: D0.h, arm: D1.arm, sb: D1.sb };
      r.err = ''; } catch (e) { r.err = String(e) + ' ' + (e.stack || '').split('\n')[1]; }
    for (const id of [...fingers.keys()]) ev('pointerup', id, 0, 0); FLN.say = null;
    log.splice(0); IMP.tr = I0.tr; IMP.w = I0.w; impReset(); BOND.v = B0; restoreClock(clock); mat = { ...PRESETS.clay }; setup(); SLP.on = false; LIFE.st = 'rest';
    const okA = !r.err && r.a.n1.fire === 1 && r.a.n0.fire === 0 && r.a.n0.arm === 0 && Math.abs(r.a.gap - .4) <= .03 && r.a.aimDiff >= 0 && r.a.aimDiff <= .3 && r.a.push >= .05
      && r.a.lookN > 0 && r.a.look1 === r.a.lookN && r.a.look0 === 0 && r.a.endSame && r.a.keepTrBd;
    const okB = !r.err && r.b.n1.ans >= 1 && r.b.n1.arm === 2 && r.b.lean2 && r.b.endSame && r.b.n0.fire === 0;
    const okC = !r.err && r.c.n1 >= 1 && r.c.blinks.every(x => x.P > .3 && x.allOpen && x.closed >= .4 && x.openMid && x.openEnd === 1) && r.c.notHappy1.length === 0 && r.c.n0 === 0 && r.c.notHappy0.length === 0 && r.c.purrFr0 > 600;
    const okD = !r.err && r.d.same && r.d.arm === 0 && r.d.sb === 0;
    r.part = { a: okA, b: okB, c: okC, d: okD }; r.ok = okA && okB && okC && okD;
    res.T88_tapBack = r; res.PASS.tapBack = r.ok; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  // T74 v2.62 扯斷成兩隻、碰到合回（多米 11-26）。測試本身在 splittest.js（也能單獨跑），用真正的預設（PRE62）。擋：四版合併動畫都會斷、斷了不准再斷、拖去碰一定合、合回 3 秒後點數一樣、面積 ±3%、A 回到原本大小；放著自己爬回去也合；splitAgain 1 合回後能再斷、0 不能；split 0 不斷
  { const clock = saveClock(), T0 = performance.now(); let o = { r: { err: '' }, pass: false };
    const P74 = {}; for (const k in PRE62) P74[k] = { ...PRE62[k], lookNoDown: 0 };   // v2.63 C5：張望不朝下預設 1 之後窗台上張望的方向變了（合回那幾格跟著變），這一項量的是舊規格，釘 0
    try { window.__SPLIT_PRE = P74; o = await (0, eval)(await (await fetch('splittest.js?' + Date.now())).text()); } catch (e) { o.r.err = String(e); } finally { delete window.__SPLIT_PRE; }
    o.r.sec = Math.round((performance.now() - T0) / 1000); res.T74_split = o.r; log.splice(0); restoreClock(clock); mat = { ...PRESETS.clay }; setup();
    res.PASS.split = !!o.pass; res.ALL_PASS = Object.values(res.PASS).every(Boolean); }
  draw();
  Object.assign(VIEW, VIEW0); viewSync();
  Object.assign(PRESETS, P27R); Object.assign(PRESETS, PRE47); Object.assign(PRESETS, PRE62); SLP.lastAny = -99; chooseSlime(SLIME, false, false);   // v2.23：回到原本那隻（材質、個性、顏色）；v2.47：真正的預設值還回去
  for (const k in IMPS) delete IMPS[k]; Object.assign(IMPS, JSON.parse(IMPS0)); IMP.tr = IMP0.tr; IMP.w = IMP0.w; IMPD.tr = IMP.tr; IMPD.w = IMP.w; IMPSV.noSave = false;   // v2.34：熟還回去
  if (SFX) SFX.frame = sfxFrame0;
  WALK.noSave = false; walkLoad();
  restoreClock(clock00); ({ specialUntil, releaseCount, nextSpecial } = misc00); BR.phase = misc00.ph; BR.tlPrev = misc00.tl;
  Math.random = realRandom;   // 跑完把真的亂數還給 app
  sfxPlay = origPlay; window.requestAnimationFrame = realRAF; requestAnimationFrame(frame);
  console.log(JSON.stringify(res, null, 1));
  return res;
})();
