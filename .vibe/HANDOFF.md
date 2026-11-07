# Handoff: v2.31（2026-11-07 晚上，第十九會話，等多米點移植批次）

> 短版。細節看 git log、`.vibe/標準清單.md` 最後一節「模擬器實測」、`.vibe/代決清單.md` 11-07 最後四列；長版在 `.vibe/handoff/archive/2026-11-07-v2.31-長版.md`。

## 現況

- 網頁 v2.31 上線（`?v=233`），程式這次沒動：皮 A 清透、碗在正中間、石頭盤和盆栽是背景、牠只爬進爬出碗、搖晃沉澱；第二種玩法「散出來吃回來」用切換列切。
- selftest 49 項在同一個 iframe 連跑 3 輪全過（上次跑的，這次沒動程式沒重跑）。
- **這次做了 limrun 模擬器實測**（iPhone 16 Pro、iOS 26.4、402×874）：線上 `?v=233` 果凍皮、碗、擺飾、亮粉都畫得出來，每幀 33 毫秒（模擬器上限）。兩種玩法流程都走得完：沉澱從濁到清約 40 秒（寫的是 30 秒，沒動數字）；散出來吃回來一輪約 20 秒（噴 36 顆、9 秒剩 3 顆、24 秒吃完回碗）。第一次開線上網址整頁空白，重開就好，原因沒抓到。點牠不會跳「動作與方向」權限（模擬器沒加速度計）。細節在 `標準清單.md` 最後一節。
- 手機版沒動：還是平塗、碗在左、沒有搖、沒有走路素材。
- limrun：帳號有點數、這台電腦的 lim 已登入。我開的實例測完已刪。另外有兩台**沒標籤**的實例自己冒出來（17:08、17:34，25m 硬上限、5m 閒置），都在沒人動 5 分鐘後自己終止；懷疑是 lim 的 `--create` 預設補開的，下次指令一律帶 `--id --no-create`。

## 等多米

1. **已定（11-07 晚上）**：走路是主機制，搖留著當捏以外的另一種互動，兩個都不拿掉。還沒定：散出來吃回來要不要搬手機（我建議先不搬）。
2. 移植批次 `.uiux/04-手感/手機版移植批次-暫定.md` 要點頭：順序 0 到 6、吃回來先不搬、果凍皮放最後。
3. 真機搖起來怎樣：門檻 13 會不會誤觸或搖不到、霧夠不夠濃、30 秒會不會太久（模擬器量到約 40 秒）、叮的音量。
4. 舊帳：build 106 步數讀到幾天前、閘門 1 三個測試、`CLAUDE.md` 草稿 v2.24 到 v2.31 要不要照改。

## 下一步

1. 第一句話問：批次文件點不點頭（順序、吃回來先不搬、皮放最後）。點了就從批次 0 開始，一次一批，每批 push 一次看 Actions 編譯，TestFlight 在批次 1、3、5 之後各發一次（要多米開口）。
2. 批次 0 的內容：Swift 預設改成眼睛開、`limbs 0`、`tentBump 0`；黏液整段刪（`FeelParams` 的 `drops`、`dropsV`，`SlimeRig` 的 drops 區，`SlimeView` 的 drop、strand 圖層，候選 219 等對照裡的 drops 欄位）。
3. 批次 1 對照網頁 `index.html` 搜尋「v2.29 防打結」（`buildMesh`、`meshGuard`、`noFlip`）、「v2.29 眼睛不跑出身體」。
4. 不拿掉搖也不拿掉走路（多米 11-07 晚上定的）。
4. 可選的小事：線上第一次開空白那件，要抓的話在 `index.html` 加 `window.onerror` 顯示層；調整面板在 402 寬排版爆掉（按鈕直排、底下幾排橫向溢出），開發用的，多米說要修再修。

## 怎麼做事（不變）

- 多米沒 Mac。推 `swiftui-port` 會跑只編譯的檢查；TestFlight 等多米開口：`gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`。
- 推 main（只放 web 和 docs）：`git worktree add <scratchpad>/wt-main origin/main -B main-sync` → `git checkout <hash> -- prototype .uiux .vibe CLAUDE.md` → 確認 `git diff --cached --name-only -- ios` 是空的 → `git commit -C <hash>` → `git push origin main-sync:main` → 移除 worktree 與分支。改版換 `?v=`。這次只改 docs，沒推 main。
- 本機預覽：`preview_start` 名稱 `web-proto`；先 `resize_window` 393×852 再 `navigate`。面板藏著時 rAF 不跑，把 `requestAnimationFrame` 換成空函式，自己呼叫 `update(1/60)`、`draw()`。
- selftest：放進 393×852 的 iframe，`ifr.contentWindow.eval(src)`，結果存 `localStorage`。同一個 iframe 連跑 3 輪（每次重開 iframe 都算第一輪，會不一樣）。只跑一段：`src.slice(0, src.indexOf('  // T1 輕按')) + '  res.PASS={};\n' + src.slice(src.indexOf('  // T46 v2.30'))`。跑的時候不准改 `index.html`。
- 補丁用 Write 寫 python 再 `python -I`，每個取代檢查次數；先 `node -e "new Function(...)"` 檢查語法再開瀏覽器。
- 任何「到幾秒為止」的計時器都要防時鐘倒回（selftest 會 restoreClock）。
- limrun（`npx -y lim@0.51.0`，先 `export LIM_DAEMON=false`）：開 `lim ios create --label project=nienie-slime --inactivity-timeout 10m --hard-timeout 40m --model iphone --json`；開網頁 `lim ios open-url --id <id> <網址>`（第一次空白就再開一次）；截圖 `lim ios screenshot out.png --id <id> --size scaled`（402×874，座標和 tap 一樣）；點 `lim ios tap X Y --id <id>`；長按用 `perform` 的 touchDown／`{"type":"wait","durationMs":1600}`／touchUp。網頁上 `tapElement` 會逾時、面板要捲 30 次才到底，要按面板按鈕比較快的做法是複製一份到 scratchpad、注入捷徑鈕和狀態列、`python -m http.server 8766` 加 `lim ios tunnel --selector localhost:8766 --id <id> --detach --no-inspect`，模擬器開 `http://localhost:8766/`（捷徑鈕要聽 pointerup，位置先截圖量，CSS 的 top 和螢幕差約 80 點）。測完立刻 `lim ios tunnel stop`、`lim ios delete <id>`、`lim ios list` 確認；別的專案的（`project=` 標籤）不動。真正的搖（加速度）模擬器給不了。
- 文件：改動寫進 `標準清單.md`（驗收）、`代決清單.md`（替多米決定的）、`黃金行為.md`、`CLAUDE-md-vX-草稿.md`；提案放 `.uiux/04-手感/`。
