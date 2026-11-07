# Handoff: 手機版七批追到網頁 v2.31，build 117 已發 TestFlight，等多米真機回報

> 產出時間：2026-11-07 19:27（第十九會話結束）
> 前一會話的最後狀態，給下一個會話接續用。舊版在 `.vibe/handoff/archive/`。

## ✅ 這次完成了什麼

- 用 limrun 的 iPhone 16 Pro 模擬器實測網頁 v2.31：果凍皮畫得出來，沉澱約 40 秒清、散出來吃回來一輪約 20 秒；結果在 `標準清單.md` v2.31 那節「模擬器實測」。
- 多米定案：走路是主機制，搖留著當捏以外的另一種互動，兩個都不拿掉。寫進 `CLAUDE-md-v2.31-草稿.md` 第 5-2 條。
- 寫移植批次文件 `.uiux/04-手感/手機版移植批次-暫定.md`，多米點頭：順序 0 到 6、吃回來先不搬、果凍皮放最後、TestFlight 全做完再發一次。
- 手機版（`swiftui-port`）七批全搬完，每批一個 commit（`port batch 0` 到 `port batch 6`），每批都過 Actions 編譯：刪黏液；防打結與眼睛不出界；窗台、重力、正中間的碗、白天夜晚背景；爬出碗爬回碗；走路（CMPedometer 真步數、問權限、回家翻過碗後緣）；搖晃沉澱（CoreMotion、叮聲 wav）；果凍皮（Metal 著色器照網頁改寫）。
- 新檔：`ios/NieNie/Slime/SceneArt.swift`、`JellySkin.swift`、`JellySkin.metal`；`Resources/scene-*.webp` 四張、`ding-01.wav`。
- 面板新東西：背景（0 藍 1 白天 2 夜晚）、皮（0 平塗 1 果凍）、牠自己出門、防打結五個、搖八個滑桿；走路三顆、搖三顆按鈕。
- 多米開口後發了 TestFlight：**build 117**（run 42367574466），編譯和上傳都成功。
- 文件：`標準清單.md` 最後一節「手機版移植」是第一次裝機的檢查順序；`代決清單.md` 11-07「移植」那幾列是替多米決定的事；`ios/README.md` 頂端補了一段；limrun 的兩份記憶更新了。

## 🚧 還沒做完 / 待決定

- 七批沒有一批在真機跑過，build 117 是第一次裝。Metal 果凍皮、CMPedometer、CoreMotion 都是編譯過但沒看過畫面，一次冒出好幾個問題很正常。
- 多米還沒回報 build 117 裝上去怎樣。
- 搖的兩種玩法要不要留吃回來，手機沒搬（網頁切換列還有）。等多米玩過網頁再說。
- 「運動多牠就比較興奮」待設計：基準線是平常的牠，走路只往上加，不做走得少就難過。要先寫提案。
- 舊帳：build 106 步數讀到幾天前、閘門 1 三個測試、`CLAUDE.md` 草稿 v2.24 到 v2.31（這次加了第 7 條）要不要照改。
- 網頁 docs 這幾個 commit 還沒同步到 main（網頁沒改，下次一起推）。

## 📌 關鍵決策（這次定下來的，下次別再爭論）

- 走路主、搖副，兩個都留（多米 11-07 晚上）。
- TestFlight 全做完再發一次，不分批發（多米）。
- 吃回來先不搬手機；果凍皮放最後、走 Metal 不用 CAGradientLayer 拼（多米點頭）。
- 手機版的背景、皮、搖的數字都放調整面板，畫面上不加切換列（我定的，代決清單有）。
- 走路答「好」之後步數從當天 0 點算起；每次回前景讀一次（我定的）。
- 叮聲照網頁三個正弦用 Python 烘成 wav，不在 app 裡合成（我定的）。
- 先前仍有效的：皮 A 清透、碗在中間、只跟碗互動、黏液取消、手感基準只為基準表的數字改。

## 📂 下個會話最重要的檔案

- `.vibe/標準清單.md` 最後一節「手機版移植」 ← 多米回報時對照這個順序
- `.uiux/04-手感/手機版移植批次-暫定.md` ← 七批各做了什麼、進度勾
- `.vibe/代決清單.md` 11-07「移植」那幾列
- `ios/NieNie/Slime/SlimeRig.swift`：搜尋「v2.28 窗台」「v2.30 routes」「走路 (v2.31 批次 4)」「v2.31 搖晃沉澱」各一段
- `ios/NieNie/Slime/SlimeView.swift`：`updateScene`、`drawGlitter`、`drawJelly`
- `ios/NieNie/App/SlimeController.swift`：走路讀步數、搖的 CoreMotion
- `prototype/web/index.html` 對照用（搬的時候每段都照它）

## ⏭️ 下一步從哪繼續

1. 第一句話問多米：build 117 裝上去，照標準清單最後一節的順序，第一眼看到什麼。會不會開、手感有沒有退步、不打結、碗、背景切換、走路假裝鈕、兩道權限、搖三下、果凍皮掉幀。
2. 照回報修，一次一件。這台電腦編譯不了 Swift：改完 push `swiftui-port`，`gh run watch <id> --repo domyweb666/nienie-slime --exit-status` 等約 2 到 5 分鐘；錯了 `gh run view <id> --log-failed | grep error:`。修一批再發一次 TestFlight（要多米開口）：`gh workflow run ios.yml --repo domyweb666/nienie-slime --ref swiftui-port -f testflight=true`。
3. 多米回報前不要往 `swiftui-port` 堆新功能。
4. 如果多米先回網頁的事（吃回來留不留、搖的門檻），照舊流程改網頁、跑 selftest、推 main 換 `?v=`。

## 🛠️ 怎麼做事（這次學到的，加在舊規矩上）

- Swift 補丁：Write 寫 python 再 `python -I`，每個取代檢查次數；改完看大括號平衡和 diff 再推。這次踩到兩個：函式參數跟常數同名會蓋掉（`night`）；`2 * .pi / 5` 沒有型別上下文要寫 `Double.pi`。
- 推 `swiftui-port` 每次都會跑一次編譯檢查（約 2 到 5 分鐘），docs-only 也會。
- limrun：`export LIM_DAEMON=false`，指令一律帶 `--id --no-create`；開 `lim ios create --label project=nienie-slime --inactivity-timeout 10m --hard-timeout 40m --model iphone --json`；網頁第一次開空白就再開一次；網頁上 `tapElement` 會逾時，要按面板按鈕就複製一份到 scratchpad 注入捷徑鈕（聽 pointerup，位置先截圖量）加 `lim ios tunnel --selector localhost:8766`；測完 `tunnel stop`、`delete`、`list` 確認。
- 叮聲：三個正弦 1318.5／2637／1975.5 Hz，音量 1／.35／.18，衰減 1.4／.9／.6 秒，8 毫秒起音，48k 單聲道，峰值 −6 dBFS，播放時 gain 0.5。
- 舊規矩不變：多米沒 Mac；推 main 用 worktree 只放 `prototype .uiux .vibe CLAUDE.md`，確認 `git diff --cached --name-only -- ios` 是空的；本機預覽 `web-proto` 先 resize 393×852；selftest 同一個 iframe 連跑 3 輪、跑的時候不改 `index.html`；計時器都防時鐘倒回。

## 🗑️ 這次會話的雜訊（下次別重新討論）

- 一開始我建議留搖拿掉走路，多米的理由（走路掛在本來就每天做的事上）比較強，已改口，別再提。
- limrun 冒出兩台沒標籤的實例，都是 5 分鐘沒人動自己關了，疑似 `--create` 預設補開的；指令帶 `--no-create` 就好，不用再查。
- 模擬器沒有加速度計，點牠不會跳「動作與方向」權限，不是 bug。
- 線上網頁第一次開整頁空白一次、重開就好，重現不了，沒改程式。
- 網頁調整面板在 402 寬排版會爆（開發用），多米說要修再修。
