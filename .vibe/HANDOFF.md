# Handoff: v2.31（2026-11-07）

> 短版。細節看 git log、`.vibe/標準清單.md` 最後一節、`.vibe/代決清單.md` 11-07 那幾列；長版在 `.vibe/handoff/archive/2026-11-07-v2.31-長版.md`。

## 現況

- 網頁 v2.31 上線（`?v=233`）：皮 A 清透、碗在正中間、石頭盤和盆栽是背景、牠只爬進爬出碗、搖晃沉澱（搖三下肚子裡變霧，放著約 30 秒清透、發光、叮；捏也會攪起一點；亮粉一直在身體裡）；第二種玩法「散出來吃回來」用切換列切：搖了亮粉噴到窗台或碗口，牠自己爬去一顆顆吃回來，吃完叮。走路回來那趟翻過碗後緣進碗，東西放窗台上碗的左右。
- selftest 49 項在同一個 iframe 連跑 3 輪全過。
- 手機版沒動：還是平塗、碗在左、沒有搖、沒有走路素材。

## 等多米

1. 搖和走路留哪一個（目的是黏性；Agent 建議留搖）；搖的兩種玩法沉澱、散出來吃回來留哪一個。
2. 真機搖起來怎樣：門檻 13 會不會誤觸或搖不到、霧夠不夠濃、30 秒會不會太久。
3. 舊帳：build 106 步數讀到幾天前、閘門 1 三個測試、`CLAUDE.md` 草稿 v2.24 到 v2.31 要不要照改。

## 下一步

1. 第一句話問上面三件。
2. 搖或走路定了就把輸家拿掉。走路：`WALK`、`walk*`、面板三顆、`ios/NieNie/UI/StepProbe.swift`、`NSMotionUsageDescription`。搖：`SNW`、`shk*`、面板三顆。
3. 再來是手機版移植：防打結、眼睛、果凍皮、窗台和碗、擺飾背景、搖或走路。先不要動程式，比對 `prototype/web/index.html` 與 `ios/NieNie/Slime/SlimeRig.swift`、`ios/NieNie/App/SlimeController.swift`，列批次給多米點頭。

## 怎麼做事（不變）

- 多米沒 Mac。推 `swiftui-port` 會跑只編譯的檢查；TestFlight 等多米開口：`gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`。
- 推 main（只放 web 和 docs）：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支。改版換 `?v=`。
- 本機預覽：`preview_start` 名稱 `web-proto`；先 `resize_window` 393×852 再 `navigate`。面板藏著時 rAF 不跑，把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。
- selftest：放進 393×852 的 iframe，`ifr.contentWindow.eval(src)`，結果存 `localStorage`。同一個 iframe 連跑 3 輪（每次重開 iframe 都算第一輪，會不一樣）。只跑一段：`src.slice(0, src.indexOf('  // T1 輕按')) + '  res.PASS={};\n' + src.slice(src.indexOf('  // T46 v2.30'))`。跑的時候不准改 `index.html`。
- 補丁用 Write 寫 python 再 `python -I`，每個取代檢查次數；先 `node -e "new Function(...)"` 檢查語法再開瀏覽器。
- 任何「到幾秒為止」的計時器都要防時鐘倒回（selftest 會 restoreClock）。
- limrun：`npx -y lim@0.51.0`，`lim ios create --label project=nienie-slime --inactivity-timeout 10m`，`lim ios open-url` 開網頁版；測完立刻 `lim ios delete`，別的專案的（`project=` 標籤）不動。
- 2026-11-07 limrun 開實例被拒：帳號沒有剩餘點數也沒有訂閱，要多米去 console 的 billing 加點數才能再用。
- 文件：改動寫進 `標準清單.md`（驗收）、`代決清單.md`（替多米決定的）、`黃金行為.md`、`CLAUDE-md-vX-草稿.md`；提案放 `.uiux/04-手感/`。
