# Handoff: v2.31 手機版七批移植完（2026-11-07 晚上，第十九會話結束）

> 短版。細節看 git log（`port batch 0` 到 `port batch 6`）、`.uiux/04-手感/手機版移植批次-暫定.md`、`.vibe/標準清單.md` 最後一節「手機版移植」、`.vibe/代決清單.md` 11-07「移植」那幾列。

## 現況

- 網頁 v2.31 上線（`?v=233`），這次沒動。
- **手機版（`swiftui-port`）追到網頁 v2.31**，七批七個 commit，每批都過了 Actions 的編譯檢查，**沒有一批在真機跑過**：
  0. 黏液整段刪掉。
  1. 三角網防打結、手指實心、抓著時回正上限、整團跟手上限、眼睛不出界。
  2. 窗台、重力、正中間的碗、落地壓扁、放手規則、嚇到原地跳、鏡頭固定、白天夜晚背景（`SceneArt.swift` 烘成三張圖：天空、牆、擺飾加碗）。
  3. 路線系統：爬出碗、爬回碗、閒著回碗。
  4. 走路：CMPedometer 真步數、第二次打開送石頭、點石頭問「牠想跟你出門」、500／3000 步、一天三件、六格、捏掉、20 秒自己掉；回家從窗外（鏡頭 0.8）翻過窗框下緣、碗後緣進碗；小東西程式畫。
  5. 搖晃沉澱：CoreMotion 加速度、彈一下、亮粉揚起變霧、約 30 秒沉澱閉眼慢呼吸、清透發光叮（`ding-01.wav`）、堆的形狀。只搬沉澱，吃回來留網頁。
  6. 果凍皮：`JellySkin.metal` 照網頁著色器改寫，`JellySkin.swift` 管遮罩、模糊、打光，畫在眼睛底下；腮紅；眼睛縮 0.68。
- 面板新滑桿：背景（0 藍 1 白天 2 夜晚）、皮（0 平塗 1 果凍）、牠自己出門、防打結五個、搖八個；按鈕：走路三顆、搖三顆。
- limrun 模擬器實測了網頁 v2.31（細節在標準清單 v2.31 那節「模擬器實測」）。

## 等多米

1. **build 117 已發 TestFlight**（11-07 晚上多米開口，run 42367574466）。等多米裝上去回報。
2. 裝上去照 `標準清單.md` 最後一節的順序看：會不會開、手感沒退步、不打結、碗、背景切換、走路假裝、權限兩道、搖、果凍皮掉幀。
3. 舊帳：build 106 步數讀到幾天前、閘門 1 三個測試、`CLAUDE.md` 草稿 v2.24 到 v2.31（這次又加了第 7 條）要不要照改。
4. 還沒定的：搖的兩種玩法要不要留吃回來（手機沒搬）、「運動多牠就比較興奮」要不要做（待設計）。

## 下一步

1. 第一句話問 build 117 裝上去怎樣（照標準清單最後一節的順序問）。照回報修，一次一件，數字都在面板。
2. 多米回報前不要再堆新功能到 `swiftui-port`。
3. 修的時候：Swift 這台電腦編譯不了，每次 push 看 Actions（`gh run watch <id> --exit-status`，約 2 到 5 分鐘）；錯誤用 `gh run view <id> --log-failed | grep error:` 抓。這次踩到的：參數名字蓋掉同名常數（`night`）、`2 * .pi` 沒有型別上下文要寫 `Double.pi`。

## 怎麼做事（不變）

- 多米沒 Mac。推 `swiftui-port` 會跑只編譯的檢查；TestFlight 等多米開口。
- 推 main（只放 web 和 docs）：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支。改版換 `?v=`。這次沒推 main（網頁沒改，docs 下次一起）。
- 本機預覽：`preview_start` 名稱 `web-proto`；先 `resize_window` 393×852 再 `navigate`。面板藏著時 rAF 不跑，把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。
- selftest：放進 393×852 的 iframe，`ifr.contentWindow.eval(src)`，結果存 `localStorage`。同一個 iframe 連跑 3 輪。只跑一段：`src.slice(0, src.indexOf('  // T1 輕按')) + '  res.PASS={};\n' + src.slice(src.indexOf('  // T46 v2.30'))`。跑的時候不准改 `index.html`。
- 補丁用 Write 寫 python 再 `python -I`，每個取代檢查次數；Swift 改完至少看大括號平衡和 diff。
- 任何「到幾秒為止」的計時器都要防時鐘倒回。
- limrun（`npx -y lim@0.51.0`，先 `export LIM_DAEMON=false`，指令帶 `--id --no-create`）：開 `lim ios create --label project=nienie-slime --inactivity-timeout 10m --hard-timeout 40m --model iphone --json`；網頁第一次空白就再開一次；測完立刻 `lim ios tunnel stop`、`lim ios delete <id>`、`lim ios list` 確認。細節在 11-07 的 limrun 記憶與標準清單。
- 叮的音檔：`mkding.py`（三個正弦 1318.5／2637／1975.5 Hz，音量 1／.35／.18，衰減 1.4／.9／.6 秒，8 毫秒起音，48k 單聲道，峰值 −6 dBFS），要改音色重寫一份丟進 `ios/NieNie/Resources/ding-01.wav`。
- 文件：改動寫進 `標準清單.md`（驗收）、`代決清單.md`（替多米決定的）、`黃金行為.md`、`CLAUDE-md-vX-草稿.md`；提案放 `.uiux/04-手感/`。
